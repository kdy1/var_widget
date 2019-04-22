import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

final _debugVarScopeKey = new Object();
final _debugNotifingListeners = new Object();

T _run<T>(
  List<Listenable> deps,
  ValueGetter<T> op, {
  bool isNotifyListenables = false,
}) {
  bool debug = false;
  assert(() {
    debug = true;
    return true;
  }());
  if (!debug) return op();

  deps = deps.expand((l) {
    if (l is _MergedListenable) return l._listenables;
    return [l];
  }).toList(growable: false);

  final zoneValues = <dynamic, dynamic>{
    _debugVarScopeKey: deps,
  };
  if (isNotifyListenables) {
    zoneValues.addAll({
      _debugNotifingListeners: true,
    });
  }

  return runZoned(
    op,
    zoneValues: zoneValues,
  );
}

abstract class Value<T> extends DiagnosticableTree implements ValueListenable<T> {
  String get debugLabel => null;

  @override
  @mustCallSuper
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(new FlagProperty(
      'hasListeners',
      value: hasListeners,
      showName: true,
      ifTrue: 'true',
      ifFalse: 'false',
      level: hasListeners ? DiagnosticLevel.fine : DiagnosticLevel.error,
    ));
  }

  @override
  DiagnosticsNode toDiagnosticsNode({String name, DiagnosticsTreeStyle style}) {
    return super.toDiagnosticsNode(
      name: name ?? debugLabel,
      style: DiagnosticsTreeStyle.sparse,
    );
  }

  @protected
  @visibleForTesting
  bool get hasListeners;

  String describeValue() {
    return '$value; ';
  }

  @override
  String toStringShort() {
    return '${describeValue()} ${describeIdentity(this)}';
  }

  /// Returned value notifier does not support setting value.
  ListeningValue<N> map<N>(
    N convert(
      T src,
    ), {
    String debugLabel,
  }) {
    return mapped<T, N>(this, convert, debugLabel: debugLabel);
  }

  /// Returned value notifier does not support setting value.
  static ListeningValue<T> mapped<S, T>(
          ValueListenable<S> v,
          T convert(
    S src,
  ),
          {String debugLabel}) =>
      new _Mapped(v, convert, debugLabel: debugLabel);

  /// Creates a new auto-updating value.
  ///
  static ListeningValue<S> fromListenable<S>(Listenable listenable, ValueGetter<S> value, {String debugLabel}) =>
      new _ValueFromGetter(listenable, value, debugLabel: debugLabel);

  /// Creates a new auto-updating value.
  ///
  static ListeningValue<S> from<S>(List<Listenable> listenables, ValueGetter<S> value, {String debugLabel}) {
    assert(listenables != null);
    if (listenables.length == 1 && listenables.first != null) return fromListenable(listenables[0], value, debugLabel: debugLabel);

    return fromListenable(mergeListenables(listenables), value, debugLabel: debugLabel);
  }

  static ComputedValue<S> computed<S>(ValueGetter<S> op, {String debugLabel}) => ComputedValue(op, debugLabel: debugLabel);

  static Listenable mergeListenables(List<Listenable> listenables) => new _MergedListenable(listenables);
}

class _MergedListenable extends Listenable with ChangeNotifier {
  final List<Listenable> _listenables;

  _MergedListenable(this._listenables) : assert(_listenables != null);

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      for (var l in _listenables) {
        l.addListener(_onUpdate);
      }
    }
    super.addListener(listener);
  }

  void _onUpdate() {
    notifyListeners();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);

    if (!hasListeners) {
      for (var l in _listenables) {
        l.removeListener(_onUpdate);
      }
    }
  }
}

/// Base class for [Value]s which use [ChangeNotifier].
///
/// A [ChangeNotifier] that holds a single value.
///
/// When [value] is replaced, this class notifies its listeners.
///
abstract class NotifyingValue<T> extends Value<T> with ChangeNotifier {
  @override
  @protected
  @visibleForTesting
  bool get hasListeners => super.hasListeners;
}

/// A [ChangeNotifier] that holds a single value.
///
/// When [value] is replaced, this class notifies its listeners.
class Var<T> extends NotifyingValue<T> implements Sink<T> {
  Var(
    this._value, {
    this.debugLabel,
  });

  @override
  final String debugLabel;
  T _value;

  @override
  T get value => _value;

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;

