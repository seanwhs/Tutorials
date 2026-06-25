## 1. Imports and font cache

```python
import io, json, math, os, random
from PIL import Image, ImageDraw, ImageFont


_FONT_CACHE: dict[tuple, ImageFont.FreeTypeFont] = {}
```

### Why this block exists
This section loads the basic tools needed to draw teacher-style annotations onto images. `io` handles in-memory byte buffers, `json` parses the markup instructions, `math` supports curved shapes, `os` checks for font files, and `random` adds human-like variation. The `_FONT_CACHE` dictionary stores loaded fonts so the program does not reload them every time it draws text.

### Python concepts used
- Multiple imports can be written on one line.
- `dict[tuple, ImageFont.FreeTypeFont]` is a type hint showing the cache maps a font key to a font object.
- A leading underscore in `_FONT_CACHE` signals “internal use” by convention.

### Pattern analysis
This is a **performance optimization setup**. Caching fonts is a Pythonic way to reduce repeated expensive work.

### What if
Remove the cache and call `_font(...)` repeatedly in a loop. You would see the same output, but the code would work more slowly.

***

## 2. Font loader

```python
def _font(size: int, bold: bool = False, italic: bool = False) -> ImageFont.FreeTypeFont:
    key = (size, bold, italic)
    if key in _FONT_CACHE:
        return _FONT_CACHE[key]

    candidates = [
        "fonts/Caveat-Bold.ttf" if bold else "fonts/Caveat-Regular.ttf",
        "fonts/PatrickHand-Regular.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSerif-BoldItalic.ttf" if bold else
        "/usr/share/fonts/truetype/liberation/LiberationSerif-Italic.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf" if bold else
        "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" if bold else
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ]

    f = ImageFont.load_default()
    for path in candidates:
        if os.path.exists(path):
            try:
                f = ImageFont.truetype(path, size)
                break
            except Exception:
                pass
    _FONT_CACHE[key] = f
    return f
```

### Why this block exists
This function tries to find a good font for handwritten-style grading notes. It checks several possible font files, picks the first one that exists, and falls back to Pillow’s default font if none are available.

### Python concepts used
- Default parameter values: `bold=False`, `italic=False`.
- Tuple keys in dictionaries.
- `os.path.exists(...)` checks whether a file is present.
- `try/except` prevents one bad font file from crashing the function.
- `break` stops the loop once a usable font is found.

### Pattern analysis
This is a **fallback chain**. The function tries the preferred fonts first and degrades gracefully if they are missing.

### What if
Delete the first font path from `candidates` and see how the fallback moves to the next available font.

***

## 3. Color constants

```python
RED = (198, 30, 30, 255)
RED_FILL = (198, 30, 30, 38)
BLUE = (30, 90, 200, 255)
BLUE_FILL = (30, 90, 200, 35)
GREEN = (25, 148, 55, 255)
GREEN_FILL = (25, 148, 55, 35)
ORANGE = (210, 120, 20, 255)
WHITE_SOLID = (255, 255, 255, 255)
BLACK = (20, 20, 20, 255)
```

### Why this block exists
These constants define the app’s visual language. Red means correction or error, blue means comment, green means success, orange is used for margin notes, and white or black are supporting colors.

### Python concepts used
- Tuples are used to store RGBA color values.
- Constants are written in uppercase by convention.

### Pattern analysis
This is a **palette definition**. It keeps the drawing code clean by avoiding repeated raw color values.

### What if
Change `RED` to a lighter shade and notice how the whole marking style becomes less strict-looking.

***

## 4. Jitter helper

```python
def _jitter(val: float, amount: float = 2.5) -> float:
    return val + random.uniform(-amount, amount)
```

### Why this block exists
This adds tiny random offsets to coordinates so the drawing looks hand-made instead of perfectly mechanical. That helps the markup feel like real teacher pen strokes.

### Python concepts used
- Function with type hints.
- `random.uniform(a, b)` returns a random float in a range.
- Default argument `amount=2.5`.

### Pattern analysis
This is a **humanization helper**. It intentionally introduces imperfection.

### What if
Set `amount=0` and compare the result. The drawings will become much more rigid and robotic.

***

## 5. Jittered line drawing

