// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A mandelbrot visualization.
 */

#library("mandelbrodt");

#import("dart:html");

/**
 * The entry point to the application.
 */
void main() {
  var mandelbrot = new Mandelbrot(query("#container"));

  mandelbrot.init();
}

double fpsAverage;

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
class Mandelbrot {
  CanvasElement canvas;

  num _width;
  num _height;

  num renderTime;

  Mandelbrot(this.canvas) {

  }

  num get width() => _width;

  num get height() => _height;

  init() {
    // Measure the canvas element.
    canvas.parent.rect.then((ElementRect rect) {
      _width = rect.client.width;
      _height = rect.client.height;

      canvas.width = _width;
      // just make a 100x100 black square in the top left hand corner just as a test
      var ctx = canvas.context2d;
      ctx.fillRect(0, 0, 100, 100);
    });
  }

  bool draw(int time) {
    if (time == null) {
      // time can be null for some implementations of requestAnimationFrame
      time = new Date.now().millisecondsSinceEpoch;
    }

    if (renderTime != null) {
      showFps((1000 / (time - renderTime)).round());
    }

    renderTime = time;

    var context = canvas.context2d;

    requestRedraw();
  }

  void requestRedraw() {
    window.requestAnimationFrame(draw);
  }
}
