#!/bin/sh
# make doctor: checks what Windmill needs on this Mac. Installs nothing.
GO=${GO:-go}
XCODEGEN=${XCODEGEN:-xcodegen}
bad=0
ok() { echo "ok    $1"; }
fix() { echo "fix   $1"; bad=1; }
info() { echo "info  $1"; }

if v=$("$GO" env GOVERSION 2>/dev/null); then
	minor=$(echo "$v" | sed -n 's/^go1\.\([0-9]*\).*/\1/p')
	if [ -n "$minor" ] && [ "$minor" -ge 21 ]; then ok "Go $v ($GO)"; else fix "Go $v is older than 1.21: set GO in windmill-backend/.env to a newer go binary"; fi
else
	fix "no Go at $GO: install Go 1.21 or newer, or set GO in windmill-backend/.env"
fi
if command -v "$XCODEGEN" >/dev/null 2>&1; then ok "xcodegen $("$XCODEGEN" --version 2>/dev/null | sed 's/Version: //')"; else fix "no xcodegen: install xcodegen 2.44.1, or set XCODEGEN"; fi
if docker info >/dev/null 2>&1; then ok "Docker answers"; else fix "Docker does not answer: start Colima or Docker Desktop"; fi
if docker compose version >/dev/null 2>&1; then ok "docker compose"; else fix "no docker compose plugin"; fi
if command -v ffmpeg >/dev/null 2>&1; then
	if ffmpeg -hide_banner -filters 2>/dev/null | grep -q drawtext; then ok "ffmpeg with drawtext"; else ok "ffmpeg without drawtext (seed videos use shapes only)"; fi
else
	fix "no ffmpeg: needed by make seed-media"
fi
if xcrun simctl list runtimes 2>/dev/null | grep -q 'iOS 26\.0'; then ok "iOS 26.0 simulator runtime"; else fix "no iOS 26.0 simulator runtime: add it in Xcode, Settings, Components"; fi
info "Docker context: $(docker context show 2>/dev/null || echo unknown)"
info "macOS firewall: $(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | sed 's/^Firewall is //' || echo unknown)"
exit $bad
