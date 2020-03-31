import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

class CropMethod {
  static const _channel = const MethodChannel('com.example.fluttercropphoto/image_crop');

  static Future<File> cropImage({
    File file,
    Rect area,
    double scale,
  }) {
    assert(file != null);
    assert(area != null);
    return _channel.invokeMethod('cropImage', {
      'path': file.path,
      'scale': scale ?? 1.0,
      'left': area.left,
      'top': area.top,
      'right': area.right,
      'bottom': area.bottom,
    }).then<File>((result) => File(result));
  }
}