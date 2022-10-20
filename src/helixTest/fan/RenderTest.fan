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
    verifyNotNull(mod.template("helixTest::test_index"))

    // invalid qname
    verifyErr(ArgErr#) { x := mod.template("test_index") }
    verifyErr(ArgErr#) { x := mod.template("helixTest:test_index") }
    verifyErr(ArgErr#) { x := mod.template("helixTest::test_index.fbs") }

    // file not found
    verifyNull(mod.template("helixTest::not_found", false))
    verifyErr(ArgErr#) { x := mod.template("helixTest::not_found") }
  }

//////////////////////////////////////////////////////////////////////////
// Text
//////////////////////////////////////////////////////////////////////////

  Void testRenderText()
  {
    h := ["Content-Type":"text/plain; charset=utf-8"]
    verifyGet(`/text/a`, h, "plain-text-a")
    verifyGet(`/text/b`, h, "plain-text-b")
  }

//////////////////////////////////////////////////////////////////////////
// JSON
//////////////////////////////////////////////////////////////////////////

  Void testRenderJson()
  {
    h := ["Content-Type":"application/json; charset=utf-8"]
    verifyGet(`/json/str`,  h, "\"json-str\"\n")
    verifyGet(`/json/num`,  h, "45\n")
    verifyGet(`/json/bool`, h, "true\n")
  }

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

  Void testRenderFile()
  {
    // file
    ha := ["Content-Type":"text/foo"]
    hb := ["Content-Type":"text/bar"]
    verifyGet(`/file/a.foo`, ha, "This is a file\n")
    verifyGet(`/file/b.bar`, hb, "This is another file\n")

    // download
    hc := ["Content-Type":"text/csv", "Content-Disposition":"attachment; filename=\"some.csv\""]
    verifyGet(`/file/c.csv`, hc, "foo,bar,zar\n")
  }

//////////////////////////////////////////////////////////////////////////
// Templates
//////////////////////////////////////////////////////////////////////////

  Void testRenderInline()
  {
    h := ["Content-Type":"text/html; charset=utf-8"]
    verifyGet(`/inline/a`, h, "inline-literal")
    verifyGet(`/inline/b`, h, "inline-simple [abc-543]")
  }

  Void testRenderTemplate()
  {
    h := ["Content-Type":"text/html; charset=utf-8"]
    verifyGet(`/`,       h, "Test Index")
    verifyGet(`/simple`, h, "Simple Test [xyz-123]")
  }

  Void testRenderTemplatePartials()
  {
    h := ["Content-Type":"text/html; charset=utf-8"]
    verifyGet(`/partial`, h, "Partial Test: this is a partial!")
  }
}