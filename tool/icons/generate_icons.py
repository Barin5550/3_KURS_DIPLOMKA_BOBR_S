"""Генерация иконок приложения «Маршрут» для всех платформ.

Рисует тот же логотип, что и виджет AppLogo (lib/presentation/widgets/common.dart):
оранжевая ломаная «М» с белыми точками на тёмно-синем фоне.

Запуск из корня репозитория:  python3 tool/icons/generate_icons.py
Нужен Pillow (pip install pillow).
"""

import json
import os

from PIL import Image, ImageDraw

NAVY = (0x1A, 0x3A, 0x8F)
ORANGE = (0xF5, 0x7C, 0x00)
WHITE = (255, 255, 255)

# Координаты ломаной и точек в долях стороны плитки (как в _RoutePainter).
ROUTE = [(0.22, 0.74), (0.22, 0.30), (0.50, 0.58), (0.78, 0.30), (0.78, 0.74)]
DOTS = [(0.22, 0.74), (0.78, 0.74)]
STROKE = 0.10
DOT_RADIUS = 0.065

SS = 4  # сглаживание: рисуем в 4 раза крупнее и уменьшаем


def draw_route(draw, x0, y0, side, color=ORANGE, dots=WHITE):
    """Рисует ломаную и точки в квадрате (x0, y0, side)."""
    pts = [(x0 + fx * side, y0 + fy * side) for fx, fy in ROUTE]
    width = round(STROKE * side)
    draw.line(pts, fill=color, width=width, joint="curve")
    r = width / 2
    for x, y in (pts[0], pts[-1]):  # скруглённые концы линии
        draw.ellipse((x - r, y - r, x + r, y + r), fill=color)
    rd = DOT_RADIUS * side
    for fx, fy in DOTS:
        x, y = x0 + fx * side, y0 + fy * side
        draw.ellipse((x - rd, y - rd, x + rd, y + rd), fill=dots)


def tile(size, margin=0.0, radius=0.28, square=False):
    """Плитка логотипа: скруглённый квадрат (или полный квадрат) с отступом."""
    big = size * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m = margin * big
    side = big - 2 * m
    if square:
        d.rectangle((0, 0, big, big), fill=NAVY)
    else:
        d.rounded_rectangle((m, m, m + side, m + side), radius * side, fill=NAVY)
    draw_route(d, m, m, side)
    return img.resize((size, size), Image.LANCZOS)


def maskable(size, safe=0.72):
    """Иконка на весь квадрат, логотип в безопасной зоне (маска круга/капли)."""
    big = size * SS
    img = Image.new("RGBA", (big, big), NAVY + (255,))
    d = ImageDraw.Draw(img)
    side = big * safe
    off = (big - side) / 2
    draw_route(d, off, off, side)
    return img.resize((size, size), Image.LANCZOS)


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("  ", path)


def android():
    res = "android/app/src/main/res"
    # Обычные иконки (Android 7.x и ниже): скруглённая плитка с полями.
    for folder, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        save(tile(px, margin=0.06, radius=0.22), f"{res}/mipmap-{folder}/ic_launcher.png")
    # Адаптивная иконка (Android 8+) задаётся векторами — см. XML ниже.
    os.makedirs(f"{res}/mipmap-anydpi-v26", exist_ok=True)
    with open(f"{res}/mipmap-anydpi-v26/ic_launcher.xml", "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background" />\n'
            '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
            '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n'
            "</adaptive-icon>\n"
        )
    # Логотип на холсте 108×108 dp, плитка — центральные 72 dp (безопасная зона).
    write_vector(f"{res}/drawable/ic_launcher_foreground.xml", 108, 18, 72, "#F57C00", "#FFFFFF")
    write_vector(f"{res}/drawable/ic_launcher_monochrome.xml", 108, 18, 72, "#FFFFFF", "#FFFFFF")
    # Значок уведомления: только белый силуэт на прозрачном фоне (требование Android).
    write_vector(f"{res}/drawable/ic_stat_marshrut.xml", 24, -1.0, 26, "#FFFFFF", "#FFFFFF")
    print("  ", f"{res}/drawable/*.xml")


def write_vector(path, viewport, offset, side, line, dots):
    """Векторный drawable с логотипом: плитка размером side со сдвигом offset."""
    if offset < 0:  # центрировать ломаную (для значка 24 dp)
        cx = (min(x for x, _ in ROUTE) + max(x for x, _ in ROUTE)) / 2
        cy = (min(y for _, y in ROUTE) + max(y for _, y in ROUTE)) / 2
        ox, oy = viewport / 2 - cx * side, viewport / 2 - cy * side
    else:
        ox = oy = offset

    def p(fx, fy):
        return f"{ox + fx * side:.2f},{oy + fy * side:.2f}"

    route = "M" + " L".join(p(fx, fy) for fx, fy in ROUTE)
    r = DOT_RADIUS * side
    circles = ""
    for fx, fy in DOTS:
        x, y = ox + fx * side, oy + fy * side
        circles += (
            f"M{x - r:.2f},{y:.2f} a{r:.2f},{r:.2f} 0 1,0 {2 * r:.2f},0 "
            f"a{r:.2f},{r:.2f} 0 1,0 {-2 * r:.2f},0 "
        )
    with open(path, "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            f'    android:width="{viewport}dp"\n'
            f'    android:height="{viewport}dp"\n'
            f'    android:viewportWidth="{viewport}"\n'
            f'    android:viewportHeight="{viewport}">\n'
            "    <path\n"
            f'        android:pathData="{route}"\n'
            f'        android:strokeColor="{line}"\n'
            f'        android:strokeWidth="{STROKE * side:.2f}"\n'
            '        android:strokeLineCap="round"\n'
            '        android:strokeLineJoin="round" />\n'
            "    <path\n"
            f'        android:pathData="{circles.strip()}"\n'
            f'        android:fillColor="{dots}" />\n'
            "</vector>\n"
        )


def web():
    save(tile(192, margin=0.04), "web/icons/Icon-192.png")
    save(tile(512, margin=0.04), "web/icons/Icon-512.png")
    save(maskable(192), "web/icons/Icon-maskable-192.png")
    save(maskable(512), "web/icons/Icon-maskable-512.png")
    save(tile(32, margin=0.0, radius=0.22), "web/favicon.png")


def windows():
    sizes = [16, 24, 32, 48, 64, 128, 256]
    path = "windows/runner/resources/app_icon.ico"
    tile(256, margin=0.02, radius=0.22).save(path, sizes=[(s, s) for s in sizes])
    print("  ", path)


def ios():
    folder = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    with open(f"{folder}/Contents.json", encoding="utf-8") as f:
        images = json.load(f)["images"]
    for item in images:
        base = float(item["size"].split("x")[0])
        px = round(base * int(item["scale"].rstrip("x")))
        # iOS сам скругляет углы и не допускает прозрачность.
        img = tile(px, square=True).convert("RGB")
        img.save(f"{folder}/{item['filename']}")
    print("  ", f"{folder}/*.png")


def master():
    save(tile(1024, margin=0.0, radius=0.22), "tool/icons/app_icon_1024.png")


if __name__ == "__main__":
    master()
    android()
    web()
    windows()
    ios()
