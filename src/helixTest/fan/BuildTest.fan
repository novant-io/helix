//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   18 Jun 2022  Andy Frank  Creation
//

using helix
using web

**
** Test code for BuildHelixPod.
**
class BuildTest : Test
{
  Void testFbs()
  {
    verifyFile(`/fbs/test-index.fbs`)
  }

  private Void verifyFile(Uri uri)
  {
    f := this.typeof.pod.file(uri)
    verifyNotNull(f)
  }
}