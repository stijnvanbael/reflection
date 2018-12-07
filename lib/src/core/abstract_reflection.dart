import 'package:reflectable/mirrors.dart';
import 'package:reflective/src/core/type_reflection.dart';

abstract class AbstractReflection<M extends DeclarationMirror> {
  M mirror;

  AbstractReflection(this.mirror);

  String get name => mirror.simpleName;

  String get fullName => mirror.qualifiedName;

  bool get isPrivate => mirror.isPrivate;

  bool has(Type metadata) =>
      mirror.metadata.firstWhere(
        (instance) => TypeReflection.fromInstance(instance).rawType == metadata,
        orElse: () => null,
      ) !=
      null;

  List<T> metadata<T>() => List.from(mirror.metadata
      .where((instance) => TypeReflection.fromInstance(instance).rawType == T));
}
