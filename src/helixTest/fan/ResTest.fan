//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   23 Jun 2022  Andy Frank  Creation
//

using helix
using web

**
** Test code for ResRoute.
**
class ResTest : HelixTest
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    // NOTE: test different content types to cover tests of HelixMod.resSize

    h := ["Content-Type":"text/plain; charset=utf-8"]
    c := "plain-text-a"
    verifyGet(`/text/a`, h, c)

    h = ["Content-Type":"text/css; charset=utf-8"]
    verifyGet(`/css/alpha.css`, h, "body {\n  color: #f00;\n}\n")
    verifyGet(`/css/beta.css`,  h, "h1 {\n  font-size: 32pt;\n}\n")
    verify404(`/css/nope.css`)

    verifyGet(`/foo/bar/alpha.css`,  h, "body {\n  color: #f00;\n}\n")
    verify404(`/foo/bar/beta.css`)
  }
}