Dart Reflective
===============

[![Build Status](https://drone.io/github.com/stijnvanbael/reflection/status.png)](https://drone.io/github.com/stijnvanbael/reflection/latest)

Reflective is fluent reflection API for Dart.

Examples:

    TypeReflection typeOfEmployeeName = type(Employee).field('name').type;

    Employee employee = type(Employee).construct(name: 'John Doe', email: 'john@doe.org');