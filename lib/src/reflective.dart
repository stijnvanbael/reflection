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

  Map<String, FieldReflection> get fields {
    return Maps.index(mirror.declarations.keys
    .where((key) => mirror.declarations[key] is VariableMirror)
    .map((key) => new FieldReflection(key, mirror.declarations[key], mirror.instanceMembers[key])),
        (field) => field.name);
  }

  Map<String, FieldReflection> fieldsWith(Type metadata) {
    return Maps.where(fields, (name, field) => field.has(metadata));
  }

  bool sameOrSuper(other) {
    if (other is Type) {
      return sameOrSuper(new TypeReflection(other));
    } else if (other is TypeReflection) {
      return this == other || other.mirror.isSubtypeOf(mirror);
    } else {
      return sameOrSuper(new TypeReflection.fromInstance(other));
    }
  }

  bool sameOrSub(other) {
    if (other is Type) {
      return sameOrSub(new TypeReflection(other));
    } else if (other is TypeReflection) {
      return this == other || mirror.isSubtypeOf(other.mirror);
    } else {
      return sameOrSub(new TypeReflection.fromInstance(other));
    }
  }

  List<TypeReflection> get arguments => new List.from(mirror.typeArguments.map((m) => new TypeReflection.fromMirror(m)));

  construct({Map namedArgs: const {
  }, List args: const [], String constructor: ''}) {
    return mirror.newInstance(MirrorSystem.getSymbol(constructor), args, namedArgs).reflectee;
  }

  String toString() => name;

  bool operator ==(o) => o is TypeReflection && mirror.qualifiedName == o.mirror.qualifiedName;
}

class FieldReflection {
  Symbol symbol;
  VariableMirror variable;
  MethodMirror accessor;

  FieldReflection(this.symbol, this.variable, this.accessor);

  bool has(Type metadata) => variable.metadata
  .firstWhere((instance) => instance.type.reflectedType == metadata,
  orElse: () => null) != null;

  value(Object entity) => reflect(entity).getField(symbol).reflectee;

  set(Object entity, value) => reflect(entity).setField(symbol, value);

  TypeReflection get type => new TypeReflection.fromMirror(accessor.returnType);

  get name => MirrorSystem.getName(symbol);

  String toString() => name;

  bool operator ==(o) => o is FieldReflection && variable.qualifiedName == o.variable.qualifiedName && symbol == o.symbol;
}

class Maps {
  static Map index(Iterable iterable, indexer(key)) {
    Map result = {};
    iterable.forEach((i) => result[indexer(i)] = i);
    return result;
  }

  static Map where(Map map, predicate(key, value)) {
    Map result = {};
    forEach(map, (k, v) {
      if (predicate(k, v)) result[k] = v;
    });
    return result;
  }

  static forEach(Map map, function(key, value)) {
    map.keys.forEach((k) => function(k, map[k]));
  }
}