//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   23 Jun 2022  Andy Frank  Creation
//

using web

**
** ResController services `ResRoute` requests.
**
internal class ResController : HelixController
{
  ** Service 'GET" request for file resource.
  Void get()
  {
    ResRoute r := req.stash["helix.route"]
    file := r.resolve(req.uri)
    if (file == null) sendErr(404)
    else sendFile(file)
  }
}