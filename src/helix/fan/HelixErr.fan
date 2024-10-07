//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   9 Jun 2022  Andy Frank  Creation
//

using web

**
** HelixErr is thrown while servicing a request from `HelixMod`.
**
const class HelixErr : Err
{
  ** Constructor.
  new make(Int errCode, Err? cause := null)
    : super("$errCode " + WebRes.statusMsg[errCode], cause)
  {
    this.errCode = errCode
  }

  ** Construct a new HelixErr with given error code and JSON response.
  new makeJson(Int errCode, Str:Obj? errJson, Err? cause := null)
    : super.make("$errCode " + WebRes.statusMsg[errCode], cause)
  {
    this.errCode = errCode
    this.errJson = errJson
  }

  ** Construct a HelixErr that will redirect to a given URI.
  ** This will always be a 303 temporary redirect.
  new makeRedirect(Uri uri)
    : super.make("redirect", null)
  {
    this.errCode = 303
    this.redirectUri = uri
  }

  ** HTTP error code for this error.
  const Int errCode

  ** JSON error response or 'null' if not applicable.
  const [Str:Obj?]? errJson := null

  ** URI
  const Uri? redirectUri
}
