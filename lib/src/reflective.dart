part of reflective;

class TypeReflection<T> {
  ClassMirror _mirror;
  List<TypeReflection> _arguments;

  TypeReflection(Type type, [List<Type> arguments]) {
    _mirror = reflectClass(type);
    if(arguments != null) {
      _arguments = new List.from(arguments.map((arg) => new TypeReflection(arg)));
    } else {
      _getArgumentsFromMirror();
    }
  }

  TypeReflection.fromInstance(instance) {
    _mirror = reflect(instance).type;
    _getArgumentsFromMirror();
  }

  TypeReflection.fromMirror(this._mirror) {
    _getArgumentsFromMirror();
  }

  _getArgumentsFromMirror() {
    _arguments = new List.from(_mirror.typeArguments.map((m) => new TypeReflection.fromMirror(m)));
  }

  Type get type => _mirror.reflectedType;

  String get name => MirrorSystem.getName(_mirror.qualifiedName);

  Map<String, FieldReflection> get fields {
    return Maps.index(_mirror.declarations.keys
    .where((key) => _mirror.declarations[key] is VariableMirror)
    .map((key) => new FieldReflection(key, _mirror.declarations[key], _mirror.instanceMembers[key])),
        (field) => field.name);
  }

  Map<String, FieldReflection> fieldsWith(Type metadata) {
    return Maps.where(fields, (name, field) => field.has(metadata));
  }

  bool sameOrSuper(other) {
    if (other is Type) {
      return sameOrSuper(new TypeReflection(other));
    } else if (other is TypeReflection) {
      return this == other || other._mirror.isSubtypeOf(_mirror);
    } else {
      return sameOrSuper(new TypeReflection.fromInstance(other));
    }
  }

  bool sameOrSub(other) {
    if (other is Type) {
      return sameOrSub(new TypeReflection(other));
    } else if (other is TypeReflection) {
      return this == other || _mirror.isSubtypeOf(other._mirror);
    } else {
      return sameOrSub(new TypeReflection.fromInstance(other));
    }
  }

  List<TypeReflection> get arguments => _arguments;

  T construct({Map namedArgs: const {
  }, List args: const [], String constructor: ''}) {
    return _mirror.newInstance(MirrorSystem.getSymbol(constructor), args, namedArgs).reflectee;
  }

  String toString() => name;

  bool operator ==(o) => o is TypeReflection && _mirror.qualifiedName == o._mirror.qualifiedName;
}

class FieldReflection {
  Symbol _symbol;
  VariableMirror _variable;
  MethodMirror _accessor;

  FieldReflection(this._symbol, this._variable, this._accessor);

  bool has(Type metadata) => _variable.metadata
  .firstWhere((instance) => instance.type.reflectedType == metadata,
  orElse: () => null) != null;

  value(Object entity) => reflect(entity).getField(_symbol).reflectee;

  set(Object entity, value) => reflect(entity).setField(_symbol, value);

  TypeReflection get type => new TypeReflection.fromMirror(_accessor.returnType);

  String get name => MirrorSystem.getName(_symbol);

  String toString() => name;

  bool operator ==(o) => o is FieldReflection && _variable.qualifiedName == o._variable.qualifiedName && _symbol == o._symbol;
}

class Maps {
  static Map index(Iterable iterable, indexer(key)) {
    Map result = {
    };
    iterable.forEach((i) => result[indexer(i)] = i);
    return result;
  }

  static Map where(Map map, predicate(key, value)) {
    Map result = {
    };
    forEach(map, (k, v) {
      if (predicate(k, v)) result[k] = v;
    });
    return result;
  }

  static forEach(Map map, function(key, value)) {
    map.keys.forEach((k) => function(k, map[k]));
  }
}