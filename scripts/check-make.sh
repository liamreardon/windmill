#!/bin/sh
# Checks that a value in the environment or on the make command line beats
# windmill-backend/.env, and that loading .env never rewrites it.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
make=${MAKE:-make}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/windmill-backend"
cp "$root/Makefile" "$tmp/Makefile"
printf 'WINDMILL_LISTEN=from-env-file\n' > "$tmp/windmill-backend/.env"
before=$(cat "$tmp/windmill-backend/.env")

fail=0
check() {
	want=$1; shift
	got=$("$@" 2>&1) || true
	if [ "$got" = "$want" ]; then
		echo "check-make: ok: $want"
	else
		echo "check-make: FAIL: want $want, got $got" >&2
		fail=1
	fi
}
unset WINDMILL_LISTEN 2>/dev/null || true
check from-env-file "$make" -s -C "$tmp" print-WINDMILL_LISTEN
check from-environment env WINDMILL_LISTEN=from-environment "$make" -s -C "$tmp" print-WINDMILL_LISTEN
check from-command-line "$make" -s -C "$tmp" print-WINDMILL_LISTEN WINDMILL_LISTEN=from-command-line
if [ "$(cat "$tmp/windmill-backend/.env")" != "$before" ]; then
	echo "check-make: FAIL: .env changed" >&2
	fail=1
fi
exit $fail
