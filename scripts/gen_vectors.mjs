import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const CONTRACTS_DIR = path.join(ROOT, "contracts");
const SUMMITCORE_RES = path.join(ROOT, "Packages", "SummitCore", "Sources", "SummitCore", "Resources");
const SOURCE_PATH = path.resolve(ROOT, "..", "Bloom Calculator (all-in-one).html");
const SOURCE_HTML = "Bloom Calculator (all-in-one).html";
const FOOD_LIBRARY_PATH = path.resolve(ROOT, "..", "food-library.json");

const htmlLines = readFileSync(SOURCE_PATH, "utf-8").split("\n");
function srcLine(n) {
  return htmlLines[n - 1];
}

const ENTITY_MAP = { "&quot;": '"', "&amp;": "&", "&lt;": "<", "&gt;": ">", "&#x27;": "'", "&#39;": "'", "&#x2013;": "–", "&apos;": "'" };
function decodeEntities(s) {
  return s.replace(/&#x27;|&#39;|&quot;|&amp;|&lt;|&gt;|&#x2013;|&apos;/g, (m) => ENTITY_MAP[m]);
}

function extractBracket(text, startIdx, openCh, closeCh) {
  let depth = 0;
  let i = startIdx;
  let inStr = null;
  while (i < text.length) {
    const c = text[i];
    if (inStr) {
      if (c === "\\") { i += 2; continue; }
      if (c === inStr) inStr = null;
    } else {
      if (c === "'" || c === '"' || c === "`") inStr = c;
      else if (c === openCh) depth++;
      else if (c === closeCh) {
        depth--;
        if (depth === 0) return i + 1;
      }
    }
    i++;
  }
  return null;
}

function extractArrayLiteral(lineNo, marker) {
  const line = srcLine(lineNo);
  const start = line.indexOf(marker);
  if (start === -1) throw new Error(`marker ${JSON.stringify(marker)} not found on line ${lineNo}`);
  const bracketAt = start + marker.length - 1;
  const end = extractBracket(line, bracketAt, "[", "]");
  if (end == null) throw new Error(`unterminated array literal at line ${lineNo}`);
  return line.slice(bracketAt, end);
}

function extractObjectLiteralWithTemplates(lineNo, marker) {
  const line = srcLine(lineNo);
  const start = line.indexOf(marker);
  if (start === -1) throw new Error(`marker ${JSON.stringify(marker)} not found on line ${lineNo}`);
  const objStart = start + marker.length - 1;
  let i = objStart, depth = 0, inTemplate = false, end = null;
  while (i < line.length) {
    const c = line[i];
    if (!inTemplate) {
      if (c === "`") inTemplate = true;
      else if (c === "{") depth++;
      else if (c === "}") { depth--; if (depth === 0) { end = i + 1; break; } }
    } else if (c === "`") {
      inTemplate = false;
    }
    i++;
  }
  if (end == null) throw new Error(`unterminated object literal at line ${lineNo}`);
  return line.slice(objStart, end);
}

function extractBlockFrom(startLineNo, endLineNoExclusive, marker) {
  const block = htmlLines.slice(startLineNo - 1, endLineNoExclusive - 1).join("\n");
  const start = block.indexOf(marker);
  if (start === -1) throw new Error(`marker ${JSON.stringify(marker)} not found in ${startLineNo}-${endLineNoExclusive}`);
  const bracketAt = start + marker.length - 1;
  const end = extractBracket(block, bracketAt, "[", "]");
  if (end == null) throw new Error(`unterminated array literal starting at ${startLineNo}`);
  return block.slice(bracketAt, end);
}

const FOODS_IFRAME_LINE = 1054;
const FOODS_PANTRY_LINE = 1552;
const FOOD_SVG_LINE = 1243;
const EGGS_START_LINE = 1737;
const THEME_VARS_START_LINE = 1750;
const FUNDS_START_LINE = 2060;
const SOUND_BLOCK_START_LINE = 2680;

const rawFoodsIframe = decodeEntities(extractArrayLiteral(FOODS_IFRAME_LINE, "const FOODS=["));
const foodsIframe = JSON.parse(rawFoodsIframe);

const rawFoodsPantry = decodeEntities(extractArrayLiteral(FOODS_PANTRY_LINE, "const FOODS=["));
const foodsPantry = JSON.parse(rawFoodsPantry);

const rawFoodSvgObj = decodeEntities(extractObjectLiteralWithTemplates(FOOD_SVG_LINE, "var FOOD_SVG={"));

function parseTemplateObject(objSrc) {
  const entries = {};
  let j = 1;
  const n = objSrc.length;
  while (j < n) {
    while (j < n && " \t\n\r,".includes(objSrc[j])) j++;
    if (j >= n || objSrc[j] === "}") break;
    const keyStart = j;
    while (j < n && objSrc[j] !== ":") j++;
    const key = objSrc.slice(keyStart, j).trim();
    j++;
    while (j < n && " \t\n\r".includes(objSrc[j])) j++;
    if (objSrc[j] !== "`") throw new Error(`expected backtick at ${j} for key ${key}`);
    j++;
    const valStart = j;
    while (j < n && objSrc[j] !== "`") j++;
    entries[key] = objSrc.slice(valStart, j);
    j++;
  }
  return entries;
}

const foodSvgEntries = parseTemplateObject(rawFoodSvgObj);

const eggsArraySrc = extractBlockFrom(EGGS_START_LINE, THEME_VARS_START_LINE, "const EASTER_EGGS=[");
const EASTER_EGGS_RAW = eval(eggsArraySrc);

const themeVarsSrc = extractBlockFrom(THEME_VARS_START_LINE, THEME_VARS_START_LINE + 14, "const THEME_VARS=[");
const THEME_VARS_RAW = eval(themeVarsSrc);

const fundsBlock = htmlLines.slice(FUNDS_START_LINE - 1, FUNDS_START_LINE + 5).join("\n");
const fundsSrc = fundsBlock.slice(fundsBlock.indexOf("["));
const fundsArrEnd = extractBracket(fundsSrc, 0, "[", "]");
const FUNDS_RAW = eval(fundsSrc.slice(0, fundsArrEnd));

const soundBlock = htmlLines.slice(SOUND_BLOCK_START_LINE - 1, SOUND_BLOCK_START_LINE + 9).join("\n");
const defaultMapMarker = "var DEFAULT_MAP={";
const dmStart = soundBlock.indexOf(defaultMapMarker) + defaultMapMarker.length - 1;
const dmEnd = extractBracket(soundBlock, dmStart, "{", "}");
const DEFAULT_MAP_RAW = eval("(" + soundBlock.slice(dmStart, dmEnd) + ")");

const gainMarker = "var GAIN={";
const gStart = soundBlock.indexOf(gainMarker) + gainMarker.length - 1;
const gEnd = extractBracket(soundBlock, gStart, "{", "}");
const GAIN_RAW = eval("(" + soundBlock.slice(gStart, gEnd) + ")");

const sources = {
  formatters_fmt_plain_money: `${SOURCE_HTML}:1852-1862 (fmt, plain, money)`,
  formatters_usd: `${SOURCE_HTML}:2094 (usd)`,
  calc_engine: `${SOURCE_HTML}:1851,1863-1919 (calc state, compute, setOp, equals, clearAll, toggleSign, percent)`,
  op_symbol: `${SOURCE_HTML}:1735 (OP_SYMBOL)`,
  finance_project: `${SOURCE_HTML}:2082-2091 (project = futureValue/contributions)`,
  finance_loan: `${SOURCE_HTML}:2461-2468 (loanPayment)`,
  finance_savingsgoal: `${SOURCE_HTML}:2469-2478 (savingsGoalPayment)`,
  finance_fvseries: `${SOURCE_HTML}:2479-2486 (fvSeries)`,
  finance_ruleof72: `${SOURCE_HTML}:2487 (ruleOf72)`,
  finance_realrate: `${SOURCE_HTML}:2488-2491 (realRate)`,
  finance_employermatch: `${SOURCE_HTML}:2492-2497 (employerMatch)`,
  finance_tip: `${SOURCE_HTML}:2451-2457 (tipSplit)`,
  finance_pct: `${SOURCE_HTML}:2458-2460 (pctOf, pctChange)`,
  eggs: `${SOURCE_HTML}:${EGGS_START_LINE}-1748 (EASTER_EGGS, eval'd verbatim after bracket-depth extraction)`,
  theme_root: `${SOURCE_HTML}:11-24 (:root theme vars)`,
  theme_presets: `${SOURCE_HTML}:25-41 (rose, peony, soft presets)`,
  theme_vars_editable: `${SOURCE_HTML}:${THEME_VARS_START_LINE}-1763 (THEME_VARS, eval'd verbatim)`,
  funds_default: `${SOURCE_HTML}:${FUNDS_START_LINE}-2064 (FUNDS, eval'd verbatim)`,
  soundmap: `${SOURCE_HTML}:${SOUND_BLOCK_START_LINE}-2687 (DEFAULT_MAP, GAIN, eval'd verbatim)`,
  foods_iframe: `${SOURCE_HTML}:${FOODS_IFRAME_LINE} (iframe FOODS, entity-encoded, schema n/g/m/e, bracket-depth extracted + entity-decoded + JSON.parse)`,
  foods_pantry: `${SOURCE_HTML}:${FOODS_PANTRY_LINE} (pantry FOODS, entity-encoded, schema id/name/group/measure/glyph/icon/filter/tinted, same method)`,
  food_svg: `${SOURCE_HTML}:${FOOD_SVG_LINE} (FOOD_SVG templates, entity-encoded template literals, bracket-depth + backtick-aware extraction)`,
  food_art_key: `${SOURCE_HTML}:1244-1252 (foodArtKey matcher, transcribed)`,
  recipe_parse: `${SOURCE_HTML}:2205-2286 (UNICODE_FRAC, UNIT_ALIASES, tokenQty, parseLine, fmtQty, transcribed)`,
  unit_convert: `${SOURCE_HTML}:2200-2212 (VOL, WT, convertFamily, transcribed)`,
  cleanurl_jsonld: `${SOURCE_HTML}:2963 (cleanUrl), 2344-2353 (extractJsonLdIngredients, transcribed)`,
  budget_engine: `${SOURCE_HTML}:3113-3598 (budget IIFE: state, defaults, presets, math, month switching, chart math, year aggregation, transcribed)`,
  budget_share: `${SOURCE_HTML}:3713-3735 (exBudget), 3832-3845 (importBudget, tag #summit-budget-v1, transcribed)`,
};

function round8(n) {
  return Math.round(n * 1e8) / 1e8;
}

function fmt(n) {
  if (!isFinite(n)) return "Error";
  if (n === 0) return "0";
  const abs = Math.abs(n);
  if (abs >= 1e15 || (abs < 1e-6 && abs > 0)) return n.toExponential(4);
  const r = Math.round(n * 1e8) / 1e8;
  return r.toLocaleString("en-US", { maximumFractionDigits: 8 });
}

function plain(n) {
  return (Math.round(n * 1e8) / 1e8).toString();
}

function money(n) {
  n = isFinite(n) ? n : 0;
  return "$" + n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function usd(n) {
  return "$" + Math.round(n).toLocaleString("en-US");
}

const OP_SYMBOL = { "+": "+", "-": "−", "*": "×", "/": "÷" };

function compute(a, b, op) {
  switch (op) {
    case "+": return a + b;
    case "-": return a - b;
    case "*": return a * b;
    case "/": return b === 0 ? NaN : a / b;
  }
  return b;
}

function makeCalc() {
  return { current: "0", stored: null, op: null, overwrite: true, parts: [] };
}

function calcDigit(calc, d) {
  if (calc.overwrite) { calc.current = d; calc.overwrite = false; }
  else calc.current = calc.current === "0" ? d : calc.current + d;
}

function calcDot(calc) {
  if (calc.overwrite) { calc.current = "0."; calc.overwrite = false; }
  else if (!calc.current.includes(".")) calc.current += ".";
}

function calcSetOp(calc, op) {
  const sym = OP_SYMBOL[op];
  if (calc.overwrite && calc.op != null) {
    calc.op = op;
    if (calc.parts.length) calc.parts[calc.parts.length - 1] = sym;
    return;
  }
  calc.parts.push(calc.current, sym);
  if (calc.op != null && !calc.overwrite) {
    const res = compute(calc.stored, parseFloat(calc.current), calc.op);
    calc.stored = res;
    calc.current = plain(res);
  } else {
    calc.stored = parseFloat(calc.current);
  }
  calc.op = op;
  calc.overwrite = true;
}

function calcEquals(calc) {
  if (calc.op == null) return null;
  const a = calc.stored, b = parseFloat(calc.current), op = calc.op;
  const res = compute(a, b, op);
  calc.parts.push(calc.current);
  const tokens = [...calc.parts];
  const seq = calc.parts.join("");
  const exprText = calc.parts.join(" ");
  const display = isFinite(res) ? fmt(res) : "Error";
  calc.current = isFinite(res) ? plain(res) : "0";
  calc.stored = null;
  calc.op = null;
  calc.overwrite = true;
  calc.parts = [];
  return { display, expression: exprText, sequence: seq, tokens, raw: res };
}

function calcClearAll(calc) {
  calc.current = "0"; calc.stored = null; calc.op = null; calc.overwrite = true; calc.parts = [];
}

function calcToggleSign(calc) {
  if (calc.current !== "0") calc.current = calc.current.startsWith("-") ? calc.current.slice(1) : "-" + calc.current;
}

function calcPercent(calc) {
  calc.current = plain(parseFloat(calc.current) / 100);
  calc.overwrite = true;
}

function runKeys(keys) {
  const calc = makeCalc();
  let lastEquals = null;
  for (const k of keys) {
    if (/^[0-9]$/.test(k)) calcDigit(calc, k);
    else if (k === ".") calcDot(calc);
    else if (k === "+") calcSetOp(calc, "+");
    else if (k === "-" || k === "−") calcSetOp(calc, "-");
    else if (k === "*" || k === "×") calcSetOp(calc, "*");
    else if (k === "/" || k === "÷") calcSetOp(calc, "/");
    else if (k === "=") lastEquals = calcEquals(calc);
    else if (k === "C" || k === "AC") calcClearAll(calc);
    else if (k === "+/-" || k === "sign") calcToggleSign(calc);
    else if (k === "%") calcPercent(calc);
    else throw new Error("unknown key " + k);
  }
  return { calc, lastEquals };
}

function round2(n) {
  return Math.round((Number(n) + Number.EPSILON) * 100) / 100;
}

function futureValue(principal, monthly, annualRatePct, years) {
  const i = annualRatePct / 100 / 12;
  const n = years * 12;
  return i === 0
    ? principal + monthly * n
    : principal * Math.pow(1 + i, n) + monthly * ((Math.pow(1 + i, n) - 1) / i);
}

function contributions(principal, monthly, years) {
  const n = years * 12;
  return principal + monthly * n;
}

function loanPayment(principal, annualRatePct, years) {
  const P = Number(principal);
  const i = Number(annualRatePct) / 100 / 12;
  const n = Number(years) * 12;
  return i === 0 ? P / n : (P * i) / (1 - Math.pow(1 + i, -n));
}

function savingsGoalPayment(target, principal, annualRatePct, years) {
  target = Number(target);
  const start = Number(principal) || 0;
  const i = Number(annualRatePct) / 100 / 12;
  const n = Number(years) * 12;
  const grow = Math.pow(1 + i, n);
  const fvFactor = i === 0 ? n : (grow - 1) / i;
  return (target - start * grow) / fvFactor;
}

function realRate(nominalPct, inflationPct) {
  const n = Number(nominalPct) / 100, f = Number(inflationPct) / 100;
  return ((1 + n) / (1 + f) - 1) * 100;
}

function employerMatch(salary, contribPct, matchPct, matchLimitPct) {
  salary = Number(salary);
  const c = Number(contribPct), cap = Number(matchLimitPct), rate = Number(matchPct) / 100;
  return (salary * Math.min(c, cap)) / 100 * rate;
}

function ruleOf72(ratePct) {
  return 72 / Number(ratePct);
}

function tip(bill, tipPct, people) {
  const b = Number(bill), p = Number(tipPct), n = Number(people) || 1;
  const t = (b * p) / 100;
  const total = b + t;
  return { tip: round2(t), total: round2(total), perPerson: round2(total / n) };
}

function percentOf(pct, value) {
  return (Number(value) * Number(pct)) / 100;
}

function percentChange(a, b) {
  return ((Number(b) - Number(a)) / Number(a)) * 100;
}

function kebab(s) {
  return s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
}

function eggTriggersFromTest(testFn) {
  const src = testFn.toString();
  return [...src.matchAll(/e===['"]([^'"]+)['"]/g)].map((m) => m[1]);
}

function buildEggsJson() {
  return EASTER_EGGS_RAW.map((e) => {
    const id = kebab(e.title);
    const triggers = eggTriggersFromTest(e.test);
    const dateLabel = e.date || "";
    const lines = e.kind === "toast" ? [e.msg] : e.lines;
    const more = e.more ? e.more.map((m) => `${m.t}: ${m.s}`) : null;
    return { id, kind: e.kind, title: e.title, dateLabel, lines, more, triggers };
  });
}

function eggMatch(sequence) {
  const hit = EASTER_EGGS_RAW.find((e) => e.test(sequence));
  return hit ? kebab(hit.title) : null;
}

const UNICODE_FRAC = { "½": 0.5, "⅓": 1 / 3, "⅔": 2 / 3, "¼": 0.25, "¾": 0.75, "⅛": 0.125, "⅜": 0.375, "⅝": 0.625, "⅞": 0.875, "⅕": 0.2, "⅖": 0.4, "⅗": 0.6, "⅘": 0.8, "⅙": 1 / 6, "⅚": 5 / 6 };
const FRAC_CLASS = "[½⅓⅔¼¾⅛⅜⅝⅞⅕⅖⅗⅘⅙⅚]";
const UNIT_ALIASES = { tsp: "tsp", teaspoon: "tsp", teaspoons: "tsp", tbsp: "tbsp", tbs: "tbsp", tablespoon: "tbsp", tablespoons: "tbsp", cup: "cup", cups: "cup", oz: "oz", ounce: "oz", ounces: "oz", lb: "lb", lbs: "lb", pound: "lb", pounds: "lb", g: "g", gram: "g", grams: "g", gr: "g", kg: "kg", ml: "mL", milliliter: "mL", milliliters: "mL", l: "L", liter: "L", liters: "L", litre: "L", litres: "L", pinch: "pinch", clove: "clove", cloves: "clove", can: "can", cans: "can", stick: "stick", sticks: "stick", slice: "slice", slices: "slice", pkg: "pkg", package: "pkg" };

function tokenQty(t) {
  if (UNICODE_FRAC[t] != null) return UNICODE_FRAC[t];
  let m = t.match(new RegExp("^(\\d+)(" + FRAC_CLASS + ")$"));
  if (m) return parseInt(m[1], 10) + UNICODE_FRAC[m[2]];
  if (/^\d+\/\d+$/.test(t)) { const p = t.split("/"); return parseFloat(p[0]) / parseFloat(p[1]); }
  if (/^\d*\.?\d+$/.test(t)) return parseFloat(t);
  const r = t.match(new RegExp("^(\\d*\\.?\\d+)[-\\u2013\\u2014](\\d*\\.?\\d+)$"));
  if (r) return parseFloat(r[1]);
  return null;
}

function parseLine(line) {
  if (!line) return null;
  line = line.replace(/^[\s\-*•‣◦]+/, "").trim();
  if (!line) return null;
  const tokens = line.split(/\s+/);
  let i = 0, qty = 0, hasQty = false;
  while (i < tokens.length) {
    const v = tokenQty(tokens[i]);
    if (v == null) break;
    qty += v; hasQty = true; i++;
  }
  let unit = null;
  if (i < tokens.length) {
    const raw = tokens[i].toLowerCase().replace(/[.,]/g, "");
    if (raw === "fl" && i + 1 < tokens.length && /^(oz|ounce|ounces)$/.test(tokens[i + 1].toLowerCase().replace(/[.,]/g, ""))) {
      unit = "fl oz"; i += 2;
    } else if (UNIT_ALIASES[raw]) {
      unit = UNIT_ALIASES[raw]; i++;
    }
  }
  let name = tokens.slice(i).join(" ").replace(/^of\s+/i, "").trim();
  name = name.replace(/\s*[,(].*$/, "").trim();
  if (!name) name = line;
  return { qty: hasQty ? qty : null, unit, name, raw: line };
}

function fmtQty(n) {
  if (n == null || !isFinite(n)) return "";
  if (n <= 0) return "0";
  const whole = Math.floor(n + 1e-9), frac = n - whole;
  const table = [[0, ""], [0.125, "1/8"], [0.25, "1/4"], [1 / 3, "1/3"], [0.375, "3/8"], [0.5, "1/2"], [0.625, "5/8"], [2 / 3, "2/3"], [0.75, "3/4"], [0.875, "7/8"], [1, ""]];
  let best = table[0], bd = Math.abs(frac - table[0][0]);
  for (const e of table) { const d = Math.abs(frac - e[0]); if (d < bd) { bd = d; best = e; } }
  if (bd < 0.04) {
    if (best[0] === 1) return String(whole + 1);
    if (best[0] === 0) return String(whole);
    return (whole ? whole + " " : "") + best[1];
  }
  return (Math.round(n * 100) / 100).toLocaleString("en-US", { maximumFractionDigits: 2 });
}

const VOL = { tsp: 4.92892, tbsp: 14.7868, cup: 236.588, "fl oz": 29.5735, mL: 1, L: 1000 };
const WT = { g: 1, oz: 28.3495, lb: 453.592 };

function convertUnit(value, from, to) {
  const fromVol = from in VOL, fromWt = from in WT;
  const toVol = to in VOL, toWt = to in WT;
  if (fromVol && toVol) return (value * VOL[from]) / VOL[to];
  if (fromWt && toWt) return (value * WT[from]) / WT[to];
  return null;
}

const results = {
  meta: {}, formatters: [], finance: [], calc: [], eggs: [], recipe: [], convert: [],
  budgetYmKey: [], budgetParseYM: [], budgetMonthLabel: [], budgetMonthDays: [],
  budgetChartYMax: [], budgetPerDay: [], budgetImportRow: [], budgetCatTotals: [],
  budgetNetOf: [], budgetTakeHome: [], budgetPlanned: [], budgetMonthSwitch: [],
  budgetYearAggregate: [], budgetShare: [],
};

results.meta = {
  generatedFrom: SOURCE_HTML,
  date: "2026-07-02",
  runtime: "node",
  nodeVersion: process.version,
  sources,
};

function pushFmt(fn, arg, fnImpl) {
  results.formatters.push({ fn, arg, expect: fnImpl(arg) });
}

const fmtCases = [
  0, 1, -1, 0.5, -0.5, 44, 100, 1000, 1234.5678, -1234.5678, 1000000, 1234567.891,
  0.00000001, 0.000001, 0.0000001, 1e15, 1e16, -1e16, 999999999999.99999999,
  123456789.12345678, 0.1, 0.12345678901, 3.14159265358979, 100000000, 1e-8,
  -0.000000123, 5000000000, 2.5, -2.5, 10.005, 999.995, 1e14, 9.999999e14,
  1.00000001e15, 0.99999999e-6, 12345.6789012345, -0.0000001, 42, 3.0, -3.0, 7.5, 8888.8888,
];
for (const c of fmtCases) pushFmt("fmt", c, fmt);
for (const c of fmtCases) pushFmt("plain", c, plain);
for (const c of fmtCases) pushFmt("money", c, money);
for (const c of fmtCases) pushFmt("usd", c, usd);

function pushFinance(fn, args, rawFn, expectFn) {
  const raw = rawFn(args);
  results.finance.push({ fn, args, raw, expect: expectFn(raw) });
}

const financeCases = [
  ["futureValue", { principal: 1000, monthly: 100, annualRatePct: 6, years: 10 }, (a) => futureValue(a.principal, a.monthly, a.annualRatePct, a.years), (r) => usd(r)],
  ["futureValue", { principal: 0, monthly: 500, annualRatePct: 7, years: 30 }, (a) => futureValue(a.principal, a.monthly, a.annualRatePct, a.years), (r) => usd(r)],
  ["futureValue", { principal: 10000, monthly: 0, annualRatePct: 5, years: 20 }, (a) => futureValue(a.principal, a.monthly, a.annualRatePct, a.years), (r) => usd(r)],
  ["futureValue", { principal: 1000, monthly: 100, annualRatePct: 0, years: 10 }, (a) => futureValue(a.principal, a.monthly, a.annualRatePct, a.years), (r) => usd(r)],
  ["futureValue", { principal: 5000, monthly: 200, annualRatePct: 4.5, years: 0 }, (a) => futureValue(a.principal, a.monthly, a.annualRatePct, a.years), (r) => usd(r)],
  ["futureValue", { principal: 0, monthly: 0, annualRatePct: 6, years: 10 }, (a) => futureValue(a.principal, a.monthly, a.annualRatePct, a.years), (r) => usd(r)],
  ["futureValue", { principal: 250000, monthly: 1500, annualRatePct: 8, years: 25 }, (a) => futureValue(a.principal, a.monthly, a.annualRatePct, a.years), (r) => usd(r)],
  ["futureValue", { principal: 100, monthly: 10, annualRatePct: 12, years: 1 }, (a) => futureValue(a.principal, a.monthly, a.annualRatePct, a.years), (r) => usd(r)],
  ["contributions", { principal: 1000, monthly: 100, years: 10 }, (a) => contributions(a.principal, a.monthly, a.years), (r) => usd(r)],
  ["contributions", { principal: 0, monthly: 500, years: 30 }, (a) => contributions(a.principal, a.monthly, a.years), (r) => usd(r)],
  ["contributions", { principal: 10000, monthly: 0, years: 20 }, (a) => contributions(a.principal, a.monthly, a.years), (r) => usd(r)],
  ["contributions", { principal: 5000, monthly: 200, years: 0 }, (a) => contributions(a.principal, a.monthly, a.years), (r) => usd(r)],
  ["loanPayment", { principal: 20000, annualRatePct: 6, years: 5 }, (a) => loanPayment(a.principal, a.annualRatePct, a.years), (r) => money(r)],
  ["loanPayment", { principal: 300000, annualRatePct: 6.5, years: 30 }, (a) => loanPayment(a.principal, a.annualRatePct, a.years), (r) => money(r)],
  ["loanPayment", { principal: 10000, annualRatePct: 0, years: 5 }, (a) => loanPayment(a.principal, a.annualRatePct, a.years), (r) => money(r)],
  ["loanPayment", { principal: 5000, annualRatePct: 3.9, years: 1 }, (a) => loanPayment(a.principal, a.annualRatePct, a.years), (r) => money(r)],
  ["savingsGoalPayment", { target: 50000, principal: 0, annualRatePct: 5, years: 10 }, (a) => savingsGoalPayment(a.target, a.principal, a.annualRatePct, a.years), (r) => money(r)],
  ["savingsGoalPayment", { target: 100000, principal: 20000, annualRatePct: 6, years: 15 }, (a) => savingsGoalPayment(a.target, a.principal, a.annualRatePct, a.years), (r) => money(r)],
  ["savingsGoalPayment", { target: 10000, principal: 0, annualRatePct: 0, years: 5 }, (a) => savingsGoalPayment(a.target, a.principal, a.annualRatePct, a.years), (r) => money(r)],
  ["savingsGoalPayment", { target: 5000, principal: 5000, annualRatePct: 4, years: 2 }, (a) => savingsGoalPayment(a.target, a.principal, a.annualRatePct, a.years), (r) => money(r)],
  ["realRate", { nominalPct: 7, inflationPct: 3 }, (a) => realRate(a.nominalPct, a.inflationPct), (r) => fmt(r)],
  ["realRate", { nominalPct: 5, inflationPct: 5 }, (a) => realRate(a.nominalPct, a.inflationPct), (r) => fmt(r)],
  ["realRate", { nominalPct: 2, inflationPct: 8 }, (a) => realRate(a.nominalPct, a.inflationPct), (r) => fmt(r)],
  ["realRate", { nominalPct: 0, inflationPct: 0 }, (a) => realRate(a.nominalPct, a.inflationPct), (r) => fmt(r)],
  ["employerMatch", { salary: 80000, contribPct: 6, matchPct: 50, matchLimitPct: 6 }, (a) => employerMatch(a.salary, a.contribPct, a.matchPct, a.matchLimitPct), (r) => money(r)],
  ["employerMatch", { salary: 60000, contribPct: 3, matchPct: 100, matchLimitPct: 6 }, (a) => employerMatch(a.salary, a.contribPct, a.matchPct, a.matchLimitPct), (r) => money(r)],
  ["employerMatch", { salary: 50000, contribPct: 10, matchPct: 50, matchLimitPct: 4 }, (a) => employerMatch(a.salary, a.contribPct, a.matchPct, a.matchLimitPct), (r) => money(r)],
  ["employerMatch", { salary: 45000, contribPct: 0, matchPct: 50, matchLimitPct: 5 }, (a) => employerMatch(a.salary, a.contribPct, a.matchPct, a.matchLimitPct), (r) => money(r)],
  ["ruleOf72", { ratePct: 6 }, (a) => ruleOf72(a.ratePct), (r) => fmt(r)],
  ["ruleOf72", { ratePct: 12 }, (a) => ruleOf72(a.ratePct), (r) => fmt(r)],
  ["ruleOf72", { ratePct: 1 }, (a) => ruleOf72(a.ratePct), (r) => fmt(r)],
  ["tip", { bill: 84.5, tipPct: 18, people: 3 }, (a) => tip(a.bill, a.tipPct, a.people).total, (r) => money(r)],
  ["tip", { bill: 50, tipPct: 20, people: 1 }, (a) => tip(a.bill, a.tipPct, a.people).total, (r) => money(r)],
  ["percentOf", { pct: 15, value: 200 }, (a) => percentOf(a.pct, a.value), (r) => fmt(r)],
  ["percentChange", { a: 50, b: 75 }, (a) => percentChange(a.a, a.b), (r) => fmt(r)],
];
for (const [fn, args, rawFn, expectFn] of financeCases) pushFinance(fn, args, rawFn, expectFn);

function pushCalc(keys) {
  const { calc, lastEquals } = runKeys(keys);
  const display = lastEquals ? lastEquals.display : calc.current;
  const sequence = lastEquals ? lastEquals.sequence : calc.parts.join("");
  results.calc.push({ keys, display, sequence });
}

pushCalc(["3", "+", "1", "6", "+", "2", "5", "="]);
pushCalc(["1", "2", "*", "5", "*", "2", "6", "="]);
pushCalc(["1", "2", "0", "/", "0", "="]);
pushCalc(["5", "+", "5", "="]);
pushCalc(["9", "-", "4", "="]);
pushCalc(["6", "*", "7", "="]);
pushCalc(["1", "0", "0", "/", "4", "="]);
pushCalc(["7", "+", "+", "3", "="]);
pushCalc(["7", "-", "*", "3", "="]);
pushCalc(["2", "0", "0", "%", "="]);
pushCalc(["5", "+/-", "="]);
pushCalc(["0", "+/-", "="]);
pushCalc(["9", "+/-", "+/-", "="]);
pushCalc(["1", ".", "5", "+", "2", ".", "5", "="]);
pushCalc(["3", ".", ".", "5", "="]);
pushCalc(["1", "2", "3", "C", "4", "5", "="]);
pushCalc(["1", "0", "-", "3", "-", "2", "="]);
pushCalc(["2", "+", "3", "*", "4", "="]);
pushCalc(["1", "0", "0", "-", "5", "0", "%", "="]);
pushCalc(["8", "/", "2", "/", "2", "="]);
pushCalc(["3", "÷", "1", "6", "÷", "2", "5", "="]);
pushCalc(["3", "×", "1", "6", "×", "2", "5", "="]);
pushCalc(["1", "2", "÷", "5", "÷", "2", "6", "="]);
pushCalc(["1", "2", "−", "5", "−", "2", "6", "="]);
pushCalc(["7", "×", "6", "="]);
pushCalc(["1", "2", "×", "1", "2", "="]);
pushCalc(["4", "4", "="]);
pushCalc(["1", "+", "="]);

const eggSequenceCases = [
  ["3÷16÷25", true], ["3/16/25", true],
  ["3+16+25", true],
  ["3×16×25", true], ["3*16*25", true],
  ["3−16−25", true], ["3-16-25", true],
  ["12÷5÷26", true], ["12/5/26", true],
  ["12+5+26", true],
  ["12×5×26", true], ["12*5*26", true],
  ["12−5−26", true], ["12-5-26", true],
  ["7×6", true], ["6×7", true],
  ["12×12", true],
  ["3÷16÷24", false],
  ["4+16+25", false],
  ["3+17+25", false],
  ["7×5", false],
  ["12÷5÷27", false],
  ["13-5-26", false],
  ["7+6", false],
  ["12×13", false],
];

for (const [seq, shouldMatch] of eggSequenceCases) {
  const m = eggMatch(seq);
  results.eggs.push({ sequence: seq, match: shouldMatch ? m : null });
}

const recipeCases = [
  "1 ½ cups flour",
  "2 eggs",
  "¼ tsp salt",
  "⅓ cup sugar",
  "¾ cup milk",
  "3/4 cup butter",
  "1/2 tsp baking soda",
  "2 1/2 cups all-purpose flour",
  "1 tbsp olive oil",
  "8 oz cream cheese",
  "1 lb ground beef",
  "500 g pasta",
  "2 cloves garlic, minced",
  "1 can black beans",
  "1 stick butter, softened",
  "3 slices bacon",
  "1 pinch of cinnamon",
  "2 cups water",
  "1 1/4 cups powdered sugar",
  "1 fl oz vanilla extract",
  "vanilla extract",
  "  - 2 tsp cumin",
];
for (const line of recipeCases) {
  const parsed = parseLine(line);
  results.recipe.push({ line, qty: parsed ? parsed.qty : null, unit: parsed ? parsed.unit : null, name: parsed ? parsed.name : null });
}

const convertCases = [
  ["cup", "mL", 2],
  ["tsp", "mL", 1],
  ["tbsp", "mL", 1],
  ["cup", "fl oz", 1],
  ["L", "mL", 1],
  ["mL", "L", 1000],
  ["g", "oz", 100],
  ["oz", "g", 1],
  ["lb", "g", 1],
  ["g", "lb", 1000],
  ["cup", "tbsp", 1],
  ["tbsp", "tsp", 1],
];
for (const [from, to, value] of convertCases) {
  const expect = convertUnit(value, from, to);
  results.convert.push({ value, from, to, expect: round8(expect) });
}

const BUDGET_MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August",
  "September", "October", "November", "December"];

function jsRoundBudget(x) {
  return Math.floor(x + 0.5);
}

function budgetDefMonth() {
  return {
    inc2On: true,
    inc: [
      { label: "Income 1", gross: 4200, tax: 18, ret: 5, oth: 2 },
      { label: "Income 2", gross: 3600, tax: 16, ret: 5, oth: 0 }
    ],
    cats: [
      { n: "Housing", open: true, goal: null, items: [
        { n: "Rent or mortgage", a: 1400, sel: false },
        { n: "Renters or home insurance", a: 25, sel: false }] },
      { n: "Utilities", open: false, goal: null, items: [
        { n: "Electric", a: 110, sel: false },
        { n: "Gas heat", a: 60, sel: false },
        { n: "Water and sewer", a: 45, sel: false },
        { n: "Internet", a: 70, sel: false },
        { n: "Cell phones", a: 90, sel: false }] },
      { n: "Groceries & Household", open: false, goal: null, items: [
        { n: "Groceries", a: 550, sel: false },
        { n: "Household goods", a: 60, sel: false }] },
      { n: "Transportation", open: false, goal: null, items: [
        { n: "Car payment", a: 320, sel: false },
        { n: "Fuel", a: 160, sel: false },
        { n: "Car insurance", a: 130, sel: false },
        { n: "Maintenance", a: 40, sel: false }] },
      { n: "Health", open: false, goal: null, items: [
        { n: "Health insurance", a: 180, sel: false },
        { n: "Prescriptions", a: 20, sel: false },
        { n: "Gym", a: 25, sel: false }] },
      { n: "Debt Payoff", open: false, goal: null, items: [
        { n: "Student loans", a: 220, sel: false },
        { n: "Credit card", a: 100, sel: false }] },
      { n: "Savings & Future", open: false, goal: null, items: [
        { n: "Emergency fund", a: 200, sel: false },
        { n: "Baby fund", a: 150, sel: false },
        { n: "House down payment", a: 200, sel: false }] },
      { n: "Kids & Family", open: false, goal: null, items: [
        { n: "Diapers and baby gear", a: 80, sel: false },
        { n: "Childcare", a: 0, sel: false }] },
      { n: "Lifestyle", open: false, goal: null, items: [
        { n: "Dining out", a: 180, sel: false },
        { n: "Date nights", a: 80, sel: false },
        { n: "Streaming and subscriptions", a: 35, sel: false },
        { n: "Clothing", a: 60, sel: false }] },
      { n: "Giving", open: false, goal: null, items: [
        { n: "Church or charity", a: 150, sel: false },
        { n: "Gifts", a: 40, sel: false }] },
      { n: "Everything Else", open: false, goal: null, items: [
        { n: "Buffer for surprises", a: 75, sel: false }] }
    ]
  };
}

function budgetYmKey(year, month) {
  return year + "-" + String(month).padStart(2, "0");
}

function budgetParseYM(key) {
  const parts = key.split("-");
  if (parts.length !== 2) return null;
  const y = parseInt(parts[0], 10);
  const m = parseInt(parts[1], 10);
  if (!Number.isFinite(y) || !Number.isFinite(m)) return null;
  return { year: y, month: m };
}

function budgetMonthLabel(k) {
  const p = k.split("-");
  return BUDGET_MONTHS[+p[1] - 1] + " " + p[0];
}

function budgetDeep(o) {
  return JSON.parse(JSON.stringify(o));
}

function budgetNum(v) {
  if (v === null || v === undefined) return 0;
  const f = parseFloat(v);
  return isFinite(f) ? f : 0;
}

function budgetNetOf(i) {
  const g = budgetNum(i.gross);
  const p = budgetNum(i.tax) + budgetNum(i.ret) + budgetNum(i.oth);
  return Math.max(0, g * (1 - Math.min(100, p) / 100));
}

function budgetTakeHomeOf(m) {
  let t = budgetNetOf(m.inc[0]);
  if (m.inc2On) t += budgetNetOf(m.inc[1]);
  return t;
}

function budgetCatTotal(c) {
  let t = 0;
  c.items.forEach((it) => { t += budgetNum(it.a); });
  return t;
}

function budgetCatSel(c) {
  let t = 0;
  c.items.forEach((it) => { if (it.sel) t += budgetNum(it.a); });
  return t;
}

function budgetPlannedOf(m) {
  let t = 0;
  m.cats.forEach((c) => { t += budgetCatTotal(c); });
  return t;
}

function budgetImportRow(name, qty, amount) {
  const n = String(name).trim();
  const q = (qty === "" || qty === null || qty === undefined) ? 1 : budgetNum(qty);
  const a = budgetNum(amount);
  const rounded = jsRoundBudget(q * a * 100) / 100;
  return { n: n.slice(0, 60), a: rounded, sel: false };
}

function budgetMonthDays(ymKeyStr) {
  const p = ymKeyStr.split("-");
  const y = +p[0], m = +p[1];
  return new Date(y, m, 0).getDate();
}

function budgetPerDay(sel, days) {
  return sel / days;
}

function budgetByToday(sel, today, days) {
  return sel * today / days;
}

function budgetChartYMax(sels, goals) {
  let ymax = 1;
  for (let idx = 0; idx < sels.length; idx++) {
    const g = idx < goals.length ? (goals[idx] || 0) : 0;
    ymax = Math.max(ymax, sels[idx], g);
  }
  if (sels.length > 1) {
    const allTot = sels.reduce((a, b) => a + b, 0);
    ymax = Math.max(ymax, allTot);
  }
  return ymax * 1.08;
}

function budgetSwitchMonth(monthsObj, k) {
  const months = budgetDeep(monthsObj);
  let copiedFrom = null;
  if (!months[k]) {
    const ks = Object.keys(months).sort();
    let prior = null;
    for (let i = ks.length - 1; i >= 0; i--) {
      if (ks[i] < k) { prior = ks[i]; break; }
    }
    if (!prior && ks.length) prior = ks[ks.length - 1];
    const src = prior ? budgetDeep(months[prior]) : budgetDefMonth();
    src.cats.forEach((c) => {
      c.items.forEach((it) => { it.sel = false; });
      c.goal = c.goal;
    });
    months[k] = src;
    copiedFrom = prior || null;
  }
  return { months, month: months[k], copiedFrom };
}

function budgetYearAggregate(monthsObj, year) {
  const out = [];
  for (let m = 1; m <= 12; m++) {
    const k = budgetYmKey(year, m);
    const mo = monthsObj[k];
    const pl = mo ? budgetPlannedOf(mo) : 0;
    const th = mo ? budgetTakeHomeOf(mo) : 0;
    out.push({ key: k, has: !!mo, planned: pl, takeHome: th });
  }
  return out;
}

function budgetMoneyGrouped(n) {
  n = isFinite(n) ? n : 0;
  return "$" + n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function budgetExText(cur, label, m) {
  function net(i) {
    const g = parseFloat(i.gross) || 0;
    const p = (parseFloat(i.tax) || 0) + (parseFloat(i.ret) || 0) + (parseFloat(i.oth) || 0);
    return Math.max(0, g * (1 - Math.min(100, p) / 100));
  }
  const th = net(m.inc[0]) + (m.inc2On ? net(m.inc[1]) : 0);
  let pl = 0;
  m.cats.forEach((c) => { c.items.forEach((it) => { pl += parseFloat(it.a) || 0; }); });
  let out = "Budget · " + label + "\n";
  out += "Take-home " + budgetMoneyGrouped(th) + " · planned " + budgetMoneyGrouped(pl) + " · left " + budgetMoneyGrouped(th - pl) + "\n\nINCOME\n";
  m.inc.forEach((i, ix) => {
    if (ix === 1 && !m.inc2On) return;
    out += "• " + (i.label || ("Income " + (ix + 1))) + ": $" + i.gross + " gross (tax " + i.tax + "%, retire " + i.ret + "%" + (i.oth ? (", other " + i.oth + "%") : "") + ") → " + budgetMoneyGrouped(net(i)) + "\n";
  });
  m.cats.forEach((c) => {
    let ct = 0;
    c.items.forEach((it) => { ct += parseFloat(it.a) || 0; });
    out += "\n" + String(c.n || "").toUpperCase() + " — " + budgetMoneyGrouped(ct) + "\n";
    c.items.forEach((it) => { if (String(it.n || "").trim()) out += "• " + it.n + " $" + (parseFloat(it.a) || 0) + "\n"; });
    if (c.goal != null && c.goal !== "") out += "(goal " + budgetMoneyGrouped(parseFloat(c.goal) || 0) + ")\n";
  });
  const payload = { k: cur, m: m };
  let b64 = "";
  try {
    b64 = Buffer.from(JSON.stringify(payload), "utf-8").toString("base64");
  } catch (e) {}
  if (b64) out += "\n#summit-budget-v1 " + b64;
  return out;
}

function budgetImportText(t) {
  const m = t.match(/#summit-budget-v1\s+([A-Za-z0-9+/=]+)/);
  if (!m) return null;
  try {
    const payload = JSON.parse(Buffer.from(m[1], "base64").toString("utf-8"));
    if (!payload || !payload.k || !payload.m || !payload.m.cats) return null;
    return payload;
  } catch (e) {
    return null;
  }
}

results.budgetYmKey = [
  { year: 2026, month: 7, expect: budgetYmKey(2026, 7) },
  { year: 2026, month: 11, expect: budgetYmKey(2026, 11) },
  { year: 2026, month: 1, expect: budgetYmKey(2026, 1) },
];

results.budgetParseYM = [
  { key: "2026-07", expect: budgetParseYM("2026-07") },
  { key: "2026-11", expect: budgetParseYM("2026-11") },
  { key: "bogus", expect: budgetParseYM("bogus") },
];

results.budgetMonthLabel = [
  { key: "2026-07", expect: budgetMonthLabel("2026-07") },
  { key: "2027-01", expect: budgetMonthLabel("2027-01") },
  { key: "2026-12", expect: budgetMonthLabel("2026-12") },
];

results.budgetMonthDays = [
  { key: "2027-02", expect: budgetMonthDays("2027-02") },
  { key: "2028-02", expect: budgetMonthDays("2028-02") },
  { key: "2026-04", expect: budgetMonthDays("2026-04") },
  { key: "2026-01", expect: budgetMonthDays("2026-01") },
  { key: "2000-02", expect: budgetMonthDays("2000-02") },
  { key: "1900-02", expect: budgetMonthDays("1900-02") },
  { key: "2026-12", expect: budgetMonthDays("2026-12") },
];

results.budgetChartYMax = [
  { sels: [50], goals: [null], expect: budgetChartYMax([50], [null]) },
  { sels: [50], goals: [200], expect: budgetChartYMax([50], [200]) },
  { sels: [10, 20], goals: [null, null], expect: budgetChartYMax([10, 20], [null, null]) },
  { sels: [100, 50], goals: [30, 400], expect: budgetChartYMax([100, 50], [30, 400]) },
  { sels: [0.2], goals: [null], expect: budgetChartYMax([0.2], [null]) },
  { sels: [5, 5, 5], goals: [null, null, null], expect: budgetChartYMax([5, 5, 5], [null, null, null]) },
];

results.budgetPerDay = [
  { fn: "perDay", sel: 300, days: 30, expect: budgetPerDay(300, 30) },
  { fn: "perDay", sel: 100, days: 31, expect: budgetPerDay(100, 31) },
  { fn: "perDay", sel: 0, days: 28, expect: budgetPerDay(0, 28) },
  { fn: "byToday", sel: 300, today: 15, days: 30, expect: budgetByToday(300, 15, 30) },
  { fn: "byToday", sel: 620, today: 1, days: 31, expect: budgetByToday(620, 1, 31) },
  { fn: "byToday", sel: 100, today: 28, days: 28, expect: budgetByToday(100, 28, 28) },
];

function pushBudgetImportRow(name, qty, amount) {
  results.budgetImportRow.push({ name, qty, amount, expect: budgetImportRow(name, qty, amount) });
}
pushBudgetImportRow("Milk", null, 3.5);
pushBudgetImportRow("Eggs", null, 4.25);
pushBudgetImportRow("Bread", 2, 2.5);
pushBudgetImportRow("HalfCent", 1, 0.005);
pushBudgetImportRow("HalfCentAlt", 1, 0.014);
pushBudgetImportRow("NegAmount", 1, -2.005);
pushBudgetImportRow("NegHalfCent", 3, -0.505);
pushBudgetImportRow("  Trimmed  ", 1, 5);
pushBudgetImportRow("A".repeat(75), 1, 1);
pushBudgetImportRow("  " + "B".repeat(72) + "  ", 1, 2);
pushBudgetImportRow("ZeroQty", 0, 10);
pushBudgetImportRow("FracQty", 1.5, 4);

results.budgetCatTotals = [
  { cat: { n: "Mixed", open: true, goal: null, items: [
      { n: "A", a: 100, sel: true }, { n: "B", a: 50, sel: false },
      { n: "C", a: 25.5, sel: true }, { n: "D", a: 0, sel: false }] },
    total: budgetCatTotal({ items: [{ a: 100 }, { a: 50 }, { a: 25.5 }, { a: 0 }] }),
    sel: budgetCatSel({ items: [{ a: 100, sel: true }, { a: 50, sel: false }, { a: 25.5, sel: true }, { a: 0, sel: false }] }) },
  { cat: { n: "AllSel", open: true, goal: null, items: [{ n: "X", a: 40, sel: true }, { n: "Y", a: 60, sel: true }] },
    total: 100, sel: 100 },
  { cat: { n: "NoneSel", open: true, goal: null, items: [{ n: "Z", a: 15, sel: false }] }, total: 15, sel: 0 },
  { cat: { n: "Empty", open: true, goal: null, items: [] }, total: 0, sel: 0 },
];

results.budgetNetOf = [
  { income: { label: "Income", gross: 4200, tax: 18, ret: 5, oth: 2 }, expect: budgetNetOf({ gross: 4200, tax: 18, ret: 5, oth: 2 }) },
  { income: { label: "Income", gross: 3600, tax: 16, ret: 5, oth: 0 }, expect: budgetNetOf({ gross: 3600, tax: 16, ret: 5, oth: 0 }) },
  { income: { label: "Income", gross: 5000, tax: 60, ret: 30, oth: 25 }, expect: budgetNetOf({ gross: 5000, tax: 60, ret: 30, oth: 25 }) },
  { income: { label: "Income", gross: 0, tax: 10, ret: 5, oth: 0 }, expect: budgetNetOf({ gross: 0, tax: 10, ret: 5, oth: 0 }) },
  { income: { label: "Income", gross: 3000, tax: 0, ret: 0, oth: 0 }, expect: budgetNetOf({ gross: 3000, tax: 0, ret: 0, oth: 0 }) },
  { income: { label: "Income", gross: 2000, tax: 50, ret: 30, oth: 20 }, expect: budgetNetOf({ gross: 2000, tax: 50, ret: 30, oth: 20 }) },
  { income: { label: "Income", gross: 8000, tax: 90, ret: 40, oth: 10 }, expect: budgetNetOf({ gross: 8000, tax: 90, ret: 40, oth: 10 }) },
  { income: { label: "Income", gross: 500, tax: 22, ret: 3, oth: 1 }, expect: budgetNetOf({ gross: 500, tax: 22, ret: 3, oth: 1 }) },
];

const budgetFullMonth1 = budgetDefMonth();
const budgetFullMonth2 = budgetDeep(budgetDefMonth());
budgetFullMonth2.inc2On = false;
const budgetFullMonth3 = budgetDeep(budgetDefMonth());
budgetFullMonth3.inc2On = false;
budgetFullMonth3.inc[0] = { label: "Solo", gross: 6000, tax: 20, ret: 6, oth: 0 };
const budgetFullMonth4 = budgetDeep(budgetDefMonth());
budgetFullMonth4.inc[1] = { label: "Second", gross: 1000, tax: 5, ret: 0, oth: 0 };

results.budgetTakeHome = [
  { month: budgetFullMonth1, expect: budgetTakeHomeOf(budgetFullMonth1) },
  { month: budgetFullMonth2, expect: budgetTakeHomeOf(budgetFullMonth2) },
  { month: budgetFullMonth3, expect: budgetTakeHomeOf(budgetFullMonth3) },
  { month: budgetFullMonth4, expect: budgetTakeHomeOf(budgetFullMonth4) },
];

const budgetPlannedMonth2 = budgetDeep(budgetDefMonth());
budgetPlannedMonth2.cats = [];
const budgetPlannedMonth3 = budgetDeep(budgetDefMonth());
budgetPlannedMonth3.cats = [
  { n: "One", open: true, goal: null, items: [{ n: "a", a: 33.33, sel: false }] },
  { n: "Two", open: true, goal: null, items: [{ n: "b", a: 66.67, sel: true }, { n: "c", a: 10, sel: false }] },
];

results.budgetPlanned = [
  { month: budgetFullMonth1, expect: budgetPlannedOf(budgetFullMonth1) },
  { month: budgetPlannedMonth2, expect: budgetPlannedOf(budgetPlannedMonth2) },
  { month: budgetPlannedMonth3, expect: budgetPlannedOf(budgetPlannedMonth3) },
];

function budgetMonthWithGoalAndSel() {
  const m = budgetDeep(budgetDefMonth());
  m.cats[0].goal = 500;
  m.cats[0].items[0].sel = true;
  return m;
}

const budgetScenarioPrior = { v: 2, cur: "2026-05", months: { "2026-05": budgetMonthWithGoalAndSel() } };
const budgetR1 = budgetSwitchMonth(budgetScenarioPrior.months, "2026-07");

const budgetScenarioOnlyLater = { v: 2, cur: "2026-09", months: { "2026-09": budgetMonthWithGoalAndSel() } };
const budgetR2 = budgetSwitchMonth(budgetScenarioOnlyLater.months, "2026-03");

const budgetScenarioEmpty = { v: 2, cur: "2026-07", months: {} };
const budgetR3 = budgetSwitchMonth(budgetScenarioEmpty.months, "2026-07");

const budgetMonthJan = budgetMonthWithGoalAndSel();
const budgetMonthMar = budgetDefMonth();
const budgetMonthAug = budgetMonthWithGoalAndSel();
const budgetScenarioMulti = { v: 2, cur: "2026-01", months: { "2026-01": budgetMonthJan, "2026-03": budgetMonthMar, "2026-08": budgetMonthAug } };
const budgetR4 = budgetSwitchMonth(budgetScenarioMulti.months, "2026-06");

results.budgetMonthSwitch = [
  { scenario: "prior-exists", db: budgetScenarioPrior, target: "2026-07", resultMonth: budgetR1.month, copiedFrom: budgetR1.copiedFrom },
  { scenario: "only-later-exists", db: budgetScenarioOnlyLater, target: "2026-03", resultMonth: budgetR2.month, copiedFrom: budgetR2.copiedFrom },
  { scenario: "empty", db: budgetScenarioEmpty, target: "2026-07", resultMonth: budgetR3.month, copiedFrom: budgetR3.copiedFrom },
  { scenario: "multi-prior-nearest", db: budgetScenarioMulti, target: "2026-06", resultMonth: budgetR4.month, copiedFrom: budgetR4.copiedFrom },
];

const budgetYearMonths1 = {
  "2025-12": budgetMonthWithGoalAndSel(),
  "2026-01": budgetMonthWithGoalAndSel(),
  "2026-06": (() => { const m = budgetDefMonth(); m.cats[0].items[0].a = 999; return m; })(),
};
const budgetYearDb1 = { v: 2, cur: "2026-01", months: budgetYearMonths1 };

results.budgetYearAggregate = [
  { db: budgetYearDb1, year: 2026, expect: budgetYearAggregate(budgetYearMonths1, 2026) },
  { db: { v: 2, cur: "2026-01", months: {} }, year: 2026, expect: budgetYearAggregate({}, 2026) },
];

const budgetShareMonth1 = budgetMonthWithGoalAndSel();
budgetShareMonth1.cats[1].goal = 250.5;
const budgetShareFixture1 = budgetExText("2026-07", budgetMonthLabel("2026-07"), budgetShareMonth1);
const budgetShareDecoded1 = budgetImportText(budgetShareFixture1);

const budgetShareMonth2 = budgetDeep(budgetMonthWithGoalAndSel());
budgetShareMonth2.inc2On = false;
budgetShareMonth2.cats[1].goal = 250.5;
const budgetShareFixture2 = budgetExText("2026-08", budgetMonthLabel("2026-08"), budgetShareMonth2);
const budgetShareDecoded2 = budgetImportText(budgetShareFixture2);

results.budgetShare = [
  { cur: "2026-07", month: budgetShareMonth1, fixtureText: budgetShareFixture1, decoded: budgetShareDecoded1,
    expectDb: { v: 2, cur: budgetShareDecoded1.k, months: { [budgetShareDecoded1.k]: budgetShareDecoded1.m } } },
  { cur: "2026-08", month: budgetShareMonth2, fixtureText: budgetShareFixture2, decoded: budgetShareDecoded2,
    expectDb: { v: 2, cur: budgetShareDecoded2.k, months: { [budgetShareDecoded2.k]: budgetShareDecoded2.m } } },
];

mkdirSync(CONTRACTS_DIR, { recursive: true });
writeFileSync(path.join(CONTRACTS_DIR, "vectors.json"), JSON.stringify(results, null, 2) + "\n", "utf-8");
writeFileSync(path.join(ROOT, "Packages", "SummitCore", "Tests", "SummitCoreTests", "Resources", "vectors.json"), JSON.stringify(results, null, 2) + "\n", "utf-8");

function foodArtKey(name) {
  const n = String(name).toLowerCase();
  if (/croissant/.test(n)) return "croissant";
  if (/cupcake|muffin/.test(n)) return "cupcake";
  if (/cheesecake|tiramisu|shortcake|\bcake\b/.test(n)) return "shortcake";
  if (/\bhoney\b/.test(n)) return "honeypot";
  if (/matcha|\btea\b/.test(n)) return "teacup";
  if (/coffee|espresso|latte|cappuccino|mocha|hot chocolate/.test(n)) return "hotbev";
  return null;
}

function loadFoodsUnified() {
  const libraryData = JSON.parse(readFileSync(FOOD_LIBRARY_PATH, "utf-8"));
  const libraryFoods = libraryData.foods;

  const byLowerName = new Map();
  let collisions = 0;
  const unified = [];
  let nextId = 1;

  function addFood(name, group, measure, glyph) {
    const key = String(name).trim().toLowerCase();
    if (byLowerName.has(key)) { collisions++; return; }
    const artKey = foodArtKey(name);
    const food = {
      id: String(nextId++),
      name: String(name).trim(),
      group: group || "Other",
      measure: measure || "",
      glyph: glyph || "",
      artKey: artKey,
    };
    byLowerName.set(key, food);
    unified.push(food);
  }

  for (const f of foodsPantry) addFood(f.name, f.group, f.measure, f.glyph);
  for (const f of foodsIframe) addFood(f.n, f.g, f.m, f.e);
  for (const f of libraryFoods) addFood(f.name, f.group, f.measure, f.glyph);

  return { unified, collisions, iframeCount: foodsIframe.length, pantryCount: foodsPantry.length, libraryCount: libraryFoods.length };
}

const foodsResult = loadFoodsUnified();
mkdirSync(SUMMITCORE_RES, { recursive: true });
writeFileSync(path.join(SUMMITCORE_RES, "foods.json"), JSON.stringify(foodsResult.unified, null, 2) + "\n", "utf-8");

const eggsJson = buildEggsJson();
writeFileSync(path.join(SUMMITCORE_RES, "eggs.json"), JSON.stringify(eggsJson, null, 2) + "\n", "utf-8");

const fundsDefault = FUNDS_RAW.map((f) => ({ name: f.name, ratePct: f.rate }));
writeFileSync(path.join(SUMMITCORE_RES, "funds-default.json"), JSON.stringify(fundsDefault, null, 2) + "\n", "utf-8");

const soundmapDefault = {
  defaultMap: DEFAULT_MAP_RAW,
  gain: GAIN_RAW,
  defaultGain: 0.45,
  tapRotation: ["tap1", "tap2", "tap3", "tap4", "tap5"],
  tapGain: 0.45,
};
writeFileSync(path.join(CONTRACTS_DIR, "soundmap-default.json"), JSON.stringify(soundmapDefault, null, 2) + "\n", "utf-8");

const foodArtSvgDir = path.join(ROOT, "App", "Resources", "FoodArt", "svg");
mkdirSync(foodArtSvgDir, { recursive: true });
for (const [key, svg] of Object.entries(foodSvgEntries)) {
  writeFileSync(path.join(foodArtSvgDir, `${key}.svg`), svg + "\n", "utf-8");
}

console.log(JSON.stringify({
  formatters: results.formatters.length,
  finance: results.finance.length,
  calc: results.calc.length,
  eggs: results.eggs.length,
  recipe: results.recipe.length,
  convert: results.convert.length,
  budget_total: results.budgetYmKey.length + results.budgetParseYM.length + results.budgetMonthLabel.length
    + results.budgetMonthDays.length + results.budgetChartYMax.length + results.budgetPerDay.length
    + results.budgetImportRow.length + results.budgetCatTotals.length + results.budgetNetOf.length
    + results.budgetTakeHome.length + results.budgetPlanned.length + results.budgetMonthSwitch.length
    + results.budgetYearAggregate.length + results.budgetShare.length,
  foods_unified: foodsResult.unified.length,
  foods_collisions: foodsResult.collisions,
  foods_iframe_count: foodsResult.iframeCount,
  foods_pantry_count: foodsResult.pantryCount,
  foods_library_count: foodsResult.libraryCount,
  eggs_json_count: eggsJson.length,
  food_svg_keys: Object.keys(foodSvgEntries),
  calc_self_check_1: results.calc.find(c => c.keys.join("") === "3+16+25=").display,
  calc_self_check_2: results.calc.find(c => c.keys.includes("×") && c.keys[0]==="1" && c.keys[1]==="2").sequence,
  calc_self_check_3: results.calc.find(c => c.keys.join("")==="120/0=").display,
}, null, 2));
