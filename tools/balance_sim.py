#!/usr/bin/env python3
"""Balance check for Plumb Line: a port of scripts/structure.gd physics, run with bots.

Reads the level data straight from scripts/towns.gd. For every level it reports:
  idle   what happens if the player does nothing (it should fall, or fail to clear)
  bot    how often a human-paced bot clears it, and how long a clear takes
Keep the physics here in step with structure.gd and main.gd.
"""
import math, random, re, sys, copy, itertools, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
DT = 1 / 120
BODY_M = 100.0
BODY_H = {"campanile": 62, "watertower": 45, "crane": 60, "barge": 30, "clock": 62, "pier": 58, "mast": 70}
PUMP, PIPE, RATE_K, MIN_RATE, DECK, LAG, G = 5.0, 0.7, 110.0, 4.0, 94.0, 0.18, 400.0
BAND, HOLD, FAIL, CREEP, STILL, W_WAVE = 0.3, 3.0, 9.0, 0.08, 0.8, 2.4
GUST_K = 0.016
rad, deg = math.radians, math.degrees


def load_towns():
    src = (ROOT / "scripts/towns.gd").read_text()
    body = src[src.index("const TOWNS := ") + len("const TOWNS := "):]
    return eval(body, {"true": True, "false": False})


def prep(src):
    it = copy.deepcopy(src)
    for k, v in list(it.items()):
        if isinstance(v, int):
            it[k] = float(v)
    kind = it["kind"]
    if kind == "tank":
        it.update(pipe=0.0, slosh=0.0, slosh_v=0.0, leak=0.0, leak_left=0.0)
    elif kind == "load":
        it["phi_v"] = 0.0
    elif kind == "winch":
        it.update(m=0.0, spool=0.0)
    elif kind != "train":
        it["tx"] = it["x"]
        it.setdefault("rate", max(MIN_RATE, RATE_K / it["m"]))
    return it


def mass(it):
    if it["kind"] == "tank":
        return it["level"]
    if it["kind"] == "train":
        return it["m"] * max(0.0, 1.0 - abs(it["x"]) / DECK)
    return it["m"]


class S:
    def __init__(self, d):
        self.type = d["type"]
        self.items = []
        self.creep = self.ext = self.alpha = self.omega = self.settle = self.creep_rate = self.wave_amp = 0.0
        self.pump = -1
        self.body_h = BODY_H[self.type]
        ans, wh = 0.0, BODY_M * self.body_h
        for src in d["items"]:
            it = prep(src)
            k = it["kind"]
            if k == "tank":
                ans += it["ans"] * it["x"]; wh += it["level"] * it["y"]
            elif k == "load":
                ans += it["m"] * it["x"]; wh += it["m"] * it["y"]
            elif k != "winch":
                ans += it["m"] * it["ans"]; wh += it["m"] * it["y"]
            self.items.append(it)
        self.body_x = -ans / BODY_M
        self.stiff = wh * (d.get("soil", 1.35) - 1)
        self.k = wh + self.stiff
        w = math.tau / d.get("period", 2.2)
        self.w, self.zeta = w, d.get("zeta", 0.5)
        self.inertia = self.stiff / (w * w)
        self.c = 2 * d.get("zeta", 0.5) * math.sqrt(self.inertia * self.stiff)
        if "unstable" in d:
            self.k = wh - self.stiff * d["unstable"]
            self.theta = rad(d.get("lean", 1.0))
        else:
            mx, wy = self.moments()
            th = 0.0
            for _ in range(30):
                th = (mx * math.cos(th) + wy * (math.sin(th) - th)) / (self.k - wy)
            self.theta = th

    def moments(self):
        mx, wh = BODY_M * self.body_x + self.creep, BODY_M * self.body_h
        for it in self.items:
            m, x, k = mass(it), it["x"], it["kind"]
            if k == "tank":
                x += it["slosh"]; wh += it["pipe"] * it["y"]
            elif k == "load":
                mx += m * math.sin(it["phi"]) * it["y"] * 0.35
            elif k == "winch":
                mx += it["side"] * rad(it["force"]) * self.stiff * it["spool"]
            mx += m * x
            wh += m * it["y"]
        return mx, wh

    def has_trains(self):
        return any(i["kind"] == "train" and (i["x"] * i["speed"] < 0 or abs(i["x"]) < DECK) for i in self.items)

    def capacity(self, d):
        tot, water, now, tanks = 0.0, 0.0, 0.0, []
        for it in self.items:
            k = it["kind"]
            if k in ("bell", "crate", "counter"):
                tot += it["m"] * (it["max"] - it["x"] if d > 0 else it["x"] - it["min"])
            elif k == "winch":
                return math.inf
            elif k == "tank":
                water += it["level"]; now += it["level"] * it["x"]; tanks.append(it)
        if len(tanks) > 1:
            best = 0.0
            for it in sorted(tanks, key=lambda t: -t["x"] * d):
                put = min(water, it["cap"]); best += put * it["x"]; water -= put
            tot += (best - now) * d
        return tot

    def step(self, dt, active=True):
        items = self.items
        if self.pump >= 0 and items[self.pump]["kind"] == "tank":
            dst = items[self.pump]
            others = [i for i in items if i is not dst and i["kind"] == "tank"]
            avail = sum(i["level"] for i in others)
            room = dst["cap"] - dst["level"] - dst["pipe"]
            amt = min(PUMP * dt, min(avail, room))
            if amt > 0:
                for i in others:
                    i["level"] -= amt * i["level"] / avail
                dst["pipe"] += amt
        for n, it in enumerate(items):
            k = it["kind"]
            if k in ("bell", "crate", "counter"):
                dx = it["tx"] - it["x"]; mv = it["rate"] * dt
                it["x"] += max(-mv, min(mv, dx))
            elif k == "winch":
                t = 1.0 if self.pump == n else 0.0
                it["spool"] += max(-dt / LAG, min(dt / LAG, t - it["spool"]))
            elif k == "train":
                it["x"] += it["speed"] * dt
            elif k == "tank":
                lost = min(it["leak"] * dt, it["leak_left"], it["level"])
                it["level"] -= lost; it["leak_left"] -= lost
                fl = it["pipe"] * dt / PIPE
                it["pipe"] -= fl; it["level"] += fl
                a = -36 * it["slosh"] - 0.9 * it["slosh_v"] - self.alpha * 30 + fl / dt * 0.6
                it["slosh_v"] += a * dt
                it["slosh"] = max(-5.0, min(5.0, it["slosh"] + it["slosh_v"] * dt))
            elif k == "load":
                a = -G / it["len"] * math.sin(it["phi"]) - it["damp"] * it["phi_v"] - self.alpha * it["y"] / it["len"]
                it["phi_v"] += a * dt; it["phi"] += it["phi_v"] * dt
        if active:
            self.creep += (self.creep_rate * self.theta + self.settle) * self.stiff * dt
        mx, wh = self.moments()
        tau = mx * math.cos(self.theta) + wh * math.sin(self.theta) - self.k * self.theta - self.c * self.omega + self.ext
        self.alpha = tau / self.inertia
        self.omega += self.alpha * dt
        self.theta += self.omega * dt
        self.items[:] = [i for i in items if not (i["kind"] == "train" and i["x"] * i["speed"] > 0 and abs(i["x"]) > 260)]


