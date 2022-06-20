//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   9 Jun 2022  Andy Frank  Creation
//

using web

**************************************************************************
** Router
**************************************************************************

**
** Router handles routing URIs to controllers.
**
const class Router
{
  ** Constructor.
  new make(|This| f)
  {
    f(this)
    this.routes = Route.sort(routes)
  }

  ** Route configuration.
  const Route[] routes := [,]

  ** Match a request to Route. If no matches are found, returns
  ** 'null'.  The first route that matches is chosen. Literal
  ** routes are matched before parameterized routes.
  RouteMatch? match(Uri uri, Str method)
  {
    for (i:=0; i<routes.size; i++)
    {
      r := routes[i]
      m := r.match(uri, method)
      if (m != null) return RouteMatch(r, m)
    }
    return null
  }
}

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
    // validate pattern
    try
    {
      // patterns must be absolute
      if (pattern.size == 0 || pattern[0] != '/')
        throw ArgErr("Pattern must start with '/'")

      // trailing '/' not currently supported
      if (pattern.size > 1 && pattern[-1] == '/')
        throw ArgErr("Trailing '/' not supported")

      // optimize index routes
      this.tokens = pattern == "/"
        ? RouteToken#.emptyList
        : pattern[1..-1].split('/').map |v| { RouteToken(v) }

      // check if pattern is vararg
      varIndex := tokens.findIndex |t| { t.type == RouteToken.vararg }
      if (varIndex != null && varIndex != tokens.size-1) throw Err()

      // check if pattern is literal
      this.isLiteral = tokens.all |t| { t.type == RouteToken.literal }
    }
    catch (Err err)
    {
      throw ArgErr("Invalid pattern $pattern.toCode", err)
    }

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

  ** Sort a list of routes by bubbling literals to top, and
  ** maintaining existing order for remaining routes.
  internal static Route[] sort(Route[] routes)
  {
    lits := routes.findAll |r| { r.isLiteral }
    if (lits.isEmpty) return routes

    copy := routes.dup.rw
    lits.eachr |r| { copy.moveTo(r, 0) }
    return copy.toImmutable
  }

  ** 'toStr' is `pattern`.
  override Str toStr() { pattern }

  ** Is the route all literal tokens (no args or patterns)?
  internal const Bool isLiteral

  ** Parsed tokens.
  private const RouteToken[] tokens
}

**************************************************************************
** RouteToken
**************************************************************************

**
** RouteToken models each path token in a URI pattern.
**
internal const class RouteToken
{
  ** Constructor.
  new make(Str val)
  {
    if (val[0] == '*')
    {
      this.val = val
      this.type = vararg
    }
    else if (val[0] == '{' && val[-1] == '}')
    {
      this.val  = val[1..-2]
      this.type = arg
    }
    else
    {
      this.val  = val
      this.type = literal
    }
  }

  ** Token type.
  const Int type

  ** Token value.
  const Str val

  ** Str value is "$type:$val".
  override Str toStr() { "$type:$val" }

  ** Type id for a literal token.
  static const Int literal := 0

  ** Type id for an argument token.
  static const Int arg := 1

  ** Type id for vararg token.
  static const Int vararg := 2
}

**************************************************************************
** RouteMatch
**************************************************************************

**
** RouteMatch models a matched Route instance.
**
const class RouteMatch
{
  ** Constructor
  new make(Route route, Str:Str args)
  {
    this.route = route
    this.args  = args
  }

  ** Matched route instance.
  const Route route

  ** Arguments for matched Route.
  const Str:Str args
}


