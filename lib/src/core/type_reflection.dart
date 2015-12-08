part of reflective.core;

TypeReflection type(Type type) => new TypeReflection(type);

TypeReflection instance(Object instance) => new TypeReflection.fromInstance(instance);

TypeReflection<dynamic> dynamicReflection = new TypeReflection(dynamic);

class TypeReflection<T> extends AbstractReflection<TypeMirror> {
  List<TypeReflection> _arguments;

  TypeReflection(Type type, [List<Type> arguments]) : super(reflectType(type)) {
    if (arguments != null)
      _arguments = new List.from(arguments.map((arg) => new TypeReflection(arg)));
    else
      _getArgumentsFromMirror();
  }

  TypeReflection.fromInstance(instance) : super(reflect(instance).type) {
    _getArgumentsFromMirror();
  }

  TypeReflection.fromMirror(TypeMirror mirror) : super(mirror) {
    _getArgumentsFromMirror();
  }

  TypeReflection.fromFullName(String fullName) : super(_getClassMirrorByName(fullName)) {
    _getArgumentsFromMirror();
  }

  _getArgumentsFromMirror() {
    _arguments = new List.from(_mirror.typeArguments.map((m) {
      if (m.reflectedType == dynamic)
        return dynamicReflection;
      return new TypeReflection.fromMirror(m);
    }));
  }

  TypeReflection get mixin => new TypeReflection((_mirror as ClassMirror).mixin.reflectedType);

  Type get rawType => _mirror.reflectedType;

  bool get isEnum => _mirror is ClassMirror ? (_mirror as ClassMirror).isEnum : false;

  List get enumValues {
    if (!isEnum || _mirror is! ClassMirror) return null;
    return (_mirror as ClassMirror)
        .getField(#values)
        .reflectee;
  }

  List<TypeReflection> get typeArguments => _arguments;

  Map<String, FieldReflection> get fields {
    if (_mirror is! ClassMirror) {
      return {};
    }

    var fields = _getAllFields(_mirror);
    return new Map.fromIterable(fields, key: (field) => field.name);
  }

  static ClassMirror _objectMirror = reflectClass(Object);

  Iterable<SimpleFieldReflection> _getAllFields(ClassMirror classMirror) sync* {
    var variableSymbols = classMirror.declarations.keys.where((key) => classMirror.declarations[key] is VariableMirror);

    for (var variableSymbol in variableSymbols) {
      yield _getSimpleFieldReflection(variableSymbol, classMirror);
    }

    if (classMirror.superclass != _objectMirror) {
      yield* _getAllFields(classMirror.superclass);
    }
  }

  static SimpleFieldReflection _getSimpleFieldReflection(key, ClassMirror classMirror) {
    return new SimpleFieldReflection(key, classMirror.declarations[key], classMirror.instanceMembers[key]);
  }

  Map<String, FieldReflection> fieldsWhere(bool test(FieldReflection field)) {
    return Maps.where(fields, (key, value) => test(value));
  }

  Map<String, FieldReflection> fieldsWith(Type metadata) {
    return fieldsWhere((field) => field.has(metadata));
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
    if (_mirror is! ClassMirror) throw 'Cannot construct ' + fullName;

    ClassMirror classMirror = _mirror;
    return classMirror
        .newInstance(MirrorSystem.getSymbol(constructor), args, namedArgs)
        .reflectee;
  }

  String toString() => fullName;

  bool get isAbstract => _mirror is ClassMirror && (_mirror as ClassMirror).isAbstract;

  TypeReflection get superclass => _mirror is ClassMirror && ( _mirror as ClassMirror ).superclass != null ? new TypeReflection(( _mirror as ClassMirror ).superclass.reflectedType) : null;

  bool operator ==(o) => o is TypeReflection && _mirror.qualifiedName == o._mirror.qualifiedName;

  static ClassMirror _getClassMirrorByName(String className) {
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

    return library == null ? null : library.declarations[new Symbol(name)];
  }
}
