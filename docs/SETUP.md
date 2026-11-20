# Setup

## What you need

- Java 8 or later (JMeter 5.6.x needs it; Java 17 is a safe pick).
- Apache JMeter 5.6.x.
- Nothing else. The target is the public fake API
  `https://jsonplaceholder.typicode.com`, so there is no app to install,
  no account, and no login.

> Status in this workspace: JMeter is **not installed** here and no plan in
> this repo has ever been run. The `.jmx` files have only been checked as
> valid XML. Install JMeter on your own machine before running anything.

## Install JMeter

1. Check Java: `java -version` (needs 8 or later).
2. Download the binary zip from
   <https://jmeter.apache.org/download_jmeter.cgi> (for example
   `apache-jmeter-5.6.3.zip`) and unzip it somewhere, e.g.
   `~/tools/apache-jmeter-5.6.3`.
3. Add its `bin` folder to `PATH`, or set `JMETER_HOME` (see `.env.example`):

   ```bash
   export JMETER_HOME=~/tools/apache-jmeter-5.6.3
   export PATH="$JMETER_HOME/bin:$PATH"
   ```

4. Verify: `jmeter --version` should print the JMeter version.

## Run a plan

Always run from the **repo root**. The CSV path in both plans is the
relative path `test-data/users.csv`, so it only resolves from the root.

```bash
# Load test
jmeter -p config/user.properties -n -t test-plans/load-test.jmx -l results/load-test.jtl -e -o reports/load-test

# Stress test
jmeter -p config/user.properties -n -t test-plans/stress-test.jmx -l results/stress-test.jtl -e -o reports/stress-test
```

Flags: `-p` loads the properties file, `-n` is non-GUI (headless) mode,
`-t` is the test plan, `-l` is the results file, `-e -o` generates the
HTML dashboard in the given folder.

Before re-running, delete or rename the old `results/*.jtl` file and the
old `reports/*` folder, or JMeter will refuse to overwrite the report
folder. Both folders are git-ignored, so run output stays local.

To open a plan in the GUI instead:

```bash
jmeter -p config/user.properties -t test-plans/load-test.jmx
```

## Overriding properties (env / property overrides)

Every tunable value lives in `config/user.properties` and is read in the
plans as `${__P(name,default)}`. Override without editing any file:

```bash
# Point at a different host, or raise the load, for one run only
jmeter -p config/user.properties -Jhost=api.example.com -Jload.threads=20 -Jload.loops=10 \
  -n -t test-plans/load-test.jmx -l results/load-test.jtl -e -o reports/load-test
```

| Override | What it changes | Default |
| --- | --- | --- |
| `-Jhost=` | target host | `jsonplaceholder.typicode.com` |
| `-Jprotocol=` | `http` or `https` | `https` |
| `-Jport=` | target port | `443` |
| `-Jconnect.timeout=` | connect timeout, ms | `5000` |
| `-Jresponse.timeout=` | response timeout, ms | `30000` |
| `-Jload.threads=` / `-Jload.rampup=` / `-Jload.loops=` | load test size | `10` / `10` / `5` |
| `-Jstress.threads=` / `-Jstress.rampup=` / `-Jstress.loops=` | stress test size | `50` / `30` / `10` |

`-J` on the command line beats `config/user.properties`, which beats the
built-in default in the `.jmx` file.

Optional: copy `.env.example` to `.env` and set `TARGET_HOST`,
`LOAD_THREADS`, etc. there. JMeter does not read `.env`; it is only a
place to keep values you then pass with `-J` (see the comments in
`.env.example`). `.env` is git-ignored.

## Generate the HTML dashboard from an existing results file

```bash
jmeter -g results/load-test.jtl -o reports/load-test
```

Then open `reports/load-test/index.html` in a browser. See
[TESTING.md](TESTING.md) for how to read it.
