#!/usr/bin/env python3
import json
import math
import os
import sys
import base64
import re
from datetime import date, timedelta

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VECTORS_PATH = os.path.join(ROOT, "contracts", "vectors.json")
EGGS_PATH = os.path.join(ROOT, "Packages", "SummitCore", "Sources", "SummitCore", "Resources", "eggs.json")
FOODS_PATH = os.path.join(ROOT, "Packages", "SummitCore", "Sources", "SummitCore", "Resources", "foods.json")


def js_round(x):
    if x != x:
        return x
    f = math.floor(x + 0.5)
    if f == 0 and (x < 0 or math.copysign(1, x) < 0):
        return -0.0
    return float(f)


def round8(n):
    if math.isinf(n) or n != n:
        return n
    return js_round(n * 1e8) / 1e8


def group_integer(digits):
    n = len(digits)
    out = []
    for i, ch in enumerate(digits):
        pos_from_right = n - i
        out.append(ch)
        if pos_from_right > 1 and pos_from_right % 3 == 1:
            out.append(",")
    return "".join(out)


def to_exponential4(value):
    if value == 0:
        neg = math.copysign(1, value) < 0
        return ("-" if neg else "") + "0.0000e+0"
    neg = value < 0
    v = abs(value)
    s = "%.4e" % v
    mantissa, exp = s.split("e")
    exp = int(exp)
    esign = "+" if exp >= 0 else "-"
    return ("-" if neg else "") + mantissa + "e" + esign + str(abs(exp))


def fmt_grouped(r):
    neg = r < 0
    v = abs(r)
    s = "%.8f" % v
    intpart, fracpart = s.split(".")
    fracpart = fracpart.rstrip("0")
    grouped = group_integer(intpart)
    out = grouped + ("." + fracpart if fracpart else "")
    return ("-" if neg else "") + out


def shortest_digits_and_exponent(value):
    for precision in range(0, 17):
        s = "%.*e" % (precision, value)
        if float(s) == value:
            return parse_exponential_form(s)
    s = "%.16e" % value
    return parse_exponential_form(s)


def parse_exponential_form(s):
    mantissa, exp = s.split("e")
    exp_value = int(exp)
    digits = mantissa.replace(".", "").replace("-", "")
    while len(digits) > 1 and digits.endswith("0"):
        digits = digits[:-1]
    n = exp_value + 1
    return digits, n


def number_to_string(value):
    if value != value:
        return "NaN"
    if value == 0:
        return "0"
    neg = value < 0 or math.copysign(1, value) < 0
    v = abs(value)
    if math.isinf(v):
        return "-Infinity" if neg else "Infinity"
    digits, n = shortest_digits_and_exponent(v)
    k = len(digits)
    sign = "-" if neg else ""
    if k <= n <= 21:
        return sign + digits + "0" * (n - k)
    if 0 < n <= 21:
        return sign + digits[:n] + "." + digits[n:]
    if -6 < n <= 0:
        return sign + "0." + "0" * (-n) + digits
    if k == 1:
        mant = digits
    else:
        mant = digits[0] + "." + digits[1:]
    e = n - 1
    esign = "+" if e >= 0 else "-"
    return sign + mant + "e" + esign + str(abs(e))


def fmt(n):
    if math.isinf(n) or n != n:
        return "Error"
    if n == 0:
        return "0"
    absn = abs(n)
    if absn >= 1e15 or (0 < absn < 1e-6):
        return to_exponential4(n)
    r = round8(n)
    return fmt_grouped(r)


def plain(n):
    return number_to_string(round8(n))


def money(n):
    safe = 0.0 if (math.isinf(n) or n != n) else n
    neg = safe < 0 or (safe == 0 and math.copysign(1, safe) < 0)
    v = abs(safe)
    scaled = v * 100.0
    cents_rounded = math.floor(scaled + 0.5)
    cents_str = "%.0f" % cents_rounded
    while len(cents_str) < 3:
        cents_str = "0" + cents_str
    intpart = cents_str[:-2]
    fracpart = cents_str[-2:]
    grouped = group_integer(intpart)
    sign = "-" if neg else ""
    return "$" + sign + grouped + "." + fracpart


def usd(n):
    safe = 0.0 if (math.isinf(n) or n != n) else n
    r = js_round(safe)
    neg = r < 0 or (r == 0 and math.copysign(1, r) < 0)
    v = abs(r)
    intpart = "%.0f" % v
    grouped = group_integer(intpart)
    sign = "-" if neg else ""
    return "$" + sign + grouped


JS_EPSILON = 2.220446049250313e-16


def round2(n):
    return js_round((n + JS_EPSILON) * 100.0) / 100.0


def future_value(principal, monthly, annual_rate_pct, years):
    i = annual_rate_pct / 100.0 / 12.0
    n = years * 12.0
    if i == 0:
        return principal + monthly * n
    return principal * ((1 + i) ** n) + monthly * (((1 + i) ** n - 1) / i)


def contributions(principal, monthly, years):
    n = years * 12.0
    return principal + monthly * n


def loan_payment(principal, annual_rate_pct, years):
    p = principal
    i = annual_rate_pct / 100.0 / 12.0
    n = years * 12.0
    if i == 0:
        return p / n
    return (p * i) / (1 - (1 + i) ** (-n))


