import 'package:reflectable/mirrors.dart';
import 'package:reflectable/reflectable.dart';
import 'package:reflective/core.dart';
import 'package:reflective/src/util.dart';

class Reflector extends Reflectable {
  const Reflector()
      : super(
          invokingCapability,
          typingCapability,
          reflectedTypeCapability,
          libraryCapability,
          superclassQuantifyCapability,
          subtypeQuantifyCapability,
          delegateCapability,
          typeAnnotationDeepQuantifyCapability,
        ); // Request the capability to invoke methods.
}

const reflector = const Reflector();

TypeReflection<T> type<T>([type]) => TypeReflection<T>(type);

TypeReflection<T> instance<T>(T instance) => TypeReflection.fromInstance(instance);

TypeReflection<dynamic> dynamicReflection = TypeReflection<dynamic>();

class TypeReflection<T> extends AbstractReflection<TypeMirror> {
  List<TypeReflection> _arguments;
  List<GenericArgumentReflection> _genericArguments;

  TypeReflection([Type type, List<Type> arguments]) : super(reflector.reflectType(type != null ? type : T)) {
    if (arguments != null) {
      _getGenericArgumentsFromMirror();
      for (var i = 0; i < _genericArguments.length; i++) {
        if (arguments.length > i) _genericArguments[i].value = TypeReflection(arguments[i]);
      }
      _arguments = List.from(arguments.map((arg) => TypeReflection(arg)));
    } else {
      _getArgumentsFromMirror();
      _getGenericArgumentsFromMirror();
    }
  }

  TypeReflection.fromInstance(instance) : super(reflector.reflect(instance).type) {
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

  get library => LibraryReflection((mirror as ClassMirror).owner.simpleName);

  get isGeneric => (mirror as ClassMirror).typeVariables.isNotEmpty;

  _getArgumentsFromMirror() {
    _arguments = List.from(mirror.typeArguments.map((m) {
      return _getTypeReflectionForArgument(m);
    }));
  }

  _getGenericArgumentsFromMirror() {
    _genericArguments = List<GenericArgumentReflection>();
    for (var i = 0; i < mirror.typeVariables.length; i++) {
      var genericArgumentReflection = GenericArgumentReflection()..name = mirror.typeVariables[i].simpleName;
      if (mirror.typeArguments.length > i)
        genericArgumentReflection.value = TypeReflection.fromMirror(mirror.typeArguments[i]);
      _genericArguments.add(genericArgumentReflection);
    }
  }

  TypeReflection _getTypeReflectionForArgument(TypeMirror m) {
    if (m.reflectedType == dynamic) return dynamicReflection;
    return TypeReflection.fromMirror(m);
  }

  TypeReflection get mixin => TypeReflection((mirror as ClassMirror).mixin.reflectedType);

  Type get rawType => mirror.reflectedType;

  bool get isEnum => mirror is ClassMirror ? (mirror as ClassMirror).isEnum : false;

  List get enumValues {
    if (!isEnum || mirror is! ClassMirror) return null;
    return (mirror as ClassMirror).invokeGetter('values');
  }

  List<TypeReflection> get typeArguments => _arguments;

  Map<String, FieldReflection> get fields {
    if (mirror is! ClassMirror) {
      return {};
    }

    var fields = _getAllFields(mirror);
    return Map.fromIterable(fields, key: (field) => field.name);
  }

  static ClassMirror _objectMirror = reflector.reflectType(Object);

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
    return SimpleFieldReflection(key, classMirror.declarations[key], classMirror.instanceMembers[key]);
  }

  Map<String, FieldReflection> fieldsWhere(bool test(FieldReflection field)) {
    return Map<String, FieldReflection>.from(Maps.where(fields, (key, value) => test(value)));
  }

  Map<String, FieldReflection> fieldsWith(Type metadata) {
    return fieldsWhere((field) => field.has(metadata));
  }

  FieldReflection field(String name) {
    List<String> components = name.split('.');
    if (components.length == 1) return fields[components[0]];
    FieldReflection field = null;
    components.forEach((c) {
      if (field == null)
        field = fields[c];
      else
        field = TransitiveFieldReflection(field, fields[c]);
    });
    return field;
  }

  bool sameOrSuper(other) {
    if (other is Type) {
      return sameOrSuper(TypeReflection(other));
    } else if (other is TypeReflection) {
      return this == other || other.mirror.isSubtypeOf(mirror);
    } else {
      return sameOrSuper(TypeReflection.fromInstance(other));
    }
  }

  bool sameOrSub(other) {
    if (other is Type) {
      return sameOrSub(TypeReflection(other));
    } else if (other is TypeReflection) {
      return this == other || mirror.isSubtypeOf(other.mirror);
    } else {
      return sameOrSub(TypeReflection.fromInstance(other));
    }
  }

  @deprecated
  List<TypeReflection> get arguments => _arguments;

  List<GenericArgumentReflection> get genericArguments => _genericArguments;

  T construct({Map<Symbol, dynamic> namedArgs: const {}, List args: const [], String constructor: ''}) {
    if (mirror is! ClassMirror) throw 'Cannot construct ' + fullName;

    var classMirror = mirror as ClassMirror;
    return classMirror.newInstance(constructor, args, namedArgs);
  }

  String toString() => '$fullName${typeArguments.isNotEmpty ? '<${typeArguments.join(', ')}>' : ''}';

  bool get isAbstract => mirror is ClassMirror && (mirror as ClassMirror).isAbstract;

  TypeReflection get superclass => mirror is ClassMirror && (mirror as ClassMirror).superclass != null
      ? TypeReflection((mirror as ClassMirror).superclass.reflectedType)
      : null;

  bool operator ==(o) => o is TypeReflection && mirror.qualifiedName == o.mirror.qualifiedName;

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
      library = reflector.findLibrary('');
    } else {
      library = reflector.findLibrary(libraryName);
    }

    return library == null ? null : library.declarations[name];
  }
}

class GenericArgumentReflection {
  String name;
  TypeReflection value;
}
