//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   26 Sep 2022  Andy Frank  Creation
//

using concurrent
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
// Nested
//////////////////////////////////////////////////////////////////////////

  Void testNestedMap()
  {
    // basic single-level map
    postForm(["metadata[foo]":"bar", "metadata[baz]":"qux"]) |args| {
      verifyEq(args.optNestedMap("metadata"), Str:Str["foo":"bar", "baz":"qux"])
      verifyEq(args.reqNestedMap("metadata"), Str:Str["foo":"bar", "baz":"qux"])
    }

    // single-key map
    postForm(["m[only]":"x"]) |args| {
      verifyEq(args.optNestedMap("m"), Str:Str["only":"x"])
    }

    // empty value
    postForm(["m[k]":""]) |args| {
      verifyEq(args.optNestedMap("m"), Str:Str["k":""])
    }

    // not present
    postForm([:]) |args| {
      verifyEq(args.optNestedMap("metadata"), null)
      verifyErr(ArgErr#) { args.reqNestedMap("metadata") }
    }

    // unrelated keys are ignored
    postForm(["other":"x", "metadata[k]":"v"]) |args| {
      verifyEq(args.optNestedMap("metadata"), Str:Str["k":"v"])
    }

    // deeper nesting throws
    postForm(["m[a][b]":"x"]) |args| {
      verifyErr(ArgErr#) { args.optNestedMap("m") }
    }
  }

  Void testNestedListMaps()
  {
    // basic two-element list of maps
    postForm([
      "writes[0][point_id]":"p.x", "writes[0][value]":"72",
      "writes[1][point_id]":"p.y", "writes[1][value]":"null",
    ]) |args| {
      res := args.optNestedList("writes")
      verifyEq(res.size, 2)
      verifyEq(res[0], Str:Str["point_id":"p.x", "value":"72"])
      verifyEq(res[1], Str:Str["point_id":"p.y", "value":"null"])
    }

    // single-element list
    postForm(["w[0][k]":"v"]) |args| {
      res := args.optNestedList("w")
      verifyEq(res.size, 1)
      verifyEq(res[0], Str:Str["k":"v"])
    }

    // mixed field counts per element (optional fields)
    postForm([
      "w[0][a]":"1", "w[0][b]":"2",
      "w[1][a]":"3",
    ]) |args| {
      res := args.optNestedList("w")
      verifyEq(res.size, 2)
      verifyEq(res[0], Str:Str["a":"1", "b":"2"])
      verifyEq(res[1], Str:Str["a":"3"])
    }

    // req throws when missing
    postForm([:]) |args| {
      verifyEq(args.optNestedList("w"), null)
      verifyErr(ArgErr#) { args.reqNestedList("w") }
    }
  }

  Void testNestedListScalars()
  {
    // basic scalar list
    postForm(["tags[0]":"a", "tags[1]":"b", "tags[2]":"c"]) |args| {
      res := args.optNestedList("tags")
      verifyEq(res, Obj?["a","b","c"])
    }

    // single element
    postForm(["tags[0]":"only"]) |args| {
      verifyEq(args.optNestedList("tags"), Obj?["only"])
    }
  }

  Void testNestedListErrors()
  {
    // sparse indices throw
    postForm(["w[0][k]":"v", "w[2][k]":"v"]) |args| {
      verifyErr(ArgErr#) { args.optNestedList("w") }
    }

    // non-zero starting index throws
    postForm(["w[1][k]":"v"]) |args| {
      verifyErr(ArgErr#) { args.optNestedList("w") }
    }

    // non-numeric index throws
    postForm(["w[foo][k]":"v"]) |args| {
      verifyErr(ArgErr#) { args.optNestedList("w") }
    }

    // deeper nesting throws
    postForm(["w[0][a][b]":"v"]) |args| {
      verifyErr(ArgErr#) { args.optNestedList("w") }
    }

    // mixed scalar/map shapes throw
    postForm(["w[0]":"x", "w[1][k]":"v"]) |args| {
      verifyErr(ArgErr#) { args.optNestedList("w") }
    }

    // duplicate scalar index throws (form decoder would normally
    // collapse, but if reached here it should fail loudly)
    // duplicate field within a map row throws
    postForm(["w[0][k]":"v"]) |args| {
      // sanity check happy path
      verifyEq(args.optNestedList("w").size, 1)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Uploads
//////////////////////////////////////////////////////////////////////////

  Void testUploadCleanup()
  {
    // the upload temp file is deleted once the request is done
    verifyEq(upload(`/args/upload`), 200)
    HelixFile f := ((HelixArgs)TestController.argsRef.val).reqFile("file")
    verifyEq(f.name, "a.csv")
    verifyDeleted(f.temp)
  }

  Void testUploadCleanupOnErr()
  {
    // and also when the request fails
    verifyEq(upload(`/args/upload/err`), 401)
    HelixFile f := ((HelixArgs)TestController.argsRef.val).reqFile("file")
    verifyDeleted(f.temp)
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

  ** Verify 'f' is deleted; cleanup runs after the response is sent,
  ** so allow it a moment.
  private Void verifyDeleted(File f)
  {
    100.times { if (f.exists) Actor.sleep(10ms) }
    verifyFalse(f.exists)
  }

  ** POST a multipart form with one file 'a.csv'; return the status.
  private Int upload(Uri uri)
  {
    body := "--xb\r\n" +
            "Content-Disposition: form-data; name=\"file\"; filename=\"a.csv\"\r\n" +
            "Content-Type: text/csv\r\n\r\n" +
            "a,b\r\n" +
            "--xb--\r\n"
    c := client(uri)
    c.reqHeaders["Content-Type"] = "multipart/form-data; boundary=xb"
    c.postStr(body)
    code := c.resCode
    c.close
    return code
  }

  private Void postForm(Str:Str form, |HelixArgs args| f)
  {
    verifyPost(`/args/form`, form, [:], "ok")
    f(TestController.argsRef.val)
  }
}