import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:var_widget/var_widget.dart';

abstract class VarWidget<T> extends StatefulWidget {
  final ValueListenable<T> _value;

  @override
  _VarWidgetState<T> createState() => _VarWidgetState();

  const VarWidget({
    Key key,
    @required ValueListenable<T> value,
  })  : _value = value,
        super(
          key: key,
        );

  Widget build(BuildContext context, T value);
}

class _VarWidgetState<T> extends State<VarWidget<T>> {
  T _cached;

  @override
  void initState() {
    super.initState();
    _cached = Value.get(widget._value);
    widget._value.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(VarWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._value != oldWidget._value) {
      oldWidget._value.removeListener(_handleChange);
      widget._value.addListener(_handleChange);
      _cached = Value.get(widget._value);
    }
  }

  @override
  void dispose() {
    widget._value.removeListener(_handleChange);
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.sparse;

    if (widget._value is DiagnosticableTree) {
      var diag = (widget._value as DiagnosticableTree);

      properties.add(diag.toDiagnosticsNode(
        style: DiagnosticsTreeStyle.sparse,
      ));
//      diag.debugFillProperties(properties);
//      diag.debugDescribeChildren().forEach(properties.add);
    } else {
      final v = _cached;

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

  void _handleChange() {
    setState(() {
      _cached = widget._value.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, _cached);
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
  Widget build(BuildContext context, T value) {
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
