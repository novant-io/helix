//
// Copyright (c) 2022, Novant LLC
// All Rights Reserved
//
// History:
//   26 Sep 2022  Andy Frank  Creation
//

using concurrent
using web

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
  **
  ** Where 'key' may not exist more than once.
  **
  internal static new makeReq(WebReq req, Str:Str routeArgs)
  {
    map := Str:Obj[:]
    map.addAll(routeArgs)
    map.addAll(req.uri.query)
    if (req.form != null) map.addAll(req.form)
    if (req.headers["Content-Type"]?.contains("multipart/form-data") == true)
    {
      req.parseMultiPartForm |k,in,h| {
        map.add(k, parsePart(h, in))
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
    t := File.createTemp("helix-", x, Env.cur.tempDir)
    o := t.out; in.pipe(o); o.sync.close
    return t
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
    i := v.toInt(10, false) ?: throw ArgErr("invalid value '${v}'")
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

  ** Get a required arg as 'Date' or throw error.
  Date reqDate(Str name)
  {
    v := reqStr(name)
    d := Date.fromStr(v, false) ?: throw ArgErr("invalid valud '${v}'")
    return d
  }

  ** Get a required file arg as 'InStream' or throw error.
  File reqFile(Str name)
  {
    v := req(name)
    if (v isnot File) throw ArgErr("invalid value '${v}'")
    return v
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
    v := optStr(name)
    if (v == null) return null
    return v.toInt(10, false) ?: throw ArgErr("invalid value '${v}'")
  }

  ** Get an optional arg as 'Date' or 'null' if not found;
  Date? optDate(Str name)
  {
    v := optStr(name)
    if (v == null) return null
    return Date.fromStr(v, false) ?: throw ArgErr("invalid valud '${v}'")
  }

  ** Get an optional file arg as 'InStream' or 'null' if not found.
  ** Throws 'ArgErr' if value exists but invalid.
  File? optFile(Str name)
  {
    v :=  map[name]
    if (v == null) return null
    if (v isnot File) throw ArgErr("invalid value '${v}'")
    return v
  }

  override Str toStr() { map.toStr }

  internal static const HelixArgs defVal := HelixArgs([:])

  private const Str:Obj map
}
