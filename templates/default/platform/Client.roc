HttpMethod : Str # [ "GET", "POST" ]
HttpBody : Str
HttpHeaders : Str # List({ name: Str, value: Str })
HttpUrl : Str

Client := [].{
    fetch! : Str, Str, Str, Str -> Str # HttpMethod, HttpUrl, HttpHeaders, HttpBody -> Result(HttpResponse, NetworkError)
}
