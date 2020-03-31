import 'dart:async';
import 'dart:typed_data';

import 'package:flutterwallcrop/models/wall_photo_data.dart';

class CropPhotoBloc{
  
  final StreamController<WallPhotoData> _controller = StreamController.broadcast();

  Stream<WallPhotoData> get getWallPhotoData => _controller.stream;

  onCropDone(WallPhotoData wallPhotoData){
    _controller.sink.add(wallPhotoData);
  }

  onReset(){
    _controller.sink.add(null);
  }

  void dispose(){
    _controller.close();
  }
}

/*
- onClickCropPhoito -> set position, Photo, layoutType
  + from layoutType and position => cropType
- onClickDone -> get and save Cropped Image, get and save Crop
*/
//H: 1006 - W: 1341
//startX 241 startY 123 width: 505 height: 754