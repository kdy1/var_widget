import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// A widget that rebuilds when the given [Listenable] changes value.
///
/// [ListeningWidget] is most commonly used with [Animation] objects, which are
/// [Listenable], but it can be used with any [Listenable], including
/// [ChangeNotifier] and [ValueNotifier].
///
/// [ListeningWidget] is most useful for widgets widgets that are otherwise
/// stateless. To use [ListeningWidget], simply subclass it and implement the
/// build function.
///
/// For more complex case involving additional state, consider using
/// [AnimatedBuilder].
///
/// See also:
///
///  * [AnimatedBuilder], which is useful for more complex use cases.
///  * [Animation], which is a [Listenable] object that can be used for
///    [listenable].
///  * [ChangeNotifier], which is another [Listenable] object that can be used
///    for [listenable].
abstract class ListeningWidget extends StatefulWidget {
  /// Creates a widget that rebuilds when the given listenable changes.
  ///
  /// The [listenable] argument is required.
  const ListeningWidget({Key key, @required this.listenable})
      : assert(listenable != null),
        super(key: key);

  /// The [Listenable] to which this widget is listening.
  ///
  /// Commonly an [Animation] or a [ChangeNotifier].
  final Listenable listenable;

  /// Override this method to build widgets that depend on the state of the
  /// listenable (e.g., the current value of the animation).
  @protected
  Widget build(BuildContext context);

  /// Subclasses typically do not override this method.
  @override
  _ListeningWidgetState createState() => new _ListeningWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}

class _ListeningWidgetState extends State<ListeningWidget> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(ListeningWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listenable != oldWidget.listenable) {
      oldWidget.listenable.removeListener(_handleChange);
      widget.listenable.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {
      // The listenable's state is our build state, and it changed already.
    });
  }

  @override
  Widget build(BuildContext context) => widget.build(context);
}

abstract class VarWidget<T> extends ListeningWidget {
  final ValueListenable<T> _value;

  T get value => _value.value;

  const VarWidget({
    Key key,
    @required ValueListenable<T> value,
  })  : _value = value,
        super(
          key: key,
          listenable: value,
        );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.sparse;

    if (_value is DiagnosticableTree) {
      var diag = (_value as DiagnosticableTree);

      properties.add(diag.toDiagnosticsNode(
        style: DiagnosticsTreeStyle.sparse,
      ));
//      diag.debugFillProperties(properties);
//      diag.debugDescribeChildren().forEach(properties.add);
    } else {
      final v = value;

      if (v is bool) {
        properties.add(new FlagProperty(
          'value',
          value: v,
          ifTrue: 'true',
          ifFalse: 'false',
          showName: true,
        ));
      } else if (v is String) {
        properties.add(new StringProperty('value', v, showName: true));
      } else if (v is int) {
        properties.add(new IntProperty('value', v, showName: true));
      } else {
        properties.add(new ObjectFlagProperty<T>('value', v, ifPresent: v?.toString(), ifNull: 'null', showName: true));
      }
    }
  }
}

typedef Widget VarBuilderFunction<T>(BuildContext context, T value, Widget child);

class VarBuilder<T> extends VarWidget<T> {
  final VarBuilderFunction<T> builder;
  final Widget child;

  const VarBuilder({
    Key key,
    @required ValueListenable<T> value,
    @required this.builder,
    this.child,
  }) : super(
          key: key,
          value: value,
        );

  @override
  Widget build(BuildContext context) {
    return builder(context, value, child);
  }
}

abstract class StreamWidget<T> extends StreamBuilderBase<T, AsyncSnapshot<T>> {
  const StreamWidget({
    Key key,
    Stream<T> stream,
    this.initialData,
  }) : super(key: key, stream: stream);

  /// The data that will be used to create the initial snapshot. Null by default.
  final T initialData;

  @override
  AsyncSnapshot<T> initial() => new AsyncSnapshot<T>.withData(ConnectionState.none, initialData);

  @override
  AsyncSnapshot<T> afterConnected(AsyncSnapshot<T> current) => current.inState(ConnectionState.waiting);

  @override
  AsyncSnapshot<T> afterData(AsyncSnapshot<T> current, T data) {
    return new AsyncSnapshot<T>.withData(ConnectionState.active, data);
  }

  @override
  AsyncSnapshot<T> afterError(AsyncSnapshot<T> current, Object error) {
    return new AsyncSnapshot<T>.withError(ConnectionState.active, error);
  }

  @override
  AsyncSnapshot<T> afterDone(AsyncSnapshot<T> current) => current.inState(ConnectionState.done);

  @override
  AsyncSnapshot<T> afterDisconnected(AsyncSnapshot<T> current) => current.inState(ConnectionState.none);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> snapshot);
}
