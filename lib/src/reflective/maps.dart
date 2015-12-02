part of reflective.reflective;

class Maps {
  static Map where(Map map, predicate(key, value)) {
    Map result = {};
    map.forEach((k, v) {
      if (predicate(k, v)) result[k] = v;
    });
    return result;
  }
}
