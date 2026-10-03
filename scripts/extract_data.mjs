#!/usr/bin/env node
// Extracts the seed data from the web prototype into JSON files for the iOS app.
//
// Usage: node scripts/extract_data.mjs
//
// Reads  reference/voedingswijzer-prototype.html
// Writes Voedingswijzer/Resources/Data/{foods,plans,supplements,prices,packs,stores}.json
//
// The literals are parsed straight from the prototype source (never retyped by hand)
// and evaluated in an empty sandbox, so they contain exactly what the prototype uses.

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const html = readFileSync(join(root, "reference/voedingswijzer-prototype.html"), "utf8");
const outDir = join(root, "Voedingswijzer/Resources/Data");

const EXPECTED_FOOD_COUNT = 134;

// ---------- Literal extraction ----------

// Returns the source text of the array/object literal that starts at `start`.
function balancedLiteral(src, start) {
  const open = src[start];
  if (open !== "[" && open !== "{") throw new Error(`No literal at offset ${start}`);
  let depth = 0;
  let quote = null;
  for (let i = start; i < src.length; i++) {
    const ch = src[i];
    if (quote) {
      if (ch === "\\") i++;
      else if (ch === quote) quote = null;
      continue;
    }
    if (ch === '"' || ch === "'" || ch === "`") quote = ch;
    else if (ch === "[" || ch === "{") depth++;
    else if (ch === "]" || ch === "}") {
      depth--;
      if (depth === 0) return src.slice(start, i + 1);
    }
  }
  throw new Error(`Unterminated literal at offset ${start}`);
}

function evalLiteral(source) {
  return vm.runInNewContext(`(${source})`, Object.create(null), { timeout: 1000 });
}

function constLiteral(name) {
  const match = new RegExp(`const ${name}\\s*=\\s*`).exec(html);
  if (!match) throw new Error(`const ${name} not found in prototype`);
  return evalLiteral(balancedLiteral(html, match.index + match[0].length));
}

