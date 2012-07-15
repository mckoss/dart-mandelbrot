#library("mandelbrodt");

#import("mandelbrodt-calc.dart");
#import("dart:html");
#import('dart:isolate');

final int TILE_SIZE = 64;
final int BODY_PADDING = 10;
final int CANVAS_BORDER = 1;

void main() {
  Mandelbrodt.init();
  var ui = new UI(query("#display"), query("#graph"), 1);
  port.receive((WorkResponse response, SendPort replyTo) {
    ui.pushResponse(response);
  });
}

class WorkResponse {
  List<int> data;
  int x, y;
  int cx, cy;
  
  WorkResponse(this.data, this.x, this.y, this.cx, this.cy);
  
  void render(CanvasElement canvas) {
    var ctx = canvas.context2d;
    ImageData bitmap = ctx.createImageData(cx, cy);
    for (int i = 0; i < data.length; i++) {
      bitmap.data[i] = data[i];
    }
    ctx.putImageData(bitmap, 0, 0);
  }
}

class WorkRequest {
  List<double> rc;
  int cx, cy;
  
  WorkRequest(this.rc, this.cx, this.cy);
}

class UI {
  CanvasElement graph;
  CanvasElement display;
  CanvasElement canvasTile;

  num drawCount;
  List<double> rcDisplay;
  int columns;
  int tile;
  int tiles;
  int cx;
  int cy;
  int numWorkers;
  List<double> graphData;
  int dataOffset;
  int lastTime = 0;
  Queue<WorkResponse> readyList;

  UI(this.display, this.graph, this.numWorkers) {

    drawCount = 0;

    canvasTile = new CanvasElement(TILE_SIZE, TILE_SIZE);

    int availWidth = window.innerWidth - BODY_PADDING * 2 - CANVAS_BORDER * 2;
    int availHeight = window.innerHeight - BODY_PADDING * 2 - CANVAS_BORDER * 4;
    graph.width = cx = availWidth;
    display.width = availWidth;
    graph.height = (availHeight * 0.25).toInt();
    display.height = cy = (availHeight * 0.75).toInt();
    
    Queue<WorkResponse> readyList = new Queue<WorkResponse>();
    display.on.click.add(this.handleOnClick);

    graphData = new List<double>(cx);
    for (int i = 0; i < cx; i++) {
      graphData[i] = 0.0;
    }
    dataOffset = 0;

    columns = (display.width ~/ TILE_SIZE + 1);
    tiles =  columns * (display.height ~/ TILE_SIZE + 1);
    rcDisplay = [-2.0, 1.0, 0.25, -1.0];

    var pCanvas = display.height / display.width;
    var rcHeight = (rcDisplay[1] - rcDisplay[3]).abs();
    var rcWidth = (rcDisplay[0] - rcDisplay[2]).abs();
    var pRect = rcHeight / rcWidth;
    List<double> rcCenter = [(rcDisplay[0] + rcDisplay[2]) / 2,
                             (rcDisplay[1] + rcDisplay[2]) / 2];
    
    if (pRect < pCanvas) {
      var cFactor = display.width / rcWidth;
      double dy = (display.height - rcHeight * cFactor) / cFactor;
      rcDisplay[1] -= dy / 2;
      rcDisplay[3] += dy / 2;
    } else {
      var cFactor = display.height / rcHeight;
      double dx = (display.width - rcWidth * cFactor) / cFactor;
      rcDisplay[0] -= dx / 2;
      rcDisplay[2] += dx / 2;
    }

    tile = 0;
    window.requestAnimationFrame(draw);
  }
  
  void pushResponse(WorkResponse response) {
    readyList.add(response);
  }

  List<double> getPosition(int x, int y) {
    return [rcDisplay[0] + (rcDisplay[2] - rcDisplay[0]) * x / cx,
            rcDisplay[1] + (rcDisplay[3] - rcDisplay[1]) * y / cy];
  }
  
  List<double> getTileRect(int iTile) {
    int x = (iTile % columns) * TILE_SIZE;
    int y = (iTile ~/ columns) * TILE_SIZE;
    var ul = getPosition(x, y);
    var lr = getPosition(x + TILE_SIZE, y + TILE_SIZE);
    List<double> rc = [ul[0], ul[1], lr[0], lr[1]];
  }
  
  void handleOnClick(e) {
    var x = e.x;
    var y = e.y - 2 - 10 - graph.height;
    var tl = getPosition((x - cx/4).toInt(), (y - cy/4).toInt());
    var br = getPosition((x + cx/4).toInt(), (y + cy/4).toInt());
    rcDisplay = [tl[0], tl[1], br[0], br[1]];
    tile = 0;
  }

  bool draw(int time) {
    if (!readyList.isEmpty()) {
      work = readList.removeFirst();
      work.render(canvasTile);
      display.context2d.drawImage(canvasTile, x, y);
      updateData((TILE_SIZE * TILE_SIZE) / dsecs);
    }

    drawGraph();

    timeLast = time;
    window.requestAnimationFrame(draw);
  }

  void drawTile() {
    List<double> rc = getTileRect(tile);
    Mandelbrodt.render(canvasTile, rc);
    display.context2d.drawImage(canvasTile, x, y);
  }

  void updateData(double n) {
    double dsecs = (Clock.now() - lastTime) / Clock.frequency();
    lastTime = Clock.now();
    graphData[dataOffset] = n / dsecs;
    dataOffset = (dataOffset + 1) % cx;
  }

  void drawGraph() {
    var ctx = graph.context2d;
    graph.width = graph.width;  // clear canvas
    

    double maxData = 0.0;
    double scale = 2.0;
    for (int i = 0; i < cx; i++) {
      if (graphData[i] > maxData) {
        maxData = graphData[i];
      }
      while (scale < maxData) {
        scale *= 2;
      }
    }

    ctx.font = "bold 10px sans-serif";
    ctx.textBaseline = "top";
    int scaleInt = scale.toInt();
    String str = "$scaleInt";
    
    ctx.fillText(str, 0, 0);
    ctx.textBaseline = "bottom";
    var scaleWidth = (str.length - 1) * 6;
    
    ctx.fillText("0", scaleWidth, graph.height);
    ctx.moveTo(scaleWidth + 9, 0);
    ctx.lineTo(scaleWidth + 9, graph.height);
    ctx.stroke();
    
    scale = graph.height / scale;
    
    for (int x = 0; x < cx; x++) {
      int i = (dataOffset + x) % cx;
      int y = graph.height - (graphData[i] * scale).toInt();
      if (x == 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
  }

}
