// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A mandelbrodt visualization.
 */

#library("mandelbrodt");
#import("mandelbrodt-calc.dart");
#import("dart:html");

int TILE_SIZE = 64;

/**
 * The entry point to the application.
 */
void main() {
  Mandelbrodt.init();
  var ui = new UI(query("#display"), query("#graph"));
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
  double rcWidth;
  double rcHeight;

  UI(this.display, this.graph) {

    drawCount = 0;

    canvasTile = new CanvasElement(TILE_SIZE, TILE_SIZE);

    int availWidth = window.innerWidth - BODY_PADDING * 2 - CANVAS_BORDER * 2;
    int availHeight = window.innerHeight - BODY_PADDING * 2 - CANVAS_BORDER * 4;
    graph.width = cx = availWidth;
    display.width = availWidth;
    graph.height = (availHeight * 0.25).toInt();
    display.height = cy = (availHeight * 0.75).toInt();
    
    display.on.click.add(this.handleOnClick);

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
    rcHeight = (rcDisplay[1] - rcDisplay[3]).abs();
    rcWidth = (rcDisplay[0] - rcDisplay[2]).abs();
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
  
  handleOnClick(e) {
    var tl = getPosition((e.x - cx/4).toInt(), (e.y - cy/4).toInt());
    var br = getPosition((e.x + cx/4).toInt(), (e.y + cy/4).toInt());
    rcDisplay = [tl[0], tl[1], br[0], br[1]];
    tile = 0;
  }

  bool draw(int time) {
    print("Time: $time");
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
