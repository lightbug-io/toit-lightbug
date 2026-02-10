# Tools

This folder contains tools that convert images into Toit bitmap constants and bundle them into `src/util/bitmaps.toit`.

## Setup

1. Install the Python dependency:

    ```bash
    pip install -r tools/requirements.txt
    ```

## Creating individual bitmaps

Use `tools/bitmap_toit.py` to turn a monochrome image (PNG, BMP, or even an HTTP URL) into constants that can be dropped into `.toit` files.

```bash
python tools/bitmap_toit.py path/to/logo.bmp --name LIGHTBUG-20-20 --output src/util/bitmaps/lightbug-20-20.toit
```

### Key options

* `--threshold` / `-t`: Pixels darker than this value are treated as black (default 128). When resizing an image, thresholding happens before and after the resample so you can tweak the cutoff for fuzzy icons.
* `--invert` / `-i`: Swap black and white pixels (useful when the source bitmap has white content on black background).
* `--resize WIDTH HEIGHT`: Scale the source image before generating the byte stream (use this with logos stored at large sizes).
* `--trim`: Crop empty rows/columns before packing, minimizing the final width/height.
* `--per-line`: Control how many bytes are emitted per line inside the `#[]` literal (default 12).
* `--processed-output`: Save the processed (thresholded/resized) preview image for verification.
* `--output` / `-o`: Write the snippet to a file instead of stdout.
* Pass a URL (e.g. `https://lightbug.io/images/logo_orange.png`) as the `source` argument; Pillow will download it and apply the same conversion pipeline.

Each generated `.toit` snippet includes a header comment showing the exact command used so you can reproduce it.

## Bundling bitmaps via `make bitmaps`

The `tools/bitmaps.json` manifest describes every bitmap that should be part of `src/util/bitmaps.toit`. Run the manifest-driven generator to refresh the file:

```bash
make bitmaps
```
