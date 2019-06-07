library reflective.convert;

import 'dart:convert';

import 'package:reflective/src/core.dart';

typedef dynamic Transformation(dynamic object);

class Conversion {
  var object;
  TypeReflection source;

  Conversion(this.object) {
    source = new TypeReflection.fromInstance(object);
  }

  static Conversion convert(object) {
    return new Conversion(object);
  }

  to(Type target, [List<Type> arguments]) {
    return toReflection(new TypeReflection(target, arguments));
  }

  toReflection(TypeReflection targetReflection) {
    Converter converter = Converters.find(source, targetReflection);
    if (converter is ConverterBase) {
      return converter.convertTo(object, targetReflection);
    }
    return converter.convert(object);
  }
}

class Converters {
  static Set<ConverterBase> converters = new Set();

  static ConverterBase register(Type source, Type target, Transformation conversion) {
    ConverterBase converter = new ConverterBase(new TypeReflection(source), new TypeReflection(target), conversion);
    converters.add(converter);
    return converter;
  }

  static ConverterBase add(ConverterBase converter) {
    converters.add(converter);
    return converter;
  }

  static ConverterBase find(TypeReflection source, TypeReflection target) {
    Map<int, ConverterBase> scored = {};
    converters.forEach((c) {
      int score = ((c.source == source) ? 2 : (c.source.sameOrSuper(source)) ? 1 : -2) +
          ((c.target == target) ? 2 : (c.target.sameOrSuper(target)) ? 1 : -2);
      if (score >= 2) scored[score] = c;
    });
    if (scored.containsKey(4)) return scored[4];
    if (scored.containsKey(3)) return scored[3];
    if (scored.containsKey(2)) return scored[2];
    throw new ConverterException('No converter found from ' + source.toString() + ' to ' + target.toString() + '.');
  }
}

class ConverterBase<S, T> extends Converter<S, T> {
  TypeReflection source;
  TypeReflection target;
  Transformation conversion;

  ConverterBase(this.source, this.target, [this.conversion]);

  T convert(S object) {
    return convertTo(object, target);
  }

  T convertTo(S object, TypeReflection targetReflection) {
    return conversion(object);
  }
}

class ConverterException implements Exception {
  final String message;

  ConverterException(this.message);

  toString() => message;
}

installJsonConverters() {
  Converters.add(new ObjectToJson());
  Converters.add(new JsonToObject());
}

class ObjectToJson extends ConverterBase<Object, Json> {
  ObjectToJson() : super(new TypeReflection(Object), new TypeReflection(Json));

  Json convertTo(Object object, TypeReflection targetReflection) {
    var simplified = _convert(object);
    return new Json(jsonEncode(simplified));
  }

  _convert(object) {
    if (object is DateTime) {
      return object.toString();
    } else if (object == null || object is String || object is num || object is bool) {
      return object;
    } else if (object is Iterable) {
      return new List.from(object.map((item) => _convert(item)));
    } else if (object is Map) {
      Map map = {};
      object.keys.forEach((k) => map[k.toString()] = _convert(object[k]));
      return map;
    } else {
      TypeReflection type = new TypeReflection.fromInstance(object);
      if (type.isEnum) {
        var string = object.toString();
        return string.substring(string.indexOf('.') + 1);
      }
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

class JsonToObject extends ConverterBase<Json, Object> {
  JsonToObject() : super(new TypeReflection(Json), new TypeReflection(Object));

  convertTo(Json json, TypeReflection targetReflection) {
    var decoded = jsonDecode(json.toString());
    return _convert(decoded, targetReflection);
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
        targetReflection.fields.forEach((name, field) {
          if (field != null) {
            field.set(instance, _convert(object[name], field.type));
          }
        });
        return instance;
      }
    } else if (object is Iterable) {
      TypeReflection itemType = targetReflection.genericArguments[0].value;
      List list = targetReflection.construct();
      object.forEach((i) => list.add(_convert(i, itemType)));
      return list;
    } else if (targetReflection.sameOrSuper(DateTime)) {
      return DateTime.parse(object);
    } else if (targetReflection.isEnum) {
      return targetReflection.enumValues.firstWhere((v) => v.toString().endsWith('.$object'), orElse: () => null);
    } else {
      return object;
    }
  }
}

class JsonException extends ConverterException {
  JsonException(String message) : super(message);
}

class Json {
  String value;

  Json(this.value);

  toString() => value;

  bool operator ==(o) => o is Json && value == o.value;

  int get hashCode => value.hashCode;
}

class Transient {
  const Transient();
}

const Transient transient = const Transient();
