Dart Reflective
===============

Reflective is fluent reflection API for Dart.

Examples:

    TypeReflection typeOfEmployeeName = reflect(Employee).field('name').type;

    Employee employee = reflect(Employee).construct(name: 'John Doe', email: 'john@doe.org');