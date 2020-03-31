import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutterwallcrop/models/wall_photo_data.dart';

import 'crop_method.dart';
import 'crop_painter.dart';

enum _CropAction { none, moving, scaling }

class ImageCrop extends StatefulWidget {
  final ImageProvider image;
  final double maximumScale;
  final WallPhotoData wallPhotoData;

  ImageCrop.network(String imageUrl,
      {Key key, this.maximumScale, this.wallPhotoData})
      : image = NetworkImage(imageUrl),
        assert(maximumScale != null),
        super(key: key);

  ImageCrop.asset(String assetName,
      {Key key, this.maximumScale, this.wallPhotoData})
      : image = AssetImage(assetName),
        assert(maximumScale != null),
        super(key: key);

  ImageCrop.file(File file, {Key key, this.maximumScale, this.wallPhotoData})
      : image = FileImage(file),
        assert(maximumScale != null),
        super(key: key);

  @override
  ImageCropState createState() => ImageCropState();
}

class ImageCropState extends State<ImageCrop>
    with TickerProviderStateMixin, Drag {
  final _surfaceKey = GlobalKey();
  AnimationController _activeController;
  AnimationController _settleController;
  ImageStream _imageStream;
  ui.Image _image;
  double _scale;
  double _ratio;
  Rect _view;
  Rect _area;
  Offset _lastFocalPoint;
  _CropAction _action;
  double _startScale;
  Rect _startView;
  Tween<Rect> _viewTween;
  Tween<double> _scaleTween;
  ImageStreamListener _imageListener;

  //double get scale => _area.shortestSide / _scale;

  //get crop frame size
  Rect get area {
//    widget.wallPhotoData.crop != null ? widget.wallPhotoData.crop.left : (viewWidth - 1.0) / 2,
//    widget.wallPhotoData.crop != null ? widget.wallPhotoData.crop.top : (viewHeight - 1.0) / 2,
    return _view.isEmpty
        ? null
        : Rect.fromLTWH(
            _area.left * _view.width / _scale - _view.left,
            _area.top * _view.height / _scale - _view.top,
            _area.width * _view.width / _scale,
            _area.height * _view.height / _scale,
          );
  }

  bool get _isEnabled => !_view.isEmpty && _image != null;

  @override
  void initState() {
    super.initState();
    _area = Rect.zero;
    _view = Rect.zero;
    _scale = 1.0;
    _ratio = 1.0;
    _lastFocalPoint = Offset.zero;
    _action = _CropAction.none;
    _activeController = AnimationController(
      vsync: this,
      value: 0.0,
    )..addListener(() => setState(() {}));
    _settleController = AnimationController(vsync: this)
      ..addListener(_settleAnimationChanged);
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    _activeController.dispose();
    _settleController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getImage();
  }

  @override
  void didUpdateWidget(ImageCrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      _getImage();
    }
    _activate(1.0);
  }

  Future<WallPhotoData> cropCompleted(File file) async {
    print("AREA: " + area.size.toString());
    print("AREA.width: " + _view.width.toString());
    print("AREA.height: " + _view.height.toString());
    print("_view.left: " + _view.left.toString());
    print("_view.top: " + _view.top.toString());
    final croppedFile = await CropMethod.cropImage(
      file: file,
      area: area,
    );
    return WallPhotoData(
        path: file.path,
        croppedFile: croppedFile,
        scale: _scale,
        crop: Crop(
            left: _view.left,
            top: _view.top,
            width: area.width,
            height: area.height));
  }

  void _getImage({bool force: false}) {
    final oldImageStream = _imageStream;
    _imageStream = widget.image.resolve(createLocalImageConfiguration(context));
    if (_imageStream.key != oldImageStream?.key || force) {
      oldImageStream?.removeListener(_imageListener);
      _imageListener = ImageStreamListener(_updateImage);
      _imageStream.addListener(_imageListener);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: GestureDetector(
        key: _surfaceKey,
        behavior: HitTestBehavior.opaque,
        onScaleStart: _isEnabled ? _handleScaleStart : null,
        onScaleUpdate: _isEnabled ? _handleScaleUpdate : null,
        onScaleEnd: _isEnabled ? _handleScaleEnd : null,
        child: CustomPaint(
          painter: CropPainter(
              image: _image,
              ratio: _ratio,
              view: _view,
              area: _area,
              scale: _scale,
              active: _activeController.value),
        ),
      ),
    );
  }

  void _activate(double val) {
    _activeController.animateTo(
      val,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 250),
    );
  }

  Size get _boundaries {
    return _surfaceKey.currentContext.size;
  }

  void _settleAnimationChanged() {
    setState(() {
      _scale = _scaleTween.transform(_settleController.value);
      _view = _viewTween.transform(_settleController.value);
    });
  }

  Rect _calculateDefaultArea({
    int imageWidth,
    int imageHeight,
    double viewWidth,
    double viewHeight,
  }) {
    if (imageWidth == null || imageHeight == null) {
      return Rect.zero;
    }
    final _deviceWidth =
        MediaQuery.of(context).size.width;
    final _deviceHeight =
        MediaQuery.of(context).size.height;
    final _areaOffsetWidth = _deviceWidth / 5; //vertical frame margin
    final _areaOffsetHeight = _deviceHeight / 3; ////horizontal frame margin
    final _areaOffsetRadioWidth = _areaOffsetWidth / _deviceWidth;
    final _areaOffsetRadioHeight = _areaOffsetHeight / _deviceHeight;
    final width = 1.0 - _areaOffsetRadioWidth;
    //TODO - layout type dynamic
    //line 278 - com.samsung.wall.presentation.wall.mywall/MyWallMoveAndCropFragment
    int cropType = 1;
    final height = cropType == 1
        ? (imageWidth * viewWidth * width) / (imageHeight * viewHeight * 1.0)
        : 1.0 - _areaOffsetRadioHeight;
    return Rect.fromLTWH((1.0 - width) / 2, (1.0 - height) / 2, width, height);
  }

  void _updateImage(ImageInfo imageInfo, bool synchronousCall) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        _image = imageInfo.image;
        //TODO - size image
        print(("wallPhotoData.scale: " + widget.wallPhotoData.scale.toString()));
        _scale = imageInfo.scale;

        // return larger value
        _ratio = max(
          _boundaries.width / _image.width,
          _boundaries.height / _image.height,
        );
        // NOTE: Calculate the picture display ratio, the maximum is 1.0 for all display
        final viewWidth = _boundaries.width / (_image.width * _scale * _ratio);
        final viewHeight =
            _boundaries.height / (_image.height * _scale * _ratio);
        _area = _calculateDefaultArea(
          viewWidth: viewWidth,
          viewHeight: viewHeight,
          imageWidth: _image.width,
          imageHeight: _image.height,
        );
        //TODO - set initial image position here
        _view = Rect.fromLTWH(
          widget.wallPhotoData.crop != null ? widget.wallPhotoData.crop.left : (viewWidth - 1.0) / 2,
          widget.wallPhotoData.crop != null ? widget.wallPhotoData.crop.top : (viewHeight - 1.0) / 2,
          viewWidth,
          viewHeight,
        );
      });
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _activate(1.0);
    _settleController.stop(canceled: false);
    _lastFocalPoint = details.focalPoint;
    _action = _CropAction.none;
    _startScale = _scale;
    _startView = _view;
  }

  //for animation back if move outside boundary
  Rect _getViewInBoundaries(double scale) {
    return Offset(
          max(
            min(
              _view.left,
              _area.left * _view.width / scale,
            ),
            _area.right * _view.width / scale - 1.0,
          ),
          max(
            min(
              _view.top,
              _area.top * _view.height / scale,
            ),
            _area.bottom * _view.height / scale - 1.0,
          ),
        ) &
        _view.size;
  }

  double get _maximumScale => widget.maximumScale;

  double get _minimumScale {
    final scaleX = _boundaries.width * _area.width / (_image.width * _ratio);
    final scaleY = _boundaries.height * _area.height / (_image.height * _ratio);
    return min(_maximumScale, max(scaleX, scaleY));
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    _action = details.rotation == 0.0 && details.scale == 1.0
        ? _CropAction.moving
        : _CropAction.scaling;

    if (_action == _CropAction.moving) {
      final delta = details.focalPoint -
          _lastFocalPoint; // offset is subtracted to get a relative moving distance
      _lastFocalPoint = details.focalPoint;

      setState(() {
        // move only moves in two dimensions
        _view = _view.translate(
          delta.dx / (_image.width * _scale * _ratio),
          delta.dy / (_image.height * _scale * _ratio),
        );
      });
    } else if (_action == _CropAction.scaling) {
      setState(() {
        _scale = _startScale * details.scale;

        // Calculate the scaled ratio;
        final dx = _boundaries.width *
            (1.0 - details.scale) /
            (_image.width * _scale * _ratio);
        final dy = _boundaries.height *
            (1.0 - details.scale) /
            (_image.height * _scale * _ratio);
        _view = Rect.fromLTWH(
          _startView.left + dx / 2,
          _startView.top + dy / 2,
          _startView.width,
          _startView.height,
        );
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _activate(0);

    final targetScale = _scale.clamp(
        _minimumScale, _maximumScale); // NOTE: handle scaling boundary values
    _scaleTween = Tween<double>(
      begin: _scale,
      end: targetScale,
    );

    _startView = _view;
    _viewTween = RectTween(
      begin: _view,
      end: _getViewInBoundaries(targetScale),
    );

    _settleController.value = 0.0;
    _settleController.animateTo(
      1.0,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 350),
    );
  }
}
