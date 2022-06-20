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
  Void index() { renderer.render("test-index", [:]) }
}