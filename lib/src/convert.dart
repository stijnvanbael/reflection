library reflective.convert;

import 'dart:convert';

import 'package:reflective/core.dart';

typedef dynamic Transformation(dynamic object);

class Conversion {
  var object;
  Type source;

  Conversion(this.object) {
    source = TypeReflection.fromInstance(object).rawType;
  }

  static Conversion convert(object) {
    return Conversion(object);
  }

  to(Type target) {
    Converter converter = Converters.find(source, target);
    if (converter is ConverterBase) {
      return converter.convertTo(object, target);
    }
    return converter.convert(object);
  }
}

class Converters {
  static Set<ConverterBase> converters = Set();

  static ConverterBase register(Type source, Type target, Transformation conversion) {
    ConverterBase converter = ConverterBase(source, target, conversion);
    converters.add(converter);
    return converter;
  }

  static ConverterBase add(ConverterBase converter) {
    converters.add(converter);
    return converter;
  }

  static ConverterBase find(Type source, Type target) {
    TypeReflection sourceReflection = type(source);
    TypeReflection targetReflection = type(target);
    Map<int, ConverterBase> scored = {};
    converters.forEach((c) {
      int score = ((c.source == source) ? 2 : (type(c.source).sameOrSuper(sourceReflection)) ? 1 : -2) +
          ((c.target == target) ? 2 : (type(c.target).sameOrSuper(targetReflection)) ? 1 : -2);
      if (score >= 2) scored[score] = c;
    });
    if (scored.containsKey(4)) return scored[4];
    if (scored.containsKey(3)) return scored[3];
    if (scored.containsKey(2)) return scored[2];
    throw ConverterException('No converter found from ' + source.toString() + ' to ' + target.toString() + '.');
  }
}

class ConverterBase<S, T> extends Converter<S, T> {
  Type source;
  Type target;
  Transformation conversion;

  ConverterBase(this.source, this.target, [this.conversion]);

  T convert(S object) {
    return convertTo(object, target);
  }

  T convertTo(S object, Type targetReflection) {
    return conversion(object);
  }
}

class ConverterException implements Exception {
  final String message;

  ConverterException(this.message);

  toString() => message;
}

class ObjectToJson<T> extends ConverterBase<T, Json> {
  ObjectToJson() : super(T, Json);

  Json convertTo(T object, Type targetType) {
    var simplified = _convert(object);
    return Json(jsonEncode(simplified));
  }

  _convert(object) {
    if (object is DateTime) {
      return object.toString();
    } else if (object == null || object is String || object is num || object is bool) {
      return object;
    } else if (object is Iterable) {
      return List.from(object.map((item) => _convert(item)));
    } else if (object is Map) {
      Map map = {};
      object.keys.forEach((k) => map[k.toString()] = _convert(object[k]));
      return map;
    } else {
      TypeReflection type = TypeReflection.fromInstance(object);
      return type.fields.values
          .where((field) => !field.has(Transient))
          .map((field) => {field.name: _convert(field.value(object))})
          .reduce((Map m1, Map m2) {
        m2.addAll(m1);
        return m2;
      });
    }
  }
}

class JsonToObject<T> extends ConverterBase<Json, T> {
  JsonToObject() : super(Json, T);

  convertTo(Json json, Type target) {
    var decoded = jsonDecode(json.toString());
    return _convert(decoded, type(target));
  }

  _convert(object, TypeReflection targetReflection) {
    if (object is Map) {
      if (targetReflection.sameOrSuper(Map)) {
        TypeReflection keyType = targetReflection.genericArguments[0].value;
        TypeReflection valueType = targetReflection.genericArguments[1].value;
        Map map = targetReflection.construct();
        object.keys.forEach((k) {
          var newKey = keyType.sameOrSuper(k) ? k : keyType.construct(args: [k]);
          map[newKey] = _convert(object[k], valueType);
        });
        return map;
      } else {
        var instance = targetReflection.construct();
        object.keys.forEach((k) {
          if (targetReflection.fields[k] == null)
            throw JsonException('Unknown property: ' + targetReflection.fullName + '.' + k);
        });
        targetReflection.fields.forEach((name, field) =>
            field.set(instance, _convert(object[name], field.type)));
        return instance;
      }
    } else if (object is Iterable) {
      TypeReflection itemType = targetReflection.genericArguments[0].value;
      return List.from(object.map((i) => _convert(i, itemType)));
    } else if (targetReflection.sameOrSuper(DateTime)) {
      return DateTime.parse(object);
    } else {
      return object;
    }
  }
}

class JsonException extends ConverterException {
  JsonException(String message) : super(message);
}

@reflector
class Json {
  String value;

  Json(this.value);

  toString() => value;

  bool operator ==(o) => o is Json && value == o.value;

  int get hashCode => value.hashCode;
}

@reflector
class Transient {
  const Transient();
}

const Transient transient = const Transient();
