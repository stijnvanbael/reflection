import 'package:reflectable/mirrors.dart';
import 'package:reflective/reflective.dart';

abstract class FieldReflection {
  bool get isGeneric;

  bool get isConst;

  bool has(Type metadata);

  List<T> metadata<T>();

  value(Object entity);

  set(Object entity, value);

  TypeReflection get type;

  Type get rawType;

  String get name;

  String get fullName;

  bool get isPrivate;
}

class SimpleFieldReflection extends AbstractReflection<VariableMirror>
    with FieldReflection {
  final String name;
  MethodMirror _accessor;

  SimpleFieldReflection(this.name, VariableMirror mirror, this._accessor)
      : super(mirror);

  value(Object entity) => reflector.reflect(entity).invokeGetter(name);

  set(Object entity, value) =>
      reflector.reflect(entity).invokeSetter(name, value);

  TypeReflection get type => TypeReflection.fromMirror(_accessor.returnType);

  String toString() => name;

  bool get isGeneric => mirror.type is TypeVariableMirror;

  bool get isConst => mirror.isConst;

  bool operator ==(o) =>
      o is SimpleFieldReflection && fullName == o.fullName && name == o.name;

  @override
  Type get rawType => _accessor.reflectedReturnType;
}

class TransitiveFieldReflection implements FieldReflection {
  FieldReflection _source;
  FieldReflection _target;

  TransitiveFieldReflection(this._source, this._target);

  bool has(Type metadata) => _source.has(metadata);

  List<T> metadata<T>() => _source.metadata<T>();

  value(Object entity) {
    var sourceValue = _source.value(entity);
    if (sourceValue == null) return null;
    return _target.value(sourceValue);
  }

  set(Object entity, value) => _target.set(_source.value(entity), value);

  TypeReflection get type => _source.type;

  String get name => _source.name + '.' + _target.name;

  String get fullName => _source.fullName + '.' + _target.name;

  bool get isPrivate => _target.isPrivate;

  bool get isGeneric => false;

  bool get isConst => _target.isConst;

  @override
  Type get rawType => _target.rawType;
}
