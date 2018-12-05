library reflective.test;

import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:reflective/reflective.dart';
import 'package:test/test.dart';

import 'test_library.dart';

main() {
  group('Reflection', () {
    test('Variable generic arguments', () {
      TypeReflection<Map<String, Project>> reflection =
          new TypeReflection(Map, [String, Project]);
      expect(reflection.genericArguments.length, 2);
      expect(reflection.genericArguments[0].value, new TypeReflection(String));
      expect(reflection.genericArguments[1].value, new TypeReflection(Project));
    });

    test('Dynamic generic arguments', () {
      TypeReflection<Map> reflection = new TypeReflection.fromInstance({});
      expect(reflection.genericArguments.length, 2);
      expect(reflection.genericArguments[0].value, dynamicReflection);
      expect(reflection.genericArguments[1].value, dynamicReflection);
    });

    test('Transitive fields', () {
      TypeReflection<Project> reflection = new TypeReflection(Project);
      FieldReflection field = reflection.field('lead.name');
      Project project = new Project();
      project.lead = new Employee('John');
      expect(field.value(project), 'John');

      field.set(project, 'Emma');
      expect(project.lead.name, 'Emma');
    });

    test('Fields where', () {
      TypeReflection<Employee> reflection = new TypeReflection(Employee);
      Map<String, FieldReflection> fields =
          reflection.fieldsWhere((field) => field.type.rawType == String);
      expect(fields, {
        'name': reflection.field('name'),
        'jobDescription': reflection.field('jobDescription'),
        '_sessionId': reflection.field('_sessionId')
      });
    });

    test('Private field', () {
      TypeReflection<Employee> reflection = new TypeReflection(Employee);
      FieldReflection sessionId = reflection.field('_sessionId');
      FieldReflection name = reflection.field('name');
      expect(sessionId.isPrivate, true);
      expect(name.isPrivate, false);
    });

    test('Field metadata', () {
      TypeReflection<Employee> reflection = new TypeReflection(Employee);
      FieldReflection sessionId = reflection.field('_sessionId');
      expect(sessionId.has(Transient), true);
      expect(sessionId.metadata(Transient), [transient, transient]);
    });

    test('Names', () {
      TypeReflection<Project> reflection = new TypeReflection(Project);
      expect(reflection.name, 'Project');
      expect(reflection.fullName, 'reflective.test.Project');
    });

    test('Enums', () {
      TypeReflection<Status> status = new TypeReflection(Status);
      expect(status.isEnum, true);
      expect(status.enumValues, Status.values);

      TypeReflection<Project> project = new TypeReflection(Project);
      expect(project.isEnum, false);
      expect(project.enumValues, null);
    });

    test('Returns fields on base classes', () {
      var fields = new TypeReflection(MainClass).fields;

      expect(fields.keys.any((k) => k == "id"), true);
      expect(fields.keys.any((k) => k == "name"), true);
      expect(fields.keys.any((k) => k == "works"), true);
    });

    test('isAbstract', () {
      var baseType = type(AbstractBaseClass);
      expect(baseType.isAbstract, true);
    });

    test('Superclass', () {
      var subclass = type(OtherSubclass);
      expect(subclass.superclass.name, 'AbstractBaseClass');
    });

    test('No superclass', () {
      var departmentType = type(Department);
      expect(departmentType.superclass.rawType, Object);
    });

    test('With mixins', () {
      var mixinType = type(ClassWithMixin);
      expect(mixinType.superclass.mixin.rawType, AMixin);
    });

    test('Get library', () {
      var typeReflection = type(TestType1);
      expect(typeReflection.library.name, 'reflective.test_library');
    });

    test('Generic types', () {
      var typeReflection = type(GenericType);
      expect(typeReflection.isGeneric, true);
    });

    test("Generic properties", () {
      var mirror = reflectClass(GenericTypeWithAProperty);
      var typeReflection =
          new TypeReflection.fromMirror(mirror.originalDeclaration);
      var field = typeReflection.fields["property"];
      expect(field.isGeneric, true);

      var otherTypeReflection = type(BaseClass);
      field = otherTypeReflection.fields["id"];
      expect(field.isGeneric, false);
    });

    test('Non generic type', () {
      var typeReflection = type(Role);
      expect(typeReflection.isGeneric, false);
    });

    test('Generic declaration', () {
      ClassMirror typeMirror = reflectClass(GenericType);
      var typeReflection =
          new TypeReflection.fromMirror(typeMirror.originalDeclaration);
      expect(typeReflection.genericArguments.length, 1);
      expect(typeReflection.genericArguments[0].name, "T");
      expect(typeReflection.genericArguments[0].value, isNull);
    });

    test("Instance of generic declaration", () {
      var instance = new GenericType<int>();
      var typeReflection = new TypeReflection.fromInstance(instance);
      expect(typeReflection.genericArguments.length, 1);
      expect(typeReflection.genericArguments[0].name, "T");
      expect(typeReflection.genericArguments[0].value, new TypeReflection(int));
    });

    test('Non generic type', () {
      var typeReflection = type(ClassWithConst);
      expect(typeReflection.fields["field"].isConst, true);
    });

    test('Reuse of reflections', () {
      // TODO
    });
  });

  group('Library Reflection', () {
    test('Types', () {
      var libraryReflection = new LibraryReflection('reflective.test_library');
      expect(libraryReflection.types.any((x) => x.rawType == TestType1), true);
      expect(libraryReflection.types.any((x) => x.rawType == TestType2), true);
      expect(libraryReflection.types.any((x) => x.rawType == TestType3), true);
      expect(
          libraryReflection.types.any((x) => x.rawType == TestBaseType), true);
    });

    test('Name', () {
      var libraryReflection = new LibraryReflection('reflective.test_library');
      expect(libraryReflection.name, 'reflective.test_library');
    });
  });

  group('Conversion', () {
    setUp(() {
      installJsonConverters();
    });

    Json requestJson = new Json(
        '{"headers":{"sender":"Deep Thought","accepts":"any gratitude"},"path":"/solution"}');
    Json departmentJson = new Json(
        '{"employees":[{"projects":null,"dateOfBirth":"1974-03-17 00:00:00.000","name":"Mark"},{"projects":null,"dateOfBirth":"1982-11-08 00:00:00.000","name":"Sophie"},'
        '{"projects":{"Scrum Master":{"lead":null,"storyPoints":135.5,"ongoing":false,"name":"Payment Platform"},"Lead Developer":{"lead":null,"storyPoints":307.0,"ongoing":true,"name":"Loyalty"}},'
        '"dateOfBirth":"1979-07-22 00:00:00.000","name":"Ellen"}],"name":"Development"}');
    Request request = new Request(
        '/solution', {'sender': 'Deep Thought', 'accepts': 'any gratitude'});
    Department department = new Department('Development', [
      new Employee('Mark', DateTime.parse('1974-03-17')),
      new Employee('Sophie', DateTime.parse('1982-11-08'), null, "15edf9a"),
      new Employee('Ellen', DateTime.parse('1979-07-22'), {
        new Role('Scrum Master'): new Project('Payment Platform', false, 135.5),
        new Role('Lead Developer'): new Project('Loyalty', true, 307.0)
      })
    ]);

    test('Object to JSON', () {
      expect(Conversion.convert(request).to(Json), requestJson);
      expect(Conversion.convert(department).to(Json), departmentJson);
    });

    test('JSON to Object', () {
      expect(Conversion.convert(requestJson).to(Request), request);
      expect(Conversion.convert(departmentJson).to(Department), department);
    });

    Json requestJsonWithUnknownProperty = new Json(
        '{"headers":{"sender":"Deep Thought","accepts":"any gratitude"},"path":"/solution","unknown":"unknown"}');

    test('Unknown JSON property on target Object', () {
      expect(
          () => Conversion.convert(requestJsonWithUnknownProperty).to(Request),
          throwsA(predicate((e) =>
              e is JsonException &&
              e.message ==
                  'Unknown property: reflective.test.Request.unknown')));
    });
  });
}

