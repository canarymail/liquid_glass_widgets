#!/usr/bin/env python3
"""Pixel probe for parity captures. Standard library only (no Pillow).

Captures from `xcrun simctl io <udid> screenshot` are 8-bit RGB(A) PNGs at 3x
(1206px wide on iPhone 18 Pro; the 395pt-wide scale used by the Device Hub
window screenshots is NOT used here).

  png_probe.py px   <png> x,y [x,y ...]      print RGB at pixels
  png_probe.py row  <png> y [x0 x1]          colour runs along a row
  png_probe.py col  <png> x [y0 y1]          colour runs along a column
  png_probe.py crop <png> x0 y0 x1 y1 <out> [zoom]   crop (+ nearest zoom)
  png_probe.py bbox <png> x0 y0 x1 y1 [tol]  bbox of pixels differing from the
                                             region's most common colour

Runs shorter than 2px are merged into the previous run so antialiasing does
not drown the output. Values are px; divide by the capture scale (3.0 for the
1206px captures, ~2.947 for the 1185px ones) to get points.
"""
import struct
import sys
import zlib


def load(path):
    data = open(path, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos, idat, w, h, ct, bd = 8, b"", 0, 0, 0, 8
    while pos < len(data):
        n, t = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        if t == b"IHDR":
            w, h, bd, ct, _, _, il = struct.unpack(">IIBBBBB", body)
            assert bd == 8 and il == 0 and ct in (2, 6), "need 8-bit RGB/RGBA"
        elif t == b"IDAT":
            idat += body
        pos += 12 + n
    bpp = 4 if ct == 6 else 3
    raw = zlib.decompress(idat)
    stride = w * bpp
    rows, prev = [], bytearray(stride)
    i = 0
    for _ in range(h):
        f = raw[i]
        line = bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if f == 1:
                line[x] = (line[x] + a) & 255
            elif f == 2:
                line[x] = (line[x] + b) & 255
            elif f == 3:
                line[x] = (line[x] + ((a + b) >> 1)) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[x] = (line[x] + pr) & 255
        rows.append(line)
        prev = line
    return w, h, bpp, rows


def pix(img, x, y):
    w, h, bpp, rows = img
    r = rows[y]
    o = x * bpp
    return (r[o], r[o + 1], r[o + 2])


def runs(vals, off):
    out = []
    for i, v in enumerate(vals):
        if out and (out[-1][2] == v or i - out[-1][1] < 2 and False):
            out[-1][1] = i
        else:
            out.append([i, i, v])
    # merge <2px antialias runs
    merged = []
    for s, e, v in out:
        if merged and e - s < 1:
            merged[-1][1] = e
        else:
            merged.append([s, e, v])
    for s, e, v in merged:
        print(f"{s + off:5d}..{e + off:5d} ({e - s + 1:4d}px)  rgb{v}")


def write_png(path, w, h, rows):
    raw = b"".join(b"\x00" + bytes(r) for r in rows)

    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    open(path, "wb").write(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw))
        + chunk(b"IEND", b""))


def main(a):
    cmd, img = a[1], load(a[2])
    w, h, bpp, rows = img
    if cmd == "px":
        for p in a[3:]:
            x, y = map(int, p.split(","))
            print(f"({x},{y}) rgb{pix(img, x, y)}")
    elif cmd == "row":
        y = int(a[3])
        x0, x1 = (int(a[4]), int(a[5])) if len(a) > 5 else (0, w - 1)
        runs([pix(img, x, y) for x in range(x0, x1 + 1)], x0)
    elif cmd == "col":
        x = int(a[3])
        y0, y1 = (int(a[4]), int(a[5])) if len(a) > 5 else (0, h - 1)
        runs([pix(img, x, y) for y in range(y0, y1 + 1)], y0)
    elif cmd == "crop":
        x0, y0, x1, y1 = map(int, a[3:7])
        out, z = a[7], int(a[8]) if len(a) > 8 else 1
        o = []
        for y in range(y0, y1):
            line = bytearray()
            for x in range(x0, x1):
                line += bytes(pix(img, x, y)) * z
            for _ in range(z):
                o.append(line)
        write_png(out, (x1 - x0) * z, (y1 - y0) * z, o)
        print(f"wrote {out} {(x1 - x0) * z}x{(y1 - y0) * z}")
    elif cmd == "bbox":
        x0, y0, x1, y1 = map(int, a[3:7])
        tol = int(a[7]) if len(a) > 7 else 24
        cnt = {}
        for y in range(y0, y1):
            for x in range(x0, x1):
                p = pix(img, x, y)
                cnt[p] = cnt.get(p, 0) + 1
        bg = max(cnt, key=cnt.get)
        xs, ys = [], []
        for y in range(y0, y1):
            for x in range(x0, x1):
                p = pix(img, x, y)
                if sum(abs(p[i] - bg[i]) for i in range(3)) > tol:
                    xs.append(x)
                    ys.append(y)
        if xs:
            print(f"bg rgb{bg}  bbox x {min(xs)}..{max(xs)} "
                  f"({max(xs) - min(xs) + 1}px)  y {min(ys)}..{max(ys)} "
                  f"({max(ys) - min(ys) + 1}px)")
        else:
            print(f"bg rgb{bg}  no differing pixels")
    else:
        print(__doc__)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
    else:
        main(sys.argv)
