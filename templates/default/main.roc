app [main!] {
    pf: platform "./platform/main.roc"
}

import pf.Stdout
import pf.ZServer

main! : List(Str) => Try({}, [Exit(I32)])
main! = |args| {

    Stdout.line!("Hello from Roc App!")

    args_str = Str.join_with(args, ", ")
    Stdout.line!("Args: ${args_str}")

    body = tag("h1", ["id='asdf'", "style='color:red;'"], "Hello from Roc!")

    # TODO: pass a request handler function "Str -> Str" to Server.serve!(handleRequest)
    ZServer.serve!("HTTP/1.1 200 OK\r\n\r\n${body}")

    Ok({})
}

tag : Str, List(Str), Str -> Str
tag = |t, _attrs, children| "<${t}>${children}</${t}>"

# TODO: pass a request handler function (Str -> Str) to Server.serve!(handleRequest)
#handleRequest : Str -> Str
#handleRequest = |rawRequest|
#        """
#        HTTP/1.1 200 OK\r
#        \r
#        <h1>Hello from Roc!</h1>
#        <h2>What you requested</h2>
#        <p>${rawRequest}</p>
#        """
