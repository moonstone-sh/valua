import * as v from 'valibot';

const warmupRounds = Number(process.env.VALUA_BENCH_WARMUP_ROUNDS ?? 2);
const warmupIterations = Number(process.env.VALUA_BENCH_WARMUP_ITERS ?? 10_000);
const rounds = Number(process.env.VALUA_BENCH_ROUNDS ?? 5);
const iterations = Number(process.env.VALUA_BENCH_ITERS ?? 50_000);
const json = process.argv.includes('--json');

function runPass(fn, count) {
  const start = performance.now();
  for (let index = 0; index < count; index += 1) fn();
  return (performance.now() - start) / 1_000;
}

const results = [];
function bench(name, fn) {
  for (let index = 0; index < warmupRounds; index += 1) runPass(fn, warmupIterations);
  const samples = Array.from({ length: rounds }, () => runPass(fn, iterations)).sort((a, b) => a - b);
  const seconds = samples[Math.floor(samples.length / 2)];
  const result = { name, seconds, ops_per_second: iterations / seconds };
  results.push(result);
  if (!json) console.log(`${name.padEnd(38)} | median ${seconds.toFixed(6)} s | ${result.ops_per_second.toFixed(0).padStart(10)} ops/s`);
}

// Matches the data shape in ../bench.lua. Comparable workloads, not an assertion
// that Lua tables and JavaScript objects share all validation semantics.
const flatSchema = v.object({ id: v.number(), name: v.string(), active: v.boolean() });
const flatValid = { id: 101, name: 'Alice', active: true };
const nestedSchema = v.object({ id: v.number(), name: v.string(), profile: v.object({ role: v.string(), bio: v.optional(v.string()) }) });
const nestedValid = { id: 101, name: 'Alice', profile: { role: 'admin', bio: 'engineer' } };
const pipelineSchema = v.pipe(v.string(), v.nonEmpty(), v.minLength(3), v.maxLength(50));
const threeIssueSchema = v.object({ a: v.string(), b: v.number(), c: v.boolean() });
const tenIssueSchema = v.object({
  f1: v.string(), f2: v.number(), f3: v.boolean(), f4: v.string(), f5: v.number(),
  f6: v.boolean(), f7: v.string(), f8: v.number(), f9: v.boolean(), f10: v.string(),
});
const deepSchema = v.object({ l1: v.object({ l2: v.object({ l3: v.object({ l4: v.object({ l5: v.string() }) }) }) }) });
const arraySchema = v.array(v.number());
const tupleSchema = v.tuple([v.string(), v.number(), v.boolean()]);
const recordSchema = v.record(v.string(), v.number());
const looseSchema = v.looseObject({ id: v.number() });
const strictSchema = v.strictObject({ id: v.number() });

bench('flat_success', () => v.safeParse(flatSchema, flatValid));
bench('nested_success', () => v.safeParse(nestedSchema, nestedValid));
bench('pipeline_success', () => v.safeParse(pipelineSchema, 'valid_payload'));
bench('primitive_failure', () => v.safeParse(v.string(), 12345));
bench('three_issue_failure', () => v.safeParse(threeIssueSchema, { a: 123, b: 'bad', c: 999 }));
bench('ten_issue_failure', () => v.safeParse(tenIssueSchema, { f1: 1, f2: 'a', f3: 3, f4: 4, f5: 'b', f6: 6, f7: 7, f8: 'c', f9: 9, f10: 10 }));
bench('deep_failure', () => v.safeParse(deepSchema, { l1: { l2: { l3: { l4: { l5: 99999 } } } } }));
bench('array_success', () => v.safeParse(arraySchema, [1, 2, 3, 4, 5]));
bench('tuple_success', () => v.safeParse(tupleSchema, ['ok', 1, true]));
bench('record_success', () => v.safeParse(recordSchema, { a: 1, b: 2, c: 3 }));
bench('loose_object_success', () => v.safeParse(looseSchema, { id: 1, extra: 'kept' }));
bench('strict_object_failure', () => v.safeParse(strictSchema, { id: 1, extra: true }));

if (json) {
  console.log(JSON.stringify({
    suite: 'valua-vs-valibot-v1', implementation: 'valibot', runtime: `${process.release.name} ${process.version}`,
    rounds, iterations, warmup_rounds: warmupRounds, warmup_iterations: warmupIterations, cases: results,
  }));
}
