//
// Copyright (c) 2023, Novant LLC
// All Rights Reserved
//
// History:
//   11 Dec 2023  Andy Frank  Creation
//

using concurrent
using web
using util

**
** HelixFile wraps a `sys::File` request argument.
**
const class HelixFile
{
  ** Internal ctor.
  internal new make(Str name, File temp)
  {
    this.name = name
    this.temp = temp
  }

  ** The provided filename for this file.
  const Str name

  ** Get an `sys::Instream` instance to read file contents.
  InStream in() { temp.in }

  ** Backing temp `File` instance.
  @NoDoc const File temp
}
