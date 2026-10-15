// SwiftPM requires every C target to have a public headers directory, so this
// exists to hold the one declaration that crosses the assembly/Swift boundary.
//
// Nothing includes it: `app_main` is emitted by `@c(app_main)` in
// Sources/SwiftMinimal/App.swift, and `_start` calls it by name.

int app_main(void);