def amp_torque(st, amp, w):
    return amp * math.sqrt((st.stiff - st.inertia * w * w) ** 2 + (st.c * w) ** 2)


class Game:
    def __init__(self, lv, rng):
        self.lv, self.rng = lv, rng
        self.structs = [S(d) for d in lv["structs"]]
        for st in self.structs:
            st.creep_rate = lv.get("creep", CREEP)
            st.settle = rad(lv.get("settle", 0.0)) * self.sag(st)
            if "waves" in lv:
                st.wave_amp = amp_torque(st, rad(lv["waves"]), W_WAVE)
        self.hold = 0.0; self.stage = 0; self.t = 0.0; self.gust = 0.0; self.gust_t = 3.0
        self.moves = int(lv.get("moves", -1)); self.out = 0.0
        self.timers = [e["every"] for e in lv.get("timed", [])]
        self.done = None

    def sag(self, st):
        d = 1.0 if self.rng.random() < 0.5 else -1.0
        return d if st.capacity(-d) >= st.capacity(d) * 0.35 else -d

    def fire(self, ev):
        st = self.structs[int(ev.get("s", 0))]
        e, r = ev["e"], self.rng
        if e == "tremor":
            d = self.sag(st)
            mag = min(ev["mag"], deg(st.capacity(-d) * 0.7 / st.stiff))
            st.creep += d * rad(mag) * st.stiff; st.omega += d * rad(mag) * 1.5
        elif e == "gust":
            self.gust = 1.6 if r.random() < 0.5 else -1.6
        elif e == "add":
            st.items.append(prep(ev["item"]))
        elif e == "swing":
            for it in st.items:
                if it["kind"] == "load":
                    it["phi_v"] += ev["v"] * (1 if r.random() < 0.5 else -1)
        elif e == "load":
            for it in st.items:
                if it["kind"] == "load":
                    it["m"] = max(4.0, it["m"] + ev["dm"])
        elif e == "leak":
            for it in st.items:
                if it["kind"] == "tank":
                    it["leak"] = 0.0
            st.items[int(ev["i"])]["leak"] = ev["rate"]
            st.items[int(ev["i"])]["leak_left"] = ev.get("amount", 5.0)
        elif e == "train":
            for c in ev["cars"]:
                d = float(c["dir"])
                st.items.append(prep({"kind": "train", "m": c["m"], "y": 122.0, "x": -d * (150 + c.get("lead", 0)), "speed": d * c["speed"]}))

    def step(self, dt):
        lv = self.lv
        self.t += dt
        for i, e in enumerate(lv.get("timed", [])):
            self.timers[i] -= dt
            if self.timers[i] <= 0:
                self.timers[i] = e["every"] * self.rng.uniform(0.8, 1.2)
                self.fire(e)
        if lv.get("gusts"):
            self.gust_t -= dt
            if self.gust_t <= 0:
                self.gust = self.rng.uniform(0.6, 1.0) * (1 if self.rng.random() < 0.5 else -1)
                self.gust_t = self.rng.uniform(5.5, 9.0)
            self.gust += max(-dt * 1.4, min(dt * 1.4, -self.gust))
        ss = self.structs
        for i, st in enumerate(ss):
            ext = 0.0
            if "waves" in lv:
                ext += st.wave_amp * (math.sin(W_WAVE * self.t) + 0.5 * math.sin(W_WAVE * 1.7 * self.t + 1.3))
            ext += self.gust * st.stiff * lv.get("gust_k", GUST_K)
            if "couple" in lv and len(ss) == 2:
                o = ss[1 - i]
                ext += lv["couple"] * min(st.stiff, o.stiff) * (o.theta - st.theta)
            st.ext = ext
        for st in ss:
            st.step(dt)
        band, still = rad(lv.get("band", BAND)), lv.get("still", STILL)
        calm = True
        for st in ss:
            if abs(st.theta) > band or st.has_trains():
                calm = False
            elif "waves" not in lv and abs(deg(st.omega)) > still:
                calm = False
        self.hold = self.hold + dt if calm else max(0.0, self.hold - 1.5 * dt)
        if self.hold >= lv.get("hold", HOLD):
            evs = lv.get("events", [])
            if self.stage >= len(evs):
                self.done = "clear"; return
            self.fire(evs[self.stage]); self.stage += 1; self.hold = 0.0
            sag = rad(lv.get("settle", 0.0))
            for st in ss:
                st.settle = sag * self.sag(st)
            return
        fail = rad(lv.get("fail", FAIL))
        if any(abs(st.theta) > fail for st in ss):
            self.done = "fell"; return
        if self.moves == 0 and not calm:
            self.out += dt
            if self.out >= 3.0:
                self.done = "fell"
        else:
            self.out = 0.0


