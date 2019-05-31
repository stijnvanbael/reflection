part of reflective.core;

abstract class AbstractReflection<M extends DeclarationMirror> {
  M _mirror;

  AbstractReflection(this._mirror);

  String get name => MirrorSystem.getName(_mirror.simpleName);

  String get fullName => MirrorSystem.getName(_mirror.qualifiedName);

  bool get isPrivate => _mirror.isPrivate;

  bool has(Type metadata) =>
      _mirror.metadata.firstWhere((instance) => instance.type.reflectedType == metadata, orElse: () => null) != null;

  List metadata(Type type) => metadataWhere((metadata) => metadata.runtimeType == type);

  List metadataWhere(bool filter(metadata)) =>
      new List.from(_mirror.metadata.map((instance) => instance.reflectee).where(filter));
}
