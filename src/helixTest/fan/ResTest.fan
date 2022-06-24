//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   23 Jun 2022  Andy Frank  Creation
//

using helix
using web

**
** Test code for ResRoute.
**
class ResTest : HelixTest
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    h := ["Content-Type":"text/css; charset=utf-8"]
    verifyGet(`/css/test.css`, h, "body {
                                     color: #f00;
                                   }
                                   ")
  }
}