app [main!] {
    pf: platform "./platform/main.roc"
}

import pf.Stdout
import pf.ZServer

status : U32, Str -> Str
status = |s, m| "HTTP/1.1 ${U32.to_str(s)} ${m}\r\n\r\n"

tag : Str, List(Str), Str -> Str
tag = |t, attrs, children| "<${t} ${Str.join_with(attrs, " ")}>${children}</${t}>"

resp : U32, Str, Str -> Str
resp = |s, m, b| "${status(s, m)}${b}"

main! : List(Str) => Try({}, [Exit(I32)])
main! = |args| {
    _a = args

    Stdout.line!("Hello World!")

    ZServer.serve!(
        resp(200, "OK",
            tag("h1", ["style='color: purple;'"], "Hello World!")
        )
    )

    Ok({})
}