    _run(
      [],
      super.notifyListeners,
      isNotifyListenables: true,
    );
  }

  @override
  void add(T data) {
    value = data;
  }

  @override
  void close() {
    dispose();
  }
}

/// A value which requires calling `.refresh()` to update value.
class ComputedValue<T> extends BaseComputedValue<T> {
  ComputedValue(
    this.op, {
    this.debugLabel,
  })  : assert(op != null),
        super(op());

  final ValueGetter<T> op;
  @override
  final String debugLabel;

  @override
  T newValue() => op();

  /// Refreshes the value.
  void refresh() => super.update();
}

class LazyException implements Exception {
  final String debugLabel;
  final String shortHash;

  LazyException({this.debugLabel, this.shortHash});

  @override
  String toString() {
    return "LazyException: $debugLabel#$shortHash is lazy";
  }
}

abstract class BaseComputedValue<T> extends NotifyingValue<T> {
  BaseComputedValue(T value) : _value = value;

  T _value;

  @override
  T get value {
    assert(() {
      if (Zone.current[_debugNotifingListeners] == true) {
        return true;
      }

      List<Listenable> deps = Zone.current[_debugVarScopeKey];
      if (deps != null) {
        if (deps.contains(this)) return true;
      }

      debugPrint('Deps: $deps; this: #${shortHash(this)}');

      throw new LazyException(
        debugLabel: debugLabel,
        shortHash: shortHash(this),
      );
    }());
    return _value;
  }

  @protected
  T newValue();

  /// Refreshes the value.
  @protected
  void update() {
    var nv = newValue();
    if (nv == _value) return;

    _value = nv;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    _run(
      [],
      super.notifyListeners,
      isNotifyListenables: true,
    );
  }

  @override
  String describeValue() {
    return '$value; (new: ${newValue()})';
  }
}

abstract class ListeningValue<T> extends BaseComputedValue<T> {
  ListeningValue(
    this._listenable,
    T value, {
    this.debugLabel,
  })  : assert(_listenable != null),
        super(value);

  final Listenable _listenable;

  @override
  final String debugLabel;

  @override
  void update() {
    _run(
      [this._listenable],
      super.update,
      isNotifyListenables: true,
    );
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      // we are now interested on the value.
      _listenable.addListener(this.update);
      update();
    }
    super.addListener(listener);
    assert(hasListeners);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _listenable.removeListener(this.update);
    }
  }

  @override
  void dispose() {
    _listenable.removeListener(this.update);
    super.dispose();
  }

  @override
  @protected
  List<DiagnosticsNode> debugDescribeChildren() {
    return _listenableToDiagnosticNodes(_listenable);
  }
}

/// This handles [_MergedListenable]
List<DiagnosticsNode> _listenableToDiagnosticNodes(Listenable listenable) {
  assert(listenable != null);

  if (listenable is _MergedListenable) {
    return listenable._listenables.map(_listenableToDiagnosticNode).toList(growable: false);
  }

  var node = _listenableToDiagnosticNode(listenable);
  if (node != null) return [node];

  return const [];
}

DiagnosticsNode _listenableToDiagnosticNode(Listenable listenable) {
  assert(listenable != null);

  if (listenable is Value) {
    return listenable.toDiagnosticsNode(
      name: listenable.debugLabel,
      style: DiagnosticsTreeStyle.sparse,
    );
  }
  Object o = listenable;
  if (o is Diagnosticable) {
    return o.toDiagnosticsNode(
      style: DiagnosticsTreeStyle.sparse,
    );
  }

  return new DiagnosticsProperty('<unnamed value>', listenable);
}

class _ValueFromGetter<T> extends ListeningValue<T> {
  final ValueGetter<T> _get;

  _ValueFromGetter(Listenable listenable, this._get, {String debugLabel})
      : assert(_get != null),
        super(
          listenable,
          _run([listenable], _get),
          debugLabel: debugLabel,
        );

  @override
  T newValue() => _get();
}

typedef T _TransformFunction<S, T>(S value);

class _Mapped<S, T> extends ListeningValue<T> {
  final ValueListenable<S> _source;
  final _TransformFunction<S, T> _convert;

  _Mapped(this._source, this._convert, {String debugLabel})
      : super(
          _source,
          _run([_source], () => _convert(_source.value)),
          debugLabel: debugLabel,
        );

  @override
  @mustCallSuper
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new DiagnosticsProperty('op', _convert, showName: true));
  }

  @override
  T newValue() => _convert(_source.value);
}
