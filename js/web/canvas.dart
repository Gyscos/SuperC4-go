library superc4_ui;

export 'package:polymer/init.dart';

import 'dart:html';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:core';
import 'package:css_animation/css_animation.dart';

class CanvasDrawer {
  List<int> board;

  var ready = false;
  var idle = true;

  num rawSize = 0;
  num cellSize = 1;
  num realSize = 0;

  num lineWidth = 2;
  num offset = 0;
  num center = 0;

  num mouseX = -1;
  num mouseY = -1;

  num gameSize = 8;

  num startSize;
  num endSize;
  Stopwatch stopwatch;

  num transitionDuration = 500;

  CanvasElement canvas;

  Function onPlay;

  List<ImageElement> player = new List<ImageElement>(2);

  CanvasDrawer(this.canvas) {
    startSize = endSize = gameSize;

    player[0] = querySelector("#image_x");
    player[1] = querySelector("#image_o");

    canvas.onMouseMove.listen((event) => onMouseMove(event.offset));
    canvas.onMouseLeave.listen((_) => hideMouse());
    canvas.onClick.listen((_)=>onClick());

    window.requestAnimationFrame(redraw);
  }

  void hideMouse() {
    mouseX = mouseY = -1;
  }

  void onClick() {
    if (ready)
      onPlay(mouseX, mouseY);
  }

  void onMouseMove(Point p) {
    // print(p.toString() + " - " + center.toString() + " ~/ " + cellSize.toString());
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
    if (!idle && mouseX >= 0 && mouseY >= 0) {
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
    }

    context.stroke();

    for (var x = 0; x < gameSize; x++) {
      for (var y = 0; y < gameSize; y++) {
        var v = board[x+y*gameSize];
        if (v != 0) {
          var img = player[v-1];
          context.drawImageScaled(img, offset+x*cellSize, offset+y*cellSize, cellSize, cellSize);
        }
      }
    }

    window.requestAnimationFrame(redraw);
  }
}

class Game {
  List<int> board;
  var gameSize = 8;

  Function onPlay;

  num currentPlayer = 0;

  Game() {
    board = new List<int>.filled(gameSize*gameSize, 0);
  }

  void clear() {
    currentPlayer = 0;
    board.fillRange(0, board.length, 0);
  }

  int getCell(x, y) {
    return board[x + y*gameSize];
  }

  void setCell(x, y, value) {
    board[x+y*gameSize] = value;
  }

  bool isInBounds(x, y) {
    return (x >= 0 && y >= 0 && x < gameSize && y < gameSize);
  }

  bool hasFreeCell(cx, cy, dx, dy) {
    for (var i = 1; i < gameSize; i++) {
      if (!isInBounds(cx+i*dx, cy+i*dy))
        break;
      if (getCell(cx+i*dx, cy+i*dy) == 0)
        return true;
    }

    return false;
  }

  int countCells(cx,cy, dx,dy, value) {
    var sum = 0;

    for (var i = 1; i < gameSize; i++) {
      if (getCell(cx+i*dy, cy+i*dy) != value)
        break;
      sum++;
    }

    return sum;
  }

  bool isValidMove(num x, num y) {
    if (!isInBounds(x,y))
      return false;

    if (getCell(x,y) != 0)
      return false;

    if (hasFreeCell(x, y,  1,  0) &&
        hasFreeCell(x, y,  0,  1) &&
        hasFreeCell(x, y, -1,  0) &&
        hasFreeCell(x, y,  0, -1))
      return false;

    return true;
  }

  bool play(num x, num y) {
    // If it is a valid move...
    if (!isValidMove(x, y))
      return false;

    setCell(x,y, currentPlayer+1);
    currentPlayer = 1-currentPlayer;

    return true;
  }
}

class GameManager {

  CanvasDrawer cd = new CanvasDrawer(querySelector("#canvas"));
  Game game = new Game();

  var server = "http://abury.fr:8080";

  var fadeIn = new CssAnimation('opacity', 0, 1);
  var fadeOut = new CssAnimation('opacity', 1, 0);

