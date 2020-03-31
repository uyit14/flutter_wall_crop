import 'package:flutter/material.dart';
import 'package:flutterwallcrop/blocs/crop_photo_bloc.dart';
import 'package:provider/provider.dart';

import 'pages/canvas_to_png.dart';
import 'pages/crop_page.dart';
import 'pages/home_page.dart';
import 'pages/move_scale_image.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Provider<CropPhotoBloc>(
      create: (_) => CropPhotoBloc(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => HomePage(),
          'crop_page': (context) => CropPage(),
          'canvas_to_png': (context) => ImageGenerator()
        },
      ),
    );
  }
}

//https://stackoverflow.com/questions/59455524/how-to-crop-the-png-image-and-remove-its-unused-space-using-canvas-in-flutter
