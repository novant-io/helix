//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   18 Jun 2022  Andy Frank  Creation
//

using build

**
** BuildHelixPod adds additional configuration to 'BuildPod' for
** compiling Helix web framework resources.
**
abstract class BuildHelixPod : BuildPod
{
  ** List of Uris relative to build script of directories containing
  ** the fass style styles to compile to CSS.
  Uri[]? fassDirs

  ** List of Uris relative to build script of directories containing
  ** the Fanbar source templates to compile.
  Uri[]? fbsDirs

  ** List of Uris relative to build script of directories containing
  ** the source images to copy and/or compress.
  Uri[]? imgDirs

  // ** TinyPng API key used to compress images.
  // Str? tinyPngKey

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
    compileFass
    compileFbs
    compressImg
    log.unindent
  }

  ** Compile fass style sheets if `fassDirs` is configured.
  @Target { help = "Compile fass style sheets" }
  virtual Void compileFass()
  {
    // short-circuit if source dirs
    fassDirs = this.fassDirs ?: Uri#.emptyList
    if (fassDirs.size > 0) CompileFass(this).run
  }

  ** Compile Fanbar templates if `fbsDirs` is configured.
  @Target { help = "Compile fanbars templates" }
  virtual Void compileFbs()
  {
    // short-circuit if source dirs
    fbsDirs = this.fbsDirs ?: Uri#.emptyList
    if (fbsDirs.size > 0) CompileFbs(this).run
  }

  ** Compile Fanbar templates if `fbsDirs` is configured.
  @Target { help = "Compress image resources" }
  virtual Void compressImg()
  {
    // short-circuit if source dirs
    imgDirs = this.imgDirs ?: Uri#.emptyList
    if (imgDirs.size > 0) CompressImg(this).run
  }
}