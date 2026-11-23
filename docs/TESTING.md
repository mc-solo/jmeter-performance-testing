# Testing

## What is tested

Both plans hit the same three requests against the target API
(`https://jsonplaceholder.typicode.com`, a free public fake API). Test
data comes from `test-data/users.csv` (10 rows of `userId`, `postId`,
`title`), read by a CSV Data Set Config and reused as `${userId}`,
`${postId}` and `${title}`.

| Plan | Threads | Ramp-up | Loops | Total samples per sampler |
| --- | --- | --- | --- | --- |
| `test-plans/load-test.jmx` | 10 | 10 s | 5 | 50 |
| `test-plans/stress-test.jmx` | 50 | 30 s | 10 | 500 |

Both plans run these samplers, in order, for every thread and loop:

| Sampler | Check |
| --- | --- |
| `GET /posts` | Returns 200, finishes in under 5000 ms (Duration Assertion), and the body contains `"userId"` and `"title"` |
| `GET /posts/${postId}` | Returns 200, finishes in under 5000 ms, and the body contains the expected `"userId": ${userId}` from the CSV row plus `"title"` and `"body"` |
| `POST /posts` | Returns 201, with `Content-Type: application/json`; body is `{"title": "${title}", "body": "Performance test post", "userId": ${userId}}`; the created body echoes `"title": "${title}"` and `"userId": ${userId}`, and finishes in under 5000 ms |

Both plans also include a Summary Report and an Aggregate Report listener,
so average, min, max, error % and throughput are visible in the GUI.

Notes:

- JSONPlaceholder is a fake API: `POST /posts` returns 201 but does not
  really save anything.
- The stress plan is meant to push harder than the load plan. Slower
  responses or some errors under stress are expected, and are part of what
  the test is for.
- The 5000 ms threshold is a literal in the Duration Assertion inside the
  `.jmx` files (JMeter does not evaluate `${__P(...)}` there). It is also
  recorded as `duration.max.ms` in `config/user.properties`; if you change
  one, change the other to match.

## How to run

See [SETUP.md](SETUP.md). Short version, from the repo root, using
the run script (it clears the old `.jtl` and report folder first,
because JMeter refuses to overwrite a report folder):

```bash
# Load test
./scripts/run-jmeter.sh load

# Stress test
./scripts/run-jmeter.sh stress

# Stress test with an override (any -J property from config/user.properties)
./scripts/run-jmeter.sh stress -Jstress.threads=20
```

The same runs without the script:

```bash
# Load test
jmeter -p config/user.properties -n -t test-plans/load-test.jmx -l results/load-test.jtl -e -o reports/load-test

# Stress test
jmeter -p config/user.properties -n -t test-plans/stress-test.jmx -l results/stress-test.jtl -e -o reports/stress-test
```

## How to read the HTML dashboard report

After a run, open `reports/load-test/index.html` (or
`reports/stress-test/index.html`) in a browser.

- **Dashboard / overview:** the headline numbers — total samples, error
  %, average / min / max response time, throughput (requests per second).
  This is the first thing to check after a run.
- **Statistics table:** one row per sampler (`GET /posts`,
  `GET /posts/${postId}`, `POST /posts`) with samples, error %, average,
  median, 90th / 95th / 99th percentile, min, max and throughput. Use the
  percentiles, not just the average: a good average can hide a slow tail.
- **Response time graphs (over time / percentiles):** look for response
  time climbing as threads ramp up, and for spikes. A flat line under load
  is healthy; a line that keeps rising suggests the target is saturating.
- **Errors section:** lists failed samples by type. Any error % above 0
  deserves a look at the failing sampler and its assertion message in the
  `.jtl` file.
- **Top 5 errors by sampler:** the most common failures, useful for
  spotting one bad endpoint instead of a general overload.

To regenerate a dashboard from a results file you already have:

```bash
jmeter -g results/load-test.jtl -o reports/load-test
```

## Results

No results yet. No run has been done from this repo, so no response
times, error rates or throughput numbers are claimed here. The `.jmx`
files have only been checked as valid XML, and JMeter is not installed in
this workspace. Results will be added after a real run.
