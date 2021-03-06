/* Copyright 2016 The Bazel Authors. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package rules_test

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	bf "github.com/bazelbuild/buildtools/build"
	"github.com/bazelbuild/rules_go/go/tools/gazelle/config"
	"github.com/bazelbuild/rules_go/go/tools/gazelle/merger"
	"github.com/bazelbuild/rules_go/go/tools/gazelle/packages"
	"github.com/bazelbuild/rules_go/go/tools/gazelle/resolve"
	"github.com/bazelbuild/rules_go/go/tools/gazelle/rules"
	"github.com/bazelbuild/rules_go/go/tools/gazelle/testdata"
)

func testConfig(repoRoot, goPrefix string) *config.Config {
	c := &config.Config{
		RepoRoot:            repoRoot,
		GoPrefix:            goPrefix,
		GenericTags:         config.BuildTags{},
		Platforms:           config.DefaultPlatformTags,
		ValidBuildFileNames: []string{"BUILD.old"},
	}
	c.PreprocessTags()
	return c
}

func packageFromDir(c *config.Config, dir string) (*packages.Package, *bf.File) {
	var pkg *packages.Package
	var oldFile *bf.File
	packages.Walk(c, dir, func(_ *config.Config, p *packages.Package, f *bf.File) {
		if p.Dir == dir {
			pkg = p
			oldFile = f
		}
	})
	return pkg, oldFile
}

func TestGenerator(t *testing.T) {
	repoRoot := filepath.Join(testdata.Dir(), "repo")
	goPrefix := "example.com/repo"
	c := testConfig(repoRoot, goPrefix)
	l := resolve.NewLabeler(c)
	r := resolve.NewResolver(c, l)

	var dirs []string
	err := filepath.Walk(repoRoot, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if filepath.Base(path) == "BUILD.want" {
			dirs = append(dirs, filepath.Dir(path))
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}

	for _, dir := range dirs {
		rel, err := filepath.Rel(repoRoot, dir)
		if err != nil {
			t.Fatal(err)
		}

		pkg, oldFile := packageFromDir(c, dir)
		g := rules.NewGenerator(c, r, l, rel, oldFile)
		rs, _ := g.GenerateRules(pkg)
		f := &bf.File{Stmt: rs}
		rules.SortLabels(f)
		f = merger.FixLoads(f)
		got := string(bf.Format(f))

		wantPath := filepath.Join(pkg.Dir, "BUILD.want")
		wantBytes, err := ioutil.ReadFile(wantPath)
		if err != nil {
			t.Errorf("error reading %s: %v", wantPath, err)
			continue
		}
		want := string(wantBytes)

		if got != want {
			t.Errorf("g.Generate(%q, %#v) = %s; want %s", rel, pkg, got, want)
		}
	}
}

func TestGeneratorEmpty(t *testing.T) {
	c := testConfig("", "example.com/repo")
	l := resolve.NewLabeler(c)
	r := resolve.NewResolver(c, l)
	g := rules.NewGenerator(c, r, l, "", nil)

	for _, tc := range []struct {
		name string
		pkg  packages.Package
		want string
	}{
		{
			name: "nothing",
			want: `go_library(name = "go_default_library")

go_binary(name = "repo")

filegroup(name = "go_default_library_protos")

go_test(name = "go_default_test")

go_test(name = "go_default_xtest")
`,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			_, empty := g.GenerateRules(&tc.pkg)
			emptyStmt := make([]bf.Expr, len(empty))
			for i, s := range empty {
				emptyStmt[i] = s
			}
			got := string(bf.Format(&bf.File{Stmt: emptyStmt}))
			if got != tc.want {
				t.Errorf("got '%s' ;\nwant %s", got, tc.want)
			}
		})
	}
}
