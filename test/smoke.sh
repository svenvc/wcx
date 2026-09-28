#!/bin/sh
# Smoke tests for a standalone wc binary, for example one from burrito_out/.
# Usage: test/smoke.sh ./burrito_out/wc_macos_arm64
set -eu

BIN=${1:?usage: smoke.sh <path to wc binary>}
FIXTURES="$(dirname "$0")/fixtures"
failures=0

report() {
  case $1 in
    ok) printf 'ok   %s\n' "$2" ;;
    *)
      report_body="FAIL $2"
      shift 2
      for line in "$@"; do report_body="$report_body
     $line"; done
      printf '%s\n' "$report_body"
      failures=1
      ;;
  esac
}

expect() {
  if [ "$2" = "$3" ]; then
    report ok "$1"
  else
    report fail "$1" "expected: $2" "actual:   $3"
  fi
}

# The count columns of wc output, without the file name. Numbers are padded to
# 7 columns, so column 24 is the last one before the name.
counts() {
  cut -c1-24 "$1" | sed 's/ *$//'
}

# Yes/no for a grep pattern, so file names can be asserted by base name: Git
# Bash rewrites POSIX paths when it calls a native Windows binary, so the path
# wc echoes back is not the one this script passes in.
matches() {
  if grep -q -- "$2" "$1"; then echo yes; else echo no; fi
}

# Runs the binary, leaving stdout, stderr and the exit code in the temp files
# and $status. stdin is passed through.
status=0
run() {
  status=0
  "$@" >/tmp/smoke-stdout 2>/tmp/smoke-stderr || status=$?
}

echo "# smoke testing $BIN"

# The counted inputs are written here instead of taken from test/fixtures,
# because a Windows checkout rewrites those to CRLF and the byte counts below
# are about wc, not about how git checked the repository out.
printf 'a b\nc\n' >/tmp/smoke-input
: >/tmp/smoke-empty

run "$BIN" -lwcmL /tmp/smoke-input
expect "counts for a file" \
  "      2       3       6" \
  "$(counts /tmp/smoke-stdout)"
expect "names the file" "yes" "$(matches /tmp/smoke-stdout 'smoke-input$')"

run "$BIN" /tmp/smoke-input /tmp/smoke-empty
expect "multiple files with a total" \
  "      2       3       6
      0       0       0
      2       3       6" \
  "$(counts /tmp/smoke-stdout)"
expect "names the total" "yes" "$(matches /tmp/smoke-stdout ' total$')"

printf 'a b\nc\n' | run "$BIN" -m
expect "counts from stdin" "      6" "$(cat /tmp/smoke-stdout)"

run "$BIN" --version
if grep -qE '^wc \(Elixir\) [0-9]+\.[0-9]+\.[0-9]+$' /tmp/smoke-stdout; then
  report ok "version"
else
  report fail "version" "actual: $(cat /tmp/smoke-stdout)"
fi

run "$BIN" --help
if [ "$status" -eq 0 ] && grep -q '^Usage: wc ' /tmp/smoke-stderr; then
  report ok "help goes to stderr and exits 0"
else
  report fail "help goes to stderr and exits 0" \
    "status: $status" "stderr: $(cat /tmp/smoke-stderr)"
fi

run "$BIN" --bogus
if [ "$status" -eq 1 ] && grep -q "unrecognized option '--bogus'" /tmp/smoke-stderr; then
  report ok "invalid option exits 1"
else
  report fail "invalid option exits 1" \
    "status: $status" "stderr: $(cat /tmp/smoke-stderr)"
fi

run "$BIN" "$FIXTURES/does-not-exist.txt"
if [ "$status" -eq 0 ] && grep -q "no such file or directory" /tmp/smoke-stderr; then
  report ok "missing file is reported on stderr"
else
  report fail "missing file is reported on stderr" \
    "status: $status" "stderr: $(cat /tmp/smoke-stderr)"
fi

run "$BIN" "$FIXTURES"
if grep -q "Is a directory" /tmp/smoke-stderr; then
  report ok "directory is reported on stderr"
else
  report fail "directory is reported on stderr" "stderr: $(cat /tmp/smoke-stderr)"
fi

# A file larger than the 64 KiB read buffer, to catch chunk boundary bugs.
awk 'BEGIN { for (i = 0; i < 20000; i++) print "word" }' >/tmp/smoke-big
run "$BIN" -lwc /tmp/smoke-big
expect "counts a file larger than the read buffer" \
  "  20000   20000  100000" \
  "$(counts /tmp/smoke-stdout)"

rm -f /tmp/smoke-stdout /tmp/smoke-stderr /tmp/smoke-big /tmp/smoke-input /tmp/smoke-empty

if [ "$failures" -eq 0 ]; then
  echo "# all good"
else
  echo "# failures" >&2
  exit 1
fi
