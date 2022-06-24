#! /usr/bin/env fan

using build
using helix

class Build : BuildHelixPod
{
  new make()
  {
    podName = "helixTest"
    summary = "Helix framework unit testing"
    version = Version("0.1")
    meta = [
      "org.name":     "Novant",
      "org.uri":      "https://novant.io/",
      "license.name": "MIT",
      "vcs.name":     "Git",
      "vcs.uri":      "https://github.com/novant-io/helix",
      "repo.public":  "true",
      "repo.tags":    "web",
    ]
    depends  = ["sys 1.0", "concurrent 1.0", "web 1.0", "webmod 1.0", "wisp 1.0", "helix 0+"]
    srcDirs  = [`fan/`]
    fassDirs = [`fass/`]
    fbsDirs  = [`fbs/`, `fbs/sub/`]
    resDirs  = [`res/fbs/`]
  }
}
