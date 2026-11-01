//
// Copyright (c) 2026, Andy Frank
// Licensed under the MIT License
//
// History:
//   1 Nov 2026  Andy Frank  Creation
//

using helix
using web

**
** Tests for `HelixMod.maxBodySize`: an oversized body is refused
** before it is read.  TestMod sets 'maxBodySize' to 1024.
**
class BodyTest : HelixTest
{

//////////////////////////////////////////////////////////////////////////
// maxBodySize
//////////////////////////////////////////////////////////////////////////

  Void testWithinLimit()
  {
    verifyEq(post(`/args/form`, "a=1"), 200)
  }

  Void testTooLarge()
  {
    // refused from the headers alone; no body is sent
    verifyEq(headersOnly(`/args/form`, ["Content-Length":"1025"]), 413)
  }

  Void testNoLength()
  {
    // a body of unknown size cannot be checked, so is refused
    verifyEq(headersOnly(`/args/form`, ["Transfer-Encoding":"chunked"]), 411)
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  ** POST a form body; return the status.
  private Int post(Uri uri, Str body)
  {
    c := client(uri)
    c.reqHeaders["Content-Type"] = "application/x-www-form-urlencoded"
    c.postStr(body)
    code := c.resCode
    c.close
    return code
  }

  ** POST with given headers and no body; return the status.
  private Int headersOnly(Uri uri, Str:Str headers)
  {
    c := client(uri)
    c.reqMethod = "POST"
    c.reqHeaders["Content-Type"] = "application/x-www-form-urlencoded"
    c.reqHeaders.setAll(headers)
    c.writeReq.readRes
    code := c.resCode
    c.close
    return code
  }
}