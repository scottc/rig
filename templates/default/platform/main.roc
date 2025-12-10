platform ""
    requires {} { main! : List(Str) => Try({}, [Exit(I32)]) }
    exposes [
        Client,
        File,
        Server,
        Stderr,
        #Stdin,
        Stdout,
    ]
    packages {}
    provides { main_for_host! : "main_for_host" }
    targets: {
        files: "targets/",
        exe: {
            x64musl: ["crt1.o", "libhost.a", app, "libc.a"],
            #x64mac: ["libhost.a", app],
            #arm64mac: ["libhost.a", app],
            #arm64musl: ["crt1.o", "libhost.a", app, "libc.a"],
            #x64win: ["host.lib", app],
            #arm64win: ["host.lib", app],
        }
    }

import Client
import File
import Server
import Stderr
# import Stdin
import Stdout

main_for_host! : List(Str) => I32
main_for_host! = |args| {
    result = main!(args)
    match result {
        Ok({}) => 0
        Err(Exit(code)) => code
    }
}