```python
def _jittered_line(draw, x0, y0, x1, y1, fill, width=2, segments=6):
    pts = []
    for i in range(segments + 1):
        t = i / segments
        px = x0 + (x1 - x0) * t + (_jitter(0, 1.5) if 0 < i < segments else 0)
        py = y0 + (y1 - y0) * t + (_jitter(0, 1.5) if 0 < i < segments else 0)
        pts.append((px, py))
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i + 1]], fill=fill, width=width)
```

### Why this block exists
This draws a line in small connected pieces rather than one perfect stroke. The result looks more like a pen or marker drawn by hand.

### Python concepts used
- `for` loops.
- Arithmetic interpolation using `t = i / segments`.
- Lists store the generated points.
- `draw.line(...)` is Pillow’s line drawing function.

### Pattern analysis
This is a **procedural drawing pattern**. Instead of drawing directly, it builds the shape step by step.

### What if
Set `segments=1` and the line becomes much straighter and less organic.

***

## 6. Text measurement helper

```python
def _text_size(text: str, font) -> tuple[int, int]:
    try:
        bb = font.getbbox(text)
        return bb [stackoverflow](https://stackoverflow.com/questions/74327497/understanding-the-getbbox-method-of-a-pillow-font-object) - bb[0], bb [pillow.dev.org](https://pillow.dev.org.tw/en/stable/reference/ImageFont.html) - bb [pillow.readthedocs](https://pillow.readthedocs.io/en/stable/reference/ImageFont.html)
    except Exception:
        return len(text) * max(8, getattr(font, 'size', 12) // 2), getattr(font, 'size', 12)
```

### Why this block exists
This function estimates how wide and tall some text will be when drawn. That helps the program size speech bubbles, boxes, and labels correctly.

