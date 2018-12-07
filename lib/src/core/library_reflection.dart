import 'package:reflectable/mirrors.dart';
import 'package:reflective/core.dart';

LibraryReflection library(String libraryName) => LibraryReflection(libraryName);

class LibraryReflection {
  LibraryMirror _library;
  List<TypeReflection> _types;

  LibraryReflection(String libraryName) {
    if (libraryName.isEmpty) {
      _library = reflector.findLibrary('');
    } else {
      _library = reflector.findLibrary(libraryName);
    }
    _loadTypes();
  }

  void _loadTypes() {
    _types = List<TypeReflection>();
    _library.declarations.forEach((k, v) {
      try {
        if (v is ClassMirror) {
          _types.add(TypeReflection.fromMirror(v));
        }
      } catch (e) {
        throw "Error when creating TypeReflection for type " +
            v.toString() +
            ": " +
            e.toString();
      }
    });
  }

  List<TypeReflection> get types => _types;

  String get name => _library.qualifiedName;
}
