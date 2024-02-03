//
// Copyright (c) 2023, Andy Frank
// Licensed under the MIT License
//
// History:
//   23 Apr 2023  Andy Frank  Creation
//

using build
using tinypng

**
** Copy and compress source images.
**
internal class CompressImg : Task
{
  ** Constructor.
  new make(BuildHelixPod script) : super(script)
  {
  }

  ** Convenience to get `script` as `BuildHelixPod`.
  BuildHelixPod helix() { this.script }

  ** Run compile fanbars task.
  override Void run()
  {
    try
    {
      log.info("Images [$helix.podName]")
      log.indent

      // check for compression key
      TinyPng? tiny
      // key := helix.tinyPngKey
      // if (key == null) log.info("** WARN: no key found; no compression performed **")
      // else tiny = TinyPng(key)

      imgDirs := helix.imgDirs.map |u| { helix.scriptDir + u }
      tempDir := helix.scriptDir + `temp-fbs/`
      outImg  := tempDir + `img/`
      jdk     := JdkTask(helix)
      jarExe  := jdk.jarExe
      podFile := helix.outPodDir.toFile + `${helix.podName}.pod`

      // find source templates
      files := Str:File[:]
      imgDirs.each |d| { findFiles(d, files) }
      log.info("FindSourceFiles [$files.size files]")

      // init fresh temp dir
      tempDir.delete
      tempDir.create

      // compile each template
      failed := false
      files.each |f|
      {
        try
        {
          outfile := outImg + `${f.name}`
          if (tiny != null && extMap[f.ext] == true)
          {
            // TODO: we need to check if !modified so we don't rerun
            // does this require a staging dir to be kept around?
            // compress
            tiny.compress(f, outfile)
          }
          else
          {
            // copy
            f.copyTo(outfile)
          }
        }
        catch (Err err)
        {
          failed = true
          echo("${f.osPath}: ${err.msg}")
        }
      }

      // bail if compiler error found
      if (failed) throw FatalBuildErr()

      // append files to the pod zip (we use java's jar tool)
      // bump log level to hide Exec task log spam
      log.info("AppendPod [$podFile]")
      old := helix.log.level
      helix.log.level = LogLevel.err
      Exec(helix, [jarExe, "-fu", podFile.osPath, "-C", tempDir.osPath, "."], tempDir).run
      helix.log.level = old

      // cleanup
      tempDir.delete
      log.unindent
    }
    catch (Err err)
    {
      throw err as FatalBuildErr ?: fatal(err.msg)
    }
  }

  ** Recursivly find all source files.
  private Void findFiles(File file, Str:File map)
  {
    if (file.isDir) file.listFiles.each |f| { findFiles(f, map) }
    else if (extMap.containsKey(file.ext))
    {
      key := file.name
      if (map[key] == null) map.add(key, file)
      else throw fatal("Duplicate filename '${file.name}'")
    }
  }

  ** Map of supported file formats and File formats to allow and copy unmodified.
  private static const Str:Bool extMap := [:] {
    // unmodified
    it.add("gif", false)
    it.add("svg", false)
    // compress
    it.add("png",  true)
    it.add("jpg",  true)
    it.add("jpeg", true)
    it.add("webp", true)
  }
}