def solve_notched(game):
    """Exhaustive: the fewest item moves that stand every notched tower straight."""
    plans, ok = [], True
    for st in game.structs:
        its = [i for i in st.items if i["kind"] == "bell"]
        mx0 = BODY_M * st.body_x + sum(mass(i) * i["x"] for i in st.items)
        options = [[i["min"] + n * i["notch"] for n in range(int((i["max"] - i["min"]) / i["notch"]) + 1)] for i in its]
        best, count = None, 0
        tol = rad(game.lv["band"]) * st.stiff
        for combo in itertools.product(*options):
            mx = mx0 + sum(i["m"] * (c - i["x"]) for i, c in zip(its, combo))
            if abs(mx) <= tol:
                mv = sum(abs(c - i["x"]) > 0.01 for i, c in zip(its, combo))
                if mv <= (game.moves if game.moves >= 0 else 99):
                    count += 1
                if best is None or mv < best[0]:
                    best = (mv, combo, its)
        plans.append((best, count))
    return plans


def bot_play(lv, rng, react=0.22, limit=420.0, skill=1.0):
    """A human-paced player: looks every `react` seconds at a slightly stale tilt."""
    g = Game(lv, rng)
    if "moves" in lv:  # puzzle: a player who has worked it out, one move at a time
        for best, _ in solve_notched(g):
            if best is None:
                return "unsolvable", 0.0
            for i, c in zip(best[2], best[1]):
                i["tx"] = c
        while g.done is None and g.t < limit:
            g.step(DT)
        return g.done or "timeout", g.t
    buf = []
    next_look = 0.6
    wait_until = 0.0
    pump_until = 0.0
    bias = 0.0
    delay = int(react / DT)
    while g.done is None and g.t < limit:
        buf.append([(s.theta, s.omega) for s in g.structs])
        if g.t >= pump_until:
            for st in g.structs:
                if st.pump >= 0 and st.items[st.pump]["kind"] == "tank":
                    st.pump = -1
        if g.t >= next_look:
            next_look = g.t + react * rng.uniform(0.8, 1.3)
            del buf[:-int(6 / DT)]
            obs = buf[max(0, len(buf) - 1 - delay)]
            i = max(range(len(g.structs)), key=lambda n: abs(obs[n][0]))
            st = g.structs[i]
            th, om = obs[i]
            band = rad(g.lv.get("band", BAND))
            still = rad(g.lv.get("still", STILL))
            period = math.tau / st.w
            kinds = {it["kind"] for it in st.items}
            if "winch" in kinds:
                pred = th + om * 0.7
                st.pump = -1
                if abs(pred) > band * 0.3:
                    want = -1 if pred > 0 else 1
                    st.pump = next(n for n, it in enumerate(st.items) if it["kind"] == "winch" and it["side"] == want)
            elif st.type == "pier":
                # Mirror the train, trimming away any lean that is left over.
                c = next(it for it in st.items if it["kind"] == "counter")
                ff = -sum(mass(it) * (it["x"] + it["speed"] * react * 2) for it in st.items if it["kind"] == "train") / c["m"]
                bias += -(th + 0.35 * om) * st.stiff / c["m"] * 0.12
                c["tx"] = max(c["min"], min(c["max"], ff + bias))
            elif g.t >= wait_until:
                if "tank" in kinds:
                    rest = th + 2 * st.zeta / st.w * om
                    if abs(rest) > band * 0.45:
                        err = -rest * st.stiff
                        ts = [(n, it) for n, it in enumerate(st.items) if it["kind"] == "tank"]
                        n, dst = max(ts, key=lambda a: a[1]["x"] * (1 if err > 0 else -1))
                        lever = max(abs(dst["x"]) * 1.5, 1.0)
                        pulse = min(1.2, abs(err) / (PUMP * lever))
                        st.pump = n
                        pump_until = g.t + pulse
                        wait_until = pump_until + PIPE + period * 0.45
                else:
                    span = 5.2 if "waves" in g.lv else (2.2 if "load" in kinds else 0)
                    rest = th + 2 * st.zeta / st.w * om
                    if span:
                        win = buf[-int(span / DT):]
                        rest = sum(b[i][0] for b in win) / len(win)
                    if abs(rest) > band * 0.4:
                        err = -rest * st.stiff
                        mov = [it for it in st.items if it["kind"] in ("bell", "crate", "counter")]
                        mov = [it for it in mov if (it["max"] - it["x"] if err > 0 else it["x"] - it["min"]) > 0.2]
                        if mov:
                            heavy = abs(err) > band * st.stiff * 1.5
                            it = max(mov, key=lambda a: a["m"]) if heavy else min(mov, key=lambda a: a["m"])
                            it["tx"] = max(it["min"], min(it["max"], it["x"] + err / it["m"]))
                            wait_until = g.t + abs(it["tx"] - it["x"]) / it["rate"] + max(span, period * 0.45)
        g.step(DT)
    return g.done or "timeout", g.t


