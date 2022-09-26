//
// Copyright (c) 2022, Novant LLC
// All Rights Reserved
//
// History:
//   26 Sep 2022  Andy Frank  Creation
//

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
    map := Str:Str[:].addAll(routeArgs)
    map.addAll(req.uri.query)
    if (req.form != null) map.addAll(req.form)
    return HelixArgs(map)
  }

  ** Private ctor.
  private new make(Str:Str map) { this.map = map }

  ** Get a required arg as 'Int' or throw error.
  Int reqInt(Str name)
  {
    v := reqStr(name)
    i := v.toInt(10, false) ?: throw ArgErr("invalid value '${v}'")
    return i
  }

  ** Get a required arg as 'Str' or throw error.
  Str reqStr(Str name)
  {
    v := map[name]
    if (v == null) throw ArgErr("missing required argument '$name'")
    return v
  }

  ** Get an optional arg as 'Str' or 'null' if not found.
  Str? optStr(Str name) { map[name] }

  ** Get an optional arg as 'Int' or 'null' if not found.
  ** Throws 'ArgErr' if value exists but invalid.
  Int? optInt(Str name)
  {
    v := optStr(name)
    if (v == null) return null
    return v.toInt(10, false) ?: throw ArgErr("invalid value '${v}'")
  }

  override Str toStr() { map.toStr }

  internal static const HelixArgs defVal := HelixArgs([:])

  private const Str:Str map
}