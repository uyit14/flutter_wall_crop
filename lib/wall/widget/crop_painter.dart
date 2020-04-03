import 'package:flutter/material.dart';
import 'dart:ui' as ui;

const _kCropOverlayActiveOpacity = 0.3;
const _kCropOverlayInactiveOpacity = 0.7;

class CropPainter extends CustomPainter {
  final ui.Image image;
  final Rect view;
  final double ratio;
  final Rect area;
  final double scale;
  final double active;

  CropPainter(
      {this.image, this.view, this.ratio, this.area, this.scale, this.active});

  @override
  bool shouldRepaint(CropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.view != view ||
        oldDelegate.ratio != ratio ||
        oldDelegate.area != area ||
        oldDelegate.active != active ||
        oldDelegate.scale != scale;
  }

  currentReact(size) {
    return Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );
  }

  Rect currentBoundaries(size) {
    var rect = currentReact(size);
    return Rect.fromLTWH(
      rect.width * area.left,
      rect.height * area.top,
      rect.width * area.width,
      rect.height * area.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = currentReact(size);

    canvas.save();
    canvas.translate(rect.left, rect.top);

    final paint = Paint()..isAntiAlias = false;

    if (image != null) {
      final src = Rect.fromLTWH(
        0.0,
        0.0,
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final dst = Rect.fromLTWH(
        view.left * image.width * scale * ratio,
        view.top * image.height * scale * ratio,
        image.width * scale * ratio,
        image.height * scale * ratio,
      );

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0.0, 0.0, rect.width, rect.height));
      canvas.drawImageRect(image, src, dst, paint);
      canvas.restore();
    }
    final boundaries = currentBoundaries(size);

    //custom paint
    paint
      ..color = Color.fromRGBO(
          255,
          255,
          255,
          _kCropOverlayActiveOpacity * active +
              _kCropOverlayInactiveOpacity * (1.0 - active))
      ..strokeWidth = 1;
    //draw column
    canvas.drawLine(
        Offset(boundaries.left + boundaries.width / 3, boundaries.top),
        Offset(boundaries.left + boundaries.width / 3, boundaries.bottom),
        paint);
    canvas.drawLine(
        Offset(boundaries.left + boundaries.width / 3 * 2, boundaries.top),
        Offset(boundaries.left + boundaries.width / 3 * 2, boundaries.bottom),
        paint);
    //draw row
    canvas.drawLine(
        Offset(boundaries.left, boundaries.top + boundaries.height / 3),
        Offset(boundaries.right, boundaries.top + boundaries.height / 3),
        paint);
    canvas.drawLine(
        Offset(boundaries.left, boundaries.top + boundaries.height / 3 * 2),
        Offset(boundaries.right, boundaries.top + boundaries.height / 3 * 2),
        paint);

    paint.color = Color.fromRGBO(
        0x0,
        0x0,
        0x0,
        _kCropOverlayActiveOpacity * active +
            _kCropOverlayInactiveOpacity * (1.0 - active));

    final _path1 = Path()
      ..addRect(Rect.fromLTRB(0.0, 0.0, rect.width, rect.height));
    Path _path2;
    _path2 = Path()..addRect(boundaries);
    canvas.clipPath(Path.combine(PathOperation.difference, _path1,
        _path2)); // MARK: merge paths, select cross selection
    canvas.drawRect(Rect.fromLTRB(0.0, 0.0, rect.width, rect.height), paint);
    paint
      ..isAntiAlias = true
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
        Rect.fromLTRB(boundaries.left, boundaries.top, boundaries.right,
            boundaries.bottom),
        paint);
    canvas.restore();
  }
}
