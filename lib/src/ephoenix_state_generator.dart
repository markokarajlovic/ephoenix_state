import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:ephoenix_state/ephoenix_state.dart';
import 'package:source_gen/source_gen.dart';

class EphoenixStateGenerator extends GeneratorForAnnotation<EphoenixState> {
  static final _defaultCopyWithChecker =
      TypeChecker.typeNamed(DefaultCopyWith, inPackage: 'ephoenix_state');
  static final _defaultChecker =
      TypeChecker.typeNamed(Default, inPackage: 'ephoenix_state');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@EphoenixState can only be applied to classes.',
        element: element,
      );
    }

    // Pattern: abstract class with a const factory constructor.
    //
    //   abstract class Foo with _$Foo {
    //     const Foo._();
    //     const factory Foo({...}) = _Foo;
    //   }
    //
    // Generates: mixin _$Foo, class _Foo extends Foo, extension FooCopyWith.
    //
    // Note: redirectedConstructor may be null during the first build because
    // the target class (_Foo) is itself generated. We detect the pattern by
    // checking isAbstract + isFactory instead.
    final factoryConstructor = element.constructors
        .where((c) => c.isFactory)
        .firstOrNull;

    if (element.isAbstract && factoryConstructor != null) {
      return _generatePattern(element, factoryConstructor);
    }

    // Legacy field pattern: class Foo with _$FooMixin { final fields; ctor; }
    // Generates: mixin _$FooMixin, extension FooCopyWith.
    return _generateFieldPattern(element);
  }

  // ---------------------------------------------------------------------------
  // Pattern
  // ---------------------------------------------------------------------------

  String _generatePattern(
    ClassElement element,
    ConstructorElement factory,
  ) {
    final className = element.name;
    if (className == null || className.isEmpty) {
      throw InvalidGenerationSourceError(
        'Annotated class must have a valid name.',
        element: element,
      );
    }
    // Convention: impl class is _ClassName, mixin is _$ClassName.
    final implName = '_$className';
    final mixinName = '_\$$className';
    final params = factory.formalParameters;

    final buffer = StringBuffer();

    // ── Concrete implementation class ───────────────────────────────────────
    //
    // Extends the abstract user class and calls the private const constructor.
    buffer.writeln('class $implName extends $className {');
    for (final p in params) {
      buffer.writeln('  @override');
      buffer.writeln('  final ${_paramTypeName(p)} ${p.name};');
    }
    buffer.writeln();
    buffer.writeln('  const $implName({');
    for (final p in params) {
      final def = _constructorDefault(p);
      if (def != null) {
        buffer.writeln('    this.${p.name} = $def,');
      } else {
        buffer.writeln('    required this.${p.name},');
      }
    }
    buffer.writeln('  }) : super._();');
    buffer.writeln('}');
    buffer.writeln();

    // ── Mixin: abstract getters + equality + hashCode ───────────────────────
    buffer.writeln('mixin $mixinName {');
    for (final p in params) {
      buffer.writeln('  ${_paramTypeName(p)} get ${p.name};');
    }
    buffer.writeln();
    _writeMixinEquality(buffer, mixinName, params);
    _writeMixinHashCode(buffer, params);
    buffer.writeln('}');
    buffer.writeln();

    // ── Extension: copyWith ─────────────────────────────────────────────────
    buffer.writeln('extension ${className}CopyWith on $className {');
    _writeCopyWithFromParams(buffer, className, params);
    buffer.write('}');

    return buffer.toString();
  }

  void _writeMixinEquality(
    StringBuffer buf,
    String mixinName,
    List<FormalParameterElement> params,
  ) {
    buf.writeln('  @override');
    buf.writeln('  bool operator ==(Object other) {');
    buf.writeln('    if (identical(this, other)) return true;');
    if (params.isEmpty) {
      buf.writeln('    return other is $mixinName;');
    } else {
      buf.writeln('    return other is $mixinName &&');
      for (var i = 0; i < params.length; i++) {
        final name = params[i].name;
        if (name == null || name.isEmpty) continue;
        final isLast = i == params.length - 1;
        buf.writeln('      other.$name == $name${isLast ? ';' : ' &&'}');
      }
    }
    buf.writeln('  }');
    buf.writeln();
  }

  void _writeMixinHashCode(StringBuffer buf, List<FormalParameterElement> params) {
    buf.writeln('  @override');
    if (params.isEmpty) {
      buf.writeln('  int get hashCode => runtimeType.hashCode;');
    } else if (params.length == 1) {
      buf.writeln('  int get hashCode => ${params[0].name}.hashCode;');
    } else {
      final names = params
          .map((p) => p.name)
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .join(', ');
      buf.writeln('  int get hashCode => Object.hash($names);');
    }
    buf.writeln();
  }

  void _writeCopyWithFromParams(
    StringBuffer buf,
    String className,
    List<FormalParameterElement> params,
  ) {
    buf.writeln('  $className copyWith({');
    for (final p in params) {
      final name = p.name;
      if (name == null || name.isEmpty) continue;
      if (_isParamNullable(p)) {
        buf.writeln('    Object? $name = ephoenixUndefined,');
      } else {
        buf.writeln('    ${_paramTypeName(p)}? $name,');
      }
    }
    buf.writeln('  }) {');
    buf.writeln('    return $className(');
    for (final p in params) {
      final name = p.name;
      if (name == null || name.isEmpty) continue;
      final fallback = _fallbackFromParam(p);
      if (_isParamNullable(p)) {
        buf.writeln(
          '      $name: identical($name, ephoenixUndefined)'
          ' ? $fallback : $name as ${_paramTypeName(p)},',
        );
      } else {
        buf.writeln('      $name: $name ?? $fallback,');
      }
    }
    buf.writeln('    );');
    buf.writeln('  }');
  }

  bool _isParamNullable(FormalParameterElement param) =>
      param.type.nullabilitySuffix == NullabilitySuffix.question;

  String _paramTypeName(FormalParameterElement param) =>
      param.type.getDisplayString(withNullability: true);

  /// Default value for the generated concrete constructor.
  /// - @Default(v)         → v
  /// - @DefaultCopyWith(v) → v  (also acts as constructor default for convenience)
  /// - neither             → null (field becomes required)
  String? _constructorDefault(FormalParameterElement param) {
    if (_defaultChecker.hasAnnotationOf(param)) {
      return _toLiteral(
        ConstantReader(_defaultChecker.firstAnnotationOf(param)).read('value'),
      );
    }
    if (_defaultCopyWithChecker.hasAnnotationOf(param)) {
      return _toLiteral(
        ConstantReader(
          _defaultCopyWithChecker.firstAnnotationOf(param),
        ).read('value'),
      );
    }
    return null;
  }

  /// Fallback value used in copyWith when a param is not supplied.
  /// - @DefaultCopyWith(v) → v
  /// - @Default(v) or none → this.<name>  (preserve current value)
  String _fallbackFromParam(FormalParameterElement param) {
    if (_defaultCopyWithChecker.hasAnnotationOf(param)) {
      return _toLiteral(
        ConstantReader(
          _defaultCopyWithChecker.firstAnnotationOf(param),
        ).read('value'),
      );
    }
    final name = param.name;
    if (name == null || name.isEmpty) return 'null';
    return 'this.$name';
  }

  // ---------------------------------------------------------------------------
  // Legacy field pattern
  // ---------------------------------------------------------------------------

  String _generateFieldPattern(ClassElement element) {
    final className = element.name;
    if (className == null || className.isEmpty) {
      throw InvalidGenerationSourceError(
        'Annotated class must have a valid name.',
        element: element,
      );
    }
    final mixinName = '_\$${className}Mixin';

    final fields = element.fields
        .where((f) => !f.isStatic && !f.isSynthetic)
        .toList();

    final buffer = StringBuffer();

    buffer.writeln('mixin $mixinName {');
    _writeAbstractGetters(buffer, fields);
    _writeEquality(buffer, mixinName, fields);
    _writeHashCode(buffer, fields);
    buffer.writeln('}');
    buffer.writeln();

    buffer.writeln('extension ${className}CopyWith on $className {');
    _writeCopyWith(buffer, className, fields);
    buffer.write('}');

    return buffer.toString();
  }

  void _writeAbstractGetters(StringBuffer buf, List<FieldElement> fields) {
    for (final field in fields) {
      buf.writeln('  ${_typeName(field)} get ${field.name};');
    }
    buf.writeln();
  }

  void _writeEquality(
    StringBuffer buf,
    String mixinName,
    List<FieldElement> fields,
  ) {
    buf.writeln('  @override');
    buf.writeln('  bool operator ==(Object other) {');
    buf.writeln('    if (identical(this, other)) return true;');

    if (fields.isEmpty) {
      buf.writeln('    return other is $mixinName;');
    } else {
      buf.writeln('    return other is $mixinName &&');
      for (var i = 0; i < fields.length; i++) {
        final name = fields[i].name;
        final isLast = i == fields.length - 1;
        buf.writeln('      other.$name == $name${isLast ? ';' : ' &&'}');
      }
    }

    buf.writeln('  }');
    buf.writeln();
  }

  void _writeHashCode(StringBuffer buf, List<FieldElement> fields) {
    buf.writeln('  @override');

    if (fields.isEmpty) {
      buf.writeln('  int get hashCode => runtimeType.hashCode;');
    } else if (fields.length == 1) {
      buf.writeln('  int get hashCode => ${fields[0].name}.hashCode;');
    } else {
      final names = fields.map((f) => f.name).join(', ');
      buf.writeln('  int get hashCode => Object.hash($names);');
    }

    buf.writeln();
  }

  void _writeCopyWith(
    StringBuffer buf,
    String className,
    List<FieldElement> fields,
  ) {
    buf.writeln('  $className copyWith({');

    for (final field in fields) {
      if (_isNullable(field)) {
        buf.writeln('    Object? ${field.name} = ephoenixUndefined,');
      } else {
        buf.writeln('    ${_typeName(field)}? ${field.name},');
      }
    }

    buf.writeln('  }) {');
    buf.writeln('    return $className(');

    for (final field in fields) {
      final fallback = _fallback(field);
      if (_isNullable(field)) {
        buf.writeln(
          '      ${field.name}: identical(${field.name}, ephoenixUndefined)'
          ' ? $fallback : ${field.name} as ${_typeName(field)},',
        );
      } else {
        buf.writeln('      ${field.name}: ${field.name} ?? $fallback,');
      }
    }

    buf.writeln('    );');
    buf.writeln('  }');
  }

  bool _isNullable(FieldElement field) =>
      field.type.nullabilitySuffix == NullabilitySuffix.question;

  String _typeName(FieldElement field) =>
      field.type.getDisplayString(withNullability: true);

  /// Fallback for legacy field pattern copyWith.
  /// Only @DefaultCopyWith overrides; @Default does NOT affect copyWith.
  String _fallback(FieldElement field) {
    if (_defaultCopyWithChecker.hasAnnotationOf(field)) {
      final reader = ConstantReader(
        _defaultCopyWithChecker.firstAnnotationOf(field),
      );
      return _toLiteral(reader.read('value'));
    }
    return 'this.${field.name}';
  }

  String _toLiteral(ConstantReader r) {
    if (r.isNull) return 'null';
    if (r.isBool) return r.boolValue.toString();
    if (r.isInt) return r.intValue.toString();
    if (r.isDouble) {
      final v = r.doubleValue;
      return v == v.truncateToDouble() ? '${v.toInt()}.0' : v.toString();
    }
    if (r.isString) {
      final escaped = r.stringValue
          .replaceAll(r'\', r'\\')
          .replaceAll("'", r"\'");
      return "'$escaped'";
    }
    if (r.isList) {
      final items =
          r.listValue.map((e) => _toLiteral(ConstantReader(e))).join(', ');
      return 'const [$items]';
    }
    if (r.isMap) return 'const {}';
    if (r.isSet) return 'const {}';
    return 'null';
  }
}
