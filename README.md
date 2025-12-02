# Rig

**A Roc & Zig -- Hot Module Replacement Full Stack Dev Server, CLI compiler tool & Web Framework Platform.**

An opinionated elm architecture, next.js, vite, bun like... all in 1 tool, but for [roc](https://www.roc-lang.org/) & [zig](https://ziglang.org/).

We have three main components...

- The cli tool
- The web server side platform
- The web client side platform

It's called Rig, because **R**oc & Z**ig**... an uninspired name.

## Example
```sh
# install build dependencies
# enter development environment
# provides zig in $PATH...
nix develop

# build rig from source
zig build

# add rig to $PATH temporarily, just for the current session.
# effectively an alias of: rig=./zig-out/bin/rig
export PATH="$PWD/zig-out/bin:$PATH"

# run rig
rig version
rig init default
rig dev

# delete directory ./my-roc-app/
# Destructive and irrevocable, are you sure?
rig nuke
```
```sh
info: Running rig version
info:
rig 0.1.0
├─ zig 0.15.2
└─ roc Roc compiler version debug-b934ff58

info: Running rig init default my-roc-app
info: Created Dir: ./my-roc-app
info: Copied File: ./my-roc-app/build.zig
info: Copied File: ./my-roc-app/app.roc
info: Created Dir: ./my-roc-app/public
info: Copied File: ./my-roc-app/public/index.html
info: Copied File: ./my-roc-app/public/main.wasm
info: Created Dir: ./my-roc-app/platform
info: Copied File: ./my-roc-app/platform/main.roc
info: Copied File: ./my-roc-app/platform/Stdout.roc
info: Copied File: ./my-roc-app/platform/Stderr.roc
info: Copied File: ./my-roc-app/platform/host.zig
info: Created Dir: ./my-roc-app/platform/targets
info: Created Dir: ./my-roc-app/platform/targets/x64musl
info: Copied File: ./my-roc-app/platform/targets/x64musl/libc.a
info: Copied File: ./my-roc-app/platform/targets/x64musl/crt1.o
info: Created Dir: ./my-roc-app/platform/targets/arm64musl
info: Copied File: ./my-roc-app/platform/targets/arm64musl/libc.a
info: Copied File: ./my-roc-app/platform/targets/arm64musl/crt1.o
info: Copied File: ./my-roc-app/platform/Stdin.roc
info: Copied File: ./my-roc-app/platform/ZServer.roc
info: Copied File: ./my-roc-app/build.zig.zon
info: Template installed successfully!
info: Precompiling Rig Roc Web Platform
info: zig build
info: zig build finished with .{ .Exited = 0 }
info: Precompiled Rig Roc Web Platform successfully!
info:

Now run:
  cd my-roc-app
  rig dev

info: Running rig dev
info: ./my-roc-app: roc app.roc
error: Child process /home/anon/.cache/roc/3eca598d53a2d7ebebe25a544abe4d79/temp/roc-tmp-WrNCXNTMDaI7x6IUsGyXGzMJ9ngbAJ9n/roc_run_1662736024 killed by signal: 11
error: Child process crashed with segmentation fault (SIGSEGV)
error: Platform exited with code 139
```

As you can see, `rig` is still very much a work in progress... and is not ready for use in development.

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
