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