def idle_play(lv, rng, limit=180.0):
    g = Game(lv, rng)
    while g.done is None and g.t < limit:
        g.step(DT)
    return g.done or "timeout", g.t


def main():
    runs = int(sys.argv[1]) if len(sys.argv) > 1 else 12
    towns = load_towns()
    grand, problems = 0.0, []
    for t in towns:
        print(f"\n{t['name']}")
        for li, lv in enumerate(t["levels"]):
            rng = random.Random(li * 97 + len(t["name"]))
            start = [deg(S(d).theta) for d in lv["structs"]]
            fail = lv.get("fail", FAIL)
            idle, idle_t = idle_play(lv, rng)
            res = [bot_play(lv, rng) for _ in range(runs)]
            wins = [x for r, x in res if r == "clear"]
            rate = len(wins) / runs
            mean = sum(wins) / len(wins) if wins else 0
            extra = ""
            if "moves" in lv:
                g = Game(lv, rng)
                extra = " solutions=" + "/".join(str(c) for _, c in solve_notched(g))
            print(f"  L{li+1} start={'/'.join(f'{a:+.1f}' for a in start):>12}°  idle:{idle} {idle_t:5.0f}s  bot:{rate:4.0%} clear, avg {mean:5.0f}s{extra}")
            grand += mean / max(rate, 0.25)
            if rate < 0.25:
                problems.append(f"{t['name']} L{li+1}: bot clears only {rate:.0%}")
            if idle == "clear":
                problems.append(f"{t['name']} L{li+1}: clears itself with no input")
            if max(abs(a) for a in start) > fail * 0.8:
                problems.append(f"{t['name']} L{li+1}: starts at {max(map(abs, start)):.1f}° vs fail {fail}°")
    print(f"\nEstimated bot play time, including retries: {grand/60:.0f} min")
    print("PROBLEMS:" if problems else "No problems.")
    for p in problems:
        print(" -", p)


if __name__ == "__main__":
    main()
