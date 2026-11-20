# Architecture

## Folder tree

```
jmeter-performance-testing/
├── ARCHITECTURE.md            # this file
├── README.md                  # overview, setup, run commands, results
├── .env.example               # optional local overrides (no secrets in this repo)
├── .gitignore                 # results/, reports/, .env, *.jtl, *.log
├── config/
│   └── user.properties        # target host, timeouts, thread counts (JMeter properties)
├── docs/
│   ├── SETUP.md               # install JMeter, run plans, property overrides
│   └── TESTING.md             # what is tested, how to run, how to read reports
├── test-data/
│   └── users.csv              # 10 rows of userId, postId, title
├── test-plans/
│   ├── load-test.jmx          # 10 threads, 10 s ramp-up, 5 loops
│   └── stress-test.jmx        # 50 threads, 30 s ramp-up, 10 loops
├── results/                   # git-ignored: .jtl output from runs
└── reports/                   # git-ignored: HTML dashboard output from runs
```

## Why each folder exists

| Folder / file | Purpose |
| --- | --- |
| `config/` | One place for every value that changes between runs or environments. `user.properties` holds the target host, protocol, port, timeouts and thread counts. Nothing in `test-plans/` hard-codes these any more. |
| `test-data/` | The canonical home for input data. `users.csv` is the only data file; both plans read it by the relative path `test-data/users.csv`. |
| `test-plans/` | The JMeter plans (`.jmx`, XML). Each plan is one scenario: a thread group, HTTP defaults, a CSV Data Set Config, samplers, assertions and listeners. |
| `docs/` | Setup and testing guides, so the README stays short. |
| `results/` / `reports/` | Run output only. `results/` holds raw `.jtl` result files, `reports/` holds the generated HTML dashboards. Both are git-ignored and start empty. |
| `.env.example` | Documents the optional shell variables for local overrides. There are no secrets in this repo; JMeter does not read `.env` directly (see `docs/SETUP.md`). |

## Data flow

```
config/user.properties ── -p ──▶ JMeter properties (host, port, timeouts, threads)
                                              │
test-data/users.csv ── CSV Data Set Config ────┤
                                              ▼
                        test-plans/*.jmx ──▶ HTTP samplers ──▶ jsonplaceholder.typicode.com
                                              │
                                              ▼
                                   results/*.jtl ── -e -o ──▶ reports/*/index.html
```

1. JMeter starts with `-p config/user.properties`. Each `${__P(name,default)}`
   in a plan resolves to the property value, or to its built-in default if
   the property is set nowhere. `-Jname=value` on the command line
   overrides the file.
2. The CSV Data Set Config in each plan reads `test-data/users.csv`
   (relative to the repo root, which is why runs must start there) and
   exposes `${userId}`, `${postId}` and `${title}` per thread iteration.
3. HTTP Request Defaults applies the host, protocol, port and timeouts
   from step 1 to every sampler. Each sampler then runs its request, and
   its assertions check the status code, response content and duration.
4. Samples are written to `results/*.jtl`; the HTML dashboard is
   generated into `reports/*` from that file.

## How config / test-data / test-plans connect

- **config → test-plans:** `config/user.properties` defines `host`,
  `protocol`, `port`, `connect.timeout`, `response.timeout`,
  `load.threads`, `load.rampup`, `load.loops`, `stress.threads`,
  `stress.rampup`, `stress.loops`. The plans reference them only through
  `${__P(...)}` in HTTP Request Defaults and in the thread group / loop
  controller. The only hard-coded host left is the fallback default inside
  `${__P(host,jsonplaceholder.typicode.com)}` and the prose in the plan
  comments. The 5000 ms Duration Assertion stays a literal in the `.jmx`
  files because JMeter does not evaluate functions there; it is mirrored
  as `duration.max.ms` in `config/user.properties`.
- **test-data → test-plans:** both plans point their CSV Data Set Config
  at the same file, `test-data/users.csv`. The old `data/` folder is gone;
  there is no duplicate or symlink.
- **test-plans → results/reports:** a plan run with `-l` writes
  `results/<plan>.jtl`, and `-e -o` turns it into the HTML dashboard in
  `reports/<plan>/`.

## How to add a new test plan

1. Copy the closest existing plan, e.g. `cp test-plans/load-test.jmx
   test-plans/soak-test.jmx`, and rename the TestPlan and ThreadGroup
   inside it (open in the JMeter GUI, or edit the `testname` attributes).
2. If the new plan needs different thread counts or loops, add properties
   to `config/user.properties` (e.g. `soak.threads=20`) and use
   `${__P(soak.threads,20)}` in the thread group, the same way the load
   and stress plans do. Do not hard-code the numbers.
3. If it needs new test data, add a CSV under `test-data/` and point a CSV
   Data Set Config at it by its `test-data/...` relative path. Keep the
   file name descriptive (`orders.csv`, not `data2.csv`).
4. Add the run command to `README.md` and a row to the plan table in
   `docs/TESTING.md`, including what the new plan checks.
5. Validate the XML before committing: `python3 -c
   "import xml.etree.ElementTree as ET; ET.parse('test-plans/soak-test.jmx')"`.
   Do not claim results until a real JMeter run has produced them.
