//
// Copyright (c) 2024, Andy Frank
// Licensed under the MIT License
//
// History:
//   24 May 2023  Andy Frank  Creation
//

using web

**
** RobotsController services `/robots.txt` requests.
**
internal class RobotsController : HelixController
{
  ** Block all web crawlers.
  Void block()
  {
    renderer.renderText(
      "User-agent: *
       Disallow: /")
  }
}