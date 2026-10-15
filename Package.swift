// swift-tools-version: 6.4
import PackageDescription

// Embedded Swift: no runtime, no libc, whole-module only.
//
// -disable-stack-protector saves us from having to define __stack_chk_guard and
// __stack_chk_fail. -mno-outline-atomics stops the Linux backend emitting
// __aarch64_* LSE helpers from compiler-rt, which we do not link.
//
// -gnone is about size, not debugging. SwiftPM always passes -g, and the
// frontend answers by emitting unwind tables for every function in the
// embedded runtime: ~1.3 KB of .eh_frame for code that can never unwind, which
// --gc-sections cannot remove because the functions it describes are live. The
// driver appends its own -g before our -Xfrontend flags, so this wins.
let embedded: [String] = [
    "-enable-experimental-feature", "Embedded",
    "-wmo",
    "-Xfrontend", "-disable-stack-protector",
    "-Xfrontend", "-gnone",
    "-Xcc", "-mno-outline-atomics",
]

// SwiftPM applies `swiftSettings` to compile jobs and `linkerSettings` to the
// link job, and the link job needs the Embedded feature too: without it the
// driver appends -lswiftCore and we are back to a dynamically linked binary.
//
// -nostdlib drops crt0 and libc, so `Bootstrap` has to supply the platform.
// -static matters for a subtle reason: ld.lld adds a PT_INTERP for
// /lib/ld-linux-aarch64.so.1 to anything it links that is not static, and the
// kernel then hands our freestanding ET_EXEC to the dynamic loader, which
// segfaults. (Swift's driver rejects a bare `-static` here, hence -Xclang-linker.)
let freestanding: [String] = [
    "-enable-experimental-feature", "Embedded",
    "-Xclang-linker", "-nostdlib",
    "-Xclang-linker", "-static",
    "-Xclang-linker", "-fuse-ld=lld",
    "-Xclang-linker", "-Qunused-arguments",
    "-Xlinker", "-e", "-Xlinker", "_start",
    "-Xlinker", "--gc-sections",
    "-Xlinker", "-s",
]

let package = Package(
    name: "swift-minimal",
    products: [
        .executable(name: "swift-minimal", targets: ["SwiftMinimal"])
    ],
    targets: [
        .executableTarget(
            name: "SwiftMinimal",
            dependencies: ["Bootstrap"],
            swiftSettings: [.unsafeFlags(embedded)],
            linkerSettings: [.unsafeFlags(freestanding)]
        ),
        .target(name: "Bootstrap"),
    ]
)
