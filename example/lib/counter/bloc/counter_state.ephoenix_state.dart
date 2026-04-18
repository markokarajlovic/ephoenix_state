// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'counter_state.dart';

// **************************************************************************
// EphoenixStateGenerator
// **************************************************************************

class _CounterState extends CounterState {
  @override
  final int count;
  @override
  final bool isLoading;

  const _CounterState({this.count = 0, this.isLoading = false}) : super._();
}

mixin _$CounterState {
  int get count;
  bool get isLoading;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _$CounterState &&
        other.count == count &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode => Object.hash(count, isLoading);
}

extension CounterStateCopyWith on CounterState {
  CounterState copyWith({int? count, bool? isLoading}) {
    return CounterState(
      count: count ?? this.count,
      isLoading: isLoading ?? false,
    );
  }
}
