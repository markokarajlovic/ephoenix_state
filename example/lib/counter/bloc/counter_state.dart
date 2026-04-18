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
