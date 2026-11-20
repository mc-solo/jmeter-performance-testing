# JMeter Performance Testing

JMeter load and stress test plans for a public demo API. Built as hands-on practice for junior / mid level performance testing work.

Target: https://jsonplaceholder.typicode.com (a free public fake API, no real data is created).

## What is in here

| File | What it does |
| --- | --- |
| `test-plans/load-test.jmx` | Load test: 10 threads, 10 second ramp-up, 5 loops |
| `test-plans/stress-test.jmx` | Stress test: 50 threads, 30 second ramp-up, 10 loops, same requests at higher load |
| `data/users.csv` | Test data: 10 rows of `userId`, `postId`, `title`, used by both plans through `${userId}`, `${postId}` and `${title}` |

Both plans hit the same three requests:

- `GET /posts` - list all posts
- `GET /posts/${postId}` - one post, id taken from the CSV
- `POST /posts` - create a post, title and userId taken from the CSV

## What is checked

- `GET /posts` returns 200, and finishes in under 5000 ms (Duration Assertion)
- `GET /posts/${postId}` returns 200, and the response contains the expected `userId` from the CSV row
- `POST /posts` returns 201, with `Content-Type: application/json`
- Summary Report and Aggregate Report listeners are included in both plans, so you can see average, min, max, error % and throughput in the GUI

## Requirements

- Apache JMeter 5.6.x (Java 8 or later). JMeter is not installed in this workspace yet.
- No other setup is needed. The target is public, so there is nothing to install or log in to.

## How to run (headless)

Run from the repo root, so the CSV path `data/users.csv` resolves:

```bash
# Load test
jmeter -n -t test-plans/load-test.jmx -l results/load-test.jtl -e -o reports/load-test

# Stress test
jmeter -n -t test-plans/stress-test.jmx -l results/stress-test.jtl -e -o reports/stress-test
```

Notes:

- `-n` is non-GUI (headless) mode, `-t` is the test plan, `-l` is the results file, `-e -o` generates the HTML dashboard in the given folder.
- Delete or rename an old `results/*.jtl` file and `reports/*` folder before re-running, or JMeter will refuse to overwrite the report folder.
- To open a plan in the GUI instead: `jmeter -t test-plans/load-test.jmx`

## How to generate the HTML dashboard from an existing results file

```bash
jmeter -g results/load-test.jtl -o reports/load-test
```

Open `reports/load-test/index.html` in a browser.

## Results

No results yet. No run has been done from this repo, so no response times, error rates or throughput numbers are claimed here. Results will be added after a real run.

## Notes

- JSONPlaceholder is a fake API: `POST /posts` returns 201 but does not really save anything.
- The stress plan is meant to push harder than the load plan. Slower responses or some errors under stress are expected, and are part of what the test is for.
- `results/` and `reports/` are git-ignored, so run output stays local.
