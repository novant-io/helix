//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   17 Jun 2022  Andy Frank  Creation
//

using helix
using web

**
** Test code for Router class.
**
class RouterTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Index
//////////////////////////////////////////////////////////////////////////

  Void testIndexRoute()
  {
    // test index
    r := Route("/", "GET", RouterTestController#index)
    verifyRoute(r, `/`,    "GET",  Str:Str[:])
    verifyRoute(r, `/`,    "POST", null)
    verifyRoute(r, `/foo`, "GET",  null)

    // test errs
    verifyErr(ArgErr#) { x := Route("",  "GET", RouterTestController#err) }
    verifyErr(ArgErr#) { x := Route("/", "GET", #doesNotExtendHelixController) }
  }

//////////////////////////////////////////////////////////////////////////
// Literals
//////////////////////////////////////////////////////////////////////////

  Void testLiteralRoute()
  {
    // test method
    r := Route("/foo/bar", "GET", RouterTestController#literal)
    verifyRoute(r, `/foo/bar`,  "GET",  Str:Str[:])
    verifyRoute(r, `/foo/bar`,  "POST", null)
    verifyRoute(r, `/foo/bar`,  "HEAD", null)

    // test no match
    verifyRoute(r, `/`,       "GET",  null)
    verifyRoute(r, `/yo`,     "GET",  null)
    verifyRoute(r, `/foo`,    "GET",  null)
    verifyRoute(r, `/foo/`,   "GET",  null)
    verifyRoute(r, `/foo/ba`, "GET",  null)

    // test errs
    verifyErr(ArgErr#) { x := Route("/foo/", "GET", RouterTestController#err) }
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Void verifyRoute(Route r, Uri uri, Str method, [Str:Str]? vars)
  {
    verifyEq(r.match(uri, method), vars)
    verifyEq(r.match(uri, method.lower), vars)
  }

  Void doesNotExtendHelixController() {}
}

*************************************************************************
** RouterTestController
*************************************************************************

internal class RouterTestController : HelixController
{
  Void index()   {}
  Void literal() {}
  Void err()     {}
}