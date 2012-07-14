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

  List<double> graphData;

  num drawCount;
  List<double> rcDisplay;
  int columns;
  int tile;
  int tiles;
  int cx;
  int cy;

  UI(this.display, this.graph) {
    graphData = new List<double>();
    drawCount = 0;

    canvasTile = new CanvasElement(TILE_SIZE, TILE_SIZE);

    int availWidth = window.innerWidth - BODY_PADDING * 2 - CANVAS_BORDER * 2;
    int availHeight = window.innerHeight - BODY_PADDING * 2 - CANVAS_BORDER * 4;
    graph.width = cx = availWidth;
    display.width = availWidth;
    graph.height = (availHeight * 0.25).toInt();
    display.height = cy = (availHeight * 0.75).toInt();

    columns = (display.width ~/ TILE_SIZE + 1);
    tiles =  columns * (display.height ~/ TILE_SIZE + 1);
    print("Tiles: $tiles");
    rcDisplay = [-1.1, 0.45, -1.0, 0.2];
    tile = 0;
    window.requestAnimationFrame(draw);
  }

  List<double> getPosition(int x, int y) {
    return [rcDisplay[0] + (rcDisplay[2] - rcDisplay[0]) * x / cx,
            rcDisplay[1] + (rcDisplay[3] - rcDisplay[1]) * y / cy];
  }

  bool draw(int time) {
    drawCount++;

    drawGraph();
    if (tile < tiles) {
      int x = (tile % columns) * TILE_SIZE;
      int y = (tile ~/ columns) * TILE_SIZE;
      var ul = getPosition(x, y);
      var lr = getPosition(x + TILE_SIZE, y + TILE_SIZE);
      List<double> rc = [ul[0], ul[1], lr[0], lr[1]];
      tile++;
      print("Drawing tile $tile/$tiles @ $rc");
      Mandelbrodt.render(canvasTile, rc);
      display.context2d.drawImage(canvasTile, x, y);
    }
    window.requestAnimationFrame(draw);
  }

  void drawGraph() {
    if (drawCount > 123) {
      drawCount = 1;
    }
    graphData.add(1 / drawCount);
    graph.width = graph.width;
    var ctx = graph.context2d;

    var offset = 0;
    var l;
    if (graphData.length > graph.width) {
      offset = graphData.length - graph.width;
      ctx.moveTo(0, (graph.height * graphData[graphData.length - graph.width]).toInt());
      l = graph.width;
    } else {
      l = graphData.length;
      ctx.moveTo(0, (graph.height * graphData[0]).toInt());
    }

    for (var i = 0; i < l; i++) {
      if (i > graph.width) {
        break;
      }
      ctx.lineTo(i, (graph.height * graphData[i + offset]).toInt());
    }
    ctx.stroke();
  }

}