Function listEq = const ListEquality().equals;
Function mapEq = const MapEquality().equals;

class Department {
  String name;
  List<Employee> employees;

  Department([this.name, this.employees]);

  bool operator ==(o) =>
      o is Department && name == o.name && listEq(employees, o.employees);

  int get hashCode => name.hashCode + employees.hashCode;
}

class Employee {
  String name;
  DateTime dateOfBirth;
  Map<Role, Project> projects;
  @transient
  String jobDescription;
  @transient
  @transient
  String _sessionId;

  Employee([this.name, this.dateOfBirth, this.projects, this._sessionId]);

  bool operator ==(o) =>
      o is Employee &&
      name == o.name &&
      dateOfBirth == o.dateOfBirth &&
      mapEq(projects, o.projects);

  int get hashCode => name.hashCode + dateOfBirth.hashCode + projects.hashCode;
}

class Role {
  String name;

  Role(this.name);

  String toString() => name;

  bool operator ==(o) => o is Role && name == o.name;

  int get hashCode => name.hashCode;
}

class Project {
  String name;
  bool ongoing;
  double storyPoints;
  Employee lead;

  Project([this.name, this.ongoing, this.storyPoints]);

  bool operator ==(o) =>
      o is Project &&
      name == o.name &&
      ongoing == o.ongoing &&
      storyPoints == o.storyPoints;

  int get hashCode => name.hashCode + ongoing.hashCode + storyPoints.hashCode;
}

class Request {
  String path;
  Map<String, String> headers;

  Request([this.path, this.headers]);

  bool operator ==(o) =>
      o is Request && path == o.path && mapEq(headers, o.headers);
}

class BaseClass {
  int id;
}

class SubClass extends BaseClass {
  String name;
}

class MainClass extends SubClass {
  bool works;
}

enum Status { active, suspended, deleted }

abstract class AbstractBaseClass {}

class OtherSubclass extends AbstractBaseClass {}

class ClassWithMixin extends AbstractBaseClass with AMixin {}

class AMixin {
  int mixinProperty;
}

class GenericType<T> {}

class GenericTypeWithAProperty<T> {
  T property;
}

class ClassWithConst {
  static const String field = "hello";
}
