part of reflective.core;

class MethodReflection extends AbstractReflection<MethodMirror> {
  MethodReflection(MethodMirror mirror) : super(mirror);

  TypeReflection get returnType => TypeReflection.fromMirror(_mirror.returnType);

  dynamic invoke(dynamic object, List<dynamic> positionalArguments) =>
    reflect(object).invoke(_mirror.simpleName, positionalArguments).reflectee;

  Map<String, ParameterReflection> get parameters {
    var params = <String, ParameterReflection>{};
    _mirror.parameters.forEach((mirror) {
      var reflection = new ParameterReflection(mirror);
      params[reflection.name] = reflection;
    });
    return params;
  }
}

class ParameterReflection extends AbstractReflection<ParameterMirror> {
  ParameterReflection(ParameterMirror mirror) : super(mirror);

  TypeReflection get type => TypeReflection.fromMirror(_mirror.type);
}
