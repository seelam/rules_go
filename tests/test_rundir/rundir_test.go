package test_rundir

import (
	"os"
	"testing"
)

func TestRunDir(t *testing.T) {
	if _, err := os.Stat("README.md"); err != nil {
		t.Error(err)
	}
}
