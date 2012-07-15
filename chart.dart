#library("mandelbrodt.chart");

#import("dart:html");

class RateChart {
  CanvasElement canvas;
  List<double> chartData;
  int dataOffset = 0;
  int lastTime;
  
  RateChart(CanvasElement this.canvas) {
    chartData = new List<double>(canvas.width);
    for (int i = 0; i < canvas.width; i++) {
      chartData[i] = 0.0;
    }
    lastTime = Clock.now();
  }
  
  void update(num value) {
    double dsecs = (Clock.now() - lastTime) / Clock.frequency();
    lastTime = Clock.now();
    chartData[dataOffset] = value / dsecs;
    dataOffset = (dataOffset + 1) % canvas.width;
  }
  
  void draw() {
    var ctx = canvas.context2d;
    canvas.width = canvas.width;  // clear canvas (HACK - more direct way?)
    
    double maxData = 0.0;
    double scale = 2.0;
    for (int i = 0; i < canvas.width; i++) {
      if (chartData[i] > maxData) {
        maxData = chartData[i];
      }
    }
    scale = canvas.height / maxData;

    ctx.font = "bold 10px sans-serif";
    ctx.textBaseline = "top";
    ctx.fillText("${maxData.toInt()}", 0, 0);

    for (int x = 0; x < canvas.width; x++) {
      int i = (dataOffset + x) % canvas.width;
      int y = canvas.height - (chartData[i] * scale).toInt();
      if (x == 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
  }
}