def savings_goal_payment(target, principal, annual_rate_pct, years):
    start = principal
    i = annual_rate_pct / 100.0 / 12.0
    n = years * 12.0
    grow = (1 + i) ** n
    fv_factor = n if i == 0 else (grow - 1) / i
    return (target - start * grow) / fv_factor


def real_rate(nominal_pct, inflation_pct):
    nom = nominal_pct / 100.0
    inf = inflation_pct / 100.0
    return ((1 + nom) / (1 + inf) - 1) * 100.0


def employer_match(salary, contrib_pct, match_pct, match_limit_pct):
    c = contrib_pct
    cap = match_limit_pct
    rate = match_pct / 100.0
    return (salary * min(c, cap)) / 100.0 * rate


def rule_of72(rate_pct):
    return 72.0 / rate_pct


def tip(bill, tip_pct, people):
    n = 1.0 if people == 0 else float(people)
    t = (bill * tip_pct) / 100.0
    total = bill + t
    return round2(t), round2(total), round2(total / n)


def percent_of(pct, value):
    return (value * pct) / 100.0


def percent_change(a, b):
    return ((b - a) / a) * 100.0


class CalcEngine:
    def __init__(self):
        self.current = "0"
        self.overwrite = True
        self.stored = None
        self.op = None
        self.parts = []

    def digit(self, d):
        if self.overwrite:
            self.current = d
            self.overwrite = False
        else:
            self.current = d if self.current == "0" else self.current + d

    def dot(self):
        if self.overwrite:
            self.current = "0."
            self.overwrite = False
        elif "." not in self.current:
            self.current += "."

    @staticmethod
    def compute(a, b, op):
        if op == "add":
            return a + b
        if op == "subtract":
            return a - b
        if op == "multiply":
            return a * b
        if op == "divide":
            return float("nan") if b == 0 else a / b
        raise ValueError("bad op")

    @staticmethod
    def symbol(op):
        return {"add": "+", "subtract": "\u2212", "multiply": "\u00d7", "divide": "\u00f7"}[op]

    def parse_current(self):
        try:
            return float(self.current)
        except ValueError:
            return 0.0

    def set_op(self, new_op):
        sym = self.symbol(new_op)
        if self.overwrite and self.op is not None:
            self.op = new_op
            if self.parts:
                self.parts[-1] = sym
            return
        self.parts.append(self.current)
        self.parts.append(sym)
        if self.op is not None and not self.overwrite:
            a = self.stored if self.stored is not None else 0
            b = self.parse_current()
            res = self.compute(a, b, self.op)
            self.stored = res
            self.current = plain(res)
        else:
            self.stored = self.parse_current()
        self.op = new_op
        self.overwrite = True

    def equals(self):
        if self.op is None:
            return None
        a = self.stored if self.stored is not None else 0
        b = self.parse_current()
        op = self.op
        res = self.compute(a, b, op)
        self.parts.append(self.current)
        seq = "".join(self.parts)
        expr_text = " ".join(self.parts)
        finite = math.isfinite(res)
        display = fmt(res) if finite else "Error"
        self.current = plain(res) if finite else "0"
        self.stored = None
        self.op = None
        self.overwrite = True
        self.parts = []
        return {"display": display, "expression": expr_text, "sequence": seq}

    def clear_all(self):
        self.current = "0"
        self.stored = None
        self.op = None
        self.overwrite = True
        self.parts = []

    def toggle_sign(self):
        if self.current != "0":
            self.current = self.current[1:] if self.current.startswith("-") else "-" + self.current

    def percent(self):
        v = self.parse_current() / 100.0
        self.current = plain(v)
        self.overwrite = True

    def expression_text(self):
        return "" if not self.parts else " ".join(self.parts)


def run_keys(keys):
    calc = CalcEngine()
    last_equals = None
    for k in keys:
        if len(k) == 1 and k.isdigit():
            calc.digit(k)
        elif k == ".":
            calc.dot()
        elif k == "+":
            calc.set_op("add")
        elif k in ("-", "\u2212"):
            calc.set_op("subtract")
        elif k in ("*", "\u00d7"):
            calc.set_op("multiply")
        elif k in ("/", "\u00f7"):
            calc.set_op("divide")
        elif k == "=":
            last_equals = calc.equals()
        elif k in ("C", "AC"):
            calc.clear_all()
        elif k in ("+/-", "\u00b1"):
            calc.toggle_sign()
        elif k == "%":
            calc.percent()
        else:
            raise ValueError("unknown key " + k)
    return calc, last_equals


with open(EGGS_PATH, encoding="utf-8") as f:
    EGGS = json.load(f)


def egg_match(sequence):
    for egg in EGGS:
        if sequence in egg["triggers"]:
            return egg
    return None


UNICODE_FRAC = {
    "\u00bd": 0.5, "\u2153": 1.0 / 3.0, "\u2154": 2.0 / 3.0, "\u00bc": 0.25, "\u00be": 0.75,
    "\u215b": 0.125, "\u215c": 0.375, "\u215d": 0.625, "\u215e": 0.875, "\u2155": 0.2,
    "\u2156": 0.4, "\u2157": 0.6, "\u2158": 0.8, "\u2159": 1.0 / 6.0, "\u215a": 5.0 / 6.0
}

