#library("mandelbrodt.main");

#import("dart:html");
#import('dart:isolate');

#import("mandelbrodt.dart");
#import("view_port.dart");
#import("chart.dart");

final int TILE_SIZE = 64;
final int BODY_PADDING = 10;
final int CANVAS_BORDER = 1;

void main() {
  new MandelbrodtDemo(query("#display"), query("#graph"));
}

class MandelbrodtDemo {
  Mandelbrodt engine;
  RateChart chart;
  ViewPort display;
  ViewPort tile;
  int nextTile;
  int numTiles;

  MandelbrodtDemo(displayCanvas, chartCanvas) {
    engine = new Mandelbrodt();
    int availWidth = window.innerWidth - BODY_PADDING * 2 - CANVAS_BORDER * 2;
    int availHeight = window.innerHeight - BODY_PADDING * 2 - CANVAS_BORDER * 4;
    chartCanvas.width = availWidth;
    chartCanvas.height = (availHeight * 0.25).toInt();
    displayCanvas.width = availWidth;
    displayCanvas.height = availHeight - chartCanvas.height;
    
    chart = new RateChart(chartCanvas);
    display = new ViewPort(0, 0, displayCanvas, [-2.0, 1.0, 0.25, -1.0]);
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
    display.zoom([x, y], 2);
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

