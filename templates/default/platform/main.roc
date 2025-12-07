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
