# Rig

**A Roc & Zig -- Hot Module Replacement Full Stack Dev Server, CLI compiler tool & Web Framework Platform.**

An opinionated elm architecture, next.js, vite, bun like... all in 1 tool, but for [roc](https://www.roc-lang.org/) & [zig](https://ziglang.org/).

We have three main components...

- The cli tool
- The web server side platform
- The web client side platform

It's called Rig, because **R**oc & Z**ig**... an uninspired name.

## HTTP Server Example
![Logo](images/screenshot.png)

```roc
app [main!] {
    pf: platform "./platform/main.roc"
}

import pf.Stdout
import pf.ZServer

main! : List(Str) => Try({}, [Exit(I32)])
main! = |args| {
    _a = args

    Stdout.line!("Hello World!")

    ZServer.serve!(
        http_resp(1.1, 200, "OK",
            [
                http_header("Cache-Control", "no-store"),
                http_header("Content-Type", "text/html; charset=utf-8"),
            ],
            html([
                tag("html", [], [
                    tag("head", [], [
                        tag("title", [], ["Hello World!"])
                    ]),
                    tag("body", ["style='background: black;'"], [
                        tag("h1", ["style='color: yellow;'"], ["Hello"]),
                        tag("a", ["href='#'", "style='color: orange;'"], ["World!"])
                    ])
                ])
            ])
        )
    )

    Ok({})
}

# A HTTP response
http_resp : Dec, U32, Str, List(Str), Str -> Str
http_resp =
    |http_version, status_code, status_message, headers, body|
    "HTTP/${Dec.to_str(http_version)} ${U32.to_str(status_code)} ${status_message}\r\n${Str.join_with(headers, "\r\n")}\r\n\r\n${body}"

# A HTTP header
http_header : Str, Str -> Str
http_header = |key, value| "${key}: ${value}"

# The HTML 5 DOCTYPE
doctype : Str
doctype = "<!DOCTYPE html>"

# A HTML document
html : List(Str) -> Str
html = |tags| "${doctype}\r\n${Str.join_with(tags, "")}"

# An XML tag... for example, HTML or SVG tag.
tag : Str, List(Str), List(Str) -> Str
tag = |t, attrs, children| "<${t} ${Str.join_with(attrs, " ")}>${Str.join_with(children, "")}</${t}>"
```

## Contributing

...

## CLI Tool Features

- [x] Open Source, undecided on license.
- [x] Written in Zig
- [x] Projecting Scaffolding (`rig init`, Includes Web Server Platform source, so you can modify both the roc app, and the underlying platform. Depends on `zig` and `roc` being in the `$PATH`, as we want to allow you to own your own toolchain versions, think of it like a `package.json` `devDependencies`, we just merely facilitate the process.  Instead we'll supply a `flake.nix` and `flake.lock` files, so you can easily setup a reproduceable dev environment with pinned versions.)
- [x] Precompiles Web Server Platform
- [x] Prints rig, zig & roc versions. (`rig version`)
- [ ] File Watcher (`rig dev`)
- [ ] On zig/roc platform/app source modified, it recompiles the platform, and reloads it, without dropping connections, and persisting server state, for server side hot module replacement.

- [x] Linux
- [ ] Mac (not tested...)
- [ ] Windows (not tested...)

## Web Server Platform Features

- [x] Open Source, undecided on license.
- [x] Written in Zig
- [x] It has a Server.serve!() roc platform function.
- [ ] It serves files over http...
- [ ] It implements web sockets...
- [ ] It sends file modified websocket event, for client side hot module replacement...
- [ ] It ...
- [x] Linux
- [ ] Mac (not tested...)
- [ ] Windows (not tested...)

## Web Client Platform Features

- [x] Open Source, undecided on license.
- [x] Written in Zig
- [ ] Compiles to WASM
- [ ] It accepts websocket hot reload event...
- [ ] It reloads the app...
- [ ] It persists the client side app state...
- [ ] It writes to the DOM...
- [ ] It has routing...
- [ ] It has bundling and code splitting...
- [ ] It lazy loads bundles on demand...
- [x] Modern Chromium Based Browsers

## Inspiration -- Prior art...

In no particular order...

- [elm](https://elm-lang.org/)
- [bun](https://bun.com/)
- [vite](https://vite.dev/)
- [kamenchunathan/galena](https://github.com/kamenchunathan/galena)
- [niclas-ahden/joy](https://github.com/niclas-ahden/joy)
- [lukewilliamboswell/roc-experiment-js-dom](https://github.com/lukewilliamboswell/roc-experiment-js-dom)
- [lukewilliamboswell/roc-platform-template-zig](https://github.com/lukewilliamboswell/roc-platform-template-zig)
- [leptos](https://leptos.dev)
- [solidjs](https://www.solidjs.com)
- [dioxus](https://dioxuslabs.com/)
