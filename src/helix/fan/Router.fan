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

** Router handles routing URIs to controllers.
const class Router
{
  ** Constructor.
  new make(|This| f)
  {
    f(this)
    this.routes = sort(routes)
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
}

**************************************************************************
** RouteMatch
**************************************************************************

** RouteMatch models a matched Route instance.
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
