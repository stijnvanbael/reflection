library reflective.test;

import 'package:unittest/unittest.dart';
import 'package:reflective/reflective.dart';
import 'package:collection/equality.dart';


main() {
  group('Core', () {
    setUp(() {
      installJsonConverters();
    });

    test('Object to JSON', () {
      Department department = new Department("Development", [ new Employee("Mark", DateTime.parse("1974-03-17")), new Employee("Sophie", DateTime.parse("1982-11-08")), new Employee("Ellen", DateTime.parse("1979-07-22")) ]);
      var json = Conversion.convert(department).to(Json);
      expect(json, new Json("{\"employees\":[{\"dateOfBirth\":\"1974-03-17 00:00:00.000\",\"name\":\"Mark\"},{\"dateOfBirth\":\"1982-11-08 00:00:00.000\",\"name\":\"Sophie\"},{\"dateOfBirth\":\"1979-07-22 00:00:00.000\",\"name\":\"Ellen\"}],\"name\":\"Development\"}"));
    });

    test('JSON to Object', () {
      Json json = new Json("{\"employees\":[{\"dateOfBirth\":\"1974-03-17 00:00:00.000\",\"name\":\"Mark\"},{\"dateOfBirth\":\"1982-11-08 00:00:00.000\",\"name\":\"Sophie\"},{\"dateOfBirth\":\"1979-07-22 00:00:00.000\",\"name\":\"Ellen\"}],\"name\":\"Development\"}");
      var department = Conversion.convert(json).to(Department);
      expect(department, new Department("Development", [ new Employee("Mark", DateTime.parse("1974-03-17")), new Employee("Sophie", DateTime.parse("1982-11-08")), new Employee("Ellen", DateTime.parse("1979-07-22")) ]));
    });
  });
}

Function listEq = const ListEquality().equals;

class Department {
  String name;
  List<Employee> employees;

  Department([this.name, this.employees]);

  bool operator ==(o) => o is Department && name == o.name && listEq(employees, o.employees);
}

class Employee {
  String name;
  DateTime dateOfBirth;

  Employee([this.name, this.dateOfBirth]);

  bool operator ==(o) => o is Employee && name == o.name && dateOfBirth == o.dateOfBirth;
}