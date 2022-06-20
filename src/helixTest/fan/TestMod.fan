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
        // TODO

        // html
        Route("/", "GET", TestController#index),
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
  // TODO

  // templates
  Void index() { renderer.renderTemplate("test-index", [:]) }
}