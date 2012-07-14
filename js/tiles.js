/* Tiles - Hierarchical image caching library.

   The tiles library manages the creation and display
   of multi-resolution image tiles.  These can be
   displayed using a custom Google map control.

   All tile images are stored as named blob's underneath a
   global document in Pageforest.  Blob's are stored using
   a quadtree naming convention.  The "top" tile is 0.png
   and the 4 "children" tiles are 00.png, 01.png, 02.png,
   and 03.png (see tileName method, below).

   The client should override these functions:

   tiles.fnRender(blobid, canvas, fnCallback)
       Called to render a specific tile into the given canvas
       object.  Should call fnCallback when complete.

   tiles.fnUpdated(blobid, element)
       Called when the client is ready to display the given tile.

   Tiles will attempt to display the best available resolution tile
   that has already been rendered, while the tile is being rendered.
 */

namespace.lookup('com.pageforest.tiles').defineOnce(function (ns) {
    var format = namespace.lookup('org.startpad.format');
    var base = namespace.lookup('org.startpad.base');

    function Tiles(client, docid, dx, dy, rect) {
        this.client = client;
        this.docid = docid;
        this.dxTile = dx;
        this.dyTile = dy;
        this.rect = rect;
        this.listDepth = 4;
        this.tiles = {};
        this.fnRender = function (blobid, canvas, fnCallback) {
            fnCallback(canvas);
        };
        this.fnUpdated = function(blobid, obj) {
        };
    }

    Tiles.methods({
        // Create the (shared) public document into which all tiles
        // will be stored.
        createTileDoc: function() {
            this.client.storage.putDoc(this.docid, {
                title: "Tile Document - " + this.docid,
                writers: ["public"],
                blob: {version: this.docid}
            }, function (saved) {
                if (saved) {
                    alert("Document created!");
                    return;
                }
                alert("Error creating document.");
            });
        },

        // Calculate a tile name from the tile coordinates and
        // zoom level.  We choose tile prefix naming s.t.
        // childName = parentName + N (for N = 0, 1, 2, 3).
        // The top level tiles are then:
        // 0.png
        // 00.png, 01.png
        // 000.png, 001.png, 002.png, 003.png, ...
        tileName: function(coord, zoom) {
            var maxTile = Math.pow(2, zoom) - 1;
            if (coord.x < 0 || coord.y < 0 ||
                coord.x > maxTile || coord.y > maxTile) {
                return undefined;
            }

            var name = "";
            var x = coord.x;
            var y = coord.y;

            for (var i = zoom; i > 0; i--) {
                var ix = x % 2;
                var iy = y % 2;
                x = Math.floor(x / 2);
                y = Math.floor(y / 2);
                name = (2 * iy + ix).toString() + name;
            }
            return '0' + name + '.png';
        },

        findParent: function(blobid) {
            // Always assume 0.png is available.
            var quad = blobid.substr(0, blobid.indexOf('.'));
            while (quad.length > 1) {
                quad = quad.slice(0, -1);
                var tile = this.tiles[quad + '.png'];
                if (tile && tile.exists) {
                    break;
                }
            }
            return quad + '.png';
        },

        rectFromTileName: function(tileName) {
            var x = this.rect[0];
            var y = this.rect[1];
            var dx = this.rect[2] - this.rect[0];
            var dy = this.rect[3] - this.rect[1];

            for (var i = 1; i < tileName.length; i++) {
                if (tileName[i] == '.') {
                    break;
                }
                dx /= 2;
                dy /= 2;
                var quad = tileName.charCodeAt(i) - '0'.charCodeAt(0);
                if (quad % 2 == 1) {
                    x += dx;
                }
                if (quad >= 2) {
                    y += dy;
                }
            }
            return [x, y, x + dx, y + dy];
        },

        pixelRect: function(tileName, rcOther) {
            // Convert virtual rectangle to pixels in the given tile.
            var rc = this.rectFromTileName(tileName);
            var scale = [this.dxTile / (rc[2] - rc[0]),
                         this.dyTile / (rc[3] - rc[1])];

            rcOther[0] -= rc[0];
            rcOther[1] -= rc[1];
            rcOther[2] -= rc[0];
            rcOther[3] -= rc[1];

            for (var i = 0; i < 4; i++) {
                rcOther[i] = Math.floor(rcOther[i] * scale[i % 2] + 0.5);
            }
            return rcOther;
        },

        relativeRect: function(tileName, tileOther) {
            // Return the (pixel) coordinates of the other tile in
            // relation to the current one.
            return this.pixelRect(tileName, this.rectFromTileName(tileOther));
        },

        // Return a displayable tile, loaded with the best resolution
        // image that we have loaded to date.  Will kick off a render
        // function if we don't yet have the best-resolution tile
        // rendered.
        getImage: function(blobid) {
            var tile = this.ensureTile(blobid);
            return tile.div;
        },

        ensureTile: function(blobid, classname) {
            // REVIEW: Should we be caching images?  Could hamper google
            // maps' ability to free space in the browser by dereferencing
            // img objects.
            if (this.tiles[blobid]) {
                return this.tiles[blobid];
            }

            var tile = this.buildTile(blobid);
            this.tiles[blobid] = tile;

            // Only display an image we are sure is already rendered.
            var parentBlobid = this.findParent(blobid);
            var rcParent = this.relativeRect(blobid, parentBlobid);
            this.setTileImage(tile, parentBlobid, rcParent);

            // Then render the full resolution tile in the background.
            this.checkAndRender(blobid);

            return tile;
        },

        // The structure of a displayed tile is:
        //     <div><div><img/></div><div>
        // The reason for the nested div's is that Google maps
        // modifies styles on the outer element - which can conflict
        // with css properties we have defined for it.
        buildTile: function(blobid, className) {
            var divOuter = document.createElement('div');
            this.setTileSize(divOuter);

            var div = document.createElement('div');
            this.setTileSize(div);
            if (className) {
                div.className = className;
            }
            div.style.overflow = 'hidden';
            divOuter.appendChild(div);

            var img = document.createElement('img');
            div.appendChild(img);

            var divStatus = document.createElement('div');
            divStatus.className = 'status';
            this.setTileSize(divStatus);
            divOuter.appendChild(divStatus);

            var tile = {'div': divOuter,
                        'img': img,
                        'exists': false,
                        'divStatus': divStatus,
                        'blobid': blobid,
                        'status': 'new'};

            this.setTileStatus(tile, className || 'new');
            return tile;
        },

        setTileStatus: function(tile, status) {
            var url = this.client.getDocURL(this.docid, tile.blobid);
            tile.status = status;
            tile.divStatus.innerHTML = '<a target="_blank" href="' +
                url + '">' + tile.blobid + "</a><br/>" + status;
        },

        // Set the image for a tile - but defer changing the display image
        // src until we confirm the image is loaded in memory.
        setTileImage: function(tile, blobid, rc) {
            var self = this;
            var img = new Image();
            var url = this.client.getDocURL(this.docid, blobid);

            var status = 'loading';
            if (blobid != tile.blobid) {
                status += " " + blobid;
            }
            this.setTileStatus(tile, status);

            $(img).bind('load', function() {
                tile.img.src = img.src;
                self.setTileSize(tile.img, rc);
                var status = 'loaded';
                if (blobid != tile.blobid) {
                    status = "displaying " + blobid;
                }
                self.setTileStatus(tile, status);
                self.fnUpdated(tile.blobid, tile.div);
            });
            img.src = url;
        },

        // Copy the tile's image src url and style attributes from one
        // tile to another.
        copyTileAttrs: function(destDiv, srcDiv) {
            var styles = ['top', 'left', 'width', 'height',
                          'position', 'display'];

            var destImg = destDiv.firstChild.firstChild;
            var srcImg = srcDiv.firstChild.firstChild;

            // Don't copy for un-initialized tiles
            if (srcImg.src == "") {
                return;
            }

            destImg.src = srcImg.src;
            for (var i = 0; i < styles.length; i++) {
                destImg.style[styles[i]] = srcImg.style[styles[i]];
            }
        },

        setTileSize: function(elt, rc) {
            if (rc == undefined) {
                rc = [0, 0, this.dxTile, this.dyTile];
            }
            // Note that the parent div is absolute positioned (by
            // Google Maps), and the child image is absolute
            // positioned within the parent div.
            elt.style.position = 'absolute';
            elt.style.left = rc[0] + 'px';
            elt.style.top = rc[1] + 'px';
            elt.style.width = (rc[2] - rc[0]) + 'px';
            elt.style.height = (rc[3] - rc[1]) + 'px';
        },

        // Check if an image exists in the cache.  If not, render it
        // and put it in the cache (and update the DOM image that
        // is displaying it when it is loaded).
        checkAndRender: function(blobid) {
            var self = this;

            self.checkTileExists(blobid, function (exists) {
                var tile = self.ensureTile(blobid);

                if (exists) {
                    self.setTileImage(tile, blobid);
                    return;
                }

                var canvas = document.createElement('canvas');
                canvas.width = self.dxTile;
                canvas.height = self.dyTile;

                self.setTileStatus(tile, 'queued');
                self.fnRender(blobid, canvas, function () {
                    // Update the visible tile with the rendered pixels.
                    tile.img.src = canvas.toDataURL();
                    self.setTileSize(tile.img);
                    self.setTileStatus(tile, 'rendered');
                    self.fnUpdated(blobid, tile.div);
                    tile.exists = true;
                    function deferred() {
                        self.cachePNG(tile, canvas);
                    }
                    setTimeout(deferred, 10);
                });
            });
        },

        cachePNG: function(tile, canvas) {
            var tags = [];
            var blobid = tile.blobid;
            var tagString = blobid.substr(0, blobid.indexOf('.'));
            for (var level = 1; level <= this.listDepth; level++) {
                tagString = tagString.slice(0, -1);
                if (tagString.length == 0) {
                    break;
                }
                tags.push('p' + level + ':' + tagString);
            }
            var self = this;
            this.client.storage.putBlob(this.docid, blobid,
                format.canvasToPNG(canvas),
                {'encoding': 'base64', 'tags': tags},
                function (status) {
                    self.setTileStatus(tile,
                                       'saved: ' + status);
                });
        },

        checkTileExists: function(blobid, fn) {
            // TODO: Load the current tile states using the LIST
            // command using clustered tags.
            var self = this;
            var tile = this.ensureTile(blobid);
            if (tile.exists) {
                fn(true);
                return;
            }

            function deferredCheck() {
                self.client.storage.getBlob(self.docid, blobid,
                                            {dataType: "image/png",
                                             headOnly: true},
                                    function(status) {
                                        if (status) {
                                            self.setTileStatus(tile,
                                                               'available');
                                            tile.exists = true;
                                        }
                                        fn(status);
                                    });
            }

            // Defer for a while to allow some idle time processing
            // of the google maps control
            setTimeout(deferredCheck, 10);
        }
    });

    ns.extend({
        'Tiles': Tiles
    });
});
