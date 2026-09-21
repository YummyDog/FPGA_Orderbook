"""
Cycle-accurate model of order_book + ram_array, to reproduce the test 4 hang.

Transcribed from the RTL, not from intent - including the parts that look
wrong. The point is to find where it wedges, so anything "corrected" on the
way in would hide the answer.

Covers: the table counter, the insert (cuckoo eviction) process, the
lookup/modify process, the shared read addresses, and ram_sdp's READ_FIRST
behaviour with one cycle of read latency.
"""

# --- geometry, from ram_pkg ------------------------------------------------
NUM_TABLES = 4
ADDR_W = 4
DEPTH = 1 << ADDR_W
KEY_W = 65
VAL_W = 66
SLOT_W = 1 + KEY_W + VAL_W          # 132
VALID_BIT = SLOT_W - 1              # 131
KEY_LO, KEY_HI = VAL_W, SLOT_W - 2  # 66 .. 130
KEY_MASK = (1 << KEY_W) - 1
VAL_MASK = (1 << VAL_W) - 1
QTY_LO = 34                         # value = qty(32) price(32) undisc implied

OP_ADD, OP_EXEC, OP_REPLACE, OP_DELETE = 0, 1, 2, 3
OP_NAME = ("ADD", "EXEC", "REPL", "DEL")


# --- hash65 ---------------------------------------------------------------
def xorshift64(x):
    m = (1 << 64) - 1
    x ^= (x << 13) & m
    x ^= x >> 7
    x ^= (x << 17) & m
    return x & m


def build_masks():
    s = 0x9E3779B97F4A7C15
    masks = []
    for _t in range(NUM_TABLES):
        rows = []
        for b in range(ADDR_W):
            v = 0
            for i in range(KEY_W - 1, -1, -1):      # C_KEY_W-1 downto 0
                s = xorshift64(s)
                v |= (s & 1) << i
            v &= ~((1 << ADDR_W) - 1)               # clear low ADDR_W bits
            v |= (1 << b)                           # one-hot at b
            rows.append(v)
        masks.append(rows)
    return masks


MASKS = build_masks()


def hash_(key, tbl):
    h = 0
    for b in range(ADDR_W):
        h |= (bin(key & MASKS[tbl][b]).count("1") & 1) << b
    return h


# --- slot helpers ---------------------------------------------------------
def make_slot(valid, key, val):
    return (valid << VALID_BIT) | ((key & KEY_MASK) << KEY_LO) | (val & VAL_MASK)


def slot_valid(s):
    return (s >> VALID_BIT) & 1


def slot_key(s):
    return (s >> KEY_LO) & KEY_MASK


def slot_vkey(s):
    return (s >> KEY_LO) & ((1 << (KEY_W + 1)) - 1)   # valid + key, 66 bits


def slot_val(s):
    return s & VAL_MASK


def modify_func(op, lookup, prev, modify):
    """ram_pkg.modify_func, transcribed."""
    prev_qty = (prev >> QTY_LO) & 0xFFFFFFFF
    mod_qty = (modify >> QTY_LO) & 0xFFFFFFFF
    if op == OP_EXEC and mod_qty < prev_qty:
        notqty = modify & ((1 << QTY_LO) - 1)
        return make_slot(1, lookup, ((prev_qty - mod_qty) << QTY_LO) | notqty)
    if op == OP_REPLACE:
        return make_slot(1, lookup, modify)
    return 0


