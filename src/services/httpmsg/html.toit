import ...util.bytes show stringify-all-bytes
import ...devices as devices
import .msgs

html-page device/devices.Device docsUrl/string custom-actions/Map -> string:
  return """<html><head><meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    button, input[type="button"] {
        outline: none;
        border: none;
        background-color: #fc7c3d;
        color: #fff;
        padding: 10px;
        margin: 3px 5px 3px 0;
        cursor: pointer;
        
    }
  </style>
  </head><body>
  <h1>Lightbug $(device.name)</h1>
  <input type="button" value="Send bytes" onclick="submit()">
  <input type="text" id="post" name="post" style="width: 50%;">
  <div>
  <div><h2>Presets</h2>$(generate-msg-buttons device custom-actions)</div>
  <div><h2>Screen</h2>$(generate-screen-html)</div>
  </div>
  </br><a href="$(docsUrl)/devices/api/generate" target="_blank">You can also generate your own messages</a>
  <h2>Log</h2>
  <div id="l"><span>Sent messages, and their responses will appear here...</span></div>
  
<script>
    function submit(input = null, end = '/post') {
        submitMulti([input], end);
    }
    function submitMulti(inputs = [], end = '/post') {
        let post = inputs.map(input => {
            let p = input || document.getElementById('post').value;
            return p.split(/[, ]+/).map(s => s.trim()).map(s => {
                if (s.startsWith('0x')) {
                    return parseInt(s, 16);
                } else {
                    return parseInt(s, 10);
                }
            }).join(' ');
        }).join('\\n');

        fetch(end, {
            method: 'POST',
            body: post,
        })
        .then(response => {
            const reader = response.body.getReader();
            const decoder = new TextDecoder();
            function read() {
                reader.read().then(({ done, value }) => {
                    if (done) {
                        return;
                    }
                    const text = decoder.decode(value, { stream: true });
                    const lines = text.split('\\n');
                    lines.forEach(line => {
                        if (line.trim() !== '') {
                            const d = document.getElementById('l');
                            d.prepend(document.createElement('br'));
                            const p = document.createElement('span');
                            p.textContent = line;
                            d.prepend(p);
                            const matches = line.match(/(\\d{1,3}(\\s\\d{1,3})+)/g);
                            if (matches) {
                                matches.forEach(b => {
                                    const a = document.createElement('a');
                                    a.href = "$(docsUrl)/devices/api/parse?bytes=" + b;
                                    a.textContent = "(parse)";
                                    a.target = "_blank";
                                    d.prepend(document.createTextNode(' '));
                                    d.prepend(a);
                                });
                            }
                        }
                    });
                    read();
                }).catch(error => {
                    console.error('Error reading stream:', error);
                });
            }
            read();
        })
        .catch((error) => {
            console.error('Error:', error);
        });
    }
    let fetching = false;
    function poll() {
        if (fetching) return;
        fetching = true;
        fetch('/poll')
        .then(response => response.text())
        .then(text => {
            const lines = text.split('\\n');
            lines.forEach(line => {
                if (line.trim() !== '') {
                    const d = document.getElementById('l');
                    d.prepend(document.createElement('br'));
                    const p = document.createElement('span');
                    p.textContent = line;
                    d.prepend(p);
                    const matches = line.match(/(\\d{1,3}(\\s\\d{1,3})+)/g);
                    if (matches) {
                        matches.forEach(b => {
                            const a = document.createElement('a');
                            a.href = "$(docsUrl)/devices/api/parse?bytes=" + b;
                            a.textContent = "(parse)";
                            a.target = "_blank";
                            d.prepend(document.createTextNode(' '));
                            d.prepend(a);
                        });
                    }
                }
            });
        })
        .catch((error) => {
            console.error('Error:', error);
        })
        .finally(() => {
            fetching = false;
        });
    }
    setInterval(poll, 2000);
</script>
</body></html>"""

generate-msg-buttons device/devices.Device custom-actions/Map -> string:
  dynamicHtml := ""
  sample-messages.keys.map: |key|
    unsupported := false
    device.messages-not-supported.map: |id|
        if key.contains "$id":
          unsupported = true
    if not unsupported:
      sectionHtml := """$key<br>"""
      hasEntries := false
      sample-messages[key].keys.map: |action|
        unsupported = false
        device.messages-not-supported.map: |id|
            if action.contains "$id":
              unsupported = true
        if not unsupported:
          hasEntries = true
          sectionHtml = sectionHtml + """<input type="button" value="$action" onclick="submit('$(stringify-all-bytes sample-messages[key][action] --short=true --commas=false --hex=false)')">\n"""
      sectionHtml = sectionHtml + """<br>\n"""
      if hasEntries:
        dynamicHtml = dynamicHtml + sectionHtml
  custom-actions.keys.map: |key|
    dynamicHtml = dynamicHtml + """$key<br>\n"""
    custom-actions[key].keys.map: |action|
      dynamicHtml = dynamicHtml + """<input type="button" value="$action" onclick="submit('$(custom-actions[key][action])','/custom')">\n"""
    dynamicHtml = dynamicHtml + """<br>\n"""
  return dynamicHtml

