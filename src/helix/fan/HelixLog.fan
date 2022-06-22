//
// Copyright (c) 2022, Andy Frank
// Licensed under the MIT License
//
// History:
//   21 Jun 2022  Andy Frank  Creation
//

using concurrent

*************************************************************************
** HelixLog
*************************************************************************

internal const class HelixLog
{
  ** Trace message and optional error.
  Void trace(Str msg, Err? err := null)
  {
    actor.send([msg, err].toImmutable)
  }

  private const ActorPool pool := ActorPool { it.name="helix-log" }
  private const Actor actor := Actor(pool) |Obj obj->Obj?|
  {
    List msg := obj
    echo(msg.first)
    if (msg.getSafe(1) is Err) ((Err)msg[1]).trace
    return null
  }
}