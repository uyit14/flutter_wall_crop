import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterwallcrop/blocs/crop_photo_bloc.dart';
import 'package:flutterwallcrop/models/wall_photo_data.dart';
import 'package:flutterwallcrop/widgets/image_crop_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class CropPage extends StatefulWidget {
  @override
  _CropPageState createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  final cropKey = GlobalKey<ImageCroppState>();
  PermissionHandler _permissionHandler = PermissionHandler();

  @override
  void initState() {
    super.initState();
    _listenForPermissionStatus();
  }



  void _listenForPermissionStatus() {
    final Future<PermissionStatus> statusFuture =
    PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
    statusFuture.then((PermissionStatus status) async {
      if(status!=PermissionStatus.granted){
        if(status == PermissionStatus.neverAskAgain){
          //TODO - show notify can't crop or do something
          return;
        }
        await _permissionHandler.requestPermissions([PermissionGroup.storage]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map args = ModalRoute.of(context).settings.arguments;
    final WallPhotoData wallPhotoData = args['wallPhotoData'];
    //final String path = args['wallPhotoData'];
    final cropPhotoBloc = Provider.of<CropPhotoBloc>(context);
  File file = File(wallPhotoData.path);

    return Scaffold(
      appBar: AppBar(
        title: Text("Crop Page"),
      ),
      body: Stack(
        children: <Widget>[
          Container(
              child: ImageCropp.file(file, key: cropKey, maximumScale: 3.0, wallPhotoData: wallPhotoData,)
          ),
          Positioned(
            bottom: 15.0,
            left: 15.0,
            child: new FloatingActionButton(
              heroTag: 'btn-reset',
              child: new Text("Reset"),
              onPressed: (){
                final _wallPhotoData = WallPhotoData(path: wallPhotoData.path);
                cropPhotoBloc.onCropDone(_wallPhotoData);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: new Text("Done"),
        heroTag: 'btn-done',
        onPressed: () async {
          final crop = cropKey.currentState;
          final _wallPhotoData = await crop.cropCompleted(File(wallPhotoData.path));
          cropPhotoBloc.onCropDone(_wallPhotoData);
          Navigator.pop(context);
        },
      ),
    );
  }
}
