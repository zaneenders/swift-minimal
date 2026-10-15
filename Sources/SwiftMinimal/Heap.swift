// The allocator real `String` needs.
//
// Embedded Swift lowers every heap allocation to two C calls: `posix_memalign`
// to allocate and `free` to release. On a hosted target glibc answers them;
// under `-static -nostdlib` there is no glibc, so they fall to us. Backing
// those two symbols is the entire difference between `Text` and `String`.
//
// This is a bump allocator on top of `brk(2)`: the heap grows in whole pages
// as the program asks, allocations are carved off the end, and `free` is a
// no-op. That is honest for a short-lived program — a long-running one that
// churns strings would exhaust the heap and needs a free list here instead.

// Provided by Bootstrap/start-aarch64-linux.S.
@_extern(c, "sys_brk")
private func brk(_ address: UInt) -> UInt

// Rather than a fixed reserve, we ask the kernel for more; one page at a time
// would mean a syscall per string, so grow in chunks.
private let chunkSize = 16 * 1024

// `unsafe` because the allocator is process-global mutable state by nature.
// This program is single-threaded and never yields, so there is nothing to
// synchronise against — and Embedded Swift ships no `Mutex` to lock with.
nonisolated(unsafe) private var heapStart: UInt = 0
nonisolated(unsafe) private var heapEnd: UInt = 0 // current program break
nonisolated(unsafe) private var nextFree: UInt = 0

/// Bytes carved out of the heap so far. Monotonic: `free` never gives any back.
public func heapBytesUsed() -> Int {
    Int(nextFree - heapStart)
}

private func reserve(_ bytes: Int) -> UnsafeMutableRawPointer? {
    if heapEnd == 0 {
        heapStart = brk(0)
        heapEnd = heapStart
        nextFree = heapStart
    }

    let end = nextFree + UInt(bytes)
    if end > heapEnd {
        let wanted = (end - heapEnd + UInt(chunkSize) - 1) / UInt(chunkSize) * UInt(chunkSize)
        let grown = brk(heapEnd + wanted)
        // brk leaves the break unchanged when the kernel refuses to grow.
        guard grown >= heapEnd + wanted else { return nil }
        heapEnd = grown
    }

    let pointer = UnsafeMutableRawPointer(bitPattern: nextFree)
    nextFree = end
    return pointer
}

@c(posix_memalign)
public func posixMemalign(
    _ out: UnsafeMutablePointer<UnsafeMutableRawPointer?>?, _ alignment: Int, _ size: Int
) -> Int32 {
    // The runtime only ever asks for a power-of-two alignment; anything else is
    // a caller bug, so report EINVAL rather than guess.
    guard let out, alignment > 0, alignment & (alignment - 1) == 0 else {
        return 22 /* EINVAL */
    }

    // Reserve slack so the bump pointer can be rounded up to `alignment`.
    guard let base = reserve(size + alignment - 1) else {
        out.pointee = nil
        return 12 /* ENOMEM */
    }

    let address = (UInt(bitPattern: base) + UInt(alignment) - 1) & ~(UInt(alignment) - 1)
    out.pointee = UnsafeMutableRawPointer(bitPattern: address)
    return 0
}

@c(free)
public func freePointer(_ pointer: UnsafeMutableRawPointer?) {
    // Bump allocator: memory is reclaimed only when the process exits.
}
