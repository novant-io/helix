//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   18 Jun 2022  Andy Frank  Creation
//

using helix
using web

**
** Test code for HelixRenderer.
**
class RenderTest : HelixTest
{
  Void testLookup()
  {
    // valid
    verifyNotNull(mod.template("helixTest::test-index"))

    // invalid qname
    verifyErr(ArgErr#) { x := mod.template("test-index") }
    verifyErr(ArgErr#) { x := mod.template("helixTest:test-index") }
    verifyErr(ArgErr#) { x := mod.template("helixTest::test-index.fbs") }

    // file not found
    verifyNull(mod.template("helixTest::not-found", false))
    verifyErr(ArgErr#) { x := mod.template("helixTest::not-found") }
  }

  Void testRenderTemplate()
  {
    // basic test
    verifyGet(`/`, "Test Index")
  }
}