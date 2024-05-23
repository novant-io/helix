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

  **
  ** If 'true', convenience to block all crawlers by serving the
  ** following content for 'GET' requests to '/robots.txt':
  **
  **   User-agent: *
  **   Disallow: /
  **
  ** If this field is 'false', requests to '/robots.txt' will
  ** default to '404 Not Found'. To customize the response, create
  ** a new route and controller endpoint.
  **
  const Bool blockRobots := false

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
    st := Duration.now
    HelixErr? err
    try
    {
      // set mod
      req.mod = this

      // init args so HelixController.make can be used
      // even if no route mates in onServiceErr
      Actor.locals["helix.args"] = HelixArgs.defVal

      // match req to Route
      RouteMatch? match
      if (blockRobots && req.uri.path.first == "robots.txt")
      {
        match = RouteMatch(blockRobotsRoute, [:])
      }
      else
      {
        match = router.match(req.modRel, req.method)
        if (match == null) throw HelixErr(404)
        req.stash["helix.route"] = match.route
      }

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
    }
    catch (Err origErr)
    {
      // wrap err if not already HelixErr
      err = origErr as HelixErr
      if (err == null) err = HelixErr(500, origErr)

      // first check if this was a redirect
      if (err.redirectUri != null) return res.redirect(err.redirectUri, err.errCode)

      // else err callback
      onServiceErr(err)
    }
    finally
    {
      // trace request
      et := Duration.now
      traceReq(req, res, et-st, err)
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

  // only used for blockRobots
  private const Route blockRobotsRoute := Route("/robots.txt", "GET", RobotsController#block)
  private const Str:Str emptyArgs := [:]

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

  ** Subclass hook to customize logging requests.
  protected virtual Void traceReq(WebReq req, WebRes res, Duration dur, HelixErr? err)
  {
    date := DateTime.now.toLocale("kk::mm::ss")
    stat := res.statusCode
    enc  := res.headers["Content-Encoding"] ?: "uncompressed"
    len  := resSize.toLocale("B")

    // trace req
    msg  := "> [${date}] ${req.method} \"${req.uri}\" (${stat}, "
    if (stat == 200) msg += "${enc}, ${len}, "
    msg += "${dur.toLocale})"
    log.trace(msg)

    // trace stack trace
    if (err != null) log.trace("> ${err.msg}", err)
  }

  // TODO: not sure how this works yet
  internal const HelixLog log
}
