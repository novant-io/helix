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

        // html
        Route("/",       "GET", TestController#index),
        Route("/simple", "GET", TestController#simple),
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

  // templates
  Void index()  { renderer.renderTemplate("test-index", [:]) }
  Void simple() { renderer.renderTemplate("test-simple", ["foo":"xyz-123"]) }
}