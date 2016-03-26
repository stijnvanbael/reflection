part of reflective.core;

InstanceReflection instance(instance) {
  return new InstanceReflection(instance);
}

class InstanceReflection<T> {
  InstanceMirror _instance;

  InstanceReflection(instance) {
    _instance = reflect(instance);
  }

  TypeReflection<T> get type => new TypeReflection.fromInstance(_instance.reflectee);

  List metadata(Type metadata) => type.metadata(metadata);

  InstanceFieldReflection field(String name) => new InstanceFieldReflection(_instance, name);
}

class InstanceFieldReflection {
  InstanceMirror _instance;

  Symbol _symbol;

  String _name;

  InstanceFieldReflection(InstanceMirror instance, String name) {
    _instance = instance;
    _name = name;
    _symbol = MirrorSystem.getSymbol(name);
  }

  get value => _instance
      .getField(_symbol)
      .reflectee;

  set value(value) => _instance.setField(_symbol, value);

  List metadata(Type metadata) => new TypeReflection.fromInstance(_instance.reflectee)
      .field(_name)
      .metadata(metadata);
}
