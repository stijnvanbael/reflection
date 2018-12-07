library reflective.util;

class Objects {
  static int hash(List toHash) =>
      toHash.fold(17, (e1, e2) => (e1 != null ? e1.hashCode : 1) * 37 + (e2 != null ? e2.hashCode : 1));
}

class Maps {
  static Map index(Iterable iterable, indexer(key)) {
    Map result = {};
    iterable.forEach((i) => result[indexer(i)] = i);
    return result;
  }

  static Map where(Map map, predicate(key, value)) {
    Map result = {};
    forEach(map, (k, v) {
      if (predicate(k, v)) result[k] = v;
    });
    return result;
  }

  static forEach(Map map, function(key, value)) {
    map.keys.forEach((k) => function(k, map[k]));
  }
}

abstract class Optional<T> {
  const Optional();

  factory Optional.of(T value) {
    return value == null ? empty : Present(value);
  }

  factory Optional.ofIterable(Iterable<T> iterable) {
    if (iterable != null && iterable.length > 1) {
      throw RangeError.range(iterable.length, 0, 1, 'iterable.length');
    }
    return iterable == null || iterable.isEmpty ? empty : Present(iterable.first);
  }

  T get();

  T orElse(T other);

  T orNull();

  T or(T supplier());

  Optional map(dynamic mapper(T value));

  Optional expand(Optional mapper(T value));

  Optional<T> where(bool predicate(T value));

  List<T> toList();

  Optional<T> ifPresent(void handler(T value));

  Optional<T> ifAbsent(void handler());

  bool isPresent();
}

const empty = const Empty();

class Empty<T> extends Optional<T> {
  const Empty();

  T get() => throw AbsentException();

  T orElse(T other) => other;

  T orNull() => null;

  T or(T supplier()) => supplier();

  Optional map(dynamic mapper(T value)) => this;

  Optional expand(Optional mapper(T value)) => this;

  Optional<T> where(bool predicate(T value)) => this;

  List<T> toList() => [];

  Optional<T> ifPresent(void handler(T value)) => this;

  Optional<T> ifAbsent(void handler()) {
    handler();
    return this;
  }

  bool isPresent() => false;
}

class Present<T> extends Optional<T> {
  T value;

  Present(this.value);

  T get() => value;

  T orElse(T other) => value;

  T orNull() => value;

  T or(T supplier()) => value;

  Optional map(dynamic mapper(T value)) => Optional.of(mapper(value));

  Optional expand(Optional mapper(T value)) => mapper(value);

  Optional<T> where(bool predicate(T value)) => predicate(value) ? this : empty;

  List<T> toList() => [value];

  Optional<T> ifPresent(void handler(T value)) {
    handler(value);
    return this;
  }

  Optional<T> ifAbsent(void handler()) => this;

  bool isPresent() => true;
}

class AbsentException {
}