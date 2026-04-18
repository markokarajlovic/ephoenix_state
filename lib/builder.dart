import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/ephoenix_state_generator.dart';

/// Entry point registered in `build.yaml`.
Builder ephoenixStateBuilder(BuilderOptions options) =>
    PartBuilder(
      [EphoenixStateGenerator()],
      '.ephoenix_state.dart',
    );
