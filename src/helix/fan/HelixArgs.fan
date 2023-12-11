//
// Copyright (c) 2022, Novant LLC
// All Rights Reserved
//
// History:
//   26 Sep 2022  Andy Frank  Creation
//

using concurrent
using web
using util

**
** HelixArgs captures arguments to a Controller request, which may
** be composed of URI route params, URI query params, or form values.
**
const class HelixArgs
{
  **
  ** Create new args which is a union composed of:
  **   - URI route param
  **   - URI query param
  **   - Form value
  **   - JSON request content
  **
  ** Where 'key' may not exist more than once.
  **
  internal static new makeReq(WebReq req, Str:Str routeArgs)
  {
    map := Str:Obj[:]
    map.addAll(routeArgs)
    map.addAll(req.uri.query)
    // TODO FIXIT: seeing some bug on redirects where content-type header
    // is getting sent on following GET req which trips up WebReq.form; so
    // only check this if a POST
    if (req.method == "POST" && req.form != null) map.addAll(req.form)
    if (req.headers["Content-Type"]?.contains("multipart/form-data") == true)
    {
      req.parseMultiPartForm |k,in,h| {
        map.add(k, parsePart(h, in))
      }
    }
    if (req.headers["Content-Type"]?.contains("application/json") == true)
    {
      // TODO: for now we require top object to be a map type
      try
      {
        Str:Obj? m := JsonInStream(req.in).readJson
        m.each |v,k| {
          if (v != null) map.add(k, v)
        }
      }
      catch (Err err) { throw IOErr("Invalid json", err) }
    }
    return HelixArgs(map)
  }

  private static const Regex r := Regex(Str<|filename="(.*?)"|>)
  private static Obj parsePart(Str:Str headers, InStream in)
  {
    d := headers["Content-Disposition"]
    m := r.matcher(d)

    // short-circuit as str if no filename field
    if (!m.find) return in.readAllStr

    // File.createTemp requires dir to exist first
    if (!Env.cur.tempDir.exists) Env.cur.tempDir.create

    // dump contents into temp file
    f := m.group(1)
    x := f[f.indexr(".")..-1]
    t := File.createTemp("helix-", x, Env.cur.tempDir)
    o := t.out; in.pipe(o); o.sync.close

    // wrap in HelixFile
    return HelixFile(f, t)
  }

  ** Private ctor.
  private new make(Str:Obj map) { this.map = map }

  ** Cleanup after request has been serviced.
  internal Void cleanup()
  {
    // delete any temp files not moved
    map.each |v| {
      if (v is File) ((File)v).delete
    }
  }

  private Obj req(Str name)
  {
    v := map[name]
    if (v == null) throw ArgErr("missing required argument '$name'")
    return v
  }

  ** Get a required arg as 'Str' or throw error.
  Str reqStr(Str name) { req(name).toStr }

  ** Get a required arg as 'Str' where size > 1 or throw error.
  Str reqStrNotEmpty(Str name)
  {
    v := req(name).toStr
    if (v.isEmpty) throw ArgErr("argument cannot be empty '${name}'")
    return v
  }

  ** Get a required arg as 'Str[]' or throw error.
  Str[] reqStrList(Str name)
  {
    v := reqStr(name).trim
    return v.isEmpty ? Str#.emptyList : v.split(',')
  }

  ** Get a required arg as 'Int' or throw error.
  Int reqInt(Str name)
  {
    v := reqStr(name)
    i := v.toInt(10, false) ?: throw ArgErr("invalid int value '${v}'")
    return i
  }

  ** Get a required arg as 'Int[]' or throw error.
  Int[] reqIntList(Str name)
  {
    v := reqStr(name)
    try
    {
      Int[] i := v.split(',').map |s| { s.toInt }
      return i
    }
    catch (Err err) throw ArgErr("invalid value '${v}'", err)
  }

  ** Get a required arg as 'Float' or throw error.
  Float reqFloat(Str name)
  {
    v := reqStr(name)
    f := v.toFloat(false) ?: throw ArgErr("invalid float value '${v}'")
    return f
  }

  ** Get a required arg as 'Bool' or throw error.
  Bool reqBool(Str name)
  {
    v := reqStr(name)
    b := Bool.fromStr(v, false)
    if (b == null) throw ArgErr("invalid bool value '${v}'")
    return b
  }

  ** Get a required arg as 'Date' or throw error.
  Date reqDate(Str name, Str format := "YYYY-MM-DD")
  {
    v := reqStr(name)
    d := Date.fromLocale(v, format, false) ?: throw ArgErr("invalid date value '${v}'")
    return d
  }

  ** Get a required arg as 'List' or throw error.
  List? reqList(Str name)
  {
    optList(name) ?: throw ArgErr("missing required argument '$name'")
  }

  ** Get a required arg as 'Map' or throw error.
  Map? reqMap(Str name)
  {
    optMap(name) ?: throw ArgErr("missing required argument '$name'")
  }

  ** Get a required file arg as 'File' or throw error.
  HelixFile reqFile(Str name)
  {
    // TODO FIXIT: cleanup 'req' checks so logic is DRY in optXxx
    optFile(name) ?: throw ArgErr("missing required argument '$name'")
  }

  ** Get a required file content as 'Str' or throw error. This method
  ** differs from 'reqFile(name).in.readAllStr' in that it will attempt
  ** to sniff UTF BOM encoding makers.
  Str reqFileStr(Str name)
  {
    // TODO FIXIT: cleanup 'req' checks so logic is DRY in optXxx
    optFileStr(name) ?: throw ArgErr("missing required argument '$name'")
  }

  ** Get an optional arg as 'Str' or 'null' if not found.
  Str? optStr(Str name) { map[name]?.toStr }

  ** Get an optional arg as 'Str[]' or 'null' if not found.
  Str[]? optStrList(Str name)
  {
    v := optStr(name)?.trim
    if (v == null) return null
    if (v.isEmpty) return Str#.emptyList
    return v.split(',')
  }

  ** Get an optional arg as 'Int' or 'null' if not found.
  ** Throws 'ArgErr' if value exists but invalid.
  Int? optInt(Str name)
  {
    v := optStr(name)?.trimToNull
    if (v == null) return null
    return v.toInt(10, false) ?: throw ArgErr("invalid int value '${v}'")
  }

  ** Get an optional arg as 'Float' or 'null' if not found.
  ** Throws 'ArgErr' if value exists but invalid.
  Float? optFloat(Str name)
  {
    v := optStr(name)?.trimToNull
    if (v == null) return null
    return v.toFloat(false) ?: throw ArgErr("invalid float value '${v}'")
  }

  ** Get an optional arg as 'Bool' or 'null' if not error.
  ** Throws 'ArgErr' if value exists but invalid.
  Bool? optBool(Str name)
  {
    v := optStr(name)?.trimToNull
    if (v == null) return null
    return Bool.fromStr(v, false) ?: throw ArgErr("invalid bool value '${v}'")
  }

  ** Get an optional arg as 'Date' or 'null' if not found.
  Date? optDate(Str name, Str format := "YYYY-MM-DD")
  {
    v := optStr(name)?.trimToNull
    if (v == null) return null
    return Date.fromLocale(v, format, false) ?: throw ArgErr("invalid date value '${v}'")
  }

  ** Get an optional arg as 'List' or 'null' if not found.
  List? optList(Str name)
  {
    v := map[name]
    if (v == null) return null
    if (v isnot List) throw ArgErr("invalid list value '${v}'")
    return v
  }

  ** Get an optional arg as 'Map' or 'null' if not found.
  Map? optMap(Str name)
  {
    v := map[name]
    if (v == null) return null
    if (v isnot Map) throw ArgErr("invalid map value '${v}'")
    return v
  }

  ** Get an optional file arg as 'File' or 'null' if not found.
  ** Throws 'ArgErr' if value exists but invalid.
  HelixFile? optFile(Str name)
  {
    v := map[name]
    if (v == null) return null
    if (v isnot HelixFile) throw ArgErr("invalid file value '${v}'")
    return v
  }

  ** Get an optional file content as 'Str' or 'null' if not found.
  ** Throws 'ArgErr' if value exists but invalid. This method differs
  ** from 'reqFile(name).in.readAllStr' in that it will attempt to
  ** sniff UTF BOM encoding makers.
  Str? optFileStr(Str name)
  {
    // short-circuit if file not found
    file := optFile(name)
    if (file == null) return null

    try
    {
      // check for BOM marker or if not reconzied, assume ASCII
      in := file.in
      switch (in.peek)
      {
        // UTF-8 - standard practice is to omit the BOM for UTF-8;
        // but MS likes to include them, so check. The default
        // charset is UTF-8; but set here for code clarity
        case 0xef:
          in.read
          if (in.read != 0xbb) throw IOErr("Invalid UTF-8 BOM")
          if (in.read != 0xbf) throw IOErr("Invalid UTF-8 BOM")
          in.charset = Charset.utf8

        // TODO: not tested
        // UTF-16 Big Endian
        case 0xfe:
          in.read
          if (in.read != 0xff) throw IOErr("Invalid UTF-16 BOM")
          in.charset = Charset.utf16BE

        // TODO: not tested
        // UTF-16 Little Endian
        case 0xff:
          in.read
          if (in.read != 0xfe) throw IOErr("Invalid UTF-16 BOM")
          in.charset = Charset.utf16LE
      }

      // encoding should be set now, so read string content
      return in.readAllStr
    }
    catch (Err err) throw ArgErr("invalid file content '${name}'", err)
  }

  ** Iterate each argument in instnace.
  Void each(|Str val, Str name| f)
  {
    map.each(f)
  }

  override Str toStr() { map.toStr }

  internal static const HelixArgs defVal := HelixArgs([:])

  private const Str:Obj map
}
