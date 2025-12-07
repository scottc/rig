FilePath : Str

File := [].{
    # TODO:
    # serve! : ((Str -> Str)) -> {}
    readFile! : Str -> Str # Result(Str, FileError)
    writeFile! : Str, Str -> {}
    readDir! : Str -> List(Str) # Result(List(Str), FileError)
}
