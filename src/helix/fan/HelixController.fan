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
    this.req  = Actor.locals["web.req"]
    this.res  = Actor.locals["web.res"]
    this.args = Actor.locals["helix.args"]
    this.renderer = makeRenderer
  }

  ** Parent `HelixMod` instance for the current web request.
  HelixMod mod() { req.mod }

  ** WebReq instance for the current web request.
  WebReq req { private set }

  ** WebRes instance for the current web request.
  WebRes res { private set }

  ** Base data common to all controller endpoints.
  Str:Obj? baseData := [:]

  ** Arguments for the currrent web request.
  HelixArgs args { internal set }

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

  ** Send a raw file response.
  virtual Void sendFile(File file)
  {
    extraResHeaders := null

    // special handling for video files
    if (file.ext == "mp4")
    {
      extraResHeaders = [
        "Content-Type":  "video/mp4",  // TODO: was not added until 1.0.83+
        "Accept-Ranges": "bytes",
      ]
    }

    // delegate to fileweblet
    w := FileWeblet(file)
    w.extraResHeaders = extraResHeaders
    w.onGet
  }

  ** Renderer instance for the current web request.
  HelixRenderer renderer { private set }

  ** Subclass hook to customize renderer for request.
  protected virtual HelixRenderer makeRenderer()
  {
    HelixRenderer(this)
  }
}