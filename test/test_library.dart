library reflective.test_library;

import 'package:reflective/reflective.dart';


@reflector
class TestType1 {}

@reflector
class TestType2 {}

@reflector
abstract class TestBaseType {}

@reflector
class TestType3 extends TestBaseType {}
