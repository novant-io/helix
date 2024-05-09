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
  once BrowserAgent? browser()
  {
    // short-circuit if no products
    if (products.isEmpty) return null

    UaProduct? v := null  // Version/xx
    UaProduct? s := null  // Safari/xx
    UaProduct? c := null  // Chrome/xx
    UaProduct? f := null  // Firefox/xx

    // iterate products to find matrix
    products.each |p|
    {
      switch (p.name)
      {
        case "Version": v = p
        case "Safari":  s = p
        case "Chrome":  c = p
        case "Firefox": f = p
      }
    }

    // map to browser
    if (c != null) return BrowserAgent { it.name="Chrome";  it.ver=c.ver }
    if (f != null) return BrowserAgent { it.name="Firefox"; it.ver=f.ver }
    if (s != null && v != null) return BrowserAgent { it.name="Safari"; it.ver=v.ver }

    // no match found
    return null
  }

  ** Original user-agent string for this instance.
  override const Str toStr

  ** Parse a 'UserAgent' instance from string value.
  static new fromStr(Str s, Bool checked := true)
  {
    // TODO FIXIT: this is pretty naiave and won't handle
    // tons of edge cases and unallowed chars; so come back
    // up and beef up at some point
    try
    {
      prods := UaProduct[,]
      in := s.in

      nbuf := StrBuf()
      vbuf := StrBuf()
      cbuf := StrBuf()

      ch := in.readChar
      while (ch != null)
      {
        // reset bufs
        nbuf.clear
        vbuf.clear
        cbuf.clear

        // eat leading whitespace
        while (ch == ' ') { ch = in.readChar }

        // read product name
        while (ch != '/' && ch != ' ' && ch != null)
        {
          nbuf.addChar(ch)
          ch = in.readChar
        }

        // read version
        if (ch == '/')
        {
          ch = in.readChar  // eat /
          while (ch != ' ' && ch != null)
          {
            vbuf.addChar(ch)
            ch = in.readChar
          }
        }

        // eat whitespace
        while (ch == ' ') { ch = in.readChar }

        // read comment
        if (ch == '(')
        {
          ch = in.readChar  // each (
          while (ch != ')')
          {
            if (ch == null) throw Err("Unexpected EOS")
            cbuf.addChar(ch)
            ch = in.readChar
          }
          ch = in.readChar  // each (
        }

        // add product
        if (nbuf.size > 0)
        {
          prods.add(UaProduct {
            it.name     = nbuf.toStr.trim
            it.ver      = vbuf.toStr.trimToNull
            it.comment  = cbuf.toStr.trimToNull
          })
        }
      }

      return UserAgent {
        it.toStr = s
        it.products = prods
      }
    }
    catch (Err err)
    {
      if (!checked) return null
      throw ParseErr("Invalid user agent '${s}'", err)
    }
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

  ** OS version or 'null' if unknown.
  const Str? osVer := null

  ** Device name or 'null if unknown.
  const Str? device := null

  override Str toStr()
  {
    buf := StrBuf()
    buf.add(name)
    if (ver != null) buf.addChar(' ').add(ver)
    return buf.toStr
  }
}
