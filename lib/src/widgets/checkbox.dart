import 'package:flutter/material.dart';

import '../value.dart';
import '../widget_base.dart';

class VarCheckBox extends VarWidget<bool> {
  const VarCheckBox({
    Key key,
    this.tristate = false,
    this.activeColor,
    this.checkColor,
    this.materialTapTargetSize,
    @required Value<bool> value,
  }) : super(
          key: key,
          value: value,
        );

  final Color activeColor;
  final Color checkColor;
  final bool tristate;
  final MaterialTapTargetSize materialTapTargetSize;

  @override
  Widget build(BuildContext context, bool value) {
    return Checkbox(
      activeColor: activeColor,
      checkColor: checkColor,
      tristate: tristate,
      materialTapTargetSize: materialTapTargetSize,
      value: value,
      onChanged: this.value is Settable
          ? (v) {
              (this.value as Settable).value = v;
            }
          : null,
    );
  }
}
