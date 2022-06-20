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
** HelixRenderer manages rendering fanbars templates to 'res.out'.
**
class HelixRenderer
{
  ** Constructor.
  new make(HelixController controller)
  {
    this.controller = controller
  }

  ** Parent `HelixController` for this renderer instance.
  HelixController controller { private set }

  ** Convenience for 'controller.mod'.
  HelixMod mod() { controller.mod }

  ** Convenience for 'controller.req'.
  WebReq req() { controller.req }

  ** Convenience for 'controller.res'.
  WebRes res() { controller.res }

  ** Render the given template and data to response.  The 'name'
  ** may be fully qualified 'qname', or if no pod is specified
  ** defaults to pod of this controller subclass.
  virtual Void render(Str name, Str:Obj? data)
  {
    // resolve qname
    qname := name.index("::") == null
      ? "${controller.typeof.pod.name}::${name}"
      : name

    // setup response if not already commited
    if (!res.isCommitted)
    {
      res.statusCode              = data["hx_status_code"]  ?: 200
      res.headers["Content-Type"] = data["hx_content_type"] ?: "text/html; charset=UTF-8"
    }

    // render to res.out
    out := res.out
    mod.template(qname).render(out, data)
    out.flush
  }

  virtual Void renderInline() {}

  virtual Void renderText() {}

  virtual Void renderJson() {}

  virtual Void renderErr(Int code)
  {
    // TODO err-{code}
    // fallback to generic err.fbs ?
  }
}