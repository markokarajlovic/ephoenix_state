import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/counter_cubit.dart';
import '../bloc/counter_state.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPhoenix State + Cubit'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<CounterCubit, CounterState>(
          builder: (context, state) {
            return Column(
              children: [
                Text('Is loading: ${state.isLoading.toString()}'),
                const SizedBox(height: 32),
                Text(
                  'Count: ${state.count}',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.read<CounterCubit>().decrement(),
                      icon: const Icon(Icons.remove),
                      label: const Text('Decrement'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => context.read<CounterCubit>().increment(),
                      icon: const Icon(Icons.add),
                      label: const Text('Increment'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