UNIT_ALIASES = {
    "tsp": "tsp", "teaspoon": "tsp", "teaspoons": "tsp",
    "tbsp": "tbsp", "tbs": "tbsp", "tablespoon": "tbsp", "tablespoons": "tbsp",
    "cup": "cup", "cups": "cup",
    "oz": "oz", "ounce": "oz", "ounces": "oz",
    "lb": "lb", "lbs": "lb", "pound": "lb", "pounds": "lb",
    "g": "g", "gram": "g", "grams": "g", "gr": "g",
    "kg": "kg",
    "ml": "mL", "milliliter": "mL", "milliliters": "mL",
    "l": "L", "liter": "L", "liters": "L", "litre": "L", "litres": "L",
    "pinch": "pinch",
    "clove": "clove", "cloves": "clove",
    "can": "can", "cans": "can",
    "stick": "stick", "sticks": "stick",
    "slice": "slice", "slices": "slice",
    "pkg": "pkg", "package": "pkg"
}

BULLET_CHARS = set([" ", "\t", "\n", "\r", "-", "*", "\u2022", "\u2023", "\u25e6"])


def is_decimal_number_token(t):
    if not t:
        return False
    idx = 0
    n = len(t)
    saw_digit_before_dot = False
    while idx < n and t[idx].isdigit() and t[idx].isascii():
        saw_digit_before_dot = True
        idx += 1
    saw_dot = False
    if idx < n and t[idx] == ".":
        saw_dot = True
        idx += 1
    saw_digit_after_dot = False
    while idx < n and t[idx].isdigit() and t[idx].isascii():
        saw_digit_after_dot = True
        idx += 1
    if idx != n:
        return False
    if saw_dot:
        return saw_digit_after_dot
    return saw_digit_before_dot


def digit_plus_fraction(t):
    if not t:
        return None
    last = t[-1]
    if last not in UNICODE_FRAC:
        return None
    digits_part = t[:-1]
    if not digits_part:
        return None
    if not all(c.isdigit() and c.isascii() for c in digits_part):
        return None
    try:
        whole = int(digits_part)
    except ValueError:
        return None
    return whole + UNICODE_FRAC[last]


def plain_fraction(t):
    parts = t.split("/")
    if len(parts) != 2:
        return None
    num_str, den_str = parts
    if not num_str or not den_str:
        return None
    if not (all(c.isdigit() and c.isascii() for c in num_str) and all(c.isdigit() and c.isascii() for c in den_str)):
        return None
    try:
        num = float(num_str)
        den = float(den_str)
    except ValueError:
        return None
    if den == 0:
        return None
    return num / den


def plain_decimal(t):
    if not is_decimal_number_token(t):
        return None
    return float(t)


def range_first_value(t):
    dashes = set(["-", "\u2013", "\u2014"])
    dash_index = None
    for i, c in enumerate(t):
        if c in dashes:
            dash_index = i
            break
    if dash_index is None:
        return None
    left = t[:dash_index]
    right = t[dash_index + 1:]
    if not (is_decimal_number_token(left) and is_decimal_number_token(right)):
        return None
    return float(left)


def token_qty_value(t):
    if t in UNICODE_FRAC:
        return UNICODE_FRAC[t]
    v = digit_plus_fraction(t)
    if v is not None:
        return v
    v = plain_fraction(t)
    if v is not None:
        return v
    v = plain_decimal(t)
    if v is not None:
        return v
    v = range_first_value(t)
    if v is not None:
        return v
    return None


def strip_leading_bullets(line):
    i = 0
    while i < len(line) and line[i] in BULLET_CHARS:
        i += 1
    return line[i:]


def strip_dots_commas(s):
    return "".join(c for c in s if c not in ".,")


def strip_leading_of(s):
    if s.lower().startswith("of "):
        return s[3:]
    return s


def strip_trailing_comma_paren(s):
    for i, c in enumerate(s):
        if c == "," or c == "(":
            return s[:i].strip()
    return s


def parse_line(line):
    if not line:
        return None
    trimmed = strip_leading_bullets(line).strip()
    if not trimmed:
        return None
    tokens = trimmed.split()
    i = 0
    qty = 0.0
    has_qty = False
    while i < len(tokens):
        v = token_qty_value(tokens[i])
        if v is None:
            break
        qty += v
        has_qty = True
        i += 1
    unit = None
    if i < len(tokens):
        raw = strip_dots_commas(tokens[i].lower())
        if raw == "fl" and i + 1 < len(tokens):
            nxt = strip_dots_commas(tokens[i + 1].lower())
            if nxt in ("oz", "ounce", "ounces"):
                unit = "fl oz"
                i += 2
        if unit is None and raw in UNIT_ALIASES:
            unit = UNIT_ALIASES[raw]
            i += 1
    name = " ".join(tokens[i:])
    name = strip_leading_of(name)
    name = name.strip()
    name = strip_trailing_comma_paren(name)
    name = name.strip()
    if not name:
        name = trimmed
    return {"qty": qty if has_qty else None, "unit": unit, "name": name, "raw": trimmed}


def fmt_qty(n):
    if n is None or not math.isfinite(n):
        return ""
    if n <= 0:
        return "0"
    whole = math.floor(n + 1e-9)
    frac = n - whole
    table = [
        (0, ""), (0.125, "1/8"), (0.25, "1/4"), (1.0 / 3.0, "1/3"),
        (0.375, "3/8"), (0.5, "1/2"), (0.625, "5/8"), (2.0 / 3.0, "2/3"),
        (0.75, "3/4"), (0.875, "7/8"), (1, "")
    ]
    best = table[0]
    best_diff = abs(frac - table[0][0])
    for entry in table:
        d = abs(frac - entry[0])
        if d < best_diff:
            best_diff = d
            best = entry
    if best_diff < 0.04:
        if best[0] == 1:
            return "%.0f" % (whole + 1)
        if best[0] == 0:
            return "%.0f" % whole
        whole_part = ("%.0f" % whole) + " " if whole > 0 else ""
        return whole_part + best[1]
    rounded = js_round(n * 100.0) / 100.0
    return fmt(rounded)


