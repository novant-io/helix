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
  Void verifyGet(Uri uri, Str:Str resHeaders, Str resContent)
  {
    // find gzip size of resContent
    z := Buf()
    Zip.gzipOutStream(z.out).print(resContent).close

    //
    // gzip enabled
    //
    c := client(uri).writeReq.readRes
    // verify gzip + res headers (just the ones we want to check)
    verifyEq(c.resCode, 200)
    verifyEq(c.resHeaders["Content-Encoding"], "gzip")
    resHeaders.each |v,n| { verifyEq(v, c.resHeaders[n]) }
    // verify content round-tripped
    verifyEq(resContent, c.resStr)
    // verify HelixMod.resSize  (check after c.resStr so stream drains)
    cl := c.resHeaders["Content-Length"]
    if (cl != null) verifyEq(cl, "${mod.bytesWritten}")
    verifyEq(z.size, mod.bytesWritten)

    //
    // gzip disabled
    //
    c = client(uri)
    c.reqHeaders.remove("Accept-Encoding")
    c.writeReq.readRes
    // verify !gzip + res headers (just the ones we want to check)
    verifyEq(c.resCode, 200)
    verifyEq(c.resHeaders["Content-Encoding"], null)
    resHeaders.each |v,n| { verifyEq(v, c.resHeaders[n]) }
    // verify content round-tripped
    verifyEq(resContent, c.resStr)
    // verify HelixMod.resSize (check after c.resStr so stream drains)
    cl = c.resHeaders["Content-Length"]
    if (cl != null) verifyEq(cl, "${mod.bytesWritten}")
    verifyEq(resContent.size, mod.bytesWritten)
  }

  ** Verify `sendPost` headers and content.
  Void verifyPost(Uri uri, Str:Str form, Str:Str resHeaders, Str resContent)
  {
    // gzip enabled
    c := client(uri)
    c.postForm(form)
    resHeaders.each |v,n| { verifyEq(v, c.resHeaders[n]) }
    verifyEq(c.resHeaders["Content-Encoding"], "gzip")
    verifyEq(resContent, c.resStr)

    // gzip disabled
    c = client(uri)
    c.reqHeaders.remove("Accept-Encoding")
    c.postForm(form)
    resHeaders.each |v,n| { verifyEq(v, c.resHeaders[n]) }
    verifyEq(c.resCode, 200)
    verifyEq(c.resHeaders["Content-Encoding"], null)
    verifyEq(resContent, c.resStr)
  }

  ** Verify a 404 response.
  Void verify404(Uri uri)
  {
    c := client(uri).writeReq.readRes
    // echo(c.resStr)
    verifyEq(c.resCode, 404)
  }

  ** Verify a GET 500 response.
  Void verifyGet500(Uri uri)
  {
    c := client(uri).writeReq.readRes
    // echo(c.resStr)
    verifyEq(c.resCode, 500)
  }

  ** Verify a POST 500 response.
  Void verifyPost500(Uri uri, Str:Str form)
  {
    c := client(uri)
    c.postForm(form)
    // echo(c.resStr)
    verifyEq(c.resCode, 500)
  }

  private WispService? wisp
}