"""生成「轻账」App 图标：薄荷绿对角渐变 + 白色 ¥ 符号。

产出三个文件到 assets/icon/：
  app_icon.png       1024x1024 圆角方形（旧版 Android / 兜底）
  ic_foreground.png  1024x1024 透明底前景（adaptive icon，¥ 控制在 66% 安全区内）
  ic_background.png  1024x1024 渐变底（adaptive icon 背景）
"""

import os

from PIL import Image, ImageDraw

SIZE = 1024
CX = CY = SIZE // 2

# 主色：与 AppPalette.primary 同源的薄荷青绿
C_TOP = (46, 211, 190)     # #2ED3BE
C_BOTTOM = (14, 147, 132)  # #0E9384

# ¥ 符号几何参数
TOP_Y = 332
MID_Y = 512
BOT_Y = 704
ARM_DX = 152
BAR_HALF = 150
BAR1_Y = 568
BAR2_Y = 648
STROKE = 48

OUT_DIR = r"D:\jizhang\assets\icon"


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        color = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        draw.line([(0, y), (size, y)], fill=color)
    return img


def draw_yen(img, color):
    """用粗线条 + 端点半圆拼出 ¥ 符号。"""
    draw = ImageDraw.Draw(img)
    half = STROKE // 2

    def seg(a, b):
        draw.line([a, b], fill=color, width=STROKE, joint="curve")

    def cap(p):
        draw.ellipse(
            [p[0] - half, p[1] - half, p[0] + half, p[1] + half],
            fill=color,
        )

    p_left = (CX - ARM_DX, TOP_Y)
    p_right = (CX + ARM_DX, TOP_Y)
    p_mid = (CX, MID_Y)
    p_bot = (CX, BOT_Y)
    bar1_l = (CX - BAR_HALF, BAR1_Y)
    bar1_r = (CX + BAR_HALF, BAR1_Y)
    bar2_l = (CX - BAR_HALF, BAR2_Y)
    bar2_r = (CX + BAR_HALF, BAR2_Y)

    seg(p_left, p_mid)
    seg(p_right, p_mid)
    seg(p_mid, p_bot)
    seg(bar1_l, bar1_r)
    seg(bar2_l, bar2_r)

    for point in (p_left, p_right, p_bot, bar1_l, bar1_r, bar2_l, bar2_r):
        cap(point)


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=radius, fill=255
    )
    return mask


os.makedirs(OUT_DIR, exist_ok=True)

# --- 1. adaptive 背景：满幅渐变 ---
bg = vertical_gradient(SIZE, C_TOP, C_BOTTOM)
bg.save(os.path.join(OUT_DIR, "ic_background.png"))

# --- 2. adaptive 前景：透明底 + 白色 ¥ ---
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_yen(fg, (255, 255, 255, 255))
fg.save(os.path.join(OUT_DIR, "ic_foreground.png"))

# --- 3. 兜底图标：圆角方形渐变 + 白色 ¥ ---
full = vertical_gradient(SIZE, C_TOP, C_BOTTOM).convert("RGBA")
draw_yen(full, (255, 255, 255, 255))
full.putalpha(rounded_mask(SIZE, radius=232))
full.save(os.path.join(OUT_DIR, "app_icon.png"))

for name in ("ic_background.png", "ic_foreground.png", "app_icon.png"):
    path = os.path.join(OUT_DIR, name)
    print(f"{name:22s} {os.path.getsize(path):>9,d} bytes")
