//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   9 Jun 2022  Andy Frank  Creation
//

using concurrent
using fanbars
using util
using web

**
** HelixRenderer renders response output to 'res.out'.
**
class HelixRenderer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

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

  ** Status code for response.
  Int statusCode := 200

  ** If 'true' response is always gzipped, regardless
  ** of 'Accept-Encoding' fallback.
  Bool forceGzip := false

//////////////////////////////////////////////////////////////////////////
// Render
//////////////////////////////////////////////////////////////////////////

  ** Render the given text to 'res.out' using content
  ** type '"text/plain; charset=utf-8"'.
  virtual Void renderText(Str text)
  {
    res.statusCode = this.statusCode
    res.headers["Content-Type"] = "text/plain; charset=utf-8"
    setupGzip.print(text).flush.close
  }

  ** Render the given text to 'res.out' using content
  ** type '"application/json; charset=utf-8"'.
  virtual Void renderJson(Obj obj)
  {
    res.statusCode = this.statusCode
    res.headers["Content-Type"] = "application/json; charset=utf-8"
    out := setupGzip
    JsonOutStream(out).writeJson(obj)
    out.printLine.flush.close
  }

  ** Render raw file content output to the browser using the given MIME
  ** type.  This method will flush and close the 'OutStream' after
  ** callback function is invoked. See `renderFileDownload` to trigger
  ** browser to download content instead of displaying.
  virtual Void renderFile(Str mimeType, |OutStream| f)
  {
    res.statusCode = this.statusCode
    res.headers["Content-Type"] = mimeType
    out := setupGzip
    f(out)
    out.flush.close
  }

  ** Render raw file content using the 'Content-Disposition' header
  ** to trigger browser to download instead of displaying.  This method
  ** will flush and close the 'OutStream' after callback function is
  ** invoked. See `renderFile` to render file content into browser.
  virtual Void renderFileDownload(Str mimeType, Str filename, |OutStream| f)
  {
    res.statusCode = this.statusCode
    res.headers["Content-Disposition"] = "attachment; filename=\"${filename}\""
    res.headers["Content-Type"] = mimeType
    out := setupGzip
    f(out)
    out.flush.close
  }

  ** Render the given HTML text to 'res.out' using content
  ** type '"text/html; charset=utf-8"'.
  virtual Void renderHtml(Str html)
  {
    res.statusCode = this.statusCode
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    setupGzip.print(html).flush.close
  }

  ** Render given inline template and data to 'res.out' using
  ** content type '"text/html; charset=utf-8"'.
  virtual Void renderInline(Str template, Str:Obj? data := [:])
  {
    res.statusCode = this.statusCode
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := setupGzip
    Fanbars.compile(template).render(out, mergeData(data))
    out.flush.close
  }

  ** Render the given template and data to 'res.out'. The 'name'
  ** may be fully qualified 'qname', or if no pod is specified
  ** defaults to pod of this controller subclass.  The content
  ** type will be '"text/html; charset=utf-8"'.
  virtual Void renderTemplate(Str name, Str:Obj? data := [:])
  {
    res.statusCode = this.statusCode
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := setupGzip
    template(name).render(out, mergeData(data)) |Str p->Fanbars|
    {
      // TODO: not sure this works yet; but @nodoc allow
      // templates to be specified in `data`
      data[p] as Fanbars ?: template(p)
    }
    out.flush.close
  }

  // TODO
  // virtual Void renderErr(Int code)
  // {
  //   // TODO err-{code}
  //   // fallback to generic err.fbs ?
  // }

  private Str:Obj? mergeData(Str:Obj? data)
  {
    controller.baseData.dup.setAll(data)
  }

  private Fanbars template(Str name)
  {
    // resolve qname
    qname := name.index("::") == null
      ? "${controller.typeof.pod.name}::${name}"
      : name
    return mod.template(qname)
  }

//////////////////////////////////////////////////////////////////////////
// Response Setup
//////////////////////////////////////////////////////////////////////////

  ** Setup the response for gzip compression if supported
  ** and return the appropriate OutStream instance to use.
  ** You must call 'out.close' to properly encode response
  ** if gzip is available and enabled.
  OutStream setupGzip()
  {
    // init check
    gzip := forceGzip

    if (!gzip)
    {
      // check if client supports gzip and file has text/* MIME type
      // and if so send the file using gzip compression (we don't
      // know content length in this case)
      ae := req.headers["Accept-Encoding"] ?: ""
      gzip = WebUtil.parseQVals(ae)["gzip"] > 0f
    }

    // if gzip set encoding and wrap stream
    if (gzip)
    {
      res.headers["Content-Encoding"] = "gzip"
      return Zip.gzipOutStream(res.out)
    }

    // if compression is not supported return 'res.out'
    return res.out
  }
}