app [main!] { pf: platform "./platform/main.roc" }

import pf.Stdout
import pf.ZServer

main! : List(Str) => Try({}, [Exit(I32)])
main! = |args| {

    Stdout.line!("Hello from Roc App!")

    args_str = Str.join_with(args, ", ")
    Stdout.line!("Args: ${args_str}")

    ZServer.serve!()

    Ok({})
}
