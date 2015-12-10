part of reflective.core;

LibraryReflection library(String libraryName) => new LibraryReflection(libraryName);

class LibraryReflection
{
	LibraryMirror _library;
	List<TypeReflection> _types;

	LibraryReflection.fromSymbol(Symbol libraryName)
	{
		_library = currentMirrorSystem().findLibrary(libraryName);
		_loadTypes();
	}

	LibraryReflection(String libraryName) {
		if (libraryName.isEmpty) {
			_library = currentMirrorSystem().isolate.rootLibrary;
		} else {
			_library = currentMirrorSystem().findLibrary(new Symbol(libraryName));
		}
		_loadTypes();
	}

	void _loadTypes() {
		_types = new List<TypeReflection>();
		_library.declarations.forEach( (k, v) {
			if ( v is ClassMirror ) {
				_types.add( new TypeReflection( v.reflectedType));
			}
		});
	}

	List<TypeReflection> get types => _types;

	String get name => MirrorSystem.getName(_library.qualifiedName);
}