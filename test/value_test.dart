import 'package:flutter_test/flutter_test.dart';
import 'package:var_widget/src/value.dart';

void main() {
  group('Value', _tests);
}

void _tests() {
  group('.map', () {
    Var<int> v;

    setUp(() {
      v = new Var(0, debugLabel: 'test-var');
    });

    test('usage', () async {
      List<bool> values = [];

      final mapped = v.map((int i) => i > 0);
      mapped.addListener(() {
        values.add(mapped.value);
      });

      v.value = 10;
      expect(
        values,
        equals([true]),
      );

      v.value = -10;
      expect(
        values,
        equals([true, false]),
      );

      v.value = 10;
      expect(
        values,
        equals([true, false, true]),
      );
    });

    test('invalid access', () async {
      final mapped = v.map((int i) => i > 0);
      mapped.addListener(() {});

      expect(
        () => mapped.value,
        _throwsLazyException(),
        reason: ".value of `mapped` widget is accessible only from notifyListeners and it's dependencies",
      );
    });
  });

  group('.computed', () {
    int value = 0;
    ComputedValue<int> v;

    setUp(() {
      v = Value.computed(() => value);
    });

    test('usage', () {
      var values = [];
      v.addListener(() {
        values.add(v.value);
      });

      value = 10;

      expect(
        values,
        equals([]),
        reason: '`.computed` does not update value until .refresh is called',
      );

      v.refresh();

      expect(
        values,
        equals([10]),
        reason: '`.computed` updates value when .refresh is called',
      );
    });

    test('invalid access', () {
      v.addListener(() {});

      expect(
        () => v.value,
        _throwsLazyException(),
        reason: ".value of `computed` widget is accessible only from notifyListeners and it's dependencies",
      );
    });
  });

  group('Var', () {
    test('listenable', () async {
      var called = 0, called2 = 0;
      final v = Var<int>(0, debugLabel: 'test-var');

      v.addListener(() {
        called++;
      });

      expect(v.value, equals(0));

      v.value = 1;

      expect(v.value, equals(1));

      v.addListener(() {
        called2++;
      });

      expect(
        called,
        equals(1),
      );
      expect(
        called2,
        equals(0),
      );

      v.value = 2;

      expect(
        called,
        equals(2),
      );
      expect(
        called2,
        equals(1),
      );
    });
  });
}

Matcher _throwsLazyException() {
  return throwsA(isInstanceOf<LazyException>());
}
