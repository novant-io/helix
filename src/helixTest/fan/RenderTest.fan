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

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////////
// Text
//////////////////////////////////////////////////////////////////////////

  Void testRenderText()
  {
    h := ["Content-Type":"text/plain; charset=UTF-8"]
    verifyGet(`/text/a`, h, "plain-text-a")
    verifyGet(`/text/b`, h, "plain-text-b")
  }

//////////////////////////////////////////////////////////////////////////
// JSON
//////////////////////////////////////////////////////////////////////////

  Void testRenderJson()
  {
    h := ["Content-Type":"application/json; charset=UTF-8"]
    verifyGet(`/json/str`,  h, "\"json-str\"\n")
    verifyGet(`/json/num`,  h, "45\n")
    verifyGet(`/json/bool`, h, "true\n")
  }

//////////////////////////////////////////////////////////////////////////
// Templates
//////////////////////////////////////////////////////////////////////////

  Void testRenderTemplate()
  {
    h := ["Content-Type":"text/html; charset=UTF-8"]
    verifyGet(`/`, h, "Test Index")
  }
}