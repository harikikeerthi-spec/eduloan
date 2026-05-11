import 'dart:io';
import 'package:image/image.dart';

void main() {
  final inputPath = r"C:\Users\HP\.gemini\antigravity\brain\6256240f-3f16-464b-9744-9468885f2581\media__1773139228609.jpg";
  final bytes = File(inputPath).readAsBytesSync();
  final img = decodeImage(bytes);
  if (img == null) {
    stdout.writeln('Failed to decode image');
    return;
  }

  // 1. Find bounding box of non-white pixels
  int minX = img.width, minY = img.height, maxX = 0, maxY = 0;
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      final p = img.getPixel(x, y);
      if (p.r < 240 || p.g < 240 || p.b < 240) { // not white/light grey
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  stdout.writeln('Original Bounds: $minX, $minY - $maxX, $maxY');

  // 2. Crop exactly
  final cropped = copyCrop(img, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);

  // 3. Make white pixels transparent (to make it a clean PNG foreground)
  for (int y = 0; y < cropped.height; y++) {
    for (int x = 0; x < cropped.width; x++) {
      final p = cropped.getPixel(x, y);
      if (p.r > 245 && p.g > 245 && p.b > 245) {
        cropped.setPixelRgba(x, y, 255, 255, 255, 0); 
      }
    }
  }

  // 4. Resize to exactly 480px max dimension
  // The Android safe zone is a circle of diameter 682px (approx) in a 1024px canvas.
  // An inverted triangle of 480px width fits precisely without corners bleeding out.
  final maxSize = 480;
  Image resized;
  if (cropped.width > cropped.height) {
    resized = copyResize(cropped, width: maxSize);
  } else {
    resized = copyResize(cropped, height: maxSize);
  }

  // 5. Create final 1024x1024 transparent canvas for adaptive foreground
  final finalImage = Image(width: 1024, height: 1024);
  fill(finalImage, color: ColorRgba8(255, 255, 255, 0)); // Transparent white
  
  final offsetX = (1024 - resized.width) ~/ 2;
  final offsetY = (1024 - resized.height) ~/ 2;
  compositeImage(finalImage, resized, dstX: offsetX, dstY: offsetY);

  File('assets/images/app_icon_foreground.png').writeAsBytesSync(encodePng(finalImage));

  // 6. Create solid white background version for iOS/legacy
  final squareImage = Image(width: 1024, height: 1024);
  fill(squareImage, color: ColorRgb8(255, 255, 255)); // Solid white
  compositeImage(squareImage, resized, dstX: offsetX, dstY: offsetY);
  
  File('assets/images/app_icon_square.png').writeAsBytesSync(encodePng(squareImage));

  stdout.writeln('Logos perfectly resized, padded, and generated!');
}
