
import 'dart:io';

import 'package:flutter/foundation.dart';

class WallPhotoData{
  final String type;
  final String id;
  final String fileType;
  final String path;
  final File croppedFile;
  final double scale;
  final Crop crop;

  WallPhotoData({
    @required this.type,
    @required this.id,
    @required this.fileType,
    @required this.path,
    @required this.croppedFile,
    @required this.scale,
    @required this.crop,
  });
}

class Crop{
  double left;
  double top;
  double width;
  double height;

  Crop({@required this.left, @required this.top, @required this.width, @required this.height});
}