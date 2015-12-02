part of reflective.core;

abstract class FieldReflection {
  bool has(Type metadata);

  value(Object entity);

  set(Object entity, value);

  TypeReflection get type;

  String get name;
}

class SimpleFieldReflection extends FieldReflection {
  Symbol _symbol;
  VariableMirror _variable;
  MethodMirror _accessor;

  SimpleFieldReflection(this._symbol, this._variable, this._accessor);

  bool has(Type metadata) =>
      _variable.metadata.firstWhere((instance) => instance.type.reflectedType == metadata, orElse: () => null) != null;

  value(Object entity) => reflect(entity).getField(_symbol).reflectee;

  set(Object entity, value) => reflect(entity).setField(_symbol, value);

  TypeReflection get type => new TypeReflection.fromMirror(_accessor.returnType);

  String get name => MirrorSystem.getName(_symbol);

  String toString() => name;

  bool operator ==(o) =>
      o is FieldReflection && _variable.qualifiedName == o._variable.qualifiedName && _symbol == o._symbol;
}

class TransitiveFieldReflection extends FieldReflection {
  FieldReflection _source;
  FieldReflection _target;

  TransitiveFieldReflection(this._source, this._target);

  bool has(Type metadata) => _source.has(metadata);

  value(Object entity) {
    var sourceValue = _source.value(entity);
    if (sourceValue == null) return null;
    return _target.value(sourceValue);
  }

  set(Object entity, value) => _target.set(_source.value(entity), value);

  TypeReflection get type => _source.type;

  String get name => _source.name + '.' + _target.name;
}