# Helix Web Framework

A lightweight web framework for [Fantom](https://fantom.org).

## Overview

Helix provides the essentials for building web applications:

- **Routing** - Map URI patterns to controller methods with support for path parameters (`/users/{id}`) and wildcards (`/files/*`)
- **Request Handling** - Unified access to route params, query strings, form data, file uploads, and JSON bodies with type-safe accessors
- **Response Rendering** - Output text, JSON, HTML, or Fanbars templates with automatic gzip compression
- **Static Resources** - Serve files from the filesystem or bundled pod resources
- **Lifecycle Hooks** - Run code before/after requests for auth, logging, or cleanup

## Quick Example

```fantom
// Define a controller
class UserController : HelixController
{
  Void list()
  {
    renderer.renderJson(["users": users])
  }

  Void show()
  {
    id := args.reqInt("id")
    renderer.renderJson(users.find |u| { u["id"] == id })
  }
}

// Configure routes in your module
const class MyMod : HelixMod
{
  new make()
  {
    this.router = Router
    {
      routes =
      [
        Route("/users",      "GET", UserController#list),
        Route("/users/{id}", "GET", UserController#show),
      ]
    }
  }
}
```
