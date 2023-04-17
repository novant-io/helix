//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   9 Jun 2022  Andy Frank  Creation
//

using concurrent
using fanbars
using web
using webmod

**
** HelixMod is the base class for Helix framework WebMods.
**
abstract const class HelixMod : WebMod
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Constructor.
  new make()
  {
    this.router = Router { routes=Route#.emptyList }
    this.log = HelixLog()
  }

  ** Router model.
  const Router router

//////////////////////////////////////////////////////////////////////////
// Service
//////////////////////////////////////////////////////////////////////////

  ** Invoked prior to servicing the current request.
  virtual Void onBeforeService(Route route, HelixArgs args) {}

  ** Invoked after servicing the current request.
  virtual Void onAfterService(Route route, HelixArgs args) {}

  ** Service incoming request.
  override Void onService()
  {
    try
    {
      // set mod
      st := Duration.now
      req.mod = this

      // match req to Route
      match := router.match(req.modRel, req.method)
      if (match == null) throw HelixErr(404)
      req.stash["helix.route"] = match.route

      // create and cache args
      args := HelixArgs(req, match.args)
      Actor.locals["helix.args"] = args

      // allow pre-service
      onBeforeService(match.route, args)
      match.route.onBeforeService(args)
      if (res.isDone) return

      // delegate to Route.handler/HelixController
      h := match.route.handler
      c := h.parent.make
      c.trap(h.name)

      // allow post-service
      onAfterService(match.route, args)

      // cleanup
      args.cleanup
      et := Duration.now
      trace(req, res, et-st)
    }
    catch (Err origErr)
    {
      // TODO FIXIT
      log.trace("ERR: $req.uri", origErr)

      // wrap err if not already HelixErr
      err := origErr as HelixErr
      if (err == null) err = HelixErr(500, origErr)

      // first check if this was a redirect
      if (err.redirectUri != null) return res.redirect(err.redirectUri, err.errCode)

      // else err callback
      onServiceErr(err)
    }
  }

  ** Callback when an error occured during `onService`.
  virtual Void onServiceErr(HelixErr err)
  {
    res.sendErr(err.errCode)
  }

  ** Wrap res.out with byte counter.
  @NoDoc override WebOutStream? makeResOut(OutStream out)
  {
    tout := ByteCountOutStream(out)
    req.stash["helix.out"] = tout
    return super.makeResOut(tout)
  }

  **
  ** Get the number of bytes written for the current response
  ** content, which does _not_ include HTTP headers.  This
  ** method must be called on the same actor servicing the
  ** HTTP request.
  **
  // TODO FIXIT: where should this method live?
  @NoDoc Int resSize(Bool checked := true)
  {
    // assume if bout == null then no content
    bout := req.stash["helix.out"] as ByteCountOutStream
    return bout == null ? 0 : bout.bytesWritten
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  ** Handle startup tasks.
  override Void onStart() {}

  ** Handle shutdown tasks.
  override Void onStop() {}

//////////////////////////////////////////////////////////////////////////
// Templates
//////////////////////////////////////////////////////////////////////////

  ** Return the template for given 'qname', where qname is
  ** '{pod}::{basename}`.  If template not found, then throws
  ** `ArgErr` or return 'null' if 'checked' is 'false'.
  Fanbars? template(Str qname, Bool checked := true)
  {
    tcache.get(qname, checked)
  }

  ** Template cache.
  private const TemplateCache tcache := TemplateCache()

//////////////////////////////////////////////////////////////////////////
// Logging
//////////////////////////////////////////////////////////////////////////

  // TODO: not sure how this works yet
  private Void trace(WebReq req, WebRes res, Duration time)
  {
    date := DateTime.now.toLocale("kk::mm::ss") // DD-MMM-YY")
    stat := res.statusCode
    enc  := res.headers["Content-Encoding"] ?: "uncompressed"
    len  := resSize.toLocale("B")

    msg  := "[${date}] ${req.method} \"${req.uri}\" (${stat}, "
    if (stat == 200) msg += "${enc}, ${len}, "
    msg += "${time.toLocale})"

    log.trace("> ${msg}")
    onLogTrace(msg)
  }

  // TODO: not sure how this works yet
  protected virtual Void onLogTrace(Str msg) {}

  // TODO: not sure how this works yet
  internal const HelixLog log
}
