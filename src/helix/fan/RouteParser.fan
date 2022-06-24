//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   9 Jun 2022  Andy Frank  Creation
//

using web

**************************************************************************
** RouteParser
**************************************************************************

** RouteParser parses route patterns for `Route`.
internal const class RouteParser
{
  ** Parse given pattern into list of `RouteToken`.
  static RouteToken[] parse(Str pattern)
  {
    try
    {
      // patterns must be absolute
      if (pattern.size == 0 || pattern[0] != '/')
        throw ArgErr("Pattern must start with '/'")

      // trailing '/' not currently supported
      if (pattern.size > 1 && pattern[-1] == '/')
        throw ArgErr("Trailing '/' not supported")

      // optimize index routes
      RouteToken[] tokens := pattern == "/"
        ? RouteToken#.emptyList
        : pattern[1..-1].split('/').map |v| { RouteToken(v) }

      // check if pattern is vararg
      varIndex := tokens.findIndex |t| { t.type == RouteToken.vararg }
      if (varIndex != null && varIndex != tokens.size-1) throw Err()

      return tokens
    }
    catch (Err err)
    {
      throw ArgErr("Invalid pattern $pattern.toCode", err)
    }
  }
}

**************************************************************************
** RouteToken
**************************************************************************

** RouteToken models each path token in a URI pattern.
internal const class RouteToken
{
  ** Constructor.
  new make(Str val)
  {
    if (val[0] == '*')
    {
      this.val = val
      this.type = vararg
    }
    else if (val[0] == '{' && val[-1] == '}')
    {
      this.val  = val[1..-2]
      this.type = arg
    }
    else
    {
      this.val  = val
      this.type = literal
    }
  }

  ** Token type.
  const Int type

  ** Token value.
  const Str val

  ** Str value is "$type:$val".
  override Str toStr() { "$type:$val" }

  ** Type id for a literal token.
  static const Int literal := 0

  ** Type id for an argument token.
  static const Int arg := 1

  ** Type id for vararg token.
  static const Int vararg := 2
}