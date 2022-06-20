//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   18 Jun 2022  Andy Frank  Creation
//

using concurrent
using fanbars

**
** TemplateCache caches compiled `Fanbars` templates for `HelixMod`.
**
internal const class TemplateCache
{
  ** Return the template for given 'qname', where qname is
  ** '{pod}::{basename}`.  If template not found, then throws
  ** `ArgErr` or return 'null' if 'checked' is 'false'.
  Fanbars? get(Str qname, Bool checked := true)
  {
    // check cache or update cache
    fanbars := map[qname]
    if (fanbars == null)
    {
      // resolve qname to file
      File? file
      try
      {
        i := qname.index("::") ?: throw Err()
        p := qname[0..<i]
        b := qname[i+2..-1]
        file = Pod.find(p).file(`/fbs/${b}.fbs`, false)
      }
      catch (Err err) throw ArgErr("Invalid qname '${qname}'")

      // compile and cache
      if (file != null) map[qname] = fanbars = Fanbars.compile(file)
    }

    // return or throw
    if (fanbars == null && checked) throw ArgErr("Template not found '${qname}'")
    return fanbars
  }

  private const ConcurrentMap map := ConcurrentMap()
}
