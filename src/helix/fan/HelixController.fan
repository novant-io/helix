//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   9 Jun 2022  Andy Frank  Creation
//

using concurrent
using web

**
** HelixController services web requests.
**
abstract class HelixController
{
  ** Constructor.
  new make()
  {
    this.req = Actor.locals["web.req"]
    this.res = Actor.locals["web.res"]
    this.renderer = makeRenderer
  }

  ** Parent `HelixMod` instance for the current web requests.
  HelixMod mod() { req.mod }

  ** WebReq instance for the current web request.
  WebReq req { private set }

  ** WebRes instance for the current web request.
  WebRes res { private set }

  ** Base data common to all controller endpoints.
  Str:Obj? baseData := [:]

  ** Send a temporary redirect response.
  virtual Void sendTempRedirect(Uri uri)
  {
    // 303 is default; but specify here for clarity
    res.redirect(uri, 303)
  }

  ** Send error response.
  virtual Void sendErr(Int code)
  {
    // TODO: wire through render and err templates
    // TODO: HTML vs JSON?
    res.sendErr(code)
  }

  ** Renderer instance for the current web request.
  HelixRenderer renderer { private set }

  ** Subclass hook to customize renderer for request.
  protected virtual HelixRenderer makeRenderer()
  {
    HelixRenderer(this)
  }
}