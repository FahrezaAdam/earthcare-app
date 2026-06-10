import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  try {
    final image = img.Image(width: 200, height: 200);
    img.fillRect(
      image,
      x1: 0,
      y1: 150,
      x2: 200,
      y2: 200,
      color: img.ColorRgb8(0, 0, 0),
    );
    img.drawString(
      image,
      'TEST',
      font: img.arial48,
      x: 20,
      y: 160,
      color: img.ColorRgb8(255, 255, 255),
    );
    print('Success Image Stamping');
  } catch (e) {
    print('Error: $e');
  }
}
