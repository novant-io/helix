//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   9 Jun 2022  Andy Frank  Creation
//

using web

**************************************************************************
** Route
**************************************************************************

**
** Route models how a URI pattern gets routed to a method handler.
** Example patterns:
**
**   Pattern         Uri           Args
**   --------------  ------------  ----------
**   "/"             `/`           [:]
**   "/foo/{bar}"    `/foo/12`     ["bar":"12"]
**   "/foo/*"        `/foo/x/y/z`  [:]
**   "/foo/{bar}/*"  `/foo/x/y/z`  ["bar":"x"]
**
const class Route
{
  ** Constructor.
  new make(Str pattern, Str method, Method handler)
  {
    // parse pattern
    this.tokens = RouteParser.parse(pattern)

    // validate handler
    if (!handler.parent.fits(HelixController#))
      throw ArgErr("handler.parent must subclass HelixController")

    this.pattern = pattern
    this.method  = method
    this.handler = handler
  }

  ** URI pattern for this route.
  const Str pattern

  ** HTTP method used for this route.
  const Str method

  ** Method handler for this route. Method must be an instance
  ** method on a subclass of `HelixController`.
  const Method handler

  ** Callback for route to process request before target
  ** controller services request.
  virtual Void onBeforeService(HelixArgs args) {}

  ** Match this route against the request arguments.  If route can
  ** be be matched, return the pattern arguments, or return 'null'
  ** for no match.
  [Str:Str]? match(Uri uri, Str method)
  {
    // if methods not equal, no match
    if (method.compareIgnoreCase(this.method) != 0) return null

    // if size unequal, we know there is no match
    path := uri.path
    if (tokens.last?.type == RouteToken.vararg)
    {
      if (path.size < tokens.size) return null
    }
    else if (tokens.size != path.size) return null

    // iterate tokens looking for matches
    map := Str:Str[:]
    for (i:=0; i<path.size; i++)
    {
      p := path[i]
      t := tokens[i]
      switch (t.type)
      {
        case RouteToken.literal: if (t.val != p) return null
        case RouteToken.arg:     map[t.val] = p
        case RouteToken.vararg:  break
      }
    }

    return map
  }

  ** 'toStr' is `pattern`.
  override Str toStr() { pattern }

  internal const Bool isLiteral        // are all tokens == literals
  internal const RouteToken[] tokens   // parse tokens
}

*************************************************************************
** CrudRoute
*************************************************************************

// TODO: CrudRoute("/table", Controller#)

*************************************************************************
** ResRoute
*************************************************************************

**
** ResRoute is a `Route` subclass used for servicing file resources.
** Routes are matched by 'Uri.name' based on the request URI and
** files given in 'sources' list.
**
** Example:
**
**   ResRoute("/js/foo.js",  [`fan://mypod/res/js/foo.js`])
**   ResRoute("/css/{file}", [`fan://mypod/css/`])
**
const class ResRoute : Route
{
  ** Constructor.
  new make(Str pattern, Uri[] sources) : super(pattern, "GET", ResController#getRes)
  {
    map := Str:File[:]
    sources.each |src|
    {
      if (src.isDir) listDir(src).each |f| { map.add(f.name, f) }
      else map.add(src.name, src.toFile)
    }
    this.sources = map
  }

  ** Resolve uri to file or 'null' if not found.
  internal File? resolve(Uri uri) { sources[uri.name] }

  ** List files under given directory instance.
  private File[] listDir(Uri dir)
  {
    switch (dir.scheme)
    {
      case "file": return dir.toFile.listFiles
      case "fan":
        // Pod.file does not allow us to iterate dirs so we need
        // to get manually match files using path prefix
        prefix := dir.relToAuth.pathStr
        pod    := Pod.find(dir.host)
        return pod.files.findAll |f| { !f.isDir && f.uri.pathStr.startsWith(prefix) }

      default: throw ArgErr("Unsupported scheme '$dir.scheme'")
    }
  }

  private const Str:File sources := [:]
}

*************************************************************************
** PackRoute
*************************************************************************

**
** PackRoute is a `Route` subclass used for servicing
** `FilePack`[web::FilePack]file resources.
**
** Example:
**
**   PackRoute("/js/app.js", FilePack(FilePack.toAppJsFiles(pods))
**
const class PackRoute : Route
{
  ** Constructor.
  new make(Str pattern, FilePack pack) : super(pattern, "GET", ResController#getPack)
  {
    this.pack = pack
  }

  internal const FilePack pack
}