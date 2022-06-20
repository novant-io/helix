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

  ** Get WebClient for URI on localhost.
  WebClient client(Uri uri)
  {
    WebClient(`http://localhost:${port}` + uri)
  }

  ** Verify `sendGet` headers and content.
  Void verifyGet(Uri uri, Str:Str headers, Str content)
  {
    // gzip enabled
    c := client(uri).writeReq.readRes
    headers.each |v,n| { verifyEq(v, c.resHeaders[n]) }
    verifyEq(c.resHeaders["Content-Encoding"], "gzip")
    verifyEq(content, c.resStr)

    // gzip disabled
    c = client(uri)
    c.reqHeaders.remove("Accept-Encoding")
    c.writeReq.readRes
    headers.each |v,n| { verifyEq(v, c.resHeaders[n]) }
    verifyEq(c.resHeaders["Content-Encoding"], null)
    verifyEq(content, c.resStr)
  }

  private WispService? wisp
}