VOL = {"tsp": 4.92892, "tbsp": 14.7868, "cup": 236.588, "fl oz": 29.5735, "mL": 1, "L": 1000}
WT = {"g": 1, "oz": 28.3495, "lb": 453.592}


def unit_convert(value, frm, to):
    if frm in VOL and to in VOL:
        return (value * VOL[frm]) / VOL[to]
    if frm in WT and to in WT:
        return (value * WT[frm]) / WT[to]
    return None


with open(FOODS_PATH, encoding="utf-8") as f:
    FOODS = json.load(f)


def food_match(raw):
    needle = raw.strip().lower()
    if not needle:
        return None
    for food in FOODS:
        if food["name"].lower() == needle:
            return food
    for food in FOODS:
        if food["name"].lower().startswith(needle):
            return food
    for food in FOODS:
        if needle in food["name"].lower():
            return food
    return None


def rel_close(got, expect, tol=1e-9):
    if expect == 0:
        return abs(got) < tol
    return abs((got - expect) / expect) < tol


BUDGET_MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August",
                 "September", "October", "November", "December"]


def budget_def_month():
    return {
        "inc2On": True,
        "inc": [
            {"label": "Income 1", "gross": 4200, "tax": 18, "ret": 5, "oth": 2},
            {"label": "Income 2", "gross": 3600, "tax": 16, "ret": 5, "oth": 0},
        ],
        "cats": [
            {"n": "Housing", "open": True, "goal": None, "items": [
                {"n": "Rent or mortgage", "a": 1400, "sel": False},
                {"n": "Renters or home insurance", "a": 25, "sel": False}]},
            {"n": "Utilities", "open": False, "goal": None, "items": [
                {"n": "Electric", "a": 110, "sel": False},
                {"n": "Gas heat", "a": 60, "sel": False},
                {"n": "Water and sewer", "a": 45, "sel": False},
                {"n": "Internet", "a": 70, "sel": False},
                {"n": "Cell phones", "a": 90, "sel": False}]},
            {"n": "Groceries & Household", "open": False, "goal": None, "items": [
                {"n": "Groceries", "a": 550, "sel": False},
                {"n": "Household goods", "a": 60, "sel": False}]},
            {"n": "Transportation", "open": False, "goal": None, "items": [
                {"n": "Car payment", "a": 320, "sel": False},
                {"n": "Fuel", "a": 160, "sel": False},
                {"n": "Car insurance", "a": 130, "sel": False},
                {"n": "Maintenance", "a": 40, "sel": False}]},
            {"n": "Health", "open": False, "goal": None, "items": [
                {"n": "Health insurance", "a": 180, "sel": False},
                {"n": "Prescriptions", "a": 20, "sel": False},
                {"n": "Gym", "a": 25, "sel": False}]},
            {"n": "Debt Payoff", "open": False, "goal": None, "items": [
                {"n": "Student loans", "a": 220, "sel": False},
                {"n": "Credit card", "a": 100, "sel": False}]},
            {"n": "Savings & Future", "open": False, "goal": None, "items": [
                {"n": "Emergency fund", "a": 200, "sel": False},
                {"n": "Baby fund", "a": 150, "sel": False},
                {"n": "House down payment", "a": 200, "sel": False}]},
            {"n": "Kids & Family", "open": False, "goal": None, "items": [
                {"n": "Diapers and baby gear", "a": 80, "sel": False},
                {"n": "Childcare", "a": 0, "sel": False}]},
            {"n": "Lifestyle", "open": False, "goal": None, "items": [
                {"n": "Dining out", "a": 180, "sel": False},
                {"n": "Date nights", "a": 80, "sel": False},
                {"n": "Streaming and subscriptions", "a": 35, "sel": False},
                {"n": "Clothing", "a": 60, "sel": False}]},
            {"n": "Giving", "open": False, "goal": None, "items": [
                {"n": "Church or charity", "a": 150, "sel": False},
                {"n": "Gifts", "a": 40, "sel": False}]},
            {"n": "Everything Else", "open": False, "goal": None, "items": [
                {"n": "Buffer for surprises", "a": 75, "sel": False}]},
        ],
    }


def budget_ym_key(year, month):
    return "%d-%s" % (year, str(month).zfill(2))


def budget_parse_ym(key):
    parts = key.split("-")
    if len(parts) != 2:
        return None
    try:
        y = int(parts[0])
        m = int(parts[1])
    except ValueError:
        return None
    return {"year": y, "month": m}


def budget_month_label(k):
    p = k.split("-")
    return BUDGET_MONTHS[int(p[1]) - 1] + " " + p[0]


def budget_deep(o):
    return json.loads(json.dumps(o))


def num(v):
    if v is None:
        return 0.0
    try:
        f = float(v)
    except (TypeError, ValueError):
        return 0.0
    if math.isnan(f) or math.isinf(f):
        return 0.0
    return f


