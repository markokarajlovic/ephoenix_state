## 1.0.2

* Updated `analyzer` constraint to `>=10.0.0 <13.0.0` — raises lower bound to 10.0.0 where `isOriginDeclaration` was introduced, and raises upper bound to support the latest stable (12.x).

## 1.0.1

* Added `ephoenix_state <name>` CLI command that scaffolds a new state file with the correct boilerplate in the current directory.
* Fixed deprecated `getDisplayString(withNullability: true)` calls — parameter removed as only NNBD mode is supported.
* Fixed deprecated `isSynthetic` usage on `FieldElement` — replaced with `isOriginDeclaration` per analyzer 10.x API.
* Replaced `package:flutter_lints/flutter.yaml` with `package:lints/recommended.yaml` in `analysis_options.yaml` (package is Dart-only, not Flutter).


## 1.0.0

* Initial release of `ephoenix_state`.
* Added `@ephoenixState` annotation with code generation for value-based `==`, `hashCode`, and `copyWith`.
* Added support for defaults via `@Default` and `@DefaultCopyWith`.
* Added support for abstract factory and legacy field class patterns.
