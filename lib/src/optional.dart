part of reflective;

abstract class Optional<T> {
  const Optional();

  factory Optional.of(T value) {
    return value == null ? empty : new Present(value);
  }

  factory Optional.ofIterable(Iterable<T> iterable) {
    if(iterable != null && iterable.length > 1) {
      throw new RangeError.range(iterable.length, 0, 1, 'iterable.length');
    }
    return iterable == null || iterable.isEmpty ? empty : new Present(iterable.first);
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

  T get() => throw new AbsentException();

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

  Optional map(dynamic mapper(T value)) => new Optional.of(mapper(value));

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