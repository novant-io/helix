//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   20 Jun 2022  Andy Frank  Creation
//

using concurrent
using helix
using web

*************************************************************************
** TestMod
*************************************************************************

const class TestMod : HelixMod
{
  new make()
  {
    this.router = Router {
      it.routes = [
        // text
        Route("/text/a", "GET", TestController#textA),
        Route("/text/b", "GET", TestController#textB),

        // json
        Route("/json/str",  "GET", TestController#jsonStr),
        Route("/json/num",  "GET", TestController#jsonNum),
        Route("/json/bool", "GET", TestController#jsonBool),

        // inline
        Route("/inline/a", "GET", TestController#inlineA),
        Route("/inline/b", "GET", TestController#inlineB),

        // args
        Route("/args/empty",             "GET",  TestController#argTest),
        Route("/args/route/{foo}",       "GET",  TestController#argTest),
        Route("/args/route/{foo}/{bar}", "GET",  TestController#argTest),
        Route("/args/form",              "POST", TestController#argTest),
        Route("/args/form/{foo}",        "POST", TestController#argTest),
        Route("/args/form/{foo}/{bar}",  "POST", TestController#argTest),

        // templates
        Route("/",        "GET", TestController#index),
        Route("/simple",  "GET", TestController#simple),
        Route("/partial", "GET", TestController#partial),

        // files
        Route("/file/a.foo", "GET", TestController#fileA),
        Route("/file/b.bar", "GET", TestController#fileB),
        Route("/file/c.csv", "GET", TestController#fileC),

        // resources
        ResRoute("/css/{file}",        [`fan://helixTest/css/`]),
        ResRoute("/foo/bar/alpha.css", [`fan://helixTest/css/alpha.css`]),
      ]
    }
  }
}

*************************************************************************
** TestController
*************************************************************************

class TestController : HelixController
{
  // text
  Void textA() { renderer.renderText("plain-text-a") }
  Void textB() { renderer.renderText("plain-text-b") }

  // json
  Void jsonStr()  { renderer.renderJson("json-str") }
  Void jsonNum()  { renderer.renderJson(45) }
  Void jsonBool() { renderer.renderJson(true) }

  // file
  Void fileA() {
    renderer.renderFile("text/foo") |out| {
      out.printLine("This is a file")
    }
  }
  Void fileB() {
    renderer.renderFile("text/bar") |out| {
      out.printLine("This is another file")
    }
  }
  Void fileC() {
    renderer.renderFileDownload("text/csv", "some.csv") |out| {
      out.printLine("foo,bar,zar")
    }
  }

  // inline
  Void inlineA() { renderer.renderInline("inline-literal", [:]) }
  Void inlineB() { renderer.renderInline("inline-simple [{{foo}}]", ["foo":"abc-543"]) }

  // args
  static const AtomicRef argsRef := AtomicRef(null)
  Void argTest()
  {
    TestController.argsRef.val = this.args->map
    renderer.renderText("ok")
  }

  // templates
  Void index()   { renderer.renderTemplate("test_index", [:]) }
  Void simple()  { renderer.renderTemplate("test_simple", ["foo":"xyz-123"]) }
  Void partial() { renderer.renderTemplate("test_partial", [:]) }
}