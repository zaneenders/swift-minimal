// Console output.
//
// `print` drives the `putchar` Bootstrap provides, so nothing here needs libc.
// The stdlib's only entry point is `print(_: StaticString)`, and a
// `StaticString` cannot see an interpolated literal (it does not conform to
// `ExpressibleByStringInterpolation`). Declaring `print` in this module shadows
// the stdlib one, so the whole program prints through `String` — and, for
// strings too long to be stored inline, through the allocator in Heap.swift.

@_extern(c, "putchar")
func putchar(_ c: Int32) -> Int32

// Both overloads are load-bearing. The `StaticString` one carries the stdlib's
// exact signature, which is what makes the shadowing happen, and it keeps
// `print(someStaticString)` working. `@_disfavoredOverload` then steers plain
// literals — `print("hi")` could be either type — to `String` rather than
// reporting an ambiguity against the overload it just replaced.
func print(_ text: String, terminator: StaticString = "\n") {
    for byte in text.utf8 {
        _ = putchar(Int32(byte))
    }
    write(utf8: terminator)
}

@_disfavoredOverload
func print(_ string: StaticString, terminator: StaticString = "\n") {
    write(utf8: string)
    write(utf8: terminator)
}

private func write(utf8 value: StaticString) {
    value.withUTF8Buffer { buffer in
        for byte in buffer {
            _ = putchar(Int32(byte))
        }
    }
}
