// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A mandelbrodt visualization.
 */

#library("mandelbrodt");
#import("mandelbrodt-calc.dart");
#import("dart:html");

/**
 * The entry point to the application.
 */
void main() {
  Mandelbrodt.init();
  var ui = new UI(query("#display"), query("#graph"));

  ui.init();
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

  List<double> graphData;
  
  num renderTime;
  
  num drawCount;

  UI(this.display, this.graph) {
    graphData = new List<double>();
    drawCount = 0;
  }

  init() {
    int availWidth = window.innerWidth - BODY_PADDING * 2 - CANVAS_BORDER * 2;
    int availHeight = window.innerHeight - BODY_PADDING * 2 - CANVAS_BORDER * 4;
    graph.width = availWidth;
    display.width = availWidth;
    graph.height = (availHeight * 0.25).toInt();
    display.height = (availHeight * 0.75).toInt();
    
    requestRedraw();
    
    //List<double> rc = [-1.25, 0, -1, 0.5];
    List<double> rc = [-1.25, .125, -1, .375];
    var pCanvas = display.height / display.width;
    var rcHeight = (rc[1] - rc[3]).abs();
    var rcWidth = (rc[0] - rc[2]).abs();
    print('height $rcHeight, width $rcWidth');
    var pRect = rcHeight / rcWidth;
    List<double> rcCenter = [(rc[0] + rc[2]) / 2, (rc[1] + rc[2]) / 2];
    
    //print(rc);
    //print('pRect $pRect, pCanvas $pCanvas');
    if (pRect < pCanvas) {
      var cFactor = display.width / rcWidth;
      double dy = (display.height - rcHeight * cFactor) / cFactor;
      print(dy);
      rc[1] -= dy / 2;
      rc[3] += dy / 2;
    } else {
      var cFactor = display.height / rcHeight;
      double dx = (display.width - rcWidth * cFactor) / cFactor;
      rc[0] -= dx / 2;
      rc[2] += dx / 2;
    }
    Mandelbrodt.render(display, rc);
  }
  
  bool draw(int time) {
    drawCount++;
    if (time == null) {
      // time can be null for some implementations of requestAnimationFrame
      time = new Date.now().millisecondsSinceEpoch;
    }

    if (renderTime != null) {
      //showFps((1000 / (time - renderTime)).round());
    }

    renderTime = time;


    drawGraph();
    requestRedraw();
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

  void requestRedraw() {
    window.requestAnimationFrame(draw);
  }
}
