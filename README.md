# swift-minimal

The smallest Swift binary for linux aarch64

```sh
swift build -c release
```

## Gotchas worth knowing

- Embedded Swift's `print` takes a `StaticString` plus `terminator:` — no
  interpolation, no reflection, no `Any`.
