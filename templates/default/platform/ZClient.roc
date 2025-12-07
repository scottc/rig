HttpMethod : Str # [ "GET", "POST" ]
HttpBody : Str
HttpHeaders : Str # List({ name: Str, value: Str })
HttpUri : Str

ZClient := [].{
    fetch! : Str, Str, Str, Str -> Str
}
