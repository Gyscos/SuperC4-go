library superc4_ui;

export 'package:polymer/init.dart';

import 'dart:html';
import 'dart:math' as math;

CanvasElement canvas = querySelector("#canvas");

void redraw(num _) {
  var context = canvas.context2D;

  var width = canvas.parent.client.width-40;
  var height = canvas.parent.client.height-40;

  var size = math.min(height,width);

  canvas.width = size;
  canvas.height = size;

  // print("Drawing!" + width.toString() + " " + height.toString());
  context.clearRect(0, 0, width, height);
  context.strokeStyle = "black";
  context.fillStyle = "green";
  context.fillRect(0, 0, size, size);
  context.lineWidth = 5;
  context.rect(0, 0, size, size);
  context.stroke();
  //context.strokeRect(1, 1, size-3, size-3);
  // context.rect(10, 10, width, height);



  window.requestAnimationFrame(redraw);
}

void main() {
  window.requestAnimationFrame(redraw);
}
