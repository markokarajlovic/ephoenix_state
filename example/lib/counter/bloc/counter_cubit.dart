import 'package:bloc/bloc.dart';

import 'counter_state.dart';

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(const CounterState());

  void increment() {
    emit(state.copyWith(count: state.count + 1, isLoading: true));
  }

  void decrement() {
    // isLoading resets to false automatically via @DefaultCopyWith(false)
    emit(state.copyWith(count: state.count - 1));
  }
}
