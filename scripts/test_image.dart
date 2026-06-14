import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 200, height: 200);

  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: 200,
    y2: 200,
    color: img.ColorRgb8(255, 0, 0),
  );

  img.drawString(
    image,
    'Test Timestamp',
    font: img.arial24,
    x: 10,
    y: 10,
    color: img.ColorRgb8(255, 255, 255),
  );

  debugPrint('Success');
}
