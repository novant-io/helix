#! /usr/bin/env fan

using build

class Build : BuildGroup
{
  new make()
  {
    childrenScripts =
    [
      `helix/build.fan`,
      `helixTest/build.fan`,
    ]
  }
}
