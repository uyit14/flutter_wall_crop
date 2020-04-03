import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterwallcrop/wall/viewmodel/photo_crop_viewmodel.dart';
import 'package:flutterwallcrop/wall/widget/crop_image_widget.dart';
import 'package:permission_handler/permission_handler.dart';

// entry point for testing
main() {
  runApp(MaterialApp(home: CropImagePage()));
}


class CropImagePage extends StatefulWidget {
  @override
  _CropImagePageState createState() => _CropImagePageState();
}

class _CropImagePageState extends State<CropImagePage> {
  var cropKey = GlobalKey<WallImageCropState>();
  final PermissionHandler _permissionHandler = PermissionHandler();

  Future<Null> showImage(BuildContext context, File file) async {
    new FileImage(file)
        .resolve(new ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      print('-------------------------------------------$info');
    }));
    return showDialog<Null>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(
                'Current screenshot：',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 1.1),
              ),
              content: Image.file(file));
        });
  }

  @override
  void initState() {
    super.initState();
    _listenForPermissionStatus();
  }

  void _listenForPermissionStatus() {
    final Future<PermissionStatus> statusFuture =
    PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
    statusFuture.then((PermissionStatus status) async {
      print("permission: " + status.toString());
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
    //TODO - temporary image, will get from step 5 later
    String path = "/storage/emulated/0/DCIM/Camera/IMG_20200219_083116.jpg";
    final File file = File(path);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("CROP PHOTO"),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              child: WallImageCrop.file(file, key: cropKey, maximumScale: 3.0,),
            ),
            Positioned(
              bottom: 4,
              right: 8,
              left: 8,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: RaisedButton(
                      child: Text("RESET"),
                      onPressed: (){
                        setState(() {
                          cropKey = GlobalKey<WallImageCropState>();
                        });
                      },
                      textColor: Colors.white,
                      color: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(width: 8,),
                  Expanded(
                    child: RaisedButton(
                      child: Text("DONE"),
                      onPressed: () async {
                        final crop = cropKey.currentState;
                        PhotoCropViewModel photoCropModel = await crop.cropCompleted(File(path));
                        //TODO - will send to step 5 after crop complete
                        showImage(context, photoCropModel.croppedFile);
                      },
                      textColor: Colors.white,
                      color: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
