//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   18 Jun 2022  Andy Frank  Creation
//

using build

**
** Compile fanbar templates files.
**
internal class CompileFbs : Task
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
      // short-circuit if no template dirs
      if ((helix.fbsDirs ?: Uri#.emptyList).isEmpty) return

      log.info("Templates [$helix.podName]")
      log.indent

      fbsDirs := helix.fbsDirs.map |u| { helix.scriptDir + u }
      tempDir := helix.scriptDir + `temp-fbs/`
      outFbs  := tempDir + `fbs/`
      jdk     := JdkTask(helix)
      jarExe  := jdk.jarExe
      podFile := helix.outPodDir.toFile + `${helix.podName}.pod`

      // find source templates
      files := Str:File[:]
      fbsDirs.each |d| { findFiles(d, files) }
      log.info("FindSourceTemplates [$files.size files]")

      // init fresh temp dir
      tempDir.delete
      tempDir.create

      // compile each template
      files.each |f|
      {
        // TODO FIXIT: verify template
        // TODO FIXIT: merge partials
        f.copyTo(outFbs + `${f.name}`)
      }

      // append files to the pod zip (we use java's jar tool)
      // bump log level to hide Exec task log spam
      log.info("AppendPod [$podFile]")
      helix.log.level = LogLevel.err
      Exec(helix, [jarExe, "-fu", podFile.osPath, "-C", tempDir.osPath, "."], tempDir).run

      // cleanup
      tempDir.delete
      log.unindent
    }
    catch (Err err)
    {
      throw fatal(err.msg)
    }
  }

  ** Recursivly find all source files.
  private Void findFiles(File file, Str:File map)
  {
    if (file.isDir) file.list.each |f| { findFiles(f, map) }
    else if (file.ext == "fbs")
    {
      key := file.name
      if (map[key] == null) map.add(key, file)
      else throw fatal("Duplicate filename '${file.name}'")
    }
  }
}
