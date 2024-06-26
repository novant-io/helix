//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   26 Sep 2022  Andy Frank  Creation
//

using helix

**
** Test code for HelixArgs.
**
class ArgsTest : HelixTest
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testRouteArgs()
  {
    verifyGetArgs(`/args/empty`,         [:])
    verifyGetArgs(`/args/route/x`,       ["foo":"x"])
    verifyGetArgs(`/args/route/123`,     ["foo":"123"])
    verifyGetArgs(`/args/route/x/y`,     ["foo":"x", "bar":"y"])
    verifyGetArgs(`/args/route/123/789`, ["foo":"123", "bar":"789"])
  }

  Void testQueryArgs()
  {
    verifyGetArgs(`/args/empty?a=100`,       ["a":"100"])
    verifyGetArgs(`/args/empty?a=100&b=200`, ["a":"100", "b":"200"])
  }

  Void testFormArgs()
  {
    verifyPostArgs(`/args/form`, [:], [:])
    verifyPostArgs(`/args/form`, ["name":"bob"], ["name":"bob"])
    verifyPostArgs(`/args/form`, ["name":"bob", "pass":"xyz"], ["name":"bob", "pass":"xyz"])
  }

  Void testTypes()
  {
    form := [
      "str":      "Foo",
      "bool":     "false",
      "int":      "12",
      "int-list": "1,2,3,4",
      "date-a":   "2023-03-15",
      "date-b":   "3/15/23",
      "date-c":   "",
    ]

    postForm(form) |args| {
      verifyEq(args.reqStr("str"),               "Foo")
      verifyEq(args.reqBool("bool"),             false)
      verifyEq(args.reqInt("int"),               12)
      verifyEq(args.reqIntList("int-list"),      Obj?[1,2,3,4]) // TODO FIXIT
      verifyEq(args.reqDate("date-a"),           Date("2023-03-15"))
      verifyEq(args.reqDate("date-b", "M/D/YY"), Date("2023-03-15"))
      verifyEq(args.optDate("date-c"),           null)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Combo
//////////////////////////////////////////////////////////////////////////

  Void testCombo()
  {
    // route + query
    verifyGetArgs(`/args/route/x?a=100`,         ["foo":"x", "a":"100"])
    verifyGetArgs(`/args/route/x/y?a=100&b=200`, ["foo":"x", "bar":"y", "a":"100", "b":"200"])
    verifyGet500(`/args/route/x/y?foo=100`)
    verifyGet500(`/args/route/x/y?bar=100`)

    // route + form
    verifyPostArgs(`/args/form/x`,   [:],            ["foo":"x"])
    verifyPostArgs(`/args/form/x`,   ["name":"bob"], ["foo":"x", "name":"bob"])
    verifyPostArgs(`/args/form/x/y`, ["name":"bob"], ["foo":"x", "bar":"y", "name":"bob"])
    verifyPost500(`/args/form/x`,    ["foo":"bob"])
    verifyPost500(`/args/form/x/y`,  ["bar":"xyz"])

    // route + query + form
    verifyPostArgs(`/args/form/x?a=100`,
      ["name":"bob"],
      ["foo":"x", "a":"100", "name":"bob"])
    verifyPostArgs(`/args/form/x/y?a=100&b=200`,
      ["name":"bob", "pass":"xyz"],
      ["foo":"x", "bar":"y", "a":"100", "b":"200", "name":"bob", "pass":"xyz"])
    verifyPost500(`/args/form/x?foo=100`, ["foo":"xyz"])
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Void verifyGetArgs(Uri uri, Str:Obj expected)
  {
    verifyGet(uri, [:], "ok")
    // echo("---> " + TestController.argsMapRef.val)
    Str:Obj temp := Str:Obj[:].addAll(expected)  // stupid type inference
    verifyEq(TestController.argsMapRef.val, temp)
  }

  private Void verifyPostArgs(Uri uri, Str:Str form, Str:Obj expected)
  {
    verifyPost(uri, form, [:], "ok")
    // echo("---> " + TestController.argsMapRef.val)
    Str:Obj temp := Str:Obj[:].addAll(expected)  // stupid type inference
    verifyEq(TestController.argsMapRef.val, temp)
  }

  private Void postForm(Str:Str form, |HelixArgs args| f)
  {
    verifyPost(`/args/form`, form, [:], "ok")
    f(TestController.argsRef.val)
  }
}