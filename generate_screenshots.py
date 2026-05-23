"""Generate mockup screenshots of current Namazi app screens."""
from PIL import Image, ImageDraw, ImageFont
import os

W, H = 393, 852  # iPhone 15 logical points scaled
BG = (255, 255, 255)
INDIGO = (88, 86, 214)
GREEN = (52, 199, 89)
DARK = (0, 0, 0)
SECONDARY = (142, 142, 147)
RED = (255, 59, 48)

def get_font(size, bold=False):
    paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/liberation/LiberationSans.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf" if bold else "/usr/share/fonts/truetype/freefont/FreeSans.ttf",
    ]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def draw_centered_text(draw, text, y, font, color=DARK, width=W):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (width - tw) / 2
    draw.text((x, y), text, fill=color, font=font)
    return bbox[3] - bbox[1]

def draw_wrapped_text(draw, text, y, font, color, max_width, center=True):
    words = text.split()
    lines = []
    current = ""
    for word in words:
        test = (current + " " + word).strip()
        bbox = draw.textbbox((0, 0), test, font=font)
        if bbox[2] - bbox[0] > max_width and current:
            lines.append(current)
            current = word
        else:
            current = test
    if current:
        lines.append(current)

    line_h = 0
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        lh = bbox[3] - bbox[1]
        if center:
            tw = bbox[2] - bbox[0]
            x = (W - tw) / 2
        else:
            x = (W - max_width) / 2
        draw.text((x, y), line, fill=color, font=font)
        y += lh + 6
        line_h = lh
    return y

def draw_location_icon(draw, cx, cy, size, color):
    """Draw a simple location pin circle icon."""
    r = size // 2
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=color, width=5)
    # Inner circle
    ir = r // 3
    draw.ellipse((cx - ir, cy - ir, cx + ir, cy + ir), fill=color)
    # Pin tail
    draw.polygon([(cx, cy + r + 16), (cx - 8, cy + r - 4), (cx + 8, cy + r - 4)], fill=color)

def draw_checkmark_icon(draw, cx, cy, size, color):
    """Draw a filled circle with a checkmark."""
    r = size // 2
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)
    # Checkmark
    pts = [(cx - r//3, cy), (cx - r//8, cy + r//3), (cx + r//3, cy - r//4)]
    draw.line([pts[0], pts[1], pts[2]], fill=(255, 255, 255), width=5, joint="curve")

def draw_rounded_rect(draw, x, y, w, h, r, fill=None, outline=None, width=2):
    draw.rounded_rectangle((x, y, x + w, y + h), radius=r, fill=fill, outline=outline, width=width)

# --- Screen 1: LocationPermissionView ---
img1 = Image.new("RGB", (W, H), BG)
d1 = ImageDraw.Draw(img1)

# Status bar simulation
d1.rectangle((0, 0, W, 44), fill=(248, 248, 248))
f_small = get_font(13)
d1.text((20, 14), "9:41", fill=DARK, font=get_font(14, bold=True))
d1.text((W - 60, 14), "100%", fill=DARK, font=f_small)

# Location icon (centered, ~72pt)
icon_y = 200
draw_location_icon(d1, W // 2, icon_y, 72, INDIGO)

# Title
title_y = icon_y + 60
draw_centered_text(d1, "Enable Location", title_y, get_font(28, bold=True))

# Body text
body_y = title_y + 52
draw_wrapped_text(d1, "Namazi uses your location to calculate accurate prayer times for your city.",
                  body_y, get_font(17), SECONDARY, W - 64)

# Button
btn_y = H - 130
btn_x = 24
btn_w = W - 48
btn_h = 52
draw_rounded_rect(d1, btn_x, btn_y, btn_w, btn_h, 14, fill=INDIGO)
# Center button text
btn_font = get_font(17, bold=True)
bbox = d1.textbbox((0, 0), "Allow Location", font=btn_font)
bw = bbox[2] - bbox[0]
bh = bbox[3] - bbox[1]
d1.text((btn_x + (btn_w - bw) / 2, btn_y + (btn_h - bh) / 2), "Allow Location",
        fill=(255, 255, 255), font=btn_font)

# Home indicator bar
d1.rounded_rectangle((W//2 - 65, H - 22, W//2 + 65, H - 12), radius=4, fill=(0, 0, 0, 80))

img1.save("/home/user/namazi/screen1_location_permission.png")
print("Screen 1 saved.")

# --- Screen 2: ContentView placeholder (after location is set) ---
img2 = Image.new("RGB", (W, H), BG)
d2 = ImageDraw.Draw(img2)

# Status bar
d2.rectangle((0, 0, W, 44), fill=(248, 248, 248))
d2.text((20, 14), "9:41", fill=DARK, font=get_font(14, bold=True))
d2.text((W - 60, 14), "100%", fill=DARK, font=f_small)

# Checkmark icon
check_y = H // 2 - 100
draw_checkmark_icon(d2, W // 2, check_y, 72, GREEN)

# "Location set" title
title_y2 = check_y + 56
draw_centered_text(d2, "Location set", title_y2, get_font(22, bold=True))

# Location details
details_y = title_y2 + 46
draw_centered_text(d2, "London, United Kingdom", details_y, get_font(16), SECONDARY)
draw_centered_text(d2, "51.5074, -0.1278", details_y + 28, get_font(14), SECONDARY)
draw_centered_text(d2, "Europe/London", details_y + 52, get_font(12), SECONDARY)

# Next step footnote
next_y = details_y + 100
draw_centered_text(d2, "Next: compute prayer times for today", next_y, get_font(13), SECONDARY)

# Home indicator
d2.rounded_rectangle((W//2 - 65, H - 22, W//2 + 65, H - 12), radius=4, fill=(0, 0, 0, 80))

img2.save("/home/user/namazi/screen2_location_set.png")
print("Screen 2 saved.")

print("Done!")
