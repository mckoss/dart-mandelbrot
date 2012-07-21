#library("mandelbrot");

#import("dart:html");
#import("view_port.dart");


class Mandelbrot {
  int maxIterations;

  static List<List> levelColors;

  Mandelbrot() {
    maxIterations = 2000;

    if (levelColors == null) {
      levelColors = [
                     [0, [255, 255, 255, 255]],
                     [1, [0, 8, 107, 255]],        // dark blue background
                     [2, [0, 16, 214, 255]],
                     [100, [255, 255, 0, 255]],    // yellow
                     [200, [255, 0, 0, 255]],      // red
                     [400, [0, 255, 0, 255]],      // green
                     [600, [0, 255, 255, 255]],    // cyan
                     [800, [254, 254, 254, 255]],  // white
                     [900, [128, 128, 128, 255]],  // gray
                     [1000, [0, 0, 0, 255]],       // black
                     [1200,[0, 255, 255, 255]],
                     [1400,[0, 255, 0, 255]],
                     [1600,[255, 0, 0, 255]],
                     [1800,[255, 255, 0, 255]],
                     [1900, [255, 255, 255, 255]],
                     [2000, [0, 0, 0, 255]]
                     ];
    }
  }

  int iterations(double x0, double y0) {
    if (y0 < 0) {
        y0 = -y0;
    }
    double x = x0;
    double y = y0;
    double xT;

    double x2 = x * x;
    double y2 = y * y;

    // Filter out points in the main cardiod
    if (-0.75 < x && x < 0.38 && y < 0.66) {
        double q = (x - 0.25) * (x - 0.25) + y2;
        if (q * (q + x - 0.25) < 0.25 * y2) {
            return maxIterations;
        }
    }

    // Filter out points in bulb of radius 1/4 around (-1,0)
    if (-1.25 < x && x < -0.75 && y < 0.25) {
        double d = (x + 1) * (x + 1) + y2;
        if (d < 1 / 16) {
            return maxIterations;
        }
    }

    for (int i = 0; i < maxIterations; i++) {
        if (x * x + y * y > 4) {
            return i;
        }

        xT = x * x - y * y + x0;
        y = 2 * x * y + y0;
        x = xT;
    }
    return maxIterations;
  }

  static List colorFromLevel(int level) {
    // Interpolate control points in this.levelColors
    // to map levels to colors.
    int iMin = 0;
    int iMax = levelColors.length;
    while (iMin < iMax - 1) {
        int iMid = (iMin + iMax) ~/ 2;
        int levelT = levelColors[iMid][0];
        if (levelT == level) {
            return levelColors[iMid][1];
        }
        if (levelT < level) {
            iMin = iMid;
        }
        else {
            iMax = iMid;
        }
    }

    int levelMin = levelColors[iMin][0];
    int levelMax = levelColors[iMax][0];
    // Make sure we are not overly sensitive to rounding
    double p = (level - levelMin) / (levelMax - levelMin);

    List<int> color = new List<int>(4);
    for (var i = 0; i < 4; i++) {
        int cMin = levelColors[iMin][1][i];
        int cMax = levelColors[iMax][1][i];
        var value = (cMin + p * (cMax - cMin)).toInt();
        color[i] = value;
    }

    return color;
  }

  renderData(List<int> data, List<double> rc, int cx, int cy) {
    // Per-pixel step values
    double dx = (rc[2] - rc[0]) / cx;
    double dy = (rc[3] - rc[1]) / cy;

    double y = rc[1] + dy / 2;
    int ib = 0;
    List<int> rgba = new List<int>(4);
    for (int iy = 0; iy < cy; iy++) {
        double x = rc[0] + dx / 2;
        for (int ix = 0; ix < cx; ix++) {
            int iters = iterations(x, y);
            rgba = colorFromLevel(iters);
            for (int i = 0; i < 4; i++) {
                data[ib++] = rgba[i];
            }
            x += dx;
        }
        y += dy;
    }
  }

  render(CanvasElement canvas, List<double> rc) {
    var ctx = canvas.context2d;
    ImageData bitmap = ctx.createImageData(canvas.width, canvas.height);
    renderData(bitmap.data, rc, canvas.width, canvas.height);
    ctx.putImageData(bitmap, 0, 0);
  }

  renderAt(ViewPort displayView, ViewPort tileView) {
    render(tileView.canvas, tileView.rect);
    tileView.drawOn(displayView.canvas);
  }
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
