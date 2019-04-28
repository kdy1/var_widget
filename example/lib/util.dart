import 'dart:math';
import 'dart:ui';

class RandomColor {
  final Random r = new Random();

  Color randomColor() {
    return Color.fromARGB(255, r.nextInt(255), r.nextInt(255), r.nextInt(255));
  }
}
