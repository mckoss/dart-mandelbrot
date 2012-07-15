#library("mandelbrodt.viewport");

#import("dart:html");

class ViewPort {
  int x, y;
  CanvasElement canvas;
  int columns;
  int rows;
  List<double> rect;
  
  ViewPort(this.x, this.y, this.canvas, this.rect);
  
  adjustAspectRatio() {
    var centerPoint = [(rect[0] + rect[2]) / 2, (rect[1] + rect[3])/2];
    var pixSize = this.getPixSize();
    recenter(centerPoint, pixSize);
  }
  
  double getPixSize() {
    var width = rect[2] - rect[0];
    var height = rect[3] - rect[1];
    return Math.max(width / canvas.width, height / canvas.height);
  }
  
  recenter(List<double> centerPoint, pixSize) {
    rect[0] = centerPoint[0] - pixSize * canvas.width / 2;
    rect[2] = rect[0] + pixSize * canvas.width;
    rect[1] = centerPoint[1] + pixSize * canvas.height / 2;
    rect[3] = rect[1] - pixSize * canvas.height;
  }
  
  zoom(List<int> centerPix, zoomLevel) {
    var centerPoint = getPosition(centerPix[0], centerPix[1]);
    var pixSize = getPixSize();
    recenter(centerPoint, pixSize * zoomLevel);
  }
  
  drawOn(CanvasElement display) {
    display.context2d.drawImage(canvas, x, y);
  }
  
  List<double> getPosition(int xT, int yT) {
    return [rect[0] + (rect[2] - rect[0]) * xT / canvas.width,
            rect[1] + (rect[3] - rect[1]) * yT / canvas.height];
  }
  
  ViewPort makeTile(int size) {
    var tile = new ViewPort(0, 0, new CanvasElement(size, size), null);
    tile.columns = (canvas.width / size).ceil().toInt();
    tile.rows = (canvas.height / size).ceil().toInt();
    tile.positionAt(this, 0, 0);
    return tile;
  }
  
  int numTiles() {
    return columns * rows;
  }
  
  positionTile(ViewPort parent, iTile) {
    positionAt(parent, (iTile % columns) * canvas.width, (iTile ~/ columns) * canvas.height);
  }
  
  positionAt(ViewPort parent, xT, yT) {
    x = xT;
    y = yT;
    var ul = parent.getPosition(x, y);
    var lr = parent.getPosition(x + canvas.width, y + canvas.height);
    rect = [ul[0], ul[1], lr[0], lr[1]];
  }
}

