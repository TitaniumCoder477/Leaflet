import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:potato_notes/internal/draw_object.dart';
import 'package:potato_notes/internal/utils.dart';

class WebDrawingExporter {
  static Future<String> export(
      Uri uri, List<DrawObject> objects, Size size) async {
    ImageProvider image;
    Completer<ui.Image> completer = Completer<ui.Image>();

    final canvasElement = html.CanvasElement(
      width: size.width.round(),
      height: size.height.round(),
    );
    final canvas = canvasElement.context2D;

    objects.forEach((object) {
      if (object.points.length > 1) {
        canvas.beginPath();
        canvas.strokeStyle = _colorToRgbaString(object.paint.color);
        canvas.lineWidth = object.paint.strokeWidth;
        canvas.lineJoin = "round";
        canvas.lineCap = _strokeCapToString(object.paint.strokeCap);

        for (int i = 0; i < object.points.length; i++) {
          final point = object.points[i];

          if (i == 0) {
            canvas.moveTo(point.dx, point.dy);
          } else {
            canvas.lineTo(point.dx, point.dy);
          }
        }

        canvas.stroke();
        canvas.closePath();
      } else {
        canvas.beginPath();
        canvas.fillStyle = _colorToRgbaString(object.paint.color);
        canvas.arc(
          object.points.last.dx,
          object.points.last.dy,
          object.paint.strokeWidth / 2,
          0,
          pi * 2,
        );
        canvas.fill();
      }
    });

    canvas.globalCompositeOperation = "destination-over";

    if (uri != null) {
      image = uri.toImageProvider();

      image?.resolve(ImageConfiguration())?.addListener(
        ImageStreamListener(
          (image, synchronousCall) {
            completer.complete(image.image);
          },
        ),
      );

      final parsedImage = await completer.future;
      final bytes = (await parsedImage.toByteData()).buffer.asUint8List();
      final imageData = base64.encode(bytes);
      final imageElement = html.ImageElement(
        src: imageData,
        width: size.width.round(),
        height: size.height.round(),
      );
      canvas.drawImageScaled(
        imageElement,
        0,
        0,
        size.width,
        size.height,
      );
    } else {
      canvas.fillStyle = '#FFFFFF';

      canvas.fillRect(0, 0, size.width, size.width);
    }

    return canvasElement.toDataUrl("image/png");
  }

  static _colorToRgbaString(Color color) {
    return 'rgba(${color.red},${color.green},${color.blue},${color.opacity})';
  }

  static _strokeCapToString(StrokeCap cap) {
    switch (cap) {
      case StrokeCap.round:
        return "round";
      case StrokeCap.square:
        return "square";
      case StrokeCap.butt:
      default:
        return "butt";
    }
  }
}