class OrderBook:
    def __init__(self, log=None):
        self.mem = [[0] * DEPTH for _ in range(NUM_TABLES)]
        self.rdata = [0] * NUM_TABLES

        self.table_cnt = 0
        self.busy = 0
        self.key_r = 0          # valid + key, 66 bits
        self.value_r = 0
        self.addr_r = 0
        self.ins_we = 0
        self.ins_waddr = 0
        self.ins_wdata = 0
        self.ins_wsel = 0
        self.evicting = 0

        self.looking = 0
        self.lookup_r = 0
        self.modify_r = 0
        self.op_r = OP_ADD
        self.mod_we = 0
        self.mod_waddr = 0
        self.mod_wdata = 0
        self.mod_wsel = 0

        self.cycle = 0
        self.log = log if log is not None else []

    # --- combinational ----------------------------------------------------
    def s_tready(self):
        return 0 if (self.busy or self.looking or self.mod_we) else 1

    def raddr(self, key):
        """g_raddr_i: live key when idle, the evicted key's hashes when busy."""
        if not self.busy:
            return [hash_(key, i) for i in range(NUM_TABLES)]
        prev = (self.table_cnt - 1) & (NUM_TABLES - 1)
        k = slot_key(self.rdata[prev])
        return [hash_(k, i) for i in range(NUM_TABLES)]

    # --- one clock --------------------------------------------------------
    def step(self, s_valid, s_op, s_key, s_value):
        """
        Advance one cycle. s_* are what the slave bus PRESENTS this cycle,
        whether or not it is accepted. Returns True if it was accepted.
        """
        c = self.cycle
        tready = self.s_tready()
        xfer = s_valid and tready

        raddr = self.raddr(s_key)
        prev = (self.table_cnt - 1) & (NUM_TABLES - 1)

        # ---- next state: counter ----
        if xfer or self.busy:
            n_table_cnt = 0 if self.table_cnt == NUM_TABLES - 1 else self.table_cnt + 1
        else:
            n_table_cnt = 0

        # ---- next state: insert ----
        n_busy, n_key_r, n_value_r, n_addr_r = (self.busy, self.key_r,
                                                self.value_r, self.addr_r)
        n_ins_we, n_ins_waddr = self.ins_we, self.ins_waddr
        n_ins_wdata, n_ins_wsel = self.ins_wdata, self.ins_wsel
        n_evicting = self.evicting

        if xfer and s_op == OP_ADD:
            n_busy = 1
            n_key_r = (1 << KEY_W) | s_key          # '1' & key
            n_value_r = s_value
            n_addr_r = hash_(s_key, 0)
        elif not self.busy:
            n_key_r, n_addr_r, n_value_r = 0, 0, 0
        else:
            n_key_r = slot_vkey(self.rdata[prev])
            n_value_r = slot_val(self.rdata[prev])
            n_addr_r = hash_(slot_key(self.rdata[prev]), self.table_cnt)

        if self.busy:
            if self.ins_we:
                n_evicting = 1
            n_ins_we = 1
            n_ins_waddr = self.addr_r
            n_ins_wdata = (self.key_r << VAL_W) | self.value_r
            n_ins_wsel = prev
            if slot_valid(self.rdata[prev]) == 0:
                n_busy = 0
        else:
            n_evicting = 0
            n_ins_we, n_ins_waddr, n_ins_wdata, n_ins_wsel = 0, 0, 0, 0

        # ---- next state: lookup ----
        n_looking, n_lookup_r = self.looking, self.lookup_r
        n_modify_r, n_op_r = self.modify_r, self.op_r
        n_mod_we, n_mod_waddr = self.mod_we, self.mod_waddr
        n_mod_wdata, n_mod_wsel = self.mod_wdata, self.mod_wsel

        if xfer and s_op in (OP_DELETE, OP_REPLACE, OP_EXEC):
            n_looking = 1
            n_lookup_r = s_key
            n_modify_r = s_value
            n_op_r = s_op
        elif not self.looking:
            n_lookup_r, n_modify_r, n_op_r = 0, 0, OP_ADD

        if self.looking:
            prev_val = 0
            hit = None
            for i in range(NUM_TABLES):
                if (slot_key(self.rdata[i]) == self.lookup_r
                        and slot_valid(self.rdata[i]) == 1):
                    # NOTE: raddr_i is sampled NOW, one cycle after the read
                    # that produced rdata was issued.
                    n_mod_waddr = raddr[i]
                    n_mod_we = 1
                    n_mod_wsel = i
                    prev_val = slot_val(self.rdata[i])
                    hit = i
            n_looking = 0
            n_mod_wdata = modify_func(self.op_r, self.lookup_r, prev_val,
                                      self.modify_r)
            if hit is not None:
                self.log.append(
                    f"cyc {c:3d}  LOOKUP hit  op={OP_NAME[self.op_r]} "
                    f"table={hit} correct_addr={hash_(self.lookup_r, hit)} "
                    f"USED_addr={raddr[hit]}"
                    + ("   <-- WRONG ADDRESS"
                       if raddr[hit] != hash_(self.lookup_r, hit) else ""))
        else:
            n_mod_we, n_mod_waddr, n_mod_wdata, n_mod_wsel = 0, 0, 0, 0

        # ---- memory: READ_FIRST, one cycle latency ----
        n_rdata = [self.mem[i][raddr[i]] for i in range(NUM_TABLES)]

        we = self.ins_we or self.mod_we
        if we:
            waddr = self.ins_waddr | self.mod_waddr
            wdata = self.ins_wdata | self.mod_wdata
            wsel = self.ins_wsel | self.mod_wsel
            self.mem[wsel][waddr] = wdata

        # ---- commit ----
        self.rdata = n_rdata
        self.table_cnt = n_table_cnt
        self.busy, self.key_r, self.value_r, self.addr_r = (n_busy, n_key_r,
                                                            n_value_r, n_addr_r)
        self.ins_we, self.ins_waddr = n_ins_we, n_ins_waddr
        self.ins_wdata, self.ins_wsel = n_ins_wdata, n_ins_wsel
        self.evicting = n_evicting
        self.looking, self.lookup_r = n_looking, n_lookup_r
        self.modify_r, self.op_r = n_modify_r, n_op_r
        self.mod_we, self.mod_waddr = n_mod_we, n_mod_waddr
        self.mod_wdata, self.mod_wsel = n_mod_wdata, n_mod_wsel
        self.cycle += 1

        return bool(xfer)

    def occupancy(self):
        return sum(slot_valid(s) for t in self.mem for s in t)

    def contents(self):
        out = []
        for t in range(NUM_TABLES):
            for a in range(DEPTH):
                s = self.mem[t][a]
                if slot_valid(s):
                    out.append((t, a, slot_key(s),
                                (slot_val(s) >> QTY_LO) & 0xFFFFFFFF))
        return out
