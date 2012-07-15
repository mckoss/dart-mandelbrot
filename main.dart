#library("mandelbrodt.main");

#import("dart:html");

#import("mandelbrot.dart");
#import("view_port.dart");
#import("chart.dart");

final int TILE_SIZE = 64;
final int BODY_PADDING = 10;
final int CANVAS_BORDER = 1;

void main() {
  new MandelbrotDemo(query("#display"), query("#graph"));
}

class MandelbrotDemo {
  Mandelbrot engine;
  RateChart chart;
  ViewPort display;
  ViewPort tile;
  int nextTile;
  int numTiles;

  MandelbrotDemo(displayCanvas, chartCanvas) {
    engine = new Mandelbrot();
    int availWidth = window.innerWidth - BODY_PADDING * 2 - CANVAS_BORDER * 2;
    int availHeight = window.innerHeight - BODY_PADDING * 2 - CANVAS_BORDER * 4;
    chartCanvas.width = availWidth;
    chartCanvas.height = (availHeight * 0.25).toInt();
    displayCanvas.width = availWidth;
    displayCanvas.height = availHeight - chartCanvas.height;

    chart = new RateChart(chartCanvas, "pixels");
    display = new ViewPort(0, 0, displayCanvas, [-2.0, 1.1, 0.5, -1.1]);
    display.adjustAspectRatio();
    this.prepTiles();

    display.canvas.on.click.add(this.onClick);

    window.requestAnimationFrame(draw);
  }

  prepTiles() {
    tile = display.makeTile(TILE_SIZE);
    nextTile = 0;
    numTiles = tile.numTiles();
  }

  void onClick(e) {
    var x = e.x;
    var y = e.y - 2 - 10 - chart.canvas.height;
    display.zoom([x, y], 2.0);
    prepTiles();
  }

  draw(int time) {
    if (nextTile < numTiles) {
      tile.positionTile(display, nextTile++);
      engine.renderAt(display, tile);
      chart.update(TILE_SIZE * TILE_SIZE);
      chart.draw();
    }
    window.requestAnimationFrame(draw);
  }
}


