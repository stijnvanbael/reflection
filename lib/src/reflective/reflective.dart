library reflective.reflective;

import 'dart:mirrors';

part 'field_reflection.dart';
part 'maps.dart';
part 'objects.dart';
part 'simple_field_reflection.dart';
part 'transitive_field_reflection.dart';
part 'type_reflection.dart';

TypeReflection type(Type type) => new TypeReflection(type);

TypeReflection instance(Object instance) => new TypeReflection.fromInstance(instance);

TypeReflection<dynamic> dynamicReflection = new TypeReflection(dynamic);
