//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   21 Jun 2022  Andy Frank  Creation
//

using build
using fass

**
** Compile fass style sheets.
**
internal class CompileFass : Task
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
      log.info("StyleSheets [$helix.podName]")
      log.indent

      fassDirs := helix.fassDirs.map |u| { helix.scriptDir + u }
      tempDir  := helix.scriptDir + `temp-fass/`
      outFass  := tempDir + `css/`
      jdk      := JdkTask(helix)
      jarExe   := jdk.jarExe
      podFile  := helix.outPodDir.toFile + `${helix.podName}.pod`

      // find source templates
      files := Str:File[:]
      fassDirs.each |d| { findFiles(d, files) }
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
          css := outFass + `${f.basename}.css`
          out := css.out
          Fass.compile(f.in, out) |use|
          {
            u := files[use] ?: throw Err("File not found '${use}'")
            return u.in
          }
          out.sync.close
        }
        catch (Err err)
        {
          // move line position next to file
          failed = true
          off := err.msg.index("[line:")
          msg := off==null ? err.msg : err.msg[0..<off]
          pos := off==null ? "?"     : err.msg[off+6..-2]
          echo("${f.osPath}(${pos}): ${msg}")
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
    if (file.isDir) file.list.each |f| { findFiles(f, map) }
    else if (file.ext == "fass")
    {
      key := file.name
      if (map[key] == null) map.add(key, file)
      else throw fatal("Duplicate filename '${file.name}'")
    }
  }
}
