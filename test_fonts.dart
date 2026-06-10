import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  try {
    final image = img.Image(width: 400, height: 200);
    img.fillRect(image, x1: 0, y1: 0, x2: 400, y2: 200, color: img.ColorRgb8(0, 0, 0));
    img.drawString(image, 'WAKTU: TEST', font: img.arial48, x: 20, y: 20, color: img.ColorRgb8(255, 255, 255));
    img.drawString(image, 'LOKASI: TEST LOCATION', font: img.arial24, x: 20, y: 80, color: img.ColorRgb8(255, 255, 255));
    print('Success fonts');
  } catch (e) {
    print('Error: $e');
  }
}
