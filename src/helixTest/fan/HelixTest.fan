//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   20 Jun 2022  Andy Frank  Creation
//

using helix
using web
using wisp

**
** Base class for unit tests with a running HelixMod http daemon.
**
abstract class HelixTest : Test
{
  ** TestMod instance.
  const TestMod mod := TestMod()

  ** HTTP port to run WispService on.
  const Int port := 9876

  override Void setup()
  {
    this.wisp = WispService { it.httpPort=port; it.root=mod }
    this.wisp.start
  }

  override Void teardown()
  {
    this.wisp?.stop
  }

  ** Send a GET request to running TestMod and return response text.
  Str sendGet(Uri uri)
  {
    WebClient(`http://localhost:${port}` + uri).getStr
  }

  ** Convenience for 'verifyEq(sendGet(uri), test)'.
  Void verifyGet(Uri uri, Str test)
  {
    verifyEq(sendGet(uri), test)
  }

  private WispService? wisp
}