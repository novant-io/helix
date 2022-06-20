//
// Copyright (c) 2022, Novant LLC
// All Rights Reserved
//
// History:
//   18 Jun 2022  Andy Frank  Creation
//

using build

**
** TODO
**
abstract class BuildHelixPod : BuildPod
{
  ** List of Uris relative to build script of directories containing
  ** the Fanbar source templates to compile.
  Uri[]? fbsDirs

  ** Compile the source into a pod file and all associated natives.
  ** See `compileFan`, `compileJava`, and `compileFbs`.
  @Target { help = "Compile to pod file and associated natives" }
  override Void compile()
  {
    // NOTE: keep this in sync with BuildPod.compile

    this->validate

    log.info("compile [$podName]")
    log.indent

    compileFan
    compileJava
    compileJni
    // compileDotnet
    compileFbs
    log.unindent
  }

  ** Compile Fanbar templates if `fbsDirs` is configured.
  @Target { help = "Compile fanbars templates" }
  virtual Void compileFbs()
  {
    // short-circuit if source dirs
    fbsDirs = this.fbsDirs ?: Uri#.emptyList
    if (fbsDirs.isEmpty) return

    // compile
    CompileFbs(this).run
  }
}