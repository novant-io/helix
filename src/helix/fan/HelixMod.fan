//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   9 Jun 2022  Andy Frank  Creation
//

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

  ** Invoked prior to servicing the current request.
  virtual Void onBeforeService(Str:Str args) {}

  ** Invoked after servicing the current request.
  virtual Void onAfterService(Str:Str args) {}

  ** Service incoming request.
  override Void onService()
  {
    try
    {
      // set mod
      req.mod = this

      // match req to Route
      match := router.match(req.modRel, req.method)
      if (match == null) throw HelixErr(404)
      req.stash["helix.route"] = match.route

      // allow pre-service
      onBeforeService(match.args)
      if (res.isDone) return

      // delegate to Route.handler/HelixController
      h := match.route.handler
      args := h.params.isEmpty ? null : [match.args]
      c := h.parent == typeof ? this : h.parent.make
      c.trap(h.name, args)

      // allow post-service
      onAfterService(match.args)
    }
    catch (HelixErr err)
    {
      // TODO FIXIT
      log.trace("ERR: $req.uri", err)
      res.sendErr(err.errCode)
    }
    catch (Err err)
    {
      // TODO FIXIT
      log.trace("ERR: $req.uri", err)
      res.sendErr(500)
    }
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
  internal const HelixLog log
}
