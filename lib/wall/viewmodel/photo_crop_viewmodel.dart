import 'dart:io';
import 'package:flutter/foundation.dart';

class PhotoCropViewModel {
  final String path;
  final File croppedFile;
  final double scale;
  final CropViewModel cropViewModel;

  PhotoCropViewModel({
    @required this.path,
    @required this.croppedFile,
    @required this.scale,
    @required this.cropViewModel,
  });
}

class CropViewModel {
  int left;
  int top;
  double width;
  double height;

  CropViewModel(
      {@required this.left,
      @required this.top,
      @required this.width,
      @required this.height});
}
