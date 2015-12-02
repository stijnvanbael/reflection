part of reflective.reflective;

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
