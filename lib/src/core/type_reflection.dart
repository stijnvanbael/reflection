part of reflective.core;

TypeReflection<T> type<T>([type]) => new TypeReflection<T>(type);

TypeReflection<T> instance<T>(T instance) => new TypeReflection.fromInstance(instance);

TypeReflection<dynamic> dynamicReflection = new TypeReflection<dynamic>();

class TypeReflection<T> extends AbstractReflection<TypeMirror> {
  List<TypeReflection> _arguments;
  List<GenericArgumentReflection> _genericArguments;

  TypeReflection([Type type, List<Type> arguments]) : super(reflectType(type != null ? type : T)) {
    if (arguments != null) {
      _getGenericArgumentsFromMirror();
      for (var i = 0; i < _genericArguments.length; i++) {
        if (arguments.length > i) _genericArguments[i].value = new TypeReflection(arguments[i]);
      }
      _arguments = new List.from(arguments.map((arg) => new TypeReflection(arg)));
    } else {
      _getArgumentsFromMirror();
      _getGenericArgumentsFromMirror();
    }
  }

  TypeReflection.fromInstance(instance) : super(reflect(instance).type) {
    _getArgumentsFromMirror();
    _getGenericArgumentsFromMirror();
  }

  TypeReflection.fromMirror(TypeMirror mirror) : super(mirror) {
    _getArgumentsFromMirror();
    _getGenericArgumentsFromMirror();
  }

  TypeReflection.fromFullName(String fullName) : super(_getClassMirrorByName(fullName)) {
    _getArgumentsFromMirror();
    _getGenericArgumentsFromMirror();
  }

  get library => new LibraryReflection.fromSymbol((_mirror as ClassMirror).owner.simpleName);

  get isGeneric => (_mirror as ClassMirror).typeVariables.isNotEmpty;

  _getArgumentsFromMirror() {
    _arguments = new List.from(_mirror.typeArguments.map((m) {
      return _getTypeReflectionForArgument(m);
    }));
  }

  _getGenericArgumentsFromMirror() {
    _genericArguments = new List<GenericArgumentReflection>();
    for (var i = 0; i < _mirror.typeVariables.length; i++) {
      var genericArgumentReflection = new GenericArgumentReflection()
        ..name = MirrorSystem.getName(_mirror.typeVariables[i].simpleName);
      if (_mirror.typeArguments.length > i)
        genericArgumentReflection.value = new TypeReflection.fromMirror(_mirror.typeArguments[i]);
      _genericArguments.add(genericArgumentReflection);
    }
  }

  TypeReflection _getTypeReflectionForArgument(TypeMirror m) {
    if (m.reflectedType == dynamic) return dynamicReflection;
    return new TypeReflection.fromMirror(m);
  }

  TypeReflection get mixin => new TypeReflection((_mirror as ClassMirror).mixin.reflectedType);

  Type get rawType => _mirror.reflectedType;

  bool get isEnum => _mirror is ClassMirror ? (_mirror as ClassMirror).isEnum : false;

  List get enumValues {
    if (!isEnum || _mirror is! ClassMirror) return null;
    return (_mirror as ClassMirror).getField(#values).reflectee;
  }

  List<TypeReflection> get typeArguments => _arguments;

  Map<String, FieldReflection> get fields {
    if (_mirror is! ClassMirror) {
      return {};
    }

    var fields = _getAllFields(_mirror);
    return new Map.fromIterable(fields, key: (field) => field.name);
  }

  Map<String, MethodReflection> get methods {
    if (_mirror is! ClassMirror) {
      return {};
    }

    var methods = _getAllMethods(_mirror);
    return new Map.fromIterable(methods, key: (method) => method.name);
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

  Iterable<MethodReflection> _getAllMethods(ClassMirror classMirror) sync* {
    var methodMirrors = classMirror.declarations.values.where((value) => value is MethodMirror);

    for (var methodMirror in methodMirrors) {
      yield MethodReflection(methodMirror);
    }

    if (classMirror.superclass != _objectMirror) {
      yield* _getAllMethods(classMirror.superclass);
    }
  }

  static SimpleFieldReflection _getSimpleFieldReflection(key, ClassMirror classMirror) {
    return new SimpleFieldReflection(key, classMirror.declarations[key], classMirror.instanceMembers[key]);
  }

  Map<String, FieldReflection> fieldsWhere(bool test(FieldReflection field)) {
    return Map<String, FieldReflection>.from(Maps.where(fields, (key, value) => test(value)));
  }

  Map<String, FieldReflection> fieldsWith(Type metadata) {
    return fieldsWhere((field) => field.has(metadata));
  }

  Map<String, MethodReflection> methodsWhere(bool test(MethodReflection field)) {
    return Map<String, MethodReflection>.from(Maps.where(methods, (key, value) => test(value)));
  }

  Map<String, MethodReflection> methodsWith(Type metadata) {
    return methodsWhere((method) => method.has(metadata));
  }

  FieldReflection field(String name) {
    List<String> components = name.split('.');
    if (components.length == 1) return fields[components[0]];
    FieldReflection field = null;
    components.forEach((c) {
      if (field == null)
        field = fields[c];
      else
        field = new TransitiveFieldReflection(field, fields[c]);
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

  @deprecated
  List<TypeReflection> get arguments => _arguments;

  List<GenericArgumentReflection> get genericArguments => _genericArguments;

  T construct({Map<Symbol, dynamic> namedArgs: const {}, List args: const [], String constructor: ''}) {
    if (_mirror is! ClassMirror) throw 'Cannot construct ' + fullName;

    ClassMirror classMirror = _mirror;
    return classMirror.newInstance(MirrorSystem.getSymbol(constructor), args, namedArgs).reflectee;
  }

  String toString() => fullName;

  bool get isAbstract => _mirror is ClassMirror && (_mirror as ClassMirror).isAbstract;

  TypeReflection get superclass => _mirror is ClassMirror && (_mirror as ClassMirror).superclass != null
      ? new TypeReflection((_mirror as ClassMirror).superclass.reflectedType)
      : null;

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

class GenericArgumentReflection {
  String name;
  TypeReflection value;
}
