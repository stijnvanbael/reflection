part of reflective;

class TypeReflection {
  ClassMirror mirror;

  TypeReflection(Type type) {
    mirror = reflectClass(type);
  }

  TypeReflection.fromInstance(instance) {
    mirror = reflect(instance).type;
  }

  TypeReflection.fromMirror(this.mirror);

  get type => mirror.reflectedType;

  get name => MirrorSystem.getName(mirror.qualifiedName);

  Iterable<FieldReflection> get fields {
    return mirror.declarations.keys
    .where((key) => mirror.declarations[key] is VariableMirror)
    .map((key) => new FieldReflection(key, mirror.instanceMembers[key]));
  }

  Iterable<FieldReflection> fieldsWith(Type metadata) {
    return fields.where((field) => field.has(metadata));
  }

  bool sameOrSuper(other) {
    if(other is Type) {
      return sameOrSuper(new TypeReflection(other));
    } else if(other is TypeReflection) {
      return other.mirror.isSubtypeOf(mirror);
    } else {
      return sameOrSuper(new TypeReflection.fromInstance(other));
    }
  }

  bool sameOrSub(other) {
    if(other is Type) {
      return sameOrSub(new TypeReflection(other));
    } else if(other is TypeReflection) {
      return mirror.isSubtypeOf(other.mirror);
    } else {
      return sameOrSub(new TypeReflection.fromInstance(other));
    }
  }

  List<TypeReflection> get arguments => new List.from(mirror.typeArguments.map((m) => new TypeReflection.fromMirror(m)));

  construct({Map namedArgs: const {}, List args: const [], String constructor: ''}) {
    return mirror.newInstance(MirrorSystem.getSymbol(constructor), args, namedArgs).reflectee;
  }

  String toString() => name;
}

class FieldReflection {
  Symbol symbol;
  MethodMirror mirror;

  FieldReflection(this.symbol, this.mirror);

  bool has(Type metadata) => mirror.metadata
  .firstWhere((instance) => instance.type.reflectedType == metadata,
  orElse: () => null) != null;

  value(Object entity) => reflect(entity).getField(symbol).reflectee;

  set(Object entity, value) => reflect(entity).setField(symbol, value);

  TypeReflection get type => new TypeReflection.fromMirror(mirror.returnType);

  get name => MirrorSystem.getName(symbol);

  String toString() => name;
}
