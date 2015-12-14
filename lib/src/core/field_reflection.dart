part of reflective.core;

abstract class FieldReflection {
  bool get isGeneric;

  bool has(Type metadata);

  List metadata(Type metadata);

  value(Object entity);

  set(Object entity, value);

  TypeReflection get type;

  String get name;

  String get fullName;

  bool get isPrivate;
}

class SimpleFieldReflection extends AbstractReflection<VariableMirror> with FieldReflection {
  Symbol _symbol;
  MethodMirror _accessor;

  SimpleFieldReflection(this._symbol, VariableMirror mirror, this._accessor) : super(mirror);

  value(Object entity) => reflect(entity).getField(_symbol).reflectee;

  set(Object entity, value) => reflect(entity).setField(_symbol, value);

  TypeReflection get type => new TypeReflection.fromMirror(_accessor.returnType);

  String get name => MirrorSystem.getName(_symbol);

  String toString() => name;

  bool get isGeneric => _mirror.type is TypeVariableMirror;

  bool operator ==(o) =>
      o is FieldReflection && fullName == o.fullName && _symbol == o._symbol;
}

class TransitiveFieldReflection implements FieldReflection {
  FieldReflection _source;
  FieldReflection _target;

  TransitiveFieldReflection(this._source, this._target);

  bool has(Type metadata) => _source.has(metadata);

  List metadata(Type metadata) => _source.metadata(metadata);

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
}