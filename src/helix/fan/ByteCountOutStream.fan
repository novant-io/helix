//
// Copyright (c) 2023, Andy Frank
// Licensed under the MIT License
//
// History:
//   14 Apr 2023  Andy Frank  Creation
//

*************************************************************************
** ByteCountOutStream
*************************************************************************

**
** ByteCountOutStream monitors number of bytes written
**
internal class ByteCountOutStream : OutStream
{
  new make(OutStream out) : super(out) {}

  ** Number of bytes written to this stream.
  Int bytesWritten := 0 { private set }

  override This write(Int byte)
  {
    super.write(byte)
    bytesWritten++
    return this
  }

  override This writeBuf(Buf buf, Int n := buf.remaining)
  {
    super.writeBuf(buf, n)
    bytesWritten += n
    return this
  }
}