//
// Copyright (c) 2024, Andy Frank
// Licensed under the MIT License
//
// History:
//   7 May 2024  Andy Frank  Creation
//

using helix

*************************************************************************
** UserAgentTest
*************************************************************************

class UserAgentTest : Test
{
  Void testBasics()
  {
    // empty
    ua := UserAgent("")
    verifyEq(ua.products.size, 0)
    verifyUA(ua, [[,]])

    // simple (no ver/comment)
    ua = UserAgent("foo")
    verifyUA(ua, [["foo", null, null]])

    // simple (no comment)
    ua = UserAgent("foo/12")
    verifyUA(ua, [["foo", "12", null]])

    // simple
    ua = UserAgent("foo/12 (some; comment)")
    verifyUA(ua, [["foo", "12", "some; comment"]])

    // multi simple (no ver/comment)
    ua = UserAgent("foo bar zar")
    verifyUA(ua, [
      ["foo", null, null],
      ["bar", null, null],
      ["zar", null, null]
    ])

    // multi simple (no ver/comment)
    ua = UserAgent("foo/1 bar/2 zar/3")
    verifyUA(ua, [
      ["foo", "1", null],
      ["bar", "2", null],
      ["zar", "3", null]
    ])

    // multi simple (no ver/comment)
    ua = UserAgent("foo bar/2 zar/3")
    verifyUA(ua, [
      ["foo", null, null],
      ["bar", "2", null],
      ["zar", "3", null]
    ])

    // multi simple (no ver/comment)
    ua = UserAgent("foo/1 bar zar/3")
    verifyUA(ua, [
      ["foo", "1", null],
      ["bar", null, null],
      ["zar", "3", null]
    ])
  }

  Void testBrowser()
  {
    // Safari 17.5 (macOS)
    ua := UserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15")
    verifyUA(ua, [
      ["Mozilla",     "5.0",      "Macintosh; Intel Mac OS X 10_15_7"],
      ["AppleWebKit", "605.1.15", "KHTML, like Gecko"],
      ["Version",     "17.4",     null],
      ["Safari",      "605.1.15", null],
    ])

    // Firefox 125 (Windows 10)
    ua = UserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0")
    verifyUA(ua, [
      ["Mozilla", "5.0",      "Windows NT 10.0; Win64; x64; rv:125.0"],
      ["Gecko",   "20100101", null],
      ["Firefox", "125.0",    null],
    ])

    // Chrome 123 (Windows 10)
    ua = UserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
    verifyUA(ua, [
      ["Mozilla",     "5.0",       "Windows NT 10.0; Win64; x64"],
      ["AppleWebKit", "537.36",    "KHTML, like Gecko"],
      ["Chrome",      "124.0.0.0", null],
      ["Safari",      "537.36",    null],
    ])
  }

  Void verifyUA(UserAgent ua, Str?[][] prods)
  {
    ua.products.each |p,i|
    {
      verifyEq(p.name,    prods[i][0])
      verifyEq(p.ver,     prods[i][1])
      verifyEq(p.comment, prods[i][2])
    }
  }
}