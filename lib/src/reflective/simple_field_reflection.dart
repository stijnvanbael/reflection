part of reflective.reflective;

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