// The fallback pack for products without an entry in PACK lives inline in packOf():
// PACK[f.name]||[{category→aisle}[f.cat]||'aisle','singular','plural',grams,conversion]
function packFallback() {
  const fn = /function packOf\(f\)\{return PACK\[f\.name\]\|\|\[/.exec(html);
  if (!fn) throw new Error("packOf() not found in prototype");
  const mapStart = fn.index + fn[0].length;
  const mapSource = balancedLiteral(html, mapStart);
  const rest = html.slice(mapStart + mapSource.length);
  const tail = /^\[f\.cat\]\|\|('[^']*'),('[^']*'),('[^']*'),([\d.]+),([\d.]+)\]/.exec(rest);
  if (!tail) throw new Error("Unexpected packOf() shape in prototype");
  const [, aisle, singular, plural, grams, conversion] = tail;
  return {
    categoryAisles: evalLiteral(mapSource),
    fallback: {
      aisle: evalLiteral(aisle),
      singular: evalLiteral(singular),
      plural: evalLiteral(plural),
      grams: Number(grams),
      conversion: Number(conversion),
    },
  };
}

// Plain array literals in the prototype that need no further processing.
const KEYS = constLiteral("KEYS");
const CATS = constLiteral("CATS");
const SLOTS = constLiteral("SLOTS");
const DAYS = constLiteral("DAYS");
const DEFAULT_STORES = constLiteral("DEFAULT_STORES");

const RAW = constLiteral("RAW");
const POOL = constLiteral("POOL");
const POOL_BUDGET = constLiteral("POOL_BUDGET");
const SUPPS = constLiteral("SUPPS");
const PRICE = constLiteral("PRICE");
const CAT_PRICE = constLiteral("CAT_PRICE");
const PACK = constLiteral("PACK");
const AISLES = constLiteral("AISLES");
const STORES = constLiteral("STORES");
const { categoryAisles, fallback } = packFallback();

// The default price for an unknown product: priceOf = PRICE[name] ?? CAT_PRICE[cat] ?? 5
const priceFallback = /const priceOf=f=>PRICE\[f\.name\]\?\?CAT_PRICE\[f\.cat\]\?\?([\d.]+)/.exec(html);
if (!priceFallback) throw new Error("priceOf() not found in prototype");

// ---------- Validation ----------

const errors = [];
const check = (ok, message) => { if (!ok) errors.push(message); };

check(RAW.length === EXPECTED_FOOD_COUNT, `Expected ${EXPECTED_FOOD_COUNT} foods, found ${RAW.length}`);
const foodNames = new Set(RAW.map((r) => r[0]));
check(foodNames.size === RAW.length, "Duplicate food names in RAW");
RAW.forEach((r) => {
  check(r.length === KEYS.length + 2, `Food ${r[0]} has ${r.length} columns, expected ${KEYS.length + 2}`);
  check(CATS.includes(r[1]), `Food ${r[0]} has unknown category ${r[1]}`);
  r.slice(2).forEach((v) => check(typeof v === "number" && Number.isFinite(v), `Food ${r[0]} has a non-numeric value`));
});

const menus = { budget: POOL_BUDGET, variatie: POOL };
for (const [menu, pool] of Object.entries(menus)) {
  for (const [slot] of SLOTS) {
    const meals = pool[slot];
    check(Array.isArray(meals) && meals.length >= 3, `Menu ${menu} slot ${slot} needs at least 3 meals`);
    (meals || []).forEach(([name, items]) =>
      items.forEach(([food, grams]) => {
        check(foodNames.has(food), `Meal "${name}" (${menu}/${slot}) uses unknown food "${food}"`);
        check(grams > 0, `Meal "${name}" has a non-positive amount for ${food}`);
      }));
  }
}
for (const name of Object.keys(PRICE)) check(foodNames.has(name), `PRICE has unknown food "${name}"`);
for (const [name, pack] of Object.entries(PACK)) {
  check(foodNames.has(name), `PACK has unknown food "${name}"`);
  check(AISLES.includes(pack[0]), `PACK ${name} has unknown aisle "${pack[0]}"`);
}
for (const aisle of Object.values(categoryAisles)) check(AISLES.includes(aisle), `Unknown fallback aisle "${aisle}"`);
check(AISLES.includes(fallback.aisle), `Unknown fallback aisle "${fallback.aisle}"`);
for (const s of SUPPS) {
  if (s.key) check(KEYS.includes(s.key), `Supplement ${s.id} has unknown key ${s.key}`);
  for (const k of Object.keys(s.multi || {})) check(KEYS.includes(k), `Supplement ${s.id} has unknown multi key ${k}`);
}
for (const name of DEFAULT_STORES) check(STORES.some(([n]) => n === name), `Unknown default store ${name}`);

if (errors.length) {
  console.error("Extraction failed:\n- " + errors.join("\n- "));
  process.exit(1);
}

// ---------- Output ----------

const nutrientsOf = (row) => Object.fromEntries(KEYS.map((k, j) => [k, row[j + 2]]));

const foods = {
  nutrientKeys: KEYS,
  categories: CATS,
  foods: RAW.map((r) => ({ name: r[0], category: r[1], per100g: nutrientsOf(r) })),
};

const mealsOf = (pool) =>
  Object.fromEntries(SLOTS.map(([slot]) => [slot, pool[slot].map(([name, items]) => ({
    name,
    items: items.map(([food, grams]) => ({ food, grams })),
  }))]));

const plans = {
  slots: SLOTS.map(([id, name]) => ({ id, name })),
  days: DAYS,
  menus: {
    budget: { name: "Gangbaar & goedkoop", meals: mealsOf(POOL_BUDGET) },
    variatie: { name: "Gevarieerd", meals: mealsOf(POOL) },
  },
};

const supplements = {
  supplements: SUPPS.map((s) => {
    const o = { id: s.id, name: s.name, dose: s.dose, unit: s.unit, defaultOn: s.on };
    if (s.key) o.nutrient = s.key;
    if (s.multi) o.perUnit = s.multi;
    return o;
  }),
};

const prices = {
  note: "€ per kg as weighed in the plan (cooked weight for rice, pasta, meat and fish), average Dutch private-label price.",
  perKg: PRICE,
  categoryPerKg: CAT_PRICE,
  fallbackPerKg: Number(priceFallback[1]),
};

const packOut = ([aisle, singular, plural, grams, conversion]) => ({ aisle, singular, plural, grams, conversion });
const packs = {
  aisles: AISLES,
  packs: Object.fromEntries(Object.entries(PACK).map(([name, p]) => [name, packOut(p)])),
  categoryAisles,
  fallback,
};

const stores = {
  source: "Consumentenbond prijspeiling budgetboodschappen, peildatum 6 mei 2026",
  stores: STORES.map(([name, index]) => ({ name, index })),
  defaultStores: DEFAULT_STORES,
};

mkdirSync(outDir, { recursive: true });
const files = { foods, plans, supplements, prices, packs, stores };
for (const [name, data] of Object.entries(files)) {
  writeFileSync(join(outDir, `${name}.json`), JSON.stringify(data, null, 2) + "\n");
}

// ---------- Summary ----------

console.log(`Foods: ${foods.foods.length}`);
for (const [menu, pool] of Object.entries(menus)) {
  const counts = SLOTS.map(([slot]) => `${slot} ${pool[slot].length}`);
  const total = SLOTS.reduce((a, [slot]) => a + pool[slot].length, 0);
  console.log(`Meals ${menu}: ${total} (${counts.join(", ")})`);
}
console.log(`Supplements: ${SUPPS.length}, prices: ${Object.keys(PRICE).length}, packs: ${Object.keys(PACK).length}, aisles: ${AISLES.length}, stores: ${STORES.length}`);
console.log(`Written to ${outDir}`);
