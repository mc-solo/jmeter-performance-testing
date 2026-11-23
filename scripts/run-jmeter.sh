#!/usr/bin/env bash
# Run a JMeter test plan headless and generate the HTML dashboard.
#
# Usage:
#   ./scripts/run-jmeter.sh [load|stress] [extra jmeter -J overrides...]
#   ./scripts/run-jmeter.sh load
#   ./scripts/run-jmeter.sh stress -Jstress.threads=20
#
# Outputs (results/ and reports/ are git-ignored):
#   results/<plan>-test.jtl   raw samples
#   reports/<plan>-test/      HTML dashboard (open index.html)
#
# JMeter refuses to write a dashboard into an existing folder, so an
# old report folder for the same plan is removed first. The .jtl file
# is replaced by the new run.
set -e
cd "$(dirname "$0")/.."

PLAN="${1:-load}"
shift || true
if [ "$PLAN" != "load" ] && [ "$PLAN" != "stress" ]; then
  echo "Usage: $0 [load|stress] [extra -J overrides...]" >&2
  exit 2
fi

if ! command -v jmeter >/dev/null 2>&1; then
  echo "Error: jmeter is not installed or not on PATH. See docs/SETUP.md." >&2
  exit 1
fi

mkdir -p results reports
rm -f "results/${PLAN}-test.jtl"
rm -rf "reports/${PLAN}-test"

jmeter -p config/user.properties -n \
  -t "test-plans/${PLAN}-test.jmx" \
  -l "results/${PLAN}-test.jtl" \
  -e -o "reports/${PLAN}-test" "$@"

echo "Results: results/${PLAN}-test.jtl"
echo "Report:  reports/${PLAN}-test/index.html"
