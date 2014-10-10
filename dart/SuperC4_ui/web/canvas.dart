library superc4_ui;

export 'package:polymer/init.dart';

import 'dart:html';
import 'dart:math' as math;
import 'dart:core';

class CanvasDrawer {
  num rawSize;
  num cellSize;
  num realSize;

  num lineWidth = 2;
  num offset;
  num center;

  num mouseX = -1;
  num mouseY = -1;

  num gameSize = 8;

  num startSize;
  num endSize;
  Stopwatch stopwatch;

  num transitionDuration = 500;

  CanvasElement canvas;

  CanvasDrawer(this.canvas) {
    startSize = endSize = gameSize;

    canvas.onMouseMove.listen((event) => onMouseMove(event.offset));
    canvas.onMouseLeave.listen((_) => hideMouse());
    canvas.onClick.listen((_)=>onClick());

    window.requestAnimationFrame(redraw);
  }

  void hideMouse() {
    mouseX = mouseY = -1;
  }

  void onClick() {

  }

  void onMouseMove(Point p) {
    print(p.toString() + " - " + center.toString() + " ~/ " + cellSize.toString());
    mouseX = math.min(gameSize-1, math.max(0,(p.x - offset - lineWidth/2) ~/ cellSize));
    mouseY = math.min(gameSize-1, math.max(0,(p.y - offset - lineWidth/2) ~/ cellSize));


    // print(x.toString() + " " + y.toString());
  }

  void onResize(num size) {
    var minOffset = 3;

    cellSize = (size - lineWidth - 2*minOffset) ~/ gameSize;
    realSize = cellSize * gameSize + lineWidth;
    offset = (size - realSize) ~/ 2;

    center = size~/2;
  }

  void setGameSize(num newSize) {
    startSize = gameSize;
    endSize = newSize;
    stopwatch = new Stopwatch()..start();
  }

  num getCurrentGameSize() {
    return gameSize;
  }

  void redraw(num _) {
    var context = canvas.context2D;

    var width = canvas.parent.client.width-40;
    var height = canvas.parent.client.height-40;

    var size = math.min(height,width);
    if (rawSize != size) {
      onResize(size);
      rawSize = size;
      canvas.width = size;
      canvas.height = size;
    }

    if (endSize != gameSize) {
      var duration = stopwatch.elapsed.inMilliseconds;
      var x = duration / transitionDuration;
      if (x > 1) x = 1;
      gameSize = startSize + x * (endSize-startSize);
      onResize(size);
    }

    // print("Drawing!" + width.toString() + " " + height.toString());
    context.clearRect(0, 0, width, height);
    context.strokeStyle = "black";

    //context.fillRect(0, 0, size, size);
    if (mouseX >= 0 && mouseY >= 0) {
      context.fillStyle = "#eee";
      context.fillRect(offset, offset+cellSize*mouseY, realSize, cellSize);
      context.fillRect(offset+cellSize*mouseX, offset, cellSize, realSize);
      context.fillStyle = "#ccc";
      context.fillRect(offset+cellSize*mouseX, offset+cellSize*mouseY, cellSize, cellSize);
    }

    context.lineWidth = lineWidth;
    context.beginPath();
    context.moveTo(center, center-realSize/2);
    context.lineTo(center, center+realSize/2);
    context.moveTo(center-realSize/2, center);
    context.lineTo(center+realSize/2, center);
    for (var i = 0; i <= gameSize~/2; i++) {

      context.moveTo(center+i*cellSize, center-realSize/2);
      context.lineTo(center+i*cellSize, center+realSize/2);
      context.moveTo(center-realSize/2, center+i*cellSize);
      context.lineTo(center+realSize/2, center+i*cellSize);
      context.moveTo(center-i*cellSize, center-realSize/2);
      context.lineTo(center-i*cellSize, center+realSize/2);
      context.moveTo(center-realSize/2, center-i*cellSize);
      context.lineTo(center+realSize/2, center-i*cellSize);
      //context.strokeRect(offset + i*cellSize, offset, (gameSize-2*i)*cellSize, gameSize*cellSize);
      //context.strokeRect(offset, offset + i*cellSize, gameSize*cellSize, (gameSize-2*i)*cellSize);
    }


    context.stroke();


    window.requestAnimationFrame(redraw);
  }
}

void main() {
  var cd = new CanvasDrawer(querySelector("#canvas"));
}
