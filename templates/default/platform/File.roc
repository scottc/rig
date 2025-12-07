FilePath : Str

File := [].{
    # TODO:
    # serve! : ((Str -> Str)) -> {}
    readFile! : Str -> Str # Result(Str, FileError)
    writeFile! : Str, Str -> Str
    readDir! : Str -> Str # Result(List(Str), FileError)
}
