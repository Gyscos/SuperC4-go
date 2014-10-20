part of superc4_lib;

class Drawer {

  static final num StateBlank = 0;
  static final num StateWaiting = 1;
  static final num StatePlaying = 2;

  num state;

  // Public
  var onPlay;

  // Private
  num offset = 0;
  // Width of lines separating cells
  num  lineWidth = 3;
  // cellSize includes lineWidth
  num cellSize = 1;
  // Number of cells in the board
  num gameSize = 8;
  // Number of pixels in the board
  num boardSize = 8;
  CanvasElement canvas;

  Point hoverCell = new Point(-1,-1);

  Drawer(this.canvas);

  void start() {
    canvas.onMouseMove.listen(onMouseMove);
    canvas.onMouseLeave.listen(onMouseLeave);
    window.requestAnimationFrame(redraw);
  }

  void onMouseLeave(MouseEvent event) {
    hoverCell = new Point(-1,-1);
  }

  void onMouseMove(MouseEvent event) {
    //if (state != StatePlaying)
      //return;

    num x = min(gameSize-1, max(0, (event.offset.x - offset - lineWidth/2) ~/ cellSize));
    num y = min(gameSize-1, max(0, (event.offset.y - offset - lineWidth/2) ~/ cellSize));
    hoverCell = new Point(x,y);
  }

  void remotePlay(num x, num y) {
    state = StatePlaying;
    onPlayAnimation(x, y);
  }

  void play(num x, num y) {
    if (!onPlay(x, y))
      return;

    state = StateWaiting;
    onPlayAnimation(x, y);
  }

  void onPlayAnimation(num x, num y) {

  }

  void onResize() {
    num minOffset = 3;
    cellSize = (boardSize - lineWidth - 2*minOffset) ~/ gameSize;
    offset = (boardSize - (gameSize * cellSize + lineWidth)) ~/ 2;
  }

  void redraw(_) {
    var width = canvas.parent.client.width-40;
    var height = canvas.parent.client.height-40;
    var size = min(width,height);
    if (boardSize != size) {
      boardSize = size;
      onResize();
      canvas.width = size;
      canvas.height = size;
    }
    var context = canvas.context2D;

    context.fillStyle = "white";

    context.fillRect(offset, offset, cellSize*gameSize+lineWidth, cellSize*gameSize+lineWidth);

    context.fillStyle = "black";
    context.lineWidth = lineWidth;
    context.strokeStyle = "black";
    context.beginPath();

    if (hoverCell.x != -1 && hoverCell.y != -1) {
      context.fillStyle = "#eee";
      context.fillRect(offset, offset+hoverCell.y*cellSize, gameSize*cellSize, cellSize);
      context.fillRect(offset+hoverCell.x*cellSize, offset, cellSize, gameSize*cellSize);
      context.fillStyle = "#ccc";
      context.fillRect(offset+hoverCell.x*cellSize, offset+hoverCell.y*cellSize, cellSize, cellSize);
    }

    for (var i = 0; i <= gameSize; i++) {
      context.moveTo(offset+lineWidth/2+cellSize*i, offset);
      context.lineTo(offset+lineWidth/2+cellSize*i, offset+cellSize*gameSize+lineWidth);
      context.moveTo(offset, offset+lineWidth/2+cellSize*i);
      context.lineTo(offset+cellSize*gameSize+lineWidth, offset+lineWidth/2+cellSize*i);
    }
    context.stroke();

    window.requestAnimationFrame(redraw);
  }
}