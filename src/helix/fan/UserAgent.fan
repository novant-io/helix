//
// Copyright (c) 2024, Andy Frank
// Licensed under the MIT License
//
// History:
//   7 May 2024  Andy Frank  Creation
//

*************************************************************************
** UserAgent
*************************************************************************

** UserAgent parses and models a user-agent string.
@Js const class UserAgent
{
  ** It-block ctor.
  new make(|This| f) { f(this) }

  ** List of products for this user agent.
  const UaProduct[] products

  ** Browser agent if this user agent represents a web browser,
  ** or 'null' if not applicable.
  once BrowserAgent? browser() { UaBrowserParser.parse(this) }

  ** Original user-agent string for this instance.
  override const Str toStr

  ** Parse a 'UserAgent' instance from string value.
  static new fromStr(Str s, Bool checked := true)
  {
    UaParser.parse(s, checked)
  }
}

*************************************************************************
** UaProduct
*************************************************************************

** UaProduct
@Js const class UaProduct
{
  ** It-block ctor.
  new make(|This| f) { f(this) }

  ** Name of this product.
  const Str name

  ** Version number of this product, or 'null' for none.
  const Str? ver := null

  ** Comment trailing this product, or 'null' for none.
  const Str? comment := null

  override Str toStr()
  {
    buf := StrBuf().add(name)
    if (ver != null) buf.addChar('/').add(ver)
    if (comment != null) buf.addChar(' ').addChar('(').add(comment).addChar(')')
    return buf.toStr
  }
}

*************************************************************************
** BrowserAgent
*************************************************************************

@Js const class BrowserAgent
{
  ** It-block ctor.
  new make(|This| f) { f(this) }

  ** Browser name.
  const Str name

  ** Browser verion or 'null' if unknnown.
  const Str? ver := null

  ** OS name or 'null' if unknown.
  const Str? os := null

  // TODO?
  // ** OS version or 'null' if unknown.
  // const Str? osVer := null

  // TODO?
  // ** Device name or 'null if unknown.
  // const Str? device := null

  override Str toStr()
  {
    buf := StrBuf()
    buf.add(name)
    if (ver != null) buf.addChar(' ').add(ver)
    if (os  != null) buf.add(" on ").add(os)
    return buf.toStr
  }
}
