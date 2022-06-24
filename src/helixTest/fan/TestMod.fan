//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   20 Jun 2022  Andy Frank  Creation
//

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

        // templates
        Route("/",        "GET", TestController#index),
        Route("/simple",  "GET", TestController#simple),
        Route("/partial", "GET", TestController#partial),

        // resources
        ResRoute("/css/{file}",        [TestMod#.pod.file(`/css/`)]),
        ResRoute("/foo/bar/alpha.css", [TestMod#.pod.file(`/css/alpha.css`)]),
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

  // inline
  Void inlineA() { renderer.renderInline("inline-literal", [:]) }
  Void inlineB() { renderer.renderInline("inline-simple [{{foo}}]", ["foo":"abc-543"]) }

  // templates
  Void index()   { renderer.renderTemplate("test_index", [:]) }
  Void simple()  { renderer.renderTemplate("test_simple", ["foo":"xyz-123"]) }
  Void partial() { renderer.renderTemplate("test_partial", [:]) }
}