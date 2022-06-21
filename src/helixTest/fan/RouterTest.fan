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
// Args
//////////////////////////////////////////////////////////////////////////

  Void testArgs()
  {
    r := Route("/foo/{arg}", "GET", RouterTestController#arg)
    verifyRoute(r, `/foo/123`, "GET", Str:Str["arg":"123"])
    verifyRoute(r, `/foo/abc`, "GET", Str:Str["arg":"abc"])
    verifyRoute(r, `/foo/ax9`, "GET", Str:Str["arg":"ax9"])
    verifyRoute(r, `/foo/_4b`, "GET", Str:Str["arg":"_4b"])

    r = Route("/foo/{a}/bar/{b}/list", "GET", RouterTestController#arg)
    verifyRoute(r, `/foo/123/bar/abc/list`, "GET", Str:Str["a":"123", "b":"abc"])
    verifyRoute(r, `/foo/123/bax/abc/list`, "GET", null)
  }

//////////////////////////////////////////////////////////////////////////
// Varargs
//////////////////////////////////////////////////////////////////////////

  Void testVararg()
  {
    r := Route("/foo/*", "GET", RouterTestController#varargs)
    verifyRoute(r, `/foo/x`,     "GET", Str:Str[:])
    verifyRoute(r, `/foo/x/y`,   "GET", Str:Str[:])
    verifyRoute(r, `/foo/x/y/z`, "GET", Str:Str[:])
    verifyRoute(r, `/fox/x/y/z`, "GET", null)

    r = Route("/foo/{bar}/*", "GET", RouterTestController#varargs)
    verifyRoute(r, `/foo/x/y`,     "GET", Str:Str["bar":"x"])
    verifyRoute(r, `/foo/x/y/z`,   "GET", Str:Str["bar":"x"])
    verifyRoute(r, `/foo/x/y/z/5`, "GET", Str:Str["bar":"x"])
    verifyRoute(r, `/fox/x/y/z`,   "GET", null)

    r = Route("/x/y/z/*", "GET", RouterTestController#varargs)
    verifyRoute(r, `/x`,         "GET", null)
    verifyRoute(r, `/x/y`,       "GET", null)
    verifyRoute(r, `/x/y/z`,     "GET", null)
    verifyRoute(r, `/x/y/z/foo`, "GET", Str:Str[:])
    verifyRoute(r, `/x/y/z/foo/a/b/c`, "GET", Str:Str[:])

    // errs
    verifyErr(ArgErr#) { x := Route("/foo/*/*", "GET", RouterTestController#varargs) }
    verifyErr(ArgErr#) { x := Route("/*/foo",   "GET", RouterTestController#varargs) }
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
  Void arg()     {}
  Void varargs() {}
  Void err()     {}
}