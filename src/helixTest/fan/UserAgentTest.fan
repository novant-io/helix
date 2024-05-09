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
    verifyEq(ua.browser, null)
    verifyUA(ua, [[,]])

    // simple (no ver/comment)
    ua = UserAgent("foo")
    verifyEq(ua.browser, null)
    verifyUA(ua, [["foo", null, null]])

    // simple (no comment)
    ua = UserAgent("foo/12")
    verifyEq(ua.browser, null)
    verifyUA(ua, [["foo", "12", null]])

    // simple
    ua = UserAgent("foo/12 (some; comment)")
    verifyEq(ua.browser, null)
    verifyUA(ua, [["foo", "12", "some; comment"]])

    // multi simple (no ver/comment)
    ua = UserAgent("foo bar zar")
    verifyEq(ua.browser, null)
    verifyUA(ua, [
      ["foo", null, null],
      ["bar", null, null],
      ["zar", null, null]
    ])

    // multi simple (no ver/comment)
    ua = UserAgent("foo/1 bar/2 zar/3")
    verifyEq(ua.browser, null)
    verifyUA(ua, [
      ["foo", "1", null],
      ["bar", "2", null],
      ["zar", "3", null]
    ])

    // multi simple (no ver/comment)
    ua = UserAgent("foo bar/2 zar/3")
    verifyEq(ua.browser, null)
    verifyUA(ua, [
      ["foo", null, null],
      ["bar", "2", null],
      ["zar", "3", null]
    ])

    // multi simple (no ver/comment)
    ua = UserAgent("foo/1 bar zar/3")
    verifyEq(ua.browser, null)
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
    verifyEq(ua.browser.toStr, "Safari 17.4 on macOS")
    verifyUA(ua, [
      ["Mozilla",     "5.0",      "Macintosh; Intel Mac OS X 10_15_7"],
      ["AppleWebKit", "605.1.15", "KHTML, like Gecko"],
      ["Version",     "17.4",     null],
      ["Safari",      "605.1.15", null],
    ])

    // Safari 17.4.1 (iOS)
    ua = UserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Mobile/15E148 Safari/604.1")
    verifyEq(ua.browser.toStr, "Safari 17.4.1 on iOS")
    verifyUA(ua, [
      ["Mozilla",     "5.0",      "iPhone; CPU iPhone OS 17_4_1 like Mac OS X"],
      ["AppleWebKit", "605.1.15", "KHTML, like Gecko"],
      ["Version",     "17.4.1",   null],
      ["Mobile",      "15E148",   null],
      ["Safari",      "604.1",    null],
    ])

    // Firefox 125 (macOS)
    ua = UserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 14.4; rv:125.0) Gecko/20100101 Firefox/125.0")
    verifyEq(ua.browser.toStr, "Firefox 125.0 on macOS")
    verifyUA(ua, [
      ["Mozilla", "5.0",      "Macintosh; Intel Mac OS X 14.4; rv:125.0"],
      ["Gecko",   "20100101", null],
      ["Firefox", "125.0",    null],
    ])

    // Firefox 125 (Windows 10)
    ua = UserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0")
    verifyEq(ua.browser.toStr, "Firefox 125.0 on Windows")
    verifyUA(ua, [
      ["Mozilla", "5.0",      "Windows NT 10.0; Win64; x64; rv:125.0"],
      ["Gecko",   "20100101", null],
      ["Firefox", "125.0",    null],
    ])

    // Chrome 124 (macOS)
    ua = UserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_4_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
    verifyEq(ua.browser.toStr, "Chrome 124.0.0.0 on macOS")
    verifyUA(ua, [
      ["Mozilla",     "5.0",       "Macintosh; Intel Mac OS X 14_4_1"],
      ["AppleWebKit", "537.36",    "KHTML, like Gecko"],
      ["Chrome",      "124.0.0.0", null],
      ["Safari",      "537.36",    null],
    ])

    // Chrome 123 (Windows 10)
    ua = UserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
    verifyEq(ua.browser.toStr, "Chrome 124.0.0.0 on Windows")
    verifyUA(ua, [
      ["Mozilla",     "5.0",       "Windows NT 10.0; Win64; x64"],
      ["AppleWebKit", "537.36",    "KHTML, like Gecko"],
      ["Chrome",      "124.0.0.0", null],
      ["Safari",      "537.36",    null],
    ])
  }

  private Void verifyUA(UserAgent ua, Str?[][] prods)
  {
    ua.products.each |p,i|
    {
      verifyEq(p.name,    prods[i][0])
      verifyEq(p.ver,     prods[i][1])
      verifyEq(p.comment, prods[i][2])
    }
  }
}