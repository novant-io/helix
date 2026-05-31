//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
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
      catch (Err err)
      {
        // this bubbles up from WispReq when req has no content body;
        // trap and ignore since it is a bit of a nuisance error
        ignore := false
        if (err.msg == "Attempt to access WebReq.in with no content") ignore = true
        if (!ignore) throw IOErr("Invalid json", err)
      }
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
    t := File.createTemp("helix-", x, Env.cur.tempDir).deleteOnExit
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

  ** Return 'true' if given name exists in argument list, even
  ** if value is 'null'.  See also `hasNotNull`.
  Bool has(Str name) { map.containsKey(name) }

  ** Return 'true' if given name exists in argument list and
  ** the value is non-null. See also `has`
  Bool hasNotNull(Str name) { map[name] != null }

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

  ** Get a required arg as 'Duration' or throw error.
  Duration reqDuration(Str name)
  {
    optDuration(name) ?: throw ArgErr("missing required argument '$name'")
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

  ** Get a required arg as 'Str:Str?' or throw error.
  ** See `optNestedMap` for bracket notation.
  Str:Str? reqNestedMap(Str name)
  {
    optNestedMap(name) ?: throw ArgErr("missing required argument '$name'")
  }

  ** Get a required arg as 'Obj?[]' or throw error.
  ** See `optNestedList for bracket notation.
  Obj?[] reqNestedList(Str name)
  {
    optNestedList(name) ?: throw ArgErr("missing required argument '$name'")
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

  ** Get an optional arg as 'Int' or 'null' if not found, or 'null'
  ** if value is < 0. Throws 'ArgErr' if value exists but invalid.
  Int? optIntNotNeg(Str name)
  {
    v := optInt(name)
    return v < 0 ? null : v
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

  ** Get an optional arg as 'Duration' or 'null' if not found.
  Duration? optDuration(Str name)
  {
    v := optStr(name)?.trimToNull
    if (v == null) return null
    return Duration.fromStr(v, false) ?: throw ArgErr("invalid duration value '${v}'")
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

  **
  ** Get an optional arg as a 'Str:Str?' or 'null' if not found.
  ** Nested maps use a bracket notation:
  **
  **   foo[alpha]=x&foo[beta]=y
  **
  ** Where 'optNestedMap("foo")' returns '["alpha":"x", "beta":"y"]'.
  **
  ** NOTE: all values are normalized to 'Str' types. If pulling
  ** from JSON content, the value will be converted to aa 'Str'
  ** for consistency.
  **
  [Str:Str]? optNestedMap(Str name)
  {
    // check for JSON first
    json := map[name]
    if (json != null)
    {
      if (json isnot Map) throw ArgErr("invalid nested map value '${name}'")
      res := Str:Str[:]
      (json as Map).each |v,k| {
        if (v != null) res[k] = v.toStr
      }
      return res
    }

    // else assume bracket notation
    prefix := "${name}["
    res    := Str:Str[:]
    found := false
    map.each |v, k|
    {
      if (!k.startsWith(prefix)) return
      if (!k.endsWith("]")) throw ArgErr("invalid nested key '${k}'")
      inner := k[prefix.size..-2]
      if (inner.contains("[") || inner.contains("]"))
        throw ArgErr("nested map does not support deeper nesting: '${k}'")
      res.add(inner, v.toStr)
      found = true
    }
    return found ? res : null
  }

  **
  ** Get an optional arg as a 'Obj?[]' or 'null' if not found.
  ** Nested lists use a bracket notation:
  **
  **   foo[0]=x&foo[1]=y        // list of scalars
  **   bar[0][k]=v&bar[1][k]=w  // list of maps
  **
  ** Where 'optNestedList("foo")' returns '["x","y"]'
  ** Where 'optNestedList("bar")' returns '[["k":"v"], ["k":"w"]]'
  **
  ** NOTE: all values are normalized to 'Str' types. If pulling
  ** from JSON content, the value will be converted to aa 'Str'
  ** for consistency.
  **
  Obj[]? optNestedList(Str name)
  {
    // check for JSON first
    if (map[name] != null)
    {
      // check tyoe
      json := map[name] as List
      if (json == null) throw ArgErr("invalid nested list value '${name}'")

      // short-circuit if empty
      if (json.isEmpty) return Obj[]#.emptyList

      isMap := json.first is Map
      res   := Obj[,] { it.capacity = json.size }
      json.each |item,i|
      {
        if (isMap)
        {
          if (item isnot Map) throw ArgErr("nested list '${name}' has mixed scalar/map elements at [${i}]")
          row := Str:Str[:]
          (item as Map).each |v, k| { if (v != null) row[k.toStr] = v.toStr }
          res.add(row)
        }
        else
        {
          if (item is Map) throw ArgErr("nested list '${name}' has mixed scalar/map elements at [${i}]")
          if (item == null) throw ArgErr("nested list '${name}' has null scalar element at [${i}]")
          res.add(item.toStr)
        }
      }
      return res
    }

    // else assume bracket notation; classify by element shape
    prefix := "${name}["
    Int:Obj? scalars := Int:Obj?[:]
    Int:[Str:Str] groups := Int:[Str:Str][:]
    found := false
    map.each |v, k|
    {
      if (!k.startsWith(prefix)) return
      found = true
      rest := k[prefix.size..-1]  // "<i>]" or "<i>][<inner>]"
      ci := rest.index("]")
      if (ci == null) throw ArgErr("invalid nested list key '${k}'")
      idx := rest[0..<ci].toInt(10, false)
      if (idx == null || idx < 0)
        throw ArgErr("invalid nested list index in '${k}'")
      tail := rest[ci+1..-1]
      if (tail.isEmpty)
      {
        if (scalars.containsKey(idx)) throw ArgErr("duplicate nested list key '${k}'")
        scalars[idx] = v.toStr
      }
      else
      {
        if (!tail.startsWith("[") || !tail.endsWith("]"))
          throw ArgErr("invalid nested list key '${k}'")
        inner := tail[1..-2]
        if (inner.contains("[") || inner.contains("]"))
          throw ArgErr("nested list does not support deeper nesting: '${k}'")
        row := groups[idx]
        if (row == null)
        {
          row = Str:Str[:]
          groups[idx] = row
        }
        row.add(inner, v.toStr)
      }
    }
    if (!found) return null

    if (!scalars.isEmpty && !groups.isEmpty)
      throw ArgErr("nested list '${name}' has mixed scalar/map elements")

    isScalar := !scalars.isEmpty
    indices := (isScalar ? scalars.keys : groups.keys).sort
    indices.each |i, n|
    {
      if (i != n) throw ArgErr("nested list '${name}' has sparse or non-zero-based indices: ${indices}")
    }

    Obj?[] res := Obj?[,] { it.capacity = indices.size }
    indices.each |i| { res.add(isScalar ? scalars[i] : groups[i]) }
    return res
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

  ** Get a Str:Obj of arguments from this instance.
  @NoDoc Str:Obj toMap() { map }

  override Str toStr() { map.toStr }

  internal static const HelixArgs defVal := HelixArgs([:])

  private const Str:Obj map
}
