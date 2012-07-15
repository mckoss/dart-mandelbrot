// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A mandelbrodt visualization.
 */

#library("mandelbrodt");
#import("mandelbrodt-calc.dart");
#import("dart:html");
#import('dart:isolate');

int TILE_SIZE = 64;

/**
 * The entry point to the application.
 */
void main() {
  Mandelbrodt.init();
  var ui = new UI(query("#display"), query("#graph"));
  port.receive((WorkResponse response, SendPort replyTo) {
    ui.pushResponse(response);
  });
}

class WorkResponse {
  List<int> data;
  int x, y;
  
  WorkResponse(this.data, this.x, this.y);
  
  void renderToCanvas(CanvasElement canvas) {
    var ctx = canvas.context2d;
    ImageData bitmap = ctx.createImageData(cx, cy);
    for (int i = 0; i < data.length; i++) {
    ctx.putImageData(bitmap, 0, 0);
  }
}

class WorkRequest {
  List<double> rc;
  int cx, cy;
  
  WorkRequest(this.rc, this.cx, this.cy);
}

double fpsAverage;

final int BODY_PADDING = 10;
final int CANVAS_BORDER = 1;

/**
 * Display the animation's FPS in a div.
 */
void showFps(num fps) {
  if (fpsAverage == null) {
    fpsAverage = fps;
  }

  fpsAverage = fps * 0.05 + fpsAverage * 0.95;

  query("#notes").text = "${fpsAverage.round().toInt()} fps";
}

/**
 * A representation of the solar system.
 *
 * This class maintains a list of planetary bodies, knows how to draw its
 * background and the planets, and requests that it be redraw at appropriate
 * intervals using the [Window.requestAnimationFrame] method.
 */
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
  List<double> graphData;
  int dataOffset;
  int timeLast = 0;

  UI(this.display, this.graph, int numWorkers) {

    drawCount = 0;

    canvasTile = new CanvasElement(TILE_SIZE, TILE_SIZE);

    int availWidth = window.innerWidth - BODY_PADDING * 2 - CANVAS_BORDER * 2;
    int availHeight = window.innerHeight - BODY_PADDING * 2 - CANVAS_BORDER * 4;
    graph.width = cx = availWidth;
    display.width = availWidth;
    graph.height = (availHeight * 0.25).toInt();
    display.height = cy = (availHeight * 0.75).toInt();
    
    Queue<WorkResponse> readyList = new Queue<WorkResponse>();

    graphData = new List<double>(cx);
    for (int i = 0; i < cx; i++) {
      graphData[i] = 0.0;
    }
    dataOffset = 0;

    columns = (display.width ~/ TILE_SIZE + 1);
    tiles =  columns * (display.height ~/ TILE_SIZE + 1);
    print("Tiles: $tiles");
    rcDisplay = [-1.1, 0.45, -1.0, 0.2];

    var pCanvas = display.height / display.width;
    var rcHeight = (rcDisplay[1] - rcDisplay[3]).abs();
    var rcWidth = (rcDisplay[0] - rcDisplay[2]).abs();
    print('height $rcHeight, width $rcWidth');
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

  List<double> getPosition(int x, int y) {
    return [rcDisplay[0] + (rcDisplay[2] - rcDisplay[0]) * x / cx,
            rcDisplay[1] + (rcDisplay[3] - rcDisplay[1]) * y / cy];
  }

  bool draw(int time) {
    print("Time: $time");
    if (!readyList.isEmpty()) {
      work = readList.removeFirst();
      work.renderToCanvas(canvasTile);

      canvasTile.
    }
    
    if (tile < tiles) {
      int start = Clock.now();
      drawTile();
      double dsecs = (Clock.now() - start) / Clock.frequency();
      updateData((TILE_SIZE * TILE_SIZE) / dsecs);
      tile++;
    }
    drawGraph();

    window.requestAnimationFrame(draw);
    timeLast = time;
  }

  void drawTile() {
    int x = (tile % columns) * TILE_SIZE;
    int y = (tile ~/ columns) * TILE_SIZE;
    var ul = getPosition(x, y);
    var lr = getPosition(x + TILE_SIZE, y + TILE_SIZE);
    List<double> rc = [ul[0], ul[1], lr[0], lr[1]];
    print("Drawing tile $tile/$tiles @ $rc");

    Mandelbrodt.render(canvasTile, rc);
    display.context2d.drawImage(canvasTile, x, y);
  }

  void updateData(double n) {
    print("Pixels per sec: $n");
    graphData[dataOffset] = n;
    dataOffset = (dataOffset + 1) % cx;
  }

  void drawGraph() {
    var ctx = graph.context2d;
    graph.width = graph.width;

    double maxData = 20.0;
    for (int i = 0; i < cx; i++) {
      if (graphData[i] > maxData) {
        maxData = graphData[i];
      }
    }
    double scale = graph.height / maxData;

    for (int x = 0; x < cx; x++) {
      int i = (dataOffset + x) % cx;
      int y = graph.height - (graphData[i] * scale).toInt();
      if (x == 0) {
        ctx.moveTo(x, y);
        print("$x, $y");
      } else {
        ctx.lineTo(x, y);
        if (x < 10) {
          print(".. $x, $y");
        }
      }
    }
    ctx.stroke();
  }

}
