#! /usr/bin/env fan

using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "helix"
    summary = "Helix Web Framework"
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
    depends = [
      "sys 1.0",
      "util 1.0",
      "concurrent 1.0",
      "build 1.0",
      "web 1.0",
      "webmod 1.0",
      "fass 0.1",
      "fanbars 0.11",
    ]
    srcDirs = [`fan/`, `fan/build/`]
    docApi  = true
    docSrc  = true
  }
}
