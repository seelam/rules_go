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

def emit_cover(ctx, go_toolchain,
               sources = []):
  """Construct the command line for test coverage instrument.

  Args:
    ctx: The skylark Context.
    out_object: the object file for the library being compiled. Used to name
      cover files.
    sources: an iterable of Go source files.

  Returns:
    A list of Go source code files which might be coverage instrumented.
  """
  outputs = []
  # TODO(linuxerwang): make the mode configurable.
  cover_vars = []

  for src in sources:
    if (not src.basename.endswith(".go") or
        src.basename.endswith("_test.go") or
        src.basename.endswith(".cover.go")):
      outputs += [src]
      continue

    cover_var = "Cover_" + src.basename[:-3].replace("-", "_").replace(".", "_")
    cover_vars += ["{}={}".format(cover_var,src.short_path)]
    out = ctx.new_file(cover_var + '.cover.go')
    outputs += [out]
    ctx.action(
        inputs = [src] + go_toolchain.data.tools,
        outputs = [out],
        mnemonic = "GoCover",
        executable = go_toolchain.tools.go,
        arguments = ["tool", "cover", "--mode=set", "-var=%s" % cover_var, "-o", out.path, src.path],
        env = go_toolchain.env,
    )

  return outputs, tuple(cover_vars)
