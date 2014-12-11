part of reflective;

class TypeReflection {
  ClassMirror mirror;

  TypeReflection(Type type) {
    mirror = reflectClass(type);
  }

  TypeReflection.fromInstance(instance) {
    mirror = reflect(instance).type;
  }

  Iterable<FieldReflection> get fields {
    return mirror.declarations.keys
    .where((key) => mirror.declarations[key] is VariableMirror)
    .map((key) => new FieldReflection(key, mirror.declarations[key]));
  }

  Iterable<FieldReflection> fieldsWith(Type metadata) {
    return fields.where((field) => field.has(metadata));
  }

  String toString() {
    return mirror.qualifiedName.toString();
  }
}

class FieldReflection {
  Symbol symbol;
  VariableMirror mirror;

  FieldReflection(this.symbol, this.mirror);

  bool has(Type metadata) => mirror.metadata
  .firstWhere((instance) => instance.type.reflectedType == metadata,
  orElse: () => null) != null;

  value(Object entity) => reflect(entity).getField(symbol).reflectee;

  get name => symbol.toString();

  String toString() {
    return symbol.toString();
  }
}
