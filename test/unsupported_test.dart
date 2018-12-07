import 'package:reflective/core.dart';
import 'package:test/test.dart';

import 'reflective_test.dart';
import 'reflective_test.reflectable.dart';

main() {
  initializeReflectable();
  group('Reflection - unsupported features', () {
    test('Generic properties', () {
      var mirror = reflector.reflectType(GenericTypeWithAProperty);
      var typeReflection = TypeReflection.fromMirror(mirror.originalDeclaration);
      var field = typeReflection.fields['property'];
      expect(field.isGeneric, true);

      var otherTypeReflection = type(BaseClass);
      field = otherTypeReflection.fields['id'];
      expect(field.isGeneric, false);
    });

    test('Instance of generic declaration', () {
      var instance = GenericType<int>();
      var typeReflection = TypeReflection.fromInstance(instance);
      expect(typeReflection.genericArguments.length, 1);
      expect(typeReflection.genericArguments[0].name, 'T');
      expect(typeReflection.genericArguments[0].value, TypeReflection(int));
    });

    test('Dynamic generic arguments', () {
      TypeReflection<Map> reflection = TypeReflection.fromInstance({});
      expect(reflection.genericArguments.length, 2);
      expect(reflection.genericArguments[0].value, dynamicReflection);
      expect(reflection.genericArguments[1].value, dynamicReflection);
    });

    test('Reuse of reflections', () {
      fail('TODO');
    });
  });
}