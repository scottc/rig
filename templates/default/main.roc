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
        resp(200, "OK",
            [
                header("Cache-Control", "no-store"),
            ],
            html([
                tag("html", [], [
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

# A HTTP response of any mime type
resp : U32, Str, List(Str), Str -> Str
resp =
    |status_code, status_message, headers, body|
    "${status(status_code, status_message)}\r\n${Str.join_with(headers, "\r\n")}\r\n\r\n${body}"

# The http status
status : U32, Str -> Str
status = |s, m| "HTTP/1.1 ${U32.to_str(s)} ${m}"

# A HTTP header.
header : Str, Str -> Str
header = |k, v| "${k}: ${v}"

# A HTML document
html : List(Str) -> Str
html = |tags| "${doctype}\r\n${Str.join_with(tags, "")}"

# The HTML 5 DOCTYPE
doctype : Str
doctype = "<!DOCTYPE html>"

# An XML tag... for example, HTML or SVG tag.
tag : Str, List(Str), List(Str) -> Str
tag = |t, attrs, children| "<${t} ${Str.join_with(attrs, " ")}>${Str.join_with(children, "")}</${t}>"