SCREEN_WIDTH := 250
SCREEN_HEIGHT := 122
PIXEL_SIZE := 1
BRUSH_SIZE := PIXEL-SIZE * 2
generate-screen-html -> string:
    return """
<canvas id="c" width="$(SCREEN_WIDTH * PIXEL_SIZE)" height="$(SCREEN_HEIGHT * PIXEL_SIZE)" style="border: 1px solid black;"></canvas>
</br>
<button onclick="exportBitmap()">Draw</button>
<button onclick="clearCanvas()">Clear</button>
<script>
    const c = document.getElementById('c');
    const ctx = c.getContext('2d');
    ctx.fillStyle = "#FFF";
    ctx.fillRect(0, 0, c.width, c.height);
    let isDrawing = false;
    const PIXEL_SIZE = $(PIXEL_SIZE);
    const brushSize = $(BRUSH_SIZE);
    let exportBoxes = [];

    c.addEventListener("mousedown", () => isDrawing = true);
    c.addEventListener("mouseup", () => isDrawing = false);
    c.addEventListener("mousemove", handleMouseMove);
    c.addEventListener("click", fillPixel);
    c.addEventListener("touchstart", (event) => {
        event.preventDefault();
        isDrawing = true
    });
    c.addEventListener("touchend", (event) => {
        event.preventDefault();
        isDrawing = false
    });
    c.addEventListener("touchmove", (event) => {
        event.preventDefault();
        const touch = event.touches[0];
        handleMouseMove({ clientX: touch.clientX, clientY: touch.clientY });
    });

    function clearCanvas() {
        ctx.fillStyle = "#FFF";
        ctx.fillRect(0, 0, c.width, c.height);
    }

    function handleMouseMove(event) {
        if (isDrawing) {
            fillPixel(event);
        }
    }

    function fillPixel(event) {
        const { x, y } = getMousePos(event);
        ctx.fillStyle = "#000";
        ctx.fillRect(x * PIXEL_SIZE, y * PIXEL_SIZE, brushSize, brushSize);
    }

    function getMousePos(event) {
        const rect = c.getBoundingClientRect();
        return {
            x: Math.floor((event.clientX - rect.left) / PIXEL_SIZE),
            y: Math.floor((event.clientY - rect.top) / PIXEL_SIZE)
        };
    }

    function exportBitmap() {
        const imgData = ctx.getImageData(0, 0, c.width, c.height);
        const data = imgData.data;

        // Determine bounding box in canvas (physical pixel) coordinates.
        let minX = c.width, minY = c.height, maxX = -1, maxY = -1;
        for (let y = 0; y < c.height; y++) {
            for (let x = 0; x < c.width; x++) {
                const index = (y * c.width + x) * 4;
                const r = data[index];
                const g = data[index + 1];
                const b = data[index + 2];
                // Assuming drawn pixels are pure black and background is white.
                if (r < 128 && g < 128 && b < 128) {
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        }

        // If no black pixel found, clear export fields.
        if (maxX === -1) {
            exportBoxes = [];
            return;
        }

        // Convert canvas coordinates to grid coordinates.
        const gridX = Math.floor(minX / PIXEL_SIZE);
        const gridY = Math.floor(minY / PIXEL_SIZE);
        const gridMaxX = Math.floor(maxX / PIXEL_SIZE);
        const gridMaxY = Math.floor(maxY / PIXEL_SIZE);
        const gridWidth = gridMaxX - gridX + 1;
        const gridHeight = gridMaxY - gridY + 1;

        // Build a binary grid representing filled cells.
        const binaryGrid = [];
        for (let row = 0; row < gridHeight; row++) {
            binaryGrid[row] = [];
            for (let col = 0; col < gridWidth; col++) {
                // Calculate the cell's top-left canvas coordinate.
                const cellX = (gridX + col) * PIXEL_SIZE;
                const cellY = (gridY + row) * PIXEL_SIZE;
                let isBlackCell = false;
                // Check every pixel in the cell.
                for (let j = 0; j < PIXEL_SIZE; j++) {
                    for (let i = 0; i < PIXEL_SIZE; i++) {
                        const cx = cellX + i;
                        const cy = cellY + j;
                        if (cx >= c.width || cy >= c.height) continue;
                        const idx = (cy * c.width + cx) * 4;
                        const r = data[idx];
                        const g = data[idx + 1];
                        const b = data[idx + 2];
                        if (r < 128 && g < 128 && b < 128) {
                            isBlackCell = true;
                            break;
                        }
                    }
                    if (isBlackCell) break;
                }
                binaryGrid[row][col] = isBlackCell ? 1 : 0;
            }
        }

        // Function to pack binary grid into bytes and generate C array.
        const packBinaryGrid = (startRow, endRow) => {
            const cArray = [];
            const bytesPerRow = Math.ceil(gridWidth / 8);
            for (let row = startRow; row <= endRow; row++) {
                for (let byteIndex = 0; byteIndex < bytesPerRow; byteIndex++) {
                    let byte = 0;
                    for (let bit = 0; bit < 8; bit++) {
                        const col = byteIndex * 8 + bit;
                        const bitValue = col < gridWidth ? binaryGrid[row][col] : 0;
                        byte |= (bitValue << (7 - bit));
                    }
                    // Format byte as hex (e.g., 0X3F)
                    cArray.push('0X' + byte.toString(16).padStart(2, '0').toUpperCase());
                }
            }
            return cArray;
        };

        // Split into bounding boxes
        const maxBytes = 255;
        const bytesPerRow = Math.ceil(gridWidth / 8);
        const maxRowsPerBox = Math.floor(maxBytes / bytesPerRow);
        let startRow = 0;
        exportBoxes = [];

        // const splitForExport = true; // Always split for export
        let splitForExport = true;
        let pageId = Math.floor(Math.random() * 245) + 10;

        if (splitForExport) {
            while (startRow < gridHeight) {
                const endRow = Math.min(startRow + maxRowsPerBox - 1, gridHeight - 1);
                const cArray = packBinaryGrid(startRow, endRow);
                let box = {
                    exportPositionX: gridX,
                    exportPositionY: gridY + startRow,
                    exportSizeX: gridWidth,
                    exportSizeY: endRow - startRow + 1,
                    bytes: cArray.length,
                    pixels: (endRow - startRow + 1) * gridWidth,
                    cArrayOutput: cArray.join(','),
                }
                box.msgBytes = box2msgb(box, pageId, false, (startRow === 0), (endRow === gridHeight - 1));
                exportBoxes.push(box);
                startRow = endRow + 1;
            }
        } else {
            const cArray = packBinaryGrid(0, gridHeight - 1);
            let box = {
                exportPositionX: gridX,
                exportPositionY: gridY,
                exportSizeX: gridWidth,
                exportSizeY: gridHeight,
                bytes: cArray.length,
                pixels: gridWidth * gridHeight,
                cArrayOutput: cArray.join(',')
            };
            if (box.bytes <= 255) {
                box.msgBytes = box2msgb(box,pageId,true);
            } else {
                box.msgBytes = "Too many bytes to fit in a message";
            }
            exportBoxes.push(box);
        }
        let toSend = [];
        exportBoxes.forEach(box => {
            toSend.push(box.msgBytes);
        });
        submitMulti(toSend);
    }

    function box2msgb(box, pageId, onlyOne=true, isFirst=true, isLast=true) {
        const ui16le = (num) => {
            return [num & 0xff, (num >> 8) & 0xff];
        };
        let b = [];
        b.push(3);
        b.push(255);
        b.push(255);
        b.push(...ui16le(10011));
        b.push(0);
        b.push(0);
        let d = new Map();
        d.set(3, [pageId]);
        d.set(7, [box.exportPositionX]);
        d.set(8, [box.exportPositionY]);
        d.set(9, [box.exportSizeX]);
        d.set(10, [box.exportSizeY]);
        d.set(25, box.cArrayOutput.split(',').map(byte => parseInt(byte, 16)));
        if(onlyOne) {
          d.set(6, [2]); // FullRedraw
        } else {
        if(isFirst) {
          d.set(6, [5]); // ClearDontDraw
        } else if(isLast) {
          d.set(6, [4]); // FullRedrawWithoutClear
        } else {
          d.set(6, [3]); // BufferOnly
        }}
        b.push(...ui16le(d.size));
        for (let [key, value] of d) {
            b.push(key);
        }
        for (let [key, value] of d) {
            b.push(value.length);
            b.push(...value);
        }
        const length = b.length + 2;
        b[1] = length & 0xff;
        b[2] = (length >> 8) & 0xff;
        // Just add 255 255 to the end, and the /post receiver will do the csum
        b.push(255);
        b.push(255);
        return b.toString();
    }
</script>
"""
