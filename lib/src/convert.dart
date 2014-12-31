part of reflective;

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

  to(Type target) {
    TypeReflection targetReflection = new TypeReflection(target);
    Converter converter = Converter.find(source, targetReflection);
    return converter.convert(object, targetReflection);
  }
}

class Converter {
  static List<Converter> converters = [];

  static Converter register(Type source, Type target, Transformation conversion) {
    Converter converter = new Converter(new TypeReflection(source), new TypeReflection(target), conversion);
    converters.add(converter);
    return converter;
  }

  static Converter find(TypeReflection source, TypeReflection target) {
    return converters.firstWhere(
            (c) => c.source.sameOrSuper(source) && c.target.sameOrSuper(target),
        orElse: () => throw new ConverterException("No converter found from " + source.toString() + " to " + target.toString() + "."));
  }

  TypeReflection source;
  TypeReflection target;
  Transformation conversion;

  Converter(this.source, this.target, [this.conversion]);

  convert(object, TypeReflection targetReflection) {
    return conversion(object);
  }
}

class ConverterException implements Exception {
  final String message;

  ConverterException(this.message);

  toString() => message;
}

installJsonConverters() {
  Converter.converters.add(new ObjectToJson());
  Converter.converters.add(new JsonToObject());
}

class ObjectToJson extends Converter {
  // TODO: convert Map to JSON
  ObjectToJson() : super(new TypeReflection(Object), new TypeReflection(Json));

  convert(object, TypeReflection targetReflection) {
    var simplified = simplify(object);
    return new Json(JSON.encode(simplified));
  }

  static simplify(object) {
    if (object is DateTime) {
      return object.toString();
    } else if (object is String || object is int || object is double || object is bool) {
      return object;
    } else if (object is Iterable) {
      return new List.from(object.map((item) => simplify(item)));
    } else if (object is Map) {
      // TODO
    } else {
      TypeReflection type = new TypeReflection.fromInstance(object);
      return type.fields
      .where((field) => !field.has(Ignore))
      .map((field) => {
          field.name: simplify(field.value(object))
      })
      .reduce((Map m1, Map m2) {
        m2.addAll(m1);
        return m2;
      });
    }
  }
}

class JsonToObject extends Converter {
  JsonToObject() : super(new TypeReflection(Json), new TypeReflection(Object));

  convert(Json json, TypeReflection targetReflection) {
    Map map = JSON.decode(json.toString());
    return _convert(map, targetReflection);
  }

  _convert(object, TypeReflection targetReflection) {
    if (object is Map) {
      if (targetReflection.sameOrSuper(Map)) {
        // TODO
      } else {
        var instance = targetReflection.construct();
        targetReflection.fields.forEach(
                (f) => f.set(instance, _convert(object[f.name], f.type)));
        return instance;
      }
    } else if (object is Iterable) {
      var itemType = targetReflection.arguments[0];
      return new List.from(object.map((i) => _convert(i, itemType)));
    } else if (targetReflection.sameOrSuper(DateTime)){
      return DateTime.parse(object);
    } else {
      return object;
    }
  }
}

class Json {
  String value;

  Json(this.value);

  toString() => value;

  bool operator ==(o) => o is Json && value == o.value;

  int get hashCode => value.hashCode;
}

class Ignore {
  const Ignore();
}

const Ignore ignore = const Ignore();