//
// Copyright (c) 2024, Andy Frank
// Licensed under the MIT License
//
// History:
//   24 May 2024  Andy Frank  Creation
//

using helix
using web

**
** Test code for /robots.txt handling.
**
class RobotsTest : HelixTest
{
  Void test()
  {
    // default is to return 404
    verify404(`/robots.txt`)

    // backdoor set blockRobots
    HelixMod#blockRobots->setConst(mod, true)
    verifyGet(`/robots.txt`, [:],
      "User-agent: *
       Disallow: /")

    // backdoor reset
    HelixMod#blockRobots->setConst(mod, false)
    verify404(`/robots.txt`)
  }
}