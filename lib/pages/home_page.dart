import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterwallcrop/blocs/crop_photo_bloc.dart';
import 'package:flutterwallcrop/models/wall_photo_data.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _path = "/storage/emulated/0/DCIM/Camera/IMG_20200219_083109.jpg";
  WallPhotoData _wallPhotoData = WallPhotoData();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cropPhotoBloc = Provider.of<CropPhotoBloc>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Home Page"),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<Object>(
              stream: cropPhotoBloc.getWallPhotoData,
              builder: (context, snapshot) {
                if(snapshot.hasData){
                  print("Has data");
                  _wallPhotoData = snapshot.data;
                  return Image.file(_wallPhotoData.croppedFile != null ? _wallPhotoData.croppedFile : File(_wallPhotoData.path), height: 60, width: 60,);
                }else{
                  print("No data");
                  return CircularProgressIndicator();
                }

              }
            ),
            SizedBox(height: 20,),
            FlatButton(
              onPressed: () {
               if(_wallPhotoData.path != null){
                 Navigator.of(context).pushNamed('crop_page', arguments: {'wallPhotoData' : _wallPhotoData});
                 print("!= NULL: " + _wallPhotoData.path);
               }else{
                 _wallPhotoData = WallPhotoData(path: _path);
                 print("NULL: " + _wallPhotoData.path);
                 Navigator.of(context).pushNamed('crop_page', arguments: {'wallPhotoData' : _wallPhotoData});
               }
              },
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              color: Colors.black,
              child: Text(
                'CROP PHOTO',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20,),
            FlatButton(
              onPressed: () {
                setState(() {
                  //TODO - set to default photo
                  _path = "";
                });
              },
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              color: Colors.black,
              child: Text(
                'RESET',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
