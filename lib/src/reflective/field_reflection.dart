part of reflective.reflective;

abstract class FieldReflection {
  bool has(Type metadata);

  value(Object entity);

  set(Object entity, value);

  TypeReflection get type;

  String get name;
}
