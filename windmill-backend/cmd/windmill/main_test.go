package main

import (
	"bytes"
	"testing"
)

func TestRunVersion(t *testing.T) {
	var out, errOut bytes.Buffer
	code := run([]string{"-version"}, &out, &errOut, func(string) string { return "" })
	if code != 0 {
		t.Fatalf("exit code %d, stderr %q", code, errOut.String())
	}
	if got, want := out.String(), "windmill 0.1.0-dev\n"; got != want {
		t.Fatalf("stdout %q, want %q", got, want)
	}
}
