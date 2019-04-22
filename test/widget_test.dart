import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:var_widget/var_widget.dart';

void main() {
  group('VarWidget', _tests);
}

void _tests() {
  group('VarWidget', () {
    Var<String> v;

    setUp(() {
      v = new Var('');
    });

    tearDown(() {
      v.close();
    });

    testWidgets('works', (WidgetTester tester) async {
      await tester.pumpWidget(_render(v));

      expect(
        find.text(''),
        findsOneWidget,
      );

      v.value = 'foo';

      expect(
        find.text(''),
        findsOneWidget,
        reason: 'should not be updated yet',
      );

      await tester.pump();

      expect(
        find.text(''),
        findsNothing,
      );

      expect(
        find.text('foo'),
        findsOneWidget,
      );
    });
  });

  group('VarBuilder', () {});
}

Widget _render(Value<String> v) {
  return MaterialApp(
    home: _VarText(value: v),
  );
}

class _VarText extends VarWidget<String> {
  const _VarText({
    Key key,
    @required Value<String> value,
  }) : super(
          key: key,
          value: value,
        );

  @override
  Widget build(BuildContext context) {
    return Text(value);
  }
}
