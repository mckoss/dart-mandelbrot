namespace.lookup('com.pageforest.tiles.test').defineOnce(function (ns) {
    var tiles = namespace.lookup('com.pageforest.tiles');
    var clientLib = namespace.lookup('com.pageforest.client');
    var base = namespace.lookup('org.startpad.base');

    function addTests(ts) {

        ts.addTest("tileName", function (ut) {
            var t = new tiles.Tiles();
            var tests = [
                [{x: 0, y: 0}, 0, "0.png"],
                [{x: 0, y: 1}, 0, undefined],
                [{x: 2, y: 0}, 1, undefined],
                [{x: -5, y: 0}, 1, undefined],
                [{x: 20, y: 1}, 4, undefined],
                [{x: 0, y: 0}, 2, "000.png"],
                [{x: 1, y: 0}, 2, "001.png"],
                [{x: 0, y: 1}, 2, "002.png"],
                [{x: 1, y: 1}, 2, "003.png"],
                [{x: 2, y: 2}, 2, "030.png"],
                [{x: 3, y: 3}, 2, "033.png"],
                [{x: 3, y: 0}, 2, "011.png"],
                [{x: 0, y: 3}, 2, "022.png"]
            ];

            for (var i = 0; i < tests.length; i++) {
                var test = tests[i];
                ut.assertEq(t.tileName(test[0], test[1]), test[2], i);
            }

        });

        ts.addTest("rectFromTileName", function (ut) {
            var client = new clientLib.Client({getDoc: function () {
                return {};
            }});
            var t = new tiles.Tiles(client, 'v1', 256, 256,
                                    [-2, -2, 2, 2]);
            var tests = [
                ["0.png", [-2, -2, 2, 2]],
                ["00.png", [-2, -2, 0, 0]],
                ["01.png", [0, -2, 2, 0]],
                ["02.png", [-2, 0, 0, 2]],
                ["03.png", [0, 0, 2, 2]]
            ];

            for (var i = 0; i < tests.length; i++) {
                var test = tests[i];
                ut.assertEq(t.rectFromTileName(test[0]), test[1], i);
            }
        });

        ts.addTest("relativeRect", function(ut) {
            var client = new clientLib.Client({getDoc: function () {
                return {};
            }});
            var t = new tiles.Tiles(client, 'v1', 256, 256,
                                    [-2, -2, 2, 2]);

            var rc = t.relativeRect('0.png', '00.png');
            ut.assertEq(rc, [0, 0, 128, 128]);
        });

        ts.addTest("buildTile", function(ut) {
            var client = new clientLib.Client({getDoc: function () {
                return {};
            }});
            var t = new tiles.Tiles(client, 'v1', 256, 256,
                                    [-2, -2, 2, 2]);

            var tile = t.buildTile();
            ut.assertEq(tile.div.tagName, 'DIV');
            ut.assertEq(tile.div.childNodes.length, 1);
            ut.assertIdent(tile.div.firstChild.firstChild, tile.img);
        });

        ts.addTest("getImage", function(ut) {
            var client = new clientLib.Client({getDoc: function () {
                return {};
            }});
            var t = new tiles.Tiles(client, 'v1', 256, 256,
                                    [-2, -2, 2, 2]);

            var div = t.getImage("0.png");
            ut.assertEq(div.tagName, 'DIV');

            // Note: you can't measure the elements until they are
            // added to the document.

            ut.assertEq(div.offsetWidth, 0);
            document.body.appendChild(div);
            ut.assertEq(div.offsetWidth, 256, 'div width');
            ut.assertEq(div.offsetHeight, 256, 'div height');
            var img = div.firstChild.firstChild;
            ut.assertEq(img.tagName, 'IMG');

            div = t.getImage("01.png");
            ut.assertEq(div.tagName, 'DIV');
            ut.assertEq(div.offsetWidth, 0);
            document.body.appendChild(div);
            ut.assertEq(div.offsetWidth, 256, 'div width');
            ut.assertEq(div.offsetHeight, 256, 'div height');
            img = div.firstChild.firstChild;
            ut.assertEq(img.tagName, 'IMG');
            ut.assertEq(img.offsetWidth, 512, 'img width');
            ut.assertEq(img.offsetHeight, 512, 'img height');
        });

        ts.addTest("findParent", function(ut) {
            var client = new clientLib.Client({getDoc: function () {
                return {};
            }});
            var t = new tiles.Tiles(client, 'v1', 256, 256,
                                    [-2, -2, 2, 2]);

            ut.assertEq(t.findParent('01.png'), '0.png');
            ut.assertEq(t.findParent('013.png'), '0.png');
            t.ensureTile('01.png').exists = true;
            ut.assertEq(t.findParent('013.png'), '01.png');
        });
    }

    ns.addTests = addTests;
});