def budget_net_of(i):
    g = num(i.get("gross"))
    p = num(i.get("tax")) + num(i.get("ret")) + num(i.get("oth"))
    return max(0.0, g * (1 - min(100.0, p) / 100.0))


def budget_take_home_of(m):
    t = budget_net_of(m["inc"][0])
    if m["inc2On"]:
        t += budget_net_of(m["inc"][1])
    return t


def budget_cat_total(c):
    t = 0.0
    for it in c["items"]:
        t += num(it.get("a"))
    return t


def budget_cat_sel(c):
    t = 0.0
    for it in c["items"]:
        if it.get("sel"):
            t += num(it.get("a"))
    return t


def budget_planned_of(m):
    t = 0.0
    for c in m["cats"]:
        t += budget_cat_total(c)
    return t


def budget_import_row(name, qty, amount):
    n = str(name).strip()
    q = 1.0 if (qty is None or qty == "") else num(qty)
    a = num(amount)
    rounded = js_round(q * a * 100.0) / 100.0
    return {"n": n[:60], "a": rounded, "sel": False}


def budget_month_days(ym_key_str):
    p = ym_key_str.split("-")
    y = int(p[0])
    m = int(p[1])
    if m == 12:
        ny, nm = y + 1, 1
    else:
        ny, nm = y, m + 1
    first_of_next = date(ny, nm, 1)
    last_of_this = first_of_next - timedelta(days=1)
    return last_of_this.day


def budget_per_day(sel, days):
    return sel / days


def budget_by_today(sel, today, days):
    return sel * today / days


def budget_chart_ymax(sels, goals):
    ymax = 1.0
    for idx in range(len(sels)):
        g = goals[idx] if idx < len(goals) else None
        gval = num(g) if g else 0.0
        ymax = max(ymax, sels[idx], gval)
    if len(sels) > 1:
        all_tot = sum(sels)
        ymax = max(ymax, all_tot)
    return ymax * 1.08


def budget_switch_month(months_obj, k):
    months = budget_deep(months_obj)
    copied_from = None
    if k not in months:
        ks = sorted(months.keys())
        prior = None
        for i in range(len(ks) - 1, -1, -1):
            if ks[i] < k:
                prior = ks[i]
                break
        if not prior and ks:
            prior = ks[-1]
        src = budget_deep(months[prior]) if prior else budget_def_month()
        for c in src["cats"]:
            for it in c["items"]:
                it["sel"] = False
            c["goal"] = c["goal"]
        months[k] = src
        copied_from = prior if prior else None
    return {"months": months, "month": months[k], "copiedFrom": copied_from}


def budget_year_aggregate(months_obj, year):
    out = []
    for m in range(1, 13):
        k = "%d-%s" % (year, str(m).zfill(2))
        mo = months_obj.get(k)
        pl = budget_planned_of(mo) if mo else 0.0
        th = budget_take_home_of(mo) if mo else 0.0
        out.append({"key": k, "has": bool(mo), "planned": pl, "takeHome": th})
    return out


def budget_encode_payload(payload):
    json_str = json.dumps(payload)
    return base64.b64encode(json_str.encode("utf-8")).decode("ascii")


def budget_decode_payload(b64):
    json_str = base64.b64decode(b64).decode("utf-8")
    return json.loads(json_str)


def budget_money_grouped(n):
    safe = 0.0 if (math.isinf(n) or n != n) else n
    neg = safe < 0 or (safe == 0 and math.copysign(1, safe) < 0)
    v = abs(safe)
    cents = js_round(v * 100.0)
    cents_str = "%.0f" % cents
    while len(cents_str) < 3:
        cents_str = "0" + cents_str
    intpart = cents_str[:-2]
    fracpart = cents_str[-2:]
    grouped_digits = []
    n_len = len(intpart)
    for idx, ch in enumerate(intpart):
        pos_from_right = n_len - idx
        grouped_digits.append(ch)
        if pos_from_right > 1 and pos_from_right % 3 == 1:
            grouped_digits.append(",")
    grouped = "".join(grouped_digits)
    sign = "-" if neg else ""
    return "$" + sign + grouped + "." + fracpart


def budget_ex_text(cur, label, m):
    def net(i):
        g = num(i.get("gross"))
        p = num(i.get("tax")) + num(i.get("ret")) + num(i.get("oth"))
        return max(0.0, g * (1 - min(100.0, p) / 100.0))

    th = net(m["inc"][0]) + (net(m["inc"][1]) if m["inc2On"] else 0.0)
    pl = 0.0
    for c in m["cats"]:
        for it in c["items"]:
            pl += num(it.get("a"))
    out = "Budget · " + label + "\n"
    out += "Take-home %s · planned %s · left %s\n\nINCOME\n" % (budget_money_grouped(th), budget_money_grouped(pl), budget_money_grouped(th - pl))
    for ix, i in enumerate(m["inc"]):
        if ix == 1 and not m["inc2On"]:
            continue
        label_i = i.get("label") or ("Income %d" % (ix + 1))
        oth_part = (", other %s%%" % i.get("oth")) if i.get("oth") else ""
        out += "• %s: $%s gross (tax %s%%, retire %s%%%s) → %s\n" % (
            label_i, i.get("gross"), i.get("tax"), i.get("ret"), oth_part, budget_money_grouped(net(i)))
    for c in m["cats"]:
        ct = 0.0
        for it in c["items"]:
            ct += num(it.get("a"))
        out += "\n%s — %s\n" % (str(c.get("n") or "").upper(), budget_money_grouped(ct))
        for it in c["items"]:
            if str(it.get("n") or "").strip():
                out += "• %s $%s\n" % (it.get("n"), num(it.get("a")))
        goal = c.get("goal")
        if goal is not None and goal != "":
            out += "(goal %s)\n" % budget_money_grouped(num(goal))
    payload = {"k": cur, "m": m}
    b64 = budget_encode_payload(payload)
    if b64:
        out += "\n#summit-budget-v1 " + b64
    return out


