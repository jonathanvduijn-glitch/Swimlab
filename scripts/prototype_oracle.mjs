#!/usr/bin/env node
// Runs the prototype's own calculation code (everything before the event handlers)
// in a sandbox and prints reference values for the Swift unit tests.
//
// Usage: node scripts/prototype_oracle.mjs
//
// The expectations in VoedingswijzerTests/ were generated with this script, so the
// Swift implementation is checked against the prototype rather than against itself.

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const html = readFileSync(join(root, "reference/voedingswijzer-prototype.html"), "utf8");
const start = html.indexOf("<script>") + "<script>".length;
const end = html.indexOf("// ---------- Events ----------");
const code = html.slice(start, end) + `
globalThis.__set = (o) => {
  profile = { ...DEFAULT_PROFILE, ...(o.profile || {}) };
  logs = o.logs || {}; day = o.day; suppLog = o.suppLog || {}; slotDone = o.slotDone || {};
};
globalThis.__api = { targets, score, BASE, optsFor, planFactor, portion, mealItems, sumItems, dayPlan,
  streak, totals, packOf, priceOf, SLOTS, STORES, AISLES, PACK, KEYS };
`;
const noop = () => {};
const element = { innerHTML: "", classList: { add: noop, remove: noop }, setAttribute: noop };
const sandbox = {
  document: { querySelector: () => element, querySelectorAll: () => [], addEventListener: noop },
  window: {}, localStorage: { getItem: () => null, setItem: noop },
  setTimeout: noop, clearTimeout: noop, console,
};
vm.createContext(sandbox);
vm.runInContext(code, sandbox);
const { __set: set, __api: api } = sandbox;

// Monday 5 October 2026 is weekday 0, so plan day w maps to 2026-10-(05+w).
const dayKey = (w) => `2026-10-${String(5 + w).padStart(2, "0")}`;
const round = (v, d = 4) => Math.round(v * 10 ** d) / 10 ** d;
const out = {};

// ---------- Targets ----------
set({ day: dayKey(0) });
out.targetsReference = api.targets();
set({ day: dayKey(0), profile: { kcalTarget: 0 } });
out.targetsGoalFactor = api.targets();
set({ day: dayKey(0), profile: { bmr: 0 } });
out.targetsKatch = api.targets();
set({ day: dayKey(0), profile: { bmr: 0, fat: 0 } });
out.targetsMifflinMan = api.targets();
set({ day: dayKey(0), profile: { sex: "vrouw", age: 55, height: 168, weight: 70, fat: 0, bmr: 0, act: 1.375, goal: 0.9, kcalTarget: 0, pkg: 1.6 } });
out.targetsMifflinWoman55 = api.targets();
set({ day: dayKey(0), profile: { sex: "vrouw", age: 72, fat: 0, bmr: 0 } });
out.targetsWoman72 = api.targets();

// ---------- Scores ----------
set({ day: dayKey(0) });
const T = api.targets();
out.scores = Object.fromEntries(["Spinazie", "Broccoli", "Olijfolie", "Magere kwark", "Kipfilet (gebakken)", "Havermout", "Pure chocolade 85%", "Banaan"]
  .map((n) => [n, api.score(api.BASE.find((f) => f.name === n), T)]));

// ---------- Plan (default choices, both menus) ----------
for (const style of ["budget", "variatie"]) {
  set({ day: dayKey(6), profile: { planStyle: style } });
  out[`plan_${style}`] = [0, 1, 2, 3, 4, 5, 6].map((w) => ({
    options: Object.fromEntries(api.SLOTS.map(([sid]) => [sid, api.optsFor(sid, w).map((o) => o[0])])),
    factor: round(api.planFactor(w), 6),
    meals: Object.fromEntries(api.SLOTS.map(([sid]) => [sid, api.mealItems(sid, w, api.planFactor(w)).map(({ f, g }) => [f.name, g])])),
  }));
}

// ---------- Portions ----------
out.portions = [[105, 1.4], [150, 0.7], [2, 1], [3, 1], [12.5, 1], [7.5, 1], [250, 1.13], [10, 0.4], [102.5, 1]]
  .map(([g, f]) => [g, f, api.portion(g, f)]);

