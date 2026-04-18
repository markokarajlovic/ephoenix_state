/// Marks a class for `ephoenix_state_gen` code generation.
///
/// The generator creates a mixin `_$ClassNameMixin` that provides:
/// - `==` operator comparing all instance fields
/// - `hashCode` derived from all instance fields
/// - `copyWith` method
///
/// Usage:
/// ```dart
/// part 'my_class.g.dart';
///
/// @ephoenixState
/// class MyClass with _$MyClassMixin {
///   final String name;
///   const MyClass({required this.name});
/// }
/// ```
class EphoenixState {
  const EphoenixState();
}

/// Shorthand constant for [@EphoenixState].
const ephoenixState = EphoenixState();

/// Marks a field with a default value.
///
/// In `copyWith`, when this field is not provided, [value] is used
/// instead of the current field value.
///
/// Example:
/// ```dart
/// @ephoenixState
/// class CounterState with _$CounterStateMixin {
///   final int count;
///   @Default(0)
///   final int step;
///
///   const CounterState({required this.count, this.step = 0});
/// }
///
/// // state.copyWith() => CounterState(count: state.count, step: 0)
/// // state.copyWith(step: 5) => CounterState(count: state.count, step: 5)
/// ```
class Default {
  /// The default value for this field.
  final Object? value;

  const Default(this.value);
}

/// Sets the value used in `copyWith` when a field is not provided.
///
/// Unlike [Default], this annotation only affects `copyWith` behaviour and
/// does not imply anything about the constructor's default parameter value.
///
/// Example:
/// ```dart
/// @ephoenixState
/// class LoadingState with _$LoadingStateMixin {
///   final String data;
///   @DefaultCopyWith(false)
///   final bool isLoading;
///
///   const LoadingState({required this.data, this.isLoading = false});
/// }
///
/// // state.copyWith() => LoadingState(data: state.data, isLoading: false)
/// // state.copyWith(isLoading: true) => LoadingState(data: state.data, isLoading: true)
/// ```
class DefaultCopyWith {
  /// The value to substitute in `copyWith` when this field is not provided.
  final Object? value;

  const DefaultCopyWith(this.value);
}

/// Sentinel used internally by generated `copyWith` methods.
///
/// This lets the generator distinguish "caller did not pass this nullable field"
/// from "caller explicitly passed `null`".
class EphoenixUndefined {
  const EphoenixUndefined();
}

/// @nodoc
const ephoenixUndefined = EphoenixUndefined();
