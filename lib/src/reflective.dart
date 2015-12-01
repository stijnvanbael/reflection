part of reflective;

type(Type type) => new TypeReflection(type);

instance(Object instance) => new TypeReflection.fromInstance(instance);

class TypeReflection<T> {
  TypeMirror _mirror;
  List<TypeReflection> _arguments;

  TypeReflection(Type type, [List<Type> arguments]) {
    _mirror = reflectType(type);
    if (arguments != null) {
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

  TypeReflection.fromFullName(String fullName) {
    _mirror = _getClassMirrorByName(fullName);
    _getArgumentsFromMirror();
  }

  _getArgumentsFromMirror() {
    _arguments = new List.from(_mirror.typeArguments.map((m) {
      if (m.reflectedType == dynamic) {
        return dynamicReflection;
      }
      return new TypeReflection.fromMirror(m);
    }));
  }

  Type get type => _mirror.reflectedType;

  String get name => MirrorSystem.getName(_mirror.simpleName);
  String get fullName => MirrorSystem.getName(_mirror.qualifiedName);

  bool get isEnum => _mirror is ClassMirror ? (_mirror as ClassMirror).isEnum : false;

  List get enumValues {
    if (!isEnum || _mirror is !ClassMirror)
      return null;
    return (_mirror as ClassMirror).getField(#values).reflectee;
  }

  List<TypeReflection> get typeArguments => _arguments;

  Map<String, FieldReflection> get fields {
    if (!(_mirror is ClassMirror)) {
      return {};
    }
    ClassMirror classMirror = _mirror;
    return Maps.index(
        classMirror.declarations.keys.where((key) => classMirror.declarations[key] is VariableMirror).map(
            (key) => new SimpleFieldReflection(key, classMirror.declarations[key], classMirror.instanceMembers[key])),
        (field) => field.name);
  }

  Map<String, FieldReflection> fieldsWith(Type metadata) {
    return Maps.where(fields, (name, field) => field.has(metadata));
  }

  FieldReflection field(String name) {
    List<String> components = name.split('.');
    if (components.length == 1) return fields[components[0]];
    FieldReflection field = null;
    components.forEach((c) {
      if (field == null) field = fields[c];
      else field = new TransitiveFieldReflection(field, fields[c]);
    });
    return field;
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

  T construct({Map namedArgs: const {}, List args: const [], String constructor: ''}) {
    if (!(_mirror is ClassMirror)) {
      throw 'Cannot construct ' + fullName;
    }
    ClassMirror classMirror = _mirror;
    return classMirror.newInstance(MirrorSystem.getSymbol(constructor), args, namedArgs).reflectee;
  }

  String toString() => fullName;

  bool operator ==(o) => o is TypeReflection && _mirror.qualifiedName == o._mirror.qualifiedName;

  ClassMirror _getClassMirrorByName(String className) {
    if (className == null) {
      return null;
    }

    var index = className.lastIndexOf('.');
    var libraryName = '';
    var name = className;
    if (index > 0) {
      libraryName = className.substring(0, index);
      name = className.substring(index + 1);
    }

    LibraryMirror library;
    if (libraryName.isEmpty) {
      library = currentMirrorSystem().isolate.rootLibrary;
    } else {
      library = currentMirrorSystem().findLibrary(new Symbol(libraryName));
    }

    if (library == null) {
      return null;
    }

    return library.declarations[new Symbol(name)];
  }
}

TypeReflection<dynamic> dynamicReflection = new TypeReflection(dynamic);

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

class Objects {
  static int hash(List toHash) =>
      toHash.fold(17, (e1, e2) => (e1 != null ? e1.hashCode : 1) * 37 + (e2 != null ? e2.hashCode : 1));
}
