part of reflective.reflective;

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