BUDGET_IMPORT_RE = re.compile(r"#summit-budget-v1\s+([A-Za-z0-9+/=]+)")


def budget_import_text(t):
    m = BUDGET_IMPORT_RE.search(t)
    if not m:
        return None
    try:
        payload = budget_decode_payload(m.group(1))
        if not payload or not payload.get("k") or not payload.get("m") or not payload["m"].get("cats"):
            return None
        ym = budget_parse_ym(payload["k"])
        if not ym or not (1 <= ym["month"] <= 12) or len(payload["m"].get("inc", [])) < 2:
            return None
        return payload
    except Exception:
        return None


def budget_share_parse(text):
    decoded = budget_import_text(text)
    if decoded is None:
        return None
    return {"v": 2, "cur": decoded["k"], "months": {decoded["k"]: decoded["m"]}}


def run():
    with open(VECTORS_PATH, encoding="utf-8") as f:
        vectors = json.load(f)

    results = {}

    fails = []
    for c in vectors["formatters"]:
        fn = c["fn"]
        arg = c["arg"]
        if fn == "fmt":
            got = fmt(arg)
        elif fn == "plain":
            got = plain(arg)
        elif fn == "money":
            got = money(arg)
        elif fn == "usd":
            got = usd(arg)
        else:
            fails.append((fn, arg, "unknown fn"))
            continue
        if got != c["expect"]:
            fails.append((fn, arg, "expect %r got %r" % (c["expect"], got)))
    results["formatters"] = (len(vectors["formatters"]) - len(fails), len(vectors["formatters"]), fails)

    fails = []
    for c in vectors["finance"]:
        fn = c["fn"]
        a = c["args"]
        if fn == "futureValue":
            raw = future_value(a["principal"], a["monthly"], a["annualRatePct"], a["years"])
        elif fn == "contributions":
            raw = contributions(a["principal"], a["monthly"], a["years"])
        elif fn == "loanPayment":
            raw = loan_payment(a["principal"], a["annualRatePct"], a["years"])
        elif fn == "savingsGoalPayment":
            raw = savings_goal_payment(a["target"], a["principal"], a["annualRatePct"], a["years"])
        elif fn == "realRate":
            raw = real_rate(a["nominalPct"], a["inflationPct"])
        elif fn == "employerMatch":
            raw = employer_match(a["salary"], a["contribPct"], a["matchPct"], a["matchLimitPct"])
        elif fn == "ruleOf72":
            raw = rule_of72(a["ratePct"])
        elif fn == "tip":
            raw = tip(a["bill"], a["tipPct"], a["people"])[1]
        elif fn == "percentOf":
            raw = percent_of(a["pct"], a["value"])
        elif fn == "percentChange":
            raw = percent_change(a["a"], a["b"])
        else:
            fails.append((fn, a, "unknown fn"))
            continue
        if not rel_close(raw, c["raw"]):
            fails.append((fn, a, "raw expect %r got %r" % (c["raw"], raw)))
            continue
        if fn in ("futureValue", "contributions"):
            display = usd(raw)
        elif fn in ("loanPayment", "savingsGoalPayment", "employerMatch", "tip"):
            display = money(raw)
        else:
            display = fmt(raw)
        if display != c["expect"]:
            fails.append((fn, a, "display expect %r got %r" % (c["expect"], display)))
    results["finance"] = (len(vectors["finance"]) - len(fails), len(vectors["finance"]), fails)

    fails = []
    for c in vectors["calc"]:
        calc, last_equals = run_keys(c["keys"])
        if last_equals:
            display = last_equals["display"]
            sequence = last_equals["sequence"]
        else:
            display = calc.current
            sequence = calc.expression_text().replace(" ", "")
        if display != c["display"] or sequence != c["sequence"]:
            fails.append((c["keys"], "expect display=%r seq=%r got display=%r seq=%r" % (c["display"], c["sequence"], display, sequence)))
    results["calc"] = (len(vectors["calc"]) - len(fails), len(vectors["calc"]), fails)

    fails = []
    for c in vectors["eggs"]:
        hit = egg_match(c["sequence"])
        got = hit["id"] if hit else None
        if got != c["match"]:
            fails.append((c["sequence"], "expect %r got %r" % (c["match"], got)))
    results["eggs"] = (len(vectors["eggs"]) - len(fails), len(vectors["eggs"]), fails)

    fails = []
    for c in vectors["recipe"]:
        parsed = parse_line(c["line"])
        got_qty = parsed["qty"] if parsed else None
        got_unit = parsed["unit"] if parsed else None
        got_name = parsed["name"] if parsed else None
        qty_ok = (got_qty is None and c["qty"] is None) or (
            got_qty is not None and c["qty"] is not None and abs(got_qty - c["qty"]) < 1e-9
        )
        unit_ok = got_unit == c["unit"]
        name_ok = got_name == c["name"]
        if not (qty_ok and unit_ok and name_ok):
            fails.append((c["line"], "expect qty=%r unit=%r name=%r got qty=%r unit=%r name=%r" % (c["qty"], c["unit"], c["name"], got_qty, got_unit, got_name)))
    results["recipe"] = (len(vectors["recipe"]) - len(fails), len(vectors["recipe"]), fails)

    fails = []
    for c in vectors["convert"]:
        got = unit_convert(c["value"], c["from"], c["to"])
        if got is None:
            fails.append((c, "conversion returned None"))
            continue
        got_r = round8(got)
        if not rel_close(got_r, c["expect"], tol=1e-6):
            fails.append((c, "expect %r got %r" % (c["expect"], got_r)))
    results["convert"] = (len(vectors["convert"]) - len(fails), len(vectors["convert"]), fails)

    fails = []
    for c in vectors.get("budgetNetOf", []):
        got = budget_net_of(c["income"])
        if not rel_close(got, c["expect"]):
            fails.append((c["income"], "netOf expect %r got %r" % (c["expect"], got)))
    results["budgetNetOf"] = (len(vectors.get("budgetNetOf", [])) - len(fails), len(vectors.get("budgetNetOf", [])), fails)

    fails = []
    for c in vectors.get("budgetTakeHome", []):
        got = budget_take_home_of(c["month"])
        if not rel_close(got, c["expect"]):
            fails.append(("takeHome expect %r got %r" % (c["expect"], got),))
    results["budgetTakeHome"] = (len(vectors.get("budgetTakeHome", [])) - len(fails), len(vectors.get("budgetTakeHome", [])), fails)

    fails = []
    for c in vectors.get("budgetCatTotals", []):
        gt = budget_cat_total(c["cat"])
        gs = budget_cat_sel(c["cat"])
        if not rel_close(gt, c["total"]) or not rel_close(gs, c["sel"]):
            fails.append((c["cat"], "expect total=%r sel=%r got total=%r sel=%r" % (c["total"], c["sel"], gt, gs)))
    results["budgetCatTotals"] = (len(vectors.get("budgetCatTotals", [])) - len(fails), len(vectors.get("budgetCatTotals", [])), fails)

    fails = []
    for c in vectors.get("budgetPlanned", []):
        got = budget_planned_of(c["month"])
        if not rel_close(got, c["expect"]):
            fails.append(("planned expect %r got %r" % (c["expect"], got),))
    results["budgetPlanned"] = (len(vectors.get("budgetPlanned", [])) - len(fails), len(vectors.get("budgetPlanned", [])), fails)

    fails = []
    for c in vectors.get("budgetImportRow", []):
        got = budget_import_row(c["name"], c["qty"], c["amount"])
        exp = c["expect"]
        if got["n"] != exp["n"] or not rel_close(got["a"], exp["a"]) or got["sel"] != exp["sel"]:
            fails.append((c["name"], "expect %r got %r" % (exp, got)))
    results["budgetImportRow"] = (len(vectors.get("budgetImportRow", [])) - len(fails), len(vectors.get("budgetImportRow", [])), fails)

    fails = []
    for c in vectors.get("budgetPerDay", []):
        if c["fn"] == "perDay":
            got = budget_per_day(c["sel"], c["days"])
        else:
            got = budget_by_today(c["sel"], c["today"], c["days"])
        if not rel_close(got, c["expect"]):
            fails.append((c["fn"], "expect %r got %r" % (c["expect"], got)))
    results["budgetPerDay"] = (len(vectors.get("budgetPerDay", [])) - len(fails), len(vectors.get("budgetPerDay", [])), fails)

    fails = []
    for c in vectors.get("budgetChartYMax", []):
        got = budget_chart_ymax(c["sels"], c["goals"])
        if not rel_close(got, c["expect"]):
            fails.append((c["sels"], c["goals"], "expect %r got %r" % (c["expect"], got)))
    results["budgetChartYMax"] = (len(vectors.get("budgetChartYMax", [])) - len(fails), len(vectors.get("budgetChartYMax", [])), fails)

    fails = []
    for c in vectors.get("budgetMonthDays", []):
        got = budget_month_days(c["key"])
        if got != c["expect"]:
            fails.append((c["key"], "expect %r got %r" % (c["expect"], got)))
    results["budgetMonthDays"] = (len(vectors.get("budgetMonthDays", [])) - len(fails), len(vectors.get("budgetMonthDays", [])), fails)

    fails = []
    for c in vectors.get("budgetYmKey", []):
        got = budget_ym_key(c["year"], c["month"])
        if got != c["expect"]:
            fails.append(("ymKey expect %r got %r" % (c["expect"], got),))
    results["budgetYmKey"] = (len(vectors.get("budgetYmKey", [])) - len(fails), len(vectors.get("budgetYmKey", [])), fails)

    fails = []
    for c in vectors.get("budgetParseYM", []):
        got = budget_parse_ym(c["key"])
        if got != c["expect"]:
            fails.append((c["key"], "expect %r got %r" % (c["expect"], got)))
    results["budgetParseYM"] = (len(vectors.get("budgetParseYM", [])) - len(fails), len(vectors.get("budgetParseYM", [])), fails)

    fails = []
    for c in vectors.get("budgetMonthLabel", []):
        got = budget_month_label(c["key"])
        if got != c["expect"]:
            fails.append((c["key"], "expect %r got %r" % (c["expect"], got)))
    results["budgetMonthLabel"] = (len(vectors.get("budgetMonthLabel", [])) - len(fails), len(vectors.get("budgetMonthLabel", [])), fails)

    fails = []
    for c in vectors.get("budgetMonthSwitch", []):
        db = c["db"]
        r = budget_switch_month(db["months"], c["target"])
        if r["month"] != c["resultMonth"]:
            fails.append((c["scenario"], "month mismatch"))
        if r["copiedFrom"] != c["copiedFrom"]:
            fails.append((c["scenario"], "copiedFrom expect %r got %r" % (c["copiedFrom"], r["copiedFrom"])))
    results["budgetMonthSwitch"] = (len(vectors.get("budgetMonthSwitch", [])) - len(fails), len(vectors.get("budgetMonthSwitch", [])), fails)

    fails = []
    for c in vectors.get("budgetYearAggregate", []):
        db = c["db"]
        got = budget_year_aggregate(db["months"], c["year"])
        exp = c["expect"]
        if len(got) != len(exp):
            fails.append((c["year"], "length mismatch"))
        else:
            for g, e in zip(got, exp):
                if g["key"] != e["key"] or g["has"] != e["has"] or not rel_close(g["planned"], e["planned"]) or not rel_close(g["takeHome"], e["takeHome"]):
                    fails.append((c["year"], "entry mismatch expect %r got %r" % (e, g)))
    results["budgetYearAggregate"] = (len(vectors.get("budgetYearAggregate", [])) - len(fails), len(vectors.get("budgetYearAggregate", [])), fails)

    fails = []
    for c in vectors.get("budgetShare", []):
        decoded = budget_import_text(c["fixtureText"])
        if decoded != c["decoded"]:
            fails.append((c["cur"], "decoded expect %r got %r" % (c["decoded"], decoded)))
        got_db = budget_share_parse(c["fixtureText"])
        if got_db != c["expectDb"]:
            fails.append((c["cur"], "expectDb expect %r got %r" % (c["expectDb"], got_db)))
        if decoded:
            reexported = budget_ex_text(decoded["k"], budget_month_label(decoded["k"]), decoded["m"])
            redecoded = budget_import_text(reexported)
            if redecoded != decoded:
                fails.append((c["cur"], "python roundtrip mismatch"))
    results["budgetShare"] = (len(vectors.get("budgetShare", [])) - len(fails), len(vectors.get("budgetShare", [])), fails)

    total_pass = 0
    total_count = 0
    print("category      pass/total")
    print("---------------------------")
    for cat in ["formatters", "finance", "calc", "eggs", "recipe", "convert", "budgetNetOf", "budgetTakeHome", "budgetCatTotals", "budgetPlanned", "budgetImportRow", "budgetPerDay", "budgetChartYMax", "budgetMonthDays", "budgetYmKey", "budgetParseYM", "budgetMonthLabel", "budgetMonthSwitch", "budgetYearAggregate", "budgetShare"]:
        p, t, fails = results[cat]
        total_pass += p
        total_count += t
        status = "OK" if p == t else "FAIL"
        print("%-12s  %3d/%3d  %s" % (cat, p, t, status))
        if fails:
            for f in fails[:10]:
                print("    ", f)
            if len(fails) > 10:
                print("     ... and", len(fails) - 10, "more")
    print("---------------------------")
    print("TOTAL         %3d/%3d" % (total_pass, total_count))

    extra_fails = []
    egg_count = len(EGGS)
    if egg_count != 6:
        extra_fails.append("expected 6 eggs, got %d" % egg_count)
    psalm = next((e for e in EGGS if e["id"] == "lift-my-eyes"), None)
    if psalm is None:
        extra_fails.append("psalm egg (lift-my-eyes) missing")
    elif not psalm.get("more") or not any("14" in m for m in psalm["more"]):
        extra_fails.append("psalm egg more array missing a line containing 14")
    food_count = len(FOODS)
    if food_count != 410:
        extra_fails.append("expected 410 foods, got %d" % food_count)
    if food_match("flour") is None:
        extra_fails.append("FoodLibrary.match(flour) returned None")

    import re as _re
    jsonld_pattern = _re.compile(r"<script[^>]*type=[\"\'](?:application/ld\+json)[\"\'][^>]*>([\s\S]*?)</script\s*>", _re.IGNORECASE)
    sample_html = (
        '<html><head><script type="application/ld+json">'
        '{"@type":"Recipe","recipeIngredient":["1 cup flour","2 eggs"]}'
        '</script></head></html>'
    )
    m = jsonld_pattern.findall(sample_html)
    if len(m) != 1:
        extra_fails.append("jsonLDIngredients sample regex did not find exactly one script block")
    else:
        try:
            data = json.loads(m[0])
            ings = data.get("recipeIngredient", [])
            if ings != ["1 cup flour", "2 eggs"]:
                extra_fails.append("jsonLDIngredients sample did not extract expected ingredient list")
        except Exception as e:
            extra_fails.append("jsonLDIngredients sample JSON parse failed: %r" % e)

    if extra_fails:
        print("\nContent checks:")
        for f in extra_fails:
            print("    FAIL", f)
    else:
        print("\nContent checks: OK (6 eggs, psalm hints 14, 410 foods, flour matches, jsonld sample)")

    if total_pass == total_count and not extra_fails:
        print("\nALL CHECKS PASSED")
        return 0
    print("\nSOME CHECKS FAILED")
    return 1


if __name__ == "__main__":
    sys.exit(run())
