Dart Reflective
===============

Reflective is fluent reflection API for Dart.

Examples:

    TypeReflection typeOfEmployeeName = type(Employee).field('name').type;

    Employee employee = type(Employee).construct(name: 'John Doe', email: 'john@doe.org');