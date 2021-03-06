# Copyright 2014 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@io_bazel_rules_go//go/private:go_repository.bzl",
    "go_repository",
)
load("@io_bazel_rules_go//go/private:providers.bzl",
    _GoLibrary = "GoLibrary",
    _GoBinary = "GoBinary",
    _GoEmbed = "GoEmbed",
)
load("@io_bazel_rules_go//go/private:repositories.bzl",
    "go_rules_dependencies",
    "go_register_toolchains",
)
load("@io_bazel_rules_go//go/private:toolchain.bzl",
    go_sdk = "go_sdk",
)
load("@io_bazel_rules_go//go/private:go_toolchain.bzl",
    go_toolchain = "go_toolchain",
)
load("@io_bazel_rules_go//go/private:rules/prefix.bzl", 
    "go_prefix",
)
load("@io_bazel_rules_go//go/private:rules/wrappers.bzl",
    _go_library_macro = "go_library_macro",
    _go_binary_macro = "go_binary_macro",
    _go_test_macro = "go_test_macro",
)
load("@io_bazel_rules_go//go/private:tools/embed_data.bzl", 
    "go_embed_data",
)
load("@io_bazel_rules_go//go/private:tools/gazelle.bzl", 
    "gazelle",
)
load("@io_bazel_rules_go//go/private:tools/path.bzl", 
    _go_path = "go_path",
)
load("@io_bazel_rules_go//go/private:tools/vet.bzl", 
    _go_vet_test = "go_vet_test",
)

GoLibrary = _GoLibrary
"""
This is the provider used to expose a go library to other rules.
It provides the following fields:
  TODO: List all the provider fields here
"""

GoBinary = _GoBinary
"""
This is the provider used to expose a go binary to other rules.
It provides the following fields:
  TODO: List all the provider fields here
"""

GoEmbed = _GoEmbed
"""
This is the provider used to provide paired source and deps to a go library.
This should generally be the provider returned by code generators.
It provides the following fields:
  TODO: List all the provider fields here
"""

go_library = _go_library_macro
"""
    go_library is a macro for building go libraries.
    It returns the GoLibrary providers,
    and accepts the following attributes:
        "importpath": attr.string(),
        # inputs
        "srcs": attr.label_list(),
        "deps": attr.label_list(),
        "data": attr.label_list(allow_files = True, cfg = "data"),
        # compile options
        "gc_goopts": attr.string_list(), # Options for the go compiler if using gc
        "gccgo_goopts": attr.string_list(), # Options for the go compiler if using gcc
        # cgo options
        "cgo": attr.bool(),
        "cdeps": attr.label_list(), # TODO: Would be nicer to be able to filter deps instead
        "copts": attr.string_list(), # Options for the the c compiler
        "clinkopts": attr.string_list(), # Options for the linker
"""

go_binary = _go_binary_macro
"""
    go_library is a macro for building go executables.
    It returns the GoLibrary and GoBinary providers,
    and accepts the following attributes:
        "importpath": attr.string(),
        # inputs
        "srcs": attr.label_list(),
        "deps": attr.label_list(),
        "data": attr.label_list(allow_files = True, cfg = "data"),
        # compile options
        "gc_goopts": attr.string_list(), # Options for the go compiler if using gc
        "gccgo_goopts": attr.string_list(), # Options for the go compiler if using gcc
        # link options
        "gc_linkopts": attr.string_list(), # Options for the go linker if using gc
        "gccgo_linkopts": attr.string_list(), # Options for the go linker if using gcc
        "stamp": attr.int(),
        "linkstamp": attr.string(),
        "x_defs": attr.string_dict(),
        # cgo options
        "cgo": attr.bool(),
        "cdeps": attr.label_list(), # TODO: Would be nicer to be able to filter deps instead
        "copts": attr.string_list(), # Options for the the c compiler
        "clinkopts": attr.string_list(), # Options for the linker
"""

go_test = _go_test_macro
"""
    go_test is a macro for building go executable tests.
    It returns the GoLibrary and GoBinary providers,
    and accepts the following attributes:
        "importpath": attr.string(),
        "defines_main": attr.bool(),
        # inputs
        "srcs": attr.label_list(),
        "deps": attr.label_list(),
        "data": attr.label_list(allow_files = True, cfg = "data"),
        "library": attr.label(),
        # compile options
        "gc_goopts": attr.string_list(), # Options for the go compiler if using gc
        "gccgo_goopts": attr.string_list(), # Options for the go compiler if using gcc
        # link options
        "gc_linkopts": attr.string_list(), # Options for the go linker if using gc
        "gccgo_linkopts": attr.string_list(), # Options for the go linker if using gcc
        "stamp": attr.int(),
        "linkstamp": attr.string(),
        "x_defs": attr.string_dict(),
        # cgo options
        "cgo": attr.bool(),
        "cdeps": attr.label_list(), # TODO: Would be nicer to be able to filter deps instead
        "copts": attr.string_list(), # Options for the the c compiler
        "clinkopts": attr.string_list(), # Options for the linker
"""

go_path = _go_path
"""
    go_path is a rule for creating `go build` compatible file layouts from a set of Bazel.
    targets.
        "deps": attr.label_list(providers=[GoLibrary]), # The set of go libraries to include the export
        "mode": attr.string(default="link", values=["link", "copy"]) # Whether to copy files or produce soft links
"""

go_vet_test = _go_vet_test
"""
    go_vet_test 
"""


# Compatability shims
def cgo_genrule(name, tags=[], **kwargs):
  print("DEPRECATED: {0} : cgo_genrule is deprecated. Please migrate to go_library with cgo=True.".format(name))
  return go_library(name=name, tags=tags+["manual"], cgo=True, **kwargs)

def cgo_library(name, **kwargs):
  print("DEPRECATED: {0} : cgo_library is deprecated. Please migrate to go_library with cgo=True.".format(name))
  return go_library(name=name, cgo=True, **kwargs)

def new_go_repository(name, **kwargs):
  print("DEPRECATED: {0} : new_go_repository is deprecated. Please migrate to go_repository soon.".format(name))
  return go_repository(name=name, **kwargs)

def go_repositories(
    go_version = None,
    go_linux = None,
    go_darwin = None):

  print("DEPRECATED: go_repositories has been deprecated. go_rules_dependencies installs dependencies the way nested workspaces should, and go_register_toolchains adds the toolchains")
  go_rules_dependencies()
  if go_version != None:
    go_register_toolchains(go_version=go_version)
  else:
    go_register_toolchains()

