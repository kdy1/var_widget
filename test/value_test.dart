import 'package:flutter_test/flutter_test.dart';
import 'package:var_widget/var_widget.dart';

void main() {
  group('Value', _tests);
}

void _tests() {
  group('.map', () {
    Var<int> v;

    setUp(() {
      v = new Var(0, debugLabel: 'test-var');
    });
    tearDown(() {
      v.close();
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
        throwsAssertionError,
        reason: 'value of mapped widget is accessible only from notifyListeners',
      );
    });
  });

  group('.computed', () {
    Var<int> v;

    setUp(() {
      v = new Var(0);
    });

    tearDown(() {
      v.close();
    });

    test('usage', () {});

    test('invalid access', () {
      Value.computed(() => v.value);
    });
  });

  group('Var', () {
    group('Sink', () {
      test('.add', () {
        var called = 0;
        final v = Var<int>(0, debugLabel: 'test-var');

        v.addListener(() {
          called++;
        });

        v.add(1);

        expect(
          v.value,
          equals(1),
        );
        expect(
          called,
          equals(1),
        );

        v.close();
      });
    });

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

      v.close();
    });
  });
}
