library reflective.test;

import 'package:unittest/unittest.dart';
import 'package:reflective/reflective.dart';
import 'package:collection/equality.dart';


main() {
  group('Conversion', () {
    setUp(() {
      installJsonConverters();
    });

    Json requestJson = new Json('{"headers":{"sender":"Deep Thought","accepts":"any gratitude"},"path":"/solution"}');
    Json departmentJson = new Json('{"employees":[{"projects":null,"dateOfBirth":"1974-03-17 00:00:00.000","name":"Mark"},{"projects":null,"dateOfBirth":"1982-11-08 00:00:00.000","name":"Sophie"},{"projects":{"Scrum Master":{"storyPoints":135.5,"ongoing":false,"name":"Payment Platform"},"Lead Developer":{"storyPoints":307.0,"ongoing":true,"name":"Loyalty"}},"dateOfBirth":"1979-07-22 00:00:00.000","name":"Ellen"}],"name":"Development"}');
    Request request = new Request('/solution', {'sender': 'Deep Thought', 'accepts': 'any gratitude'});
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


    Json requestJsonWithUnknownProperty = new Json('{"headers":{"sender":"Deep Thought","accepts":"any gratitude"},"path":"/solution","unknown":"unknown"}');

    test('Unknown JSON property on target Object', () {
      expect(() => Conversion.convert(requestJsonWithUnknownProperty).to(Request), throwsA(
        predicate((e) => e is JsonException && e.message == 'Unknown property: reflective.test.Request.unknown')
      ));
    });
  });
}

Function listEq = const ListEquality().equals;
Function mapEq = const MapEquality().equals;

class Department {
  String name;
  List<Employee> employees;

  Department([this.name, this.employees]);

  bool operator ==(o) => o is Department && name == o.name && listEq(employees, o.employees);

  int get hashCode => name.hashCode + employees.hashCode;
}

class Employee {
  String name;
  DateTime dateOfBirth;
  Map<Role, Project> projects;
  @transient String sessionId;

  Employee([this.name, this.dateOfBirth, this.projects, this.sessionId]);

  bool operator ==(o) => o is Employee && name == o.name && dateOfBirth == o.dateOfBirth && mapEq(projects, o.projects);

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

  Project([this.name, this.ongoing, this.storyPoints]);

  bool operator ==(o) => o is Project  && name == o.name && ongoing == o.ongoing && storyPoints == o.storyPoints;

  int get hashCode => name.hashCode + ongoing.hashCode + storyPoints.hashCode;
}

class Request {
  String path;
  Map<String, String> headers;

  Request([this.path, this.headers]);

  bool operator ==(o) => o is Request && path == o.path && mapEq(headers, o.headers);
}