### Python concepts used
- `font.getbbox(text)` returns the bounding box of the rendered text. Pillow documents `getbbox()` as returning a bounding box tuple for rendered text. [pillow.readthedocs](https://pillow.readthedocs.io/en/stable/reference/ImageFont.html)
- Tuple unpacking via indexes.
- `getattr(font, 'size', 12)` safely gets a font size or uses a fallback.

### Pattern analysis
This is a **compatibility helper**. It prefers accurate text measurement but still works if that fails.

### What if
Replace `getbbox()` with a rough manual estimate only, and see how the bubbles become less accurate.

***

## 7. Wavy underline

```python
def _wavy_underline(draw, x0, y, x1, color, amplitude=5, wavelength=14):
    steps = max(int((x1 - x0) / 2), 2)
    pts = []
    for i in range(steps + 1):
        px = x0 + (x1 - x0) * i / steps
        py = y + amplitude * math.sin(2 * math.pi * i * (x1 - x0) / (steps * wavelength))
        pts.append((px, py))
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i + 1]], fill=color, width=2)
```

### Why this block exists
This draws a loose, wavy underline, which looks more like a teacher’s pen mark than a straight digital line.

### Python concepts used
- `math.sin(...)` generates a wave.
- Points are calculated along the line and connected with short segments.
- `max(..., 2)` prevents too few steps.

### Pattern analysis
This is a **mathematical shape generator**. It converts a formula into a drawn effect.

### What if
Increase `amplitude` to make the wave more dramatic.

***

## 8. Wobbly ellipse

```python
def _wobbly_ellipse(draw, cx, cy, rx, ry, color, width=3, steps=60):
    pts = []
    for i in range(steps + 1):
        angle = 2 * math.pi * i / steps
        wobble_r = random.uniform(0.93, 1.07)
        wobble_a = angle + random.uniform(-0.04, 0.04)
        px = cx + rx * wobble_r * math.cos(wobble_a) + _jitter(0, 1.2)
        py = cy + ry * wobble_r * math.sin(wobble_a) + _jitter(0, 1.2)
        pts.append((px, py))
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i + 1]], fill=color, width=width)
```

### Why this block exists
This draws an imperfect circle or oval. It is used for score stamps and makes the shape look stamped by hand rather than generated by a machine.

### Python concepts used
- `math.cos` and `math.sin` produce points around an ellipse.
- Random wobble adds variation.
- Looping over angle values creates the outline.

### Pattern analysis
This is another **organic rendering helper**. It simulates a hand-drawn shape.

### What if
Set `wobble_r` to `1.0` and `wobble_a` to `angle` to see a much smoother ellipse.

***

## 9. Rounded rectangle

```python
def _rounded_rect(draw, x0, y0, x1, y1, r, fill=None, outline=None, width=2):
    r = min(r, max(1, (x1-x0)//2), max(1, (y1-y0)//2))
    if fill:
        draw.rectangle([x0+r, y0, x1-r, y1], fill=fill)
        draw.rectangle([x0, y0+r, x1, y1-r], fill=fill)
        draw.pieslice([x0, y0, x0+2*r, y0+2*r], 180, 270, fill=fill)
        draw.pieslice([x1-2*r, y0, x1, y0+2*r], 270, 360, fill=fill)
        draw.pieslice([x0, y1-2*r, x0+2*r, y1], 90, 180, fill=fill)
        draw.pieslice([x1-2*r, y1-2*r, x1, y1], 0, 90, fill=fill)
    if outline:
        draw.arc([x0, y0, x0+2*r, y0+2*r], 180, 270, fill=outline, width=width)
        draw.arc([x1-2*r, y0, x1, y0+2*r], 270, 360, fill=outline, width=width)
        draw.arc([x0, y1-2*r, x0+2*r, y1], 90, 180, fill=outline, width=width)
        draw.arc([x1-2*r, y1-2*r, x1, y1], 0, 90, fill=outline, width=width)
        draw.line([x0+r, y0, x1-r, y0], fill=outline, width=width)
        draw.line([x0+r, y1, x1-r, y1], fill=outline, width=width)
        draw.line([x0, y0+r, x0, y1-r], fill=outline, width=width)
        draw.line([x1, y0+r, x1, y1-r], fill=outline, width=width)
```

### Why this block exists
This function draws boxes with rounded corners, used in speech bubbles and annotation backgrounds. It gives the UI a softer, more natural look.

### Python concepts used
- Geometry with rectangle coordinates.
- `min(...)` clamps the corner radius.
- Separate fill and outline logic.

### Pattern analysis
This is a **custom shape primitive**. Other drawing functions build on top of it.

### What if
Set `r=0` and compare how the same bubble would look with sharp corners.

***

## 10. Speech bubble

```python
def _speech_bubble(draw, ax, ay, text, color, font, img_w, img_h, pad=9):
    import textwrap
    max_chars = max(12, int(img_w * 0.20 / max(1, getattr(font, 'size', 12) * 0.55)))
    lines = textwrap.wrap(text, width=max_chars) or [text]
    line_h = getattr(font, 'size', 12) + 6
    tw = max(_text_size(l, font)[0] for l in lines)
    bw = tw + pad * 2
    bh = len(lines) * line_h + pad * 2
    tail = 12

    bx = min(ax, img_w - bw - 6)
    bx = max(bx, 4)
    by = ay - bh - tail
    flip_tail = by < 4
    if flip_tail:
        by = ay + tail + 4

    _rounded_rect(draw, bx+3, by+3, bx+bw+3, by+bh+3, 7, fill=(0,0,0,55))
    _rounded_rect(draw, bx, by, bx+bw, by+bh, 7, fill=WHITE_SOLID, outline=color, width=2)
    tail_tip = (ax, ay + (tail if flip_tail else 0))
    tail_base_y = by if flip_tail else by + bh
    draw.polygon([(bx+12, tail_base_y), (bx+24, tail_base_y), tail_tip], fill=WHITE_SOLID, outline=color)
    for i, line in enumerate(lines):
        draw.text((bx+pad, by+pad + i*line_h), line, fill=(*color[:3], 230), font=font)
```

### Why this block exists
This draws a teacher-style comment bubble near a mark. It wraps text, sizes the bubble, places it on the image, and flips the tail if needed so it stays on screen.

### Python concepts used
- `textwrap.wrap(...)` splits long text into lines.
- `max(...)` and `min(...)` help keep the bubble on the image.
- `draw.polygon(...)` draws the bubble tail.
- `draw.text(...)` writes the wrapped text.

### Pattern analysis
This is a **smart layout helper**. It does positioning, wrapping, and rendering in one place.

### What if
Make `max_chars` smaller and see the bubble become taller and narrower.

***

## 11. Tick and cross marks

```python
def _draw_tick(draw, cx, cy, size, color):
    s = size * 0.38
    w = max(3, int(size // 9))
    p1 = (cx - s * 0.85 + _jitter(0,1), cy + _jitter(0,1))
    p2 = (cx - s * 0.15 + _jitter(0,1), cy + s * 0.65 + _jitter(0,1))
    p3 = (cx + s * 0.85 + _jitter(0,1), cy - s * 0.65 + _jitter(0,1))
    _jittered_line(draw, *p1, *p2, fill=color, width=w)
    _jittered_line(draw, *p2, *p3, fill=color, width=w)
```

```python
def _draw_cross(draw, cx, cy, size, color):
    s = size * 0.38
    w = max(3, int(size // 9))
    _jittered_line(draw, cx-s, cy-s, cx+s, cy+s, fill=color, width=w)
    _jittered_line(draw, cx+s, cy-s, cx-s, cy+s, fill=color, width=w)
```

### Why this block exists
These functions draw the familiar teacher tick and cross symbols. They are used to quickly show correctness or error.

### Python concepts used
- Basic geometry using a center point and size.
- Helper reuse: both rely on `_jittered_line(...)`.

### Pattern analysis
This is **symbol rendering** using shared primitives.

### What if
Increase `size` and see how the symbols become bolder and more obvious.

***

## 12. Score stamp

```python
def _draw_score_stamp(draw, cx, cy, score_text, font_large, font_small, color, alpha_layer=None):
    parts = score_text.split("/")
    if len(parts) == 2 and alpha_layer:
        text = score_text
        tw, th = _text_size(text, font_large)
        bpad = 10
        bx0, by0 = int(cx - tw/2 - bpad), int(cy - th/2 - bpad)
        bx1, by1 = int(cx + tw/2 + bpad), int(cy + th/2 + bpad)
        ad = ImageDraw.Draw(alpha_layer)
        ad.rectangle([bx0, by0, bx1, by1], fill=(*color[:3], 25))
        _rounded_rect(draw, bx0, by0, bx1, by1, 6, outline=color, width=3)
        draw.text((int(cx - tw/2), int(cy - th/2)), text, fill=color, font=font_large)
    else:
        r = max(28, getattr(font_large, 'size', 20) + 14)
        _wobbly_ellipse(draw, int(cx), int(cy), r, r, color, width=3)
        if len(parts) == 2:
            tw, th = _text_size(parts[0], font_large)
            draw.text((int(cx - tw/2), int(cy - th - 2)), parts[0], fill=color, font=font_large)
            st = "/" + parts [pillow.readthedocs](https://pillow.readthedocs.io/en/stable/reference/ImageFont.html)
            sw, sh = _text_size(st, font_small)
            draw.text((int(cx - sw/2), int(cy + 2)), st, fill=color, font=font_small)
        else:
            tw, th = _text_size(score_text, font_large)
            draw.text((int(cx - tw/2), int(cy - th/2)), score_text, fill=color, font=font_large)
```

### Why this block exists
This draws a score badge like `8/10` or `A-`. It can render a boxed stamp or a circular handwritten-looking score depending on the format.

### Python concepts used
- String splitting with `.split("/")`.
- Conditional logic based on the number of parts.
- Optional parameter `alpha_layer` for transparency effects.

### Pattern analysis
This is a **format-aware renderer**. It changes how it draws based on the input string shape.

### What if
Pass a score like `A` instead of `8/10` and see how the rendering style changes.

***

## 13. Correction box

```python
def _draw_correction_box(draw, left, top, right, bottom, color, alpha_layer):
    ad = ImageDraw.Draw(alpha_layer)
    _rounded_rect(ad, int(left), int(top), int(right), int(bottom), 6, fill=(*color[:3], 35))
    _rounded_rect(draw, int(left), int(top), int(right), int(bottom), 6, outline=color, width=3)
    _wavy_underline(draw, left, bottom + 5, right, color)
```

### Why this block exists
This highlights a wrong section with a translucent box and a wavy underline, making corrections stand out visually.

### Python concepts used
- Two drawing layers: an alpha layer and the visible overlay.
- Reuse of `_rounded_rect()` and `_wavy_underline()`.

### Pattern analysis
This is a **composite annotation effect**. It combines multiple drawing helpers into one correction style.

### What if
Remove the underline and see how much less “correction-like” the box feels.

***

## 14. Comment box

```python
def _draw_comment_box(draw, left, top, right, bottom, color):
    dash, gap = 10, 5
    total = dash + gap
    def _dashes(x0, y0, x1, y1, horiz):
        length = abs(x1-x0) if horiz else abs(y1-y0)
        for i in range(int(length / total) + 1):
            s = i * total; e = min(s + dash, length)
            if horiz:
                draw.line([(x0+s, y0), (x0+e, y0)], fill=color, width=2)
            else:
                draw.line([(x0, y0+s), (x0, y0+e)], fill=color, width=2)
    _dashes(left, top, right, top, True)
    _dashes(left, bottom, right, bottom, True)
    _dashes(left, top, left, bottom, False)
    _dashes(right, top, right, bottom, False)
```

### Why this block exists
This draws a dashed border around a comment region. It visually separates comments from corrections or praise.

### Python concepts used
- Nested helper function `_dashes`.
- Loop-based dashed line construction.

### Pattern analysis
This is a **custom border renderer**. It creates a visual style that signals “comment” instead of “error.”

### What if
Increase the dash length and notice the border becomes less dotted and more blocky.

***

## 15. Margin note

```python
def _draw_margin_note(draw, img_w, img_h, text, y_pos, color, font, side="right"):
    import textwrap
    margin_x = int(img_w * 0.02) if side == "left" else int(img_w * 0.75)
    max_width = int(img_w * 0.22)
    max_chars = max(8, int(max_width / max(1, getattr(font, 'size', 12) * 0.55)))
    lines = textwrap.wrap(text, width=max_chars) or [text]
    line_h = getattr(font, 'size', 12) + 4
    bh = len(lines) * line_h + 8
    draw.rectangle([margin_x - 4, y_pos - 4, margin_x + max_width + 4, y_pos + bh], fill=(*color[:3], 18))
    for i, line in enumerate(lines):
        draw.text((margin_x, y_pos + i * line_h), line, fill=(*color[:3], 210), font=font)
    if side == "right":
        ax = margin_x - 8
        ay = y_pos + bh // 2
        draw.polygon([(ax, ay), (ax+10, ay-5), (ax+10, ay+5)], fill=color)
```

### Why this block exists
This places notes in the page margin, like a teacher writing a side remark. It wraps the text and draws a small pointer toward the relevant area.

### Python concepts used
- `textwrap.wrap(...)` for line wrapping.
- Conditional positioning depending on `side`.
- `draw.polygon(...)` for the pointer.

### Pattern analysis
This is a **margin annotation pattern**. It imitates how teachers often write side comments instead of writing directly over the work.

### What if
Change `side="left"` to `side="right"` and see the layout move.

***

## 16. Summary block

```python
def _draw_summary_block(draw, img_w, img_h, summary_text, font, color):
    import textwrap
    block_top = int(img_h * 0.80)
    pad = 14
    max_width = int(img_w * 0.90)
    margin_x = int(img_w * 0.05)
    fs = getattr(font, 'size', 14)
    max_chars = max(20, int(max_width / (fs * 0.58)))
    lines = textwrap.wrap(summary_text, width=max_chars) or [summary_text]
    line_h = fs + 5
    block_h = len(lines) * line_h + pad * 2 + 8
    draw.rectangle([margin_x - pad, block_top - 4, margin_x + max_width + pad, block_top + block_h], fill=(255, 252, 200, 60))
    _jittered_line(draw, margin_x - pad, block_top - 4, margin_x + max_width + pad, block_top - 4, fill=color, width=2)
    for i, line in enumerate(lines):
        draw.text((margin_x, block_top + pad + i * line_h), line, fill=(*color[:3], 215), font=font)
```

### Why this block exists
This creates a summary note near the bottom of the page. It is meant to act like an overall teacher comment after all the smaller marks.

### Python concepts used
- Text wrapping.
- Rectangle drawing with a translucent fill.
- Calculated block size based on font size and text length.

### Pattern analysis
This is a **final summary overlay**. It visually separates closing feedback from detailed corrections.

### What if
Move `block_top` higher and see how the summary competes with the main markup area.

***

## 17. Main entry point

```python
def draw_teacher_markup(image_bytes: bytes, markup_json: str) -> io.BytesIO:
    random.seed(42)
    base = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
    W, H = base.size
```

### Why this block exists
This is the main function that takes an image and markup instructions, then returns a new annotated image in memory. It starts by loading the image and fixing the random seed so the visual output is somewhat reproducible.

### Python concepts used
- `io.BytesIO(...)` converts raw bytes into a file-like object.
- Pillow opens the image and converts it to RGBA.
- `random.seed(42)` makes the random jitter repeatable.

### Pattern analysis
This is the **entry point** for the whole drawing module. It sets up the canvas before any marks are drawn.

### What if
Change the seed value and see how the jittered lines and shapes vary slightly.

***

## 18. Parse JSON and safety fallback

```python
    try:
        data = json.loads(markup_json)
    except json.JSONDecodeError:
        data = {"marks": []}

    marks = data.get("marks", [])
    if len(marks) < 15:
        marks.append({
            "type": "comment",
            "bbox": [10, 10, 30, 200],
            "text": "Check working"
        })

    grade = data.get("grade", "")
```

### Why this block exists
The function needs structured annotation data to work. If parsing fails, it falls back to an empty list. It also injects a default comment when there are too few marks, so the page does not look empty.

### Python concepts used
- `json.loads()` decodes a JSON string.
- `.get(...)` retrieves dictionary values safely.
- List length check with `len(...)`.

### Pattern analysis
This is **defensive data handling**. The function keeps going even if the input data is incomplete or malformed.

### What if
Remove the default comment insertion and see how sparse markup can make the image look unfinished.

***

## 19. Layer setup and fonts

```python
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    alpha_fill = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    base_sz = max(18, min(H // 26, 52))
    f_comment = _font(base_sz, italic=True)
    f_stamp = _font(int(base_sz * 1.25), bold=True)
    f_stamp_s = _font(int(base_sz * 0.85))
    f_praise = _font(int(base_sz * 1.45), bold=True)
    f_margin = _font(int(base_sz * 0.82), italic=True)
    f_summary = _font(int(base_sz * 0.90), italic=True)
```

### Why this block exists
The function creates drawing layers so it can apply transparent highlights separately from visible annotations. It also prepares several font sizes for different kinds of teacher notes.

### Python concepts used
- `Image.new("RGBA", ...)` creates a transparent image layer.
- `ImageDraw.Draw(...)` makes a drawing context.
- `max(...)` and `min(...)` clamp font size to a reasonable range.

### Pattern analysis
This is a **layered rendering setup**. Separate layers make the annotation process cleaner and more flexible.

### What if
Change `base_sz` to a fixed number and compare how the text scales on small versus large images.

***

## 20. Drawing each mark

```python
    for mark in marks:
        try:
            ymin, xmin, ymax, xmax = mark["bbox"]
        except (KeyError, ValueError, TypeError):
            continue

        left = xmin / 1000 * W
        top = ymin / 1000 * H
        right = xmax / 1000 * W
        bottom = ymax / 1000 * H
        cx = (left + right) / 2
        cy = (top + bottom) / 2
        size = max(right - left, bottom - top)

        mtype = mark.get("type", "comment")
        text = mark.get("text", "")
```

### Why this block exists
Each annotation is processed one by one. The bounding box is converted from normalized 0–1000 coordinates into actual pixel coordinates for the current image size.

### Python concepts used
- `for` loop over a list of dictionaries.
- `try/except` protects against bad mark data.
- Coordinate scaling with arithmetic.
- `.get(...)` with defaults.

### Pattern analysis
This is the **annotation decoding loop**. It translates model output into drawable geometry.

### What if
Change the normalization assumption from 0–1000 to 0–1 and see how the coordinates would need to be adjusted.

***

## 21. Type-based rendering

```python
        if mtype == "tick":
            _draw_tick(draw, cx, cy, size, GREEN)
            if text and text.lower() not in ("correct", "✓", "", "right"):
                _speech_bubble(draw, cx, top, text, GREEN, f_comment, W, H)
        elif mtype == "cross":
            _draw_cross(draw, cx, cy, size, RED)
            if text:
                _speech_bubble(draw, cx, top, text, RED, f_comment, W, H)
        elif mtype == "score":
            _draw_score_stamp(draw, int(cx), int(cy), text, f_stamp, f_stamp_s, RED, alpha_fill)
        elif mtype == "praise":
            tw, th = _text_size(text, f_praise)
            tx = int(cx - tw / 2)
            ty = int(cy - th / 2)
            draw.text((tx + _jitter(0,1), ty + _jitter(0,1)), text, fill=RED, font=f_praise)
            _wavy_underline(draw, tx, ty + th + 5, tx + tw, RED, amplitude=4)
        elif mtype == "correction":
            _draw_correction_box(draw, left, top, right, bottom, RED, alpha_fill)
            if text:
                _speech_bubble(draw, left, top, text, RED, f_comment, W, H)
        elif mtype == "comment":
            _draw_comment_box(draw, left, top, right, bottom, BLUE)
            if text:
                _speech_bubble(draw, right, top, text, BLUE, f_comment, W, H)
        elif mtype == "margin_note":
            side = "left" if cx > W * 0.5 else "right"
            _draw_margin_note(draw, W, H, text, int(top), ORANGE, f_margin, side)
            ptr_x = int(W * 0.73) if side == "right" else int(W * 0.27)
            _jittered_line(draw, ptr_x, int(cy), int(cx), int(cy), fill=(*ORANGE[:3], 140), width=1)
        elif mtype == "summary":
            _draw_summary_block(draw, W, H, text, f_summary, BLUE)
```

### Why this block exists
This is the heart of the drawing logic. It looks at each mark type and decides how to render it: tick, cross, score, praise, correction, comment, margin note, or summary.

### Python concepts used
- `if/elif` branching.
- Helper function reuse.
- Conditional speech bubble display.
- Jittered positioning for hand-drawn feel.

### Pattern analysis
This is a **dispatcher loop**. The mark type determines the rendering strategy, which is a very common and useful pattern.

### What if
Add a new type like `"highlight"` and implement a new drawing branch for it.

***

## 22. Grade badge

```python
    if grade and grade.strip() not in ("", "N/A"):
        pad_x = max(70, int(W * 0.10))
        pad_y = max(70, int(H * 0.06))
        gx = W - pad_x
        gy = H - pad_y
        _draw_score_stamp(draw, gx, gy, grade, f_stamp, f_stamp_s, RED, alpha_fill)
```

### Why this block exists
This adds a final grade badge near the bottom-right corner if a real grade exists. It helps make the result immediately visible.

### Python concepts used
- Truthy checks on strings.
- Margin positioning using image dimensions.

### Pattern analysis
This is a **post-processing overlay**. It adds a final summary element after all marks are drawn.

### What if
Move the grade badge to the top-left and notice how it changes the composition.

***

## 23. Compose final image

```python
    result = Image.alpha_composite(base, alpha_fill)
    result = Image.alpha_composite(result, overlay)
    result = result.convert("RGB")

    out = io.BytesIO()
    result.save(out, format="PNG", optimize=True)
    out.seek(0)
    return out
```

### Why this block exists
The function merges the transparent highlight layer and the visible drawing layer onto the original image, converts it to RGB, and saves the final result into an in-memory buffer.

### Python concepts used
- `Image.alpha_composite(...)` merges RGBA layers.
- `.convert("RGB")` removes alpha for final saving compatibility.
- `io.BytesIO()` stores binary image data without writing to disk.
- `.seek(0)` rewinds the buffer so it can be read later.

### Pattern analysis
This is the **final assembly step**. All the helper work gets combined into one deliverable image.

### What if
Save the result as JPEG instead of PNG and compare how transparency-related details change.

## Big-picture reading of the module

This file is a drawing engine for teacher-style annotations. It does not decide what feedback to give; it turns structured markup into visual marks on the image. That means it sits downstream of the AI output and upstream of the user-visible preview.

The main design ideas here are:
- **Caching** for performance.
- **Fallbacks** for robustness.
- **Helper composition** for complex shapes.
- **Random jitter** for a human-like appearance.
- **Layered rendering** for transparency and clean overlays.