// ---------- Live day (budget, Monday is the log day) ----------
const breakfast = (w) => { set({ day: dayKey(w) }); return api.mealItems("ontbijt", w, api.planFactor(w)); };
const asLog = (items, slot) => items.map(({ f, g }) => ({ name: f.name, g, slot, n: Object.fromEntries(api.KEYS.map((k) => [k, f[k] || 0])) }));
const live = (logs, slotDone, w = 0) => {
  set({ day: dayKey(w), logs: { [dayKey(w)]: logs }, slotDone: { [dayKey(w)]: slotDone } });
  const D = api.dayPlan(w);
  const open = D.meals.filter((m) => !m.done);
  const S = api.sumItems(open.flatMap((m) => m.items));
  if (D.live) api.KEYS.forEach((k) => S[k] += D.eaten[k]);
  return {
    live: D.live, factor: round(D.fac, 6), eaten: round(D.eaten?.kcal ?? 0), left: round(D.left ?? 0), raw: round(D.raw ?? 0),
    expectedKcal: round(S.kcal), expectedProtein: round(S.p),
    meals: D.meals.map((m) => ({ slot: m.sid, done: m.done, marked: !!m.marked, items: m.items.map(({ f, g }) => [f.name, g]) })),
  };
};
out.liveNothingLogged = live([], {});
out.liveBreakfastLogged = live(asLog(breakfast(0), "ontbijt"), {});
out.liveBreakfastAndMarkedLunch = live(asLog(breakfast(0), "ontbijt"), { lunch: true });
out.liveBigUnslotted = live([{ name: "Olijfolie", g: 250, n: Object.fromEntries(api.KEYS.map((k) => [k, api.BASE.find((f) => f.name === "Olijfolie")[k]])) }], {});
out.liveOverTarget = live([{ name: "Olijfolie", g: 400, n: Object.fromEntries(api.KEYS.map((k) => [k, api.BASE.find((f) => f.name === "Olijfolie")[k]])) }], {});
out.liveAllMarked = live([], Object.fromEntries(api.SLOTS.map(([s]) => [s, true])));

// ---------- Shopping list (budget, default choices, default stores) ----------
const shopping = (style) => {
  set({ day: dayKey(0), profile: { planStyle: style } });
  const tot = {};
  for (let w = 0; w < 7; w++) {
    const fac = api.planFactor(w);
    api.SLOTS.forEach(([sid]) => api.mealItems(sid, w, fac).forEach(({ f, g }) => { tot[f.name] = tot[f.name] || { f, g: 0 }; tot[f.name].g += g; }));
  }
  const rows = Object.values(tot).map((x) => {
    const [aisle, sing, plur, buy, conv] = api.packOf(x.f);
    const need = x.g / conv, n = Math.max(1, Math.ceil(need / buy - 0.08));
    const packPrice = buy * conv / 1000 * api.priceOf(x.f);
    return { name: x.f.name, grams: x.g, aisle, label: `${n} ${n === 1 ? sing : plur}`, n, cost: round(n * packPrice), used: round(x.g / 1000 * api.priceOf(x.f)) };
  }).sort((a, b) => a.name.localeCompare(b.name));
  const kassa = rows.reduce((a, r) => a + r.cost, 0), used = rows.reduce((a, r) => a + r.used, 0);
  const mine = ["Albert Heijn", "Jumbo", "Lidl", "ALDI", "Dirk"];
  const sel = api.STORES.filter(([n]) => mine.includes(n)).map(([n, idx]) => ({ n, idx, v: round(kassa * (1 + idx / 100)), u: round(used * (1 + idx / 100)) })).sort((a, b) => a.v - b.v);
  const aisles = api.AISLES.filter((a) => rows.some((r) => r.aisle === a));
  return { rows, kassa: round(kassa), used: round(used), stores: sel, aisles };
};
out.shopping_budget = shopping("budget");
out.shopping_variatie = shopping("variatie");

// ---------- Creatine streak ----------
const streakOf = (days, from) => { set({ day: from, suppLog: Object.fromEntries(days.map((d) => [d, { creatine: true }])) }); return api.streak("creatine", from); };
out.streaks = {
  todayAndTwoBefore: streakOf(["2026-10-03", "2026-10-02", "2026-10-01"], "2026-10-03"),
  notYetToday: streakOf(["2026-10-02", "2026-10-01"], "2026-10-03"),
  gapYesterday: streakOf(["2026-10-01"], "2026-10-03"),
  onlyToday: streakOf(["2026-10-03"], "2026-10-03"),
  none: streakOf([], "2026-10-03"),
  acrossMonth: streakOf(["2026-10-02", "2026-10-01", "2026-09-30", "2026-09-29"], "2026-10-02"),
};

// ---------- Totals with supplements ----------
set({ day: dayKey(0), logs: { [dayKey(0)]: [] }, suppLog: { [dayKey(0)]: { vitd: true, multi: true, creatine: true } } });
out.supplementTotals = Object.fromEntries(Object.entries(api.totals(dayKey(0))).map(([k, v]) => [k, round(v)]));

console.log(JSON.stringify(out, null, 1));
