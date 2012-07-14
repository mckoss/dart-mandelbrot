/*globals importScripts, postMessage, onmessage */

importScripts("/lib/beta/js/utils.js",
              "/static/src/js/vector.js",
              "mandelbrot.js");

namespace.lookup('com.pageforest.mandelbrot.worker').defineOnce(function (ns) {
    var mandelbrot = namespace.lookup('com.pageforest.mandelbrot');
    var m = new mandelbrot.Mandelbrot();

    function doRender(evt) {
        var data = [];
        var req = evt.data;
        m.renderData(data, req.rc, req.cx, req.cy);
        postMessage({
            id: req.id,
            data: data
        });
    }

    ns.extend({
        'doRender': doRender
    });
});

onmessage = namespace.com.pageforest.mandelbrot.worker.doRender;
