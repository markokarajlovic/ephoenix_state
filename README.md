# ephoenix_state

Lightweight code generation for immutable Dart state classes.

`ephoenix_state` generates value-style behavior for your state models:
- `==` and `hashCode`
- `copyWith`
- boilerplate for an implementation class when using an abstract `factory` pattern

It is designed for simple state objects where you want a small API surface and generated ergonomics.

## Features

- Generate `==` and `hashCode` from constructor fields.
- Generate `copyWith` with nullable-field support.
- Support default values through:
  - `@Default(...)`
  - `@DefaultCopyWith(...)`
- Support two authoring styles:
  - abstract class + `factory` constructor pattern
  - direct field class pattern

## Getting started

Add dependencies:

```yaml
dependencies:
  ephoenix_state: ^0.1.0

dev_dependencies:
  build_runner: ^2.13.1
```

Then run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Usage

Create a state file and add a `part` directive ending in `.ephoenix_state.dart`:

```dart
import 'package:ephoenix_state/ephoenix_state.dart';

part 'counter_state.ephoenix_state.dart';

@ephoenixState
abstract class CounterState with _$CounterState {
  const CounterState._();

  const factory CounterState({
    @Default(0) int count,
    @DefaultCopyWith(false) bool isLoading,
  }) = _CounterState;
}
```

After generation, you can use:

```dart
final state = CounterState();

final next = state.copyWith(count: 1);
final loading = state.copyWith(isLoading: true);
```

### `@Default` and `@DefaultCopyWith`

- `@Default(value)`
  - sets a default value when creating a new instance if that field is not provided
  - in `copyWith`, if the field is not passed, it keeps the old value (`this.field`)

- `@DefaultCopyWith(value)`
  - in `copyWith`, if the field is not passed, it uses the annotation value

Example:

```dart
final state = CounterState(count: 5, isLoading: true);

final next = state.copyWith();
// next.count == 5 (keeps old value because of @Default)
// next.isLoading == false (uses annotation value because of @DefaultCopyWith)
```

## What gets generated

For annotated classes, `ephoenix_state` generates:
- equality (`==`) checks across fields
- `hashCode`
- `copyWith`
- for abstract/factory pattern: concrete implementation class and supporting mixin/extension

## Example

See the runnable sample in:
- `example/lib/counter/bloc/counter_state.dart`
- `example/lib/counter/bloc/counter_cubit.dart`

## Inspiration and credit

This package is **inspired by [freezed](https://pub.dev/packages/freezed)**.

Credit and thanks to the freezed project and maintainers for their excellent work and for inspiring this simplified approach.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
