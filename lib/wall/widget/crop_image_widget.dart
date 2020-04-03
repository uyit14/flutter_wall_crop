import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutterwallcrop/wall/viewmodel/photo_crop_viewmodel.dart';
import 'package:image_crop/image_crop.dart';
import 'crop_painter.dart';

enum _CropAction { none, moving, scaling }

class WallImageCrop extends StatefulWidget {
  final ImageProvider image;
  final double maximumScale;

  WallImageCrop.network(String imageUrl,
      {Key key, this.maximumScale})
      : image = NetworkImage(imageUrl),
        assert(maximumScale != null),
        super(key: key);

  WallImageCrop.asset(String assetName,
      {Key key, this.maximumScale})
      : image = AssetImage(assetName),
        assert(maximumScale != null),
        super(key: key);

  WallImageCrop.file(File file, {Key key, this.maximumScale})
      : image = FileImage(file),
        assert(maximumScale != null),
        super(key: key);

  @override
  WallImageCropState createState() => WallImageCropState();
}

class WallImageCropState extends State<WallImageCrop>
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
  int defaultLeftMargin;
  int defaultTopMargin;

  //get crop frame size
  Rect get area {
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
  void didUpdateWidget(WallImageCrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      _getImage();
    }
    _activate(1.0);
  }

  //using crop method of img_crop lib
  Future<PhotoCropViewModel> cropCompleted(File file) async {
    final croppedFile = await ImageCrop.cropImage(
      file: file,
      area: area,
    );
    return PhotoCropViewModel(
      path: file.path,
      croppedFile: croppedFile,
      scale: _scale,
      cropViewModel: CropViewModel(
        left: leftRatioToLeftWallCrop(_view.left),
        top: topRatioToTopWallCrop(_view.top),
        width: _image.width/_scale,
        height: _image.height/_scale
      )
    );
  }

  //calculate left margin between image and boundary
  int leftRatioToLeftWallCrop(double leftRatio){
    int leftDp = (leftRatio * _image.width * _scale * _ratio).toInt();
    if(leftDp < defaultLeftMargin){
      return defaultLeftMargin - leftDp;
    }else{
      return 0;
    }
  }

  //calculate top margin between image and boundary
  int topRatioToTopWallCrop(double topRatio){
    int topDp = (topRatio * _image.height * _scale * _ratio).toInt();
    defaultTopMargin = defaultTopMargin - 13; //TODO - 13 is appbar size - will calculate later
    if(topDp < defaultTopMargin){
      return defaultTopMargin - topDp;
    }else{
      return 0;
    }
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

  //when hold on an image
  void _activate(double val) {
    _activeController.animateTo(
      val,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 250),
    );
  }

  //get boundary of screen
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
        MediaQuery.of(context).size.width; //screen width
    final _deviceHeight =
        MediaQuery.of(context).size.height; //screen height
    final _areaOffsetWidth = _deviceWidth / 5; //vertical frame margin
    defaultLeftMargin = _areaOffsetWidth~/2; //left margin = total vertical margin / 2
    final _areaOffsetHeight = _deviceHeight / 3; //horizontal frame margin
    final _areaOffsetRadioWidth = _areaOffsetWidth / _deviceWidth;
    final _areaOffsetRadioHeight = _areaOffsetHeight / _deviceHeight;
    final width = 1.0 - _areaOffsetRadioWidth;
    //TODO - when combine with step5, will create function get cropType later
    int cropType = 1;
    //get size.width of boundary
    double _boundaryWidthSize = _deviceWidth - _areaOffsetWidth;
    defaultTopMargin = cropType == 1 ? (_deviceHeight - _boundaryWidthSize)~/2 : _areaOffsetHeight~/2; //top margin calculated based on cropType
    final height = cropType == 1
        ? (imageWidth * viewWidth * width) / (imageHeight * viewHeight * 1.0)
        : 1.0 - _areaOffsetRadioHeight;
    return Rect.fromLTWH((1.0 - width) / 2, (1.0 - height) / 2, width, height);
  }

  void _updateImage(ImageInfo imageInfo, bool synchronousCall) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        _image = imageInfo.image;
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

        //set initial image position
        _view = Rect.fromLTWH(
          (viewWidth - 1.0) / 2,
          (viewHeight - 1.0) / 2,
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