  num id;

  HttpRequest request;

  GameManager() {
    cd.board = game.board;

    // Link them up
    cd.onPlay = play;

    querySelector("#newgame_button").onClick.listen((_)=> joinGame());
    querySelector("#abort_button").onClick.listen((_)=> cancelJoin());
    querySelector("#leave_button").onClick.listen((_)=> leaveGame());
  }

  void play(num x, y) {
    if (!game.play(x, y))
      return;

    // window.alert("Sending PLAY move: " + x.toString() + ":" + y.toString());
    cd.ready = false;
    HttpRequest
      .getString(server + "/api/play?id="+id.toString()+"&x="+x.toString()+"&y="+y.toString())
      .then(onPlayAnswer);
  }

  void onPlayAnswer(msg) {
    Map obj = JSON.decode(msg);
    if (!obj["Success"]) {
      window.alert("Error: " + obj["Error"]);
    }
    wait();
  }

  void joinGame() {
    // window.alert('Joining.');

    fadeOut.apply(
        querySelector("#play_against"),
        duration: 300,
        onComplete:() {
          querySelector("#play_against").style.display = "none";
          querySelector("#joining").style.display = "block";
          fadeIn.apply(
              querySelector("#joining"),
              duration:300,
              onComplete:() {
                request = new HttpRequest();
                request.open("GET", server + "/api/join");
                request.onLoad.listen((event) => onJoinAnswer(event.target.responseText));
                request.send();
              }
          );
        }
    );
    // querySelector("#play_against").style.opacity = "0";
    // HttpRequest.getString("http://localhost:8081/api/join").then(onDataLoaded);
    //querySelector("#play_against").style.display = "none";
  }

  void cancelJoin() {
    request.abort();

    fadeOut.apply(
        querySelector("#joining"),
        duration: 300,
        onComplete:() {
          querySelector("#joining").style.display = "none";
          querySelector("#play_against").style.display = "block";
          fadeIn.apply(
              querySelector("#play_against"),
              duration:300
          );
        }
    );
  }

  void onJoinAnswer(msg) {
    Map obj = JSON.decode(msg);
    id = obj["PlayerId"];
    // window.alert("Id is " + id.toString());

    fadeOut.apply(
        querySelector("#joining"),
        duration: 300,
        onComplete:() {
          querySelector("#joining").style.display = "none";
          querySelector("#playing_against").style.display = "block";
          fadeIn.apply(
              querySelector("#playing_against"),
              duration:300,
              onComplete: startPlaying
          );
        }
    );
  }

  void startPlaying() {
    wait();
    cd.idle = false;
  }

  void wait() {
    request = new HttpRequest();
    request.open("GET", server + "/api/wait?id="+id.toString());
    request.onLoad.listen((event) => onWaitAnswer(event.target.responseText));

    request.timeout = 1000*5*60; // timeout is in ms
    request.onTimeout.listen((_)=>wait());

    request.send();
  }

  void onWaitAnswer(msg) {
    Map obj = JSON.decode(msg);
    if (!obj["Success"]) {
      // Oops
      window.alert("An error occured: " + obj["Error"]);
      leaveGame();
    } else {
      var x = obj["X"];
      var y = obj["Y"];
      if (x >= 0 && y >= 0) {
        // Make the opponent play
        game.play(x, y);
      }

      if (obj["GameOver"]) {
        onGameOver();
      } else {
        cd.ready = true;
      }
    }
  }

  void onGameOver() {
    cd.idle = true;
  }

  void leaveGame() {
    game.clear();
    request.abort();
    HttpRequest.getString(server + "/api/leave?id="+id.toString());

    fadeOut.apply(
        querySelector("#playing_against"),
        duration: 300,
        onComplete:() {
          querySelector("#playing_against").style.display = "none";
          querySelector("#play_against").style.display = "block";
          fadeIn.apply(
              querySelector("#play_against"),
              duration:300
          );
        }
    );
  }

}

void main() {
  var gm = new GameManager();

}
