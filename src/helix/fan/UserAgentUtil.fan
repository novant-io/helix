//
// Copyright (c) 2024, Andy Frank
// Licensed under the MIT License
//
// History:
//   8 May 2024  Andy Frank  Creation
//


*************************************************************************
** UaBrowserParser
*************************************************************************

@Js internal class UaBrowserParser
{
  static BrowserAgent? parse(UserAgent ua)
  {
    // short-circuit if no products
    if (ua.products.isEmpty) return null

    UaProduct? m := null  // Mozilla/5.0
    UaProduct? v := null  // Version/xx
    UaProduct? s := null  // Safari/xx
    UaProduct? c := null  // Chrome/xx
    UaProduct? f := null  // Firefox/xx
    UaProduct? e := null  // Edg/xx

    // iterate products to find matrix
    ua.products.each |p|
    {
      switch (p.name)
      {
        case "Mozilla": m = p
        case "Version": v = p
        case "Safari":  s = p
        case "Chrome":  c = p
        case "Firefox": f = p
        case "Edg":     e = p
      }
    }

    // must have mozilla/5.0 to match anything
    if (m == null) return null

    // TODO: really bad; but test first char for perfomrance
    // os/device
    Str? os
    switch (m.comment?.getSafe(0))
    {
      case 'M': os = "macOS"
      case 'i': os = "iOS"
      case 'W': os = "Windows"
    }

    // edge
    if (e != null)
    {
      return BrowserAgent {
        it.name = "Edge"
        it.ver  = e.ver
        it.os   = os
      }
    }

    // chrome
    if (c != null)
    {
      return BrowserAgent {
        it.name = c.name
        it.ver  = c.ver
        it.os   = os
      }
    }

    // firefox
    if (f != null)
    {
      return BrowserAgent {
        it.name = f.name
        it.ver  = f.ver
        it.os   = os
      }
    }

    // safari
    if (s != null && v != null)
    {
      return BrowserAgent {
        it.name = s.name
        it.ver  = v.ver
        it.os   = os
      }
    }

    // no match found
    return null
  }
}

*************************************************************************
** UaParser
*************************************************************************

@Js internal class UaParser
{
  ** Parse a 'UserAgent' instance from string value.
  static UserAgent? parse(Str s, Bool checked := true)
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