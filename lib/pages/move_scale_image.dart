import 'dart:io';

import 'package:flutter/material.dart';


class MoveScaleImage extends StatefulWidget {
  @override
  _MoveScaleImageState createState() => _MoveScaleImageState();
}

class _MoveScaleImageState extends State<MoveScaleImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Move Scale"),),
      body: Container(
        child: Image.asset("/storage/emulated/0/DCIM/Camera/IMG_20200219_083109.jpg", height: 200, width: 200, fit: BoxFit.cover, scale: 3.0,),
      ),
    );
  }
}
