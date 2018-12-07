library reflective.test;

import 'package:collection/collection.dart';
import 'package:reflectable/mirrors.dart';
import 'package:reflectable/reflectable.dart';
import 'package:reflective/reflective.dart';
import 'package:test/test.dart';

import 'reflective_test.reflectable.dart';
import 'test_library.dart';

main() {
  initializeReflectable();
  group('Reflection', () {
    test('Transitive fields', () {
      TypeReflection<Project> reflection = TypeReflection(Project);
      FieldReflection field = reflection.field('lead.name');
      Project project = Project();
      project.lead = Employee('John');
      expect(field.value(project), 'John');

      field.set(project, 'Emma');
      expect(project.lead.name, 'Emma');
    });

    test('Fields where', () {
      TypeReflection<Employee> reflection = TypeReflection(Employee);
      Map<String, FieldReflection> fields = reflection.fieldsWhere((field) => field.rawType == String);
      expect(fields, {
        'name': reflection.field('name'),
        'jobDescription': reflection.field('jobDescription'),
        'sessionId': reflection.field('sessionId')
      });
    });

    test('Field metadata', () {
      TypeReflection<Employee> reflection = TypeReflection(Employee);
      FieldReflection sessionId = reflection.field('sessionId');
      expect(sessionId.has(Transient), true);
      expect(sessionId.metadata<Transient>(), [transient, transient]);
    });

    test('Names', () {
      TypeReflection<Project> reflection = TypeReflection(Project);
      expect(reflection.name, 'Project');
      expect(reflection.fullName, 'reflective.test.Project');
    });

    test('Generic extraction', () {
      TypeReflection<Project> reflection = TypeReflection<Project>();
      expect(reflection.name, 'Project');
      expect(reflection.fullName, 'reflective.test.Project');
    });

    test('Enums', () {
      TypeReflection<Status> status = TypeReflection(Status);
      expect(status.isEnum, true);
      expect(status.enumValues, Status.values);

      TypeReflection<Project> project = TypeReflection(Project);
      expect(project.isEnum, false);
      expect(project.enumValues, null);
    });

    test('Returns fields on base classes', () {
      var fields = TypeReflection(MainClass).fields;

      expect(fields.keys.any((k) => k == 'id'), true);
      expect(fields.keys.any((k) => k == 'name'), true);
      expect(fields.keys.any((k) => k == 'works'), true);
    });

    test('isAbstract', () {
      var baseType = type(AbstractBaseClass);
      expect(baseType.isAbstract, true);
    });

    test('Superclass', () {
      var subclass = type(OtherSubclass);
      expect(subclass.superclass.name, 'AbstractBaseClass');
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

    test('Non generic type', () {
      var typeReflection = type(Role);
      expect(typeReflection.isGeneric, false);
    });

    test('Generic declaration', () {
      ClassMirror typeMirror = reflector.reflectType(GenericType);
      var typeReflection = TypeReflection.fromMirror(typeMirror.originalDeclaration);
      expect(typeReflection.genericArguments.length, 1);
      expect(typeReflection.genericArguments[0].name, 'T');
      expect(typeReflection.genericArguments[0].value, isNull);
    });

    test('Type with a const', () {
      var typeReflection = type(ClassWithConst);
      expect(typeReflection.fields['field'].isConst, true);
    });
  });

  group('Library Reflection', () {
    test('Types', () {
      var libraryReflection = LibraryReflection('reflective.test_library');
      expect(libraryReflection.types.any((x) => x.rawType == TestType1), true);
      expect(libraryReflection.types.any((x) => x.rawType == TestType2), true);
      expect(libraryReflection.types.any((x) => x.rawType == TestType3), true);
      expect(libraryReflection.types.any((x) => x.rawType == TestBaseType), true);
    });

    test('Name', () {
      var libraryReflection = LibraryReflection('reflective.test_library');
      expect(libraryReflection.name, 'reflective.test_library');
    });

    test('No superclass', () {
      var departmentType = type(Department);
      expect(departmentType.superclass.rawType, Object);
    });

    test('Variable generic arguments', () {
      TypeReflection<Map<String, Project>> reflection = TypeReflection(Map, [String, Project]);
      expect(reflection.genericArguments.length, 2);
      expect(reflection.genericArguments[0].value, TypeReflection(String));
      expect(reflection.genericArguments[1].value, TypeReflection(Project));
    });
  });

  group('Conversion', () {
    setUp(() {
      Converters.add(ObjectToJson<Request>());
      Converters.add(ObjectToJson<Department>());
      Converters.add(JsonToObject<Request>());
      Converters.add(JsonToObject<Department>());
    });

    Json requestJson = Json('{"headers":{"sender":"Deep Thought","accepts":"any gratitude"},"path":"/solution"}');
    Json departmentJson = Json(
        '{"employees":[{"projects":null,"dateOfBirth":"1974-03-17 00:00:00.000","name":"Mark"},{"projects":null,"dateOfBirth":"1982-11-08 00:00:00.000","name":"Sophie"},'
        '{"projects":{"Scrum Master":{"lead":null,"storyPoints":135.5,"ongoing":false,"name":"Payment Platform"},"Lead Developer":{"lead":null,"storyPoints":307.0,"ongoing":true,"name":"Loyalty"}},'
        '"dateOfBirth":"1979-07-22 00:00:00.000","name":"Ellen"}],"name":"Development"}');
    Request request = Request('/solution', {'sender': 'Deep Thought', 'accepts': 'any gratitude'});
    Department department = Department('Development', [
      Employee('Mark', DateTime.parse('1974-03-17')),
      Employee('Sophie', DateTime.parse('1982-11-08'), null, "15edf9a"),
      Employee('Ellen', DateTime.parse('1979-07-22'), {
        Role('Scrum Master'): Project('Payment Platform', false, 135.5),
        Role('Lead Developer'): Project('Loyalty', true, 307.0)
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

    Json requestJsonWithUnknownProperty =
        Json('{"headers":{"sender":"Deep Thought","accepts":"any gratitude"},"path":"/solution","unknown":"unknown"}');

    test('Unknown JSON property on target Object', () {
      expect(
          () => Conversion.convert(requestJsonWithUnknownProperty).to(Request),
          throwsA(predicate(
              (e) => e is JsonException && e.message == 'Unknown property: reflective.test.Request.unknown')));
    });
  });
}

Function listEq = const ListEquality().equals;
Function mapEq = const MapEquality().equals;

@reflector
class Department {
  String name;
  List<Employee> employees;

  Department([this.name, this.employees]);

  bool operator ==(o) => o is Department && name == o.name && listEq(employees, o.employees);

  int get hashCode => name.hashCode + employees.hashCode;
}

@reflector
class Employee {
  String name;
  DateTime dateOfBirth;
  Map<Role, Project> projects;
  @transient
  String jobDescription;
  @transient
  @transient
  String sessionId;

  Employee([this.name, this.dateOfBirth, this.projects, this.sessionId]);

  bool operator ==(o) => o is Employee && name == o.name && dateOfBirth == o.dateOfBirth && mapEq(projects, o.projects);

  int get hashCode => name.hashCode + dateOfBirth.hashCode + projects.hashCode;
}

@reflector
class Role {
  String name;

  Role(this.name);

  String toString() => name;

  bool operator ==(o) => o is Role && name == o.name;

  int get hashCode => name.hashCode;
}

@reflector
class Project {
  String name;
  bool ongoing;
  double storyPoints;
  Employee lead;

  Project([this.name, this.ongoing, this.storyPoints]);

  bool operator ==(o) => o is Project && name == o.name && ongoing == o.ongoing && storyPoints == o.storyPoints;

  int get hashCode => name.hashCode + ongoing.hashCode + storyPoints.hashCode;
}

@reflector
class Request {
  String path;
  Map<String, String> headers;

  Request([this.path, this.headers]);

  bool operator ==(o) => o is Request && path == o.path && mapEq(headers, o.headers);
}

@reflector
class BaseClass {
  int id;
}

@reflector
class SubClass extends BaseClass {
  String name;
}

@reflector
class MainClass extends SubClass {
  bool works;
}

@reflector
enum Status { active, suspended, deleted }

@reflector
abstract class AbstractBaseClass {}

@reflector
class OtherSubclass extends AbstractBaseClass {}

@reflector
class ClassWithMixin extends AbstractBaseClass with AMixin {}

@reflector
class AMixin {
  int mixinProperty;
}

@reflector
class GenericType<T> {}

@reflector
class GenericTypeWithAProperty<T> {
  T property;
}

@reflector
class ClassWithConst {
  static const String field = 'hello';
}
