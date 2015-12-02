part of reflective.reflective;

class Objects {
  static int hash(List toHash) =>
      toHash.fold(17, (e1, e2) => (e1 != null ? e1.hashCode : 1) * 37 + (e2 != null ? e2.hashCode : 1));
}
