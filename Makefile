# Windmill v2. On a new Mac, run `make doctor` first.
#
# windmill-backend/.env (plain KEY=value lines) loads as defaults: a value in
# the environment or on the make command line wins. Works with GNU Make 3.81.

ENV_FILE := windmill-backend/.env
ENV_MK := .run/env.mk

# ponytail: .env is rewritten as `KEY ?= value` lines at parse time. No rule
# names .env or env.mk, so make never remakes either one.
_ := $(shell mkdir -p .run; if [ -f $(ENV_FILE) ]; then sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=\(.*\)$$/\1 ?= \2/p' $(ENV_FILE); fi > $(ENV_MK))
-include $(ENV_MK)
ENV_KEYS := $(shell if [ -f $(ENV_FILE) ]; then sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' $(ENV_FILE); fi)
ifneq ($(strip $(ENV_KEYS)),)
export $(ENV_KEYS)
endif

GO ?= go
XCODEGEN ?= xcodegen
SIM ?= iPhone 17 Pro

WINDMILL_BLOB_DIR ?= windmill-backend/.data/blobs
override WINDMILL_BLOB_DIR := $(abspath $(WINDMILL_BLOB_DIR))
export WINDMILL_BLOB_DIR

.PHONY: test ios doctor

print-%:
	@echo '$($*)'

test:
	@sh scripts/check-make.sh
	cd windmill-backend && $(GO) vet ./... && $(GO) test -race -count=1 ./...

ios:
	cd windmill-ios && $(XCODEGEN) generate && open Windmill.xcodeproj

doctor:
	@GO="$(GO)" XCODEGEN="$(XCODEGEN)" sh scripts/doctor.sh
