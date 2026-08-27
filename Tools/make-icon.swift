import AppKit

// Generates the OnAir AppIcon set: a radio-waves glyph on a red squircle.

let outDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath

func tinted(_ image: NSImage, _ color: NSColor) -> NSImage {
    let out = NSImage(size: image.size)
    out.lockFocus()
    color.set()
    let r = NSRect(origin: .zero, size: image.size)
    image.draw(in: r)
    r.fill(using: .sourceAtop)
    out.unlockFocus()
    return out
}

func makeIcon(pixels px: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: px, height: px)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let f = CGFloat(px)
    let inset = f * 0.06
    let rect = NSRect(x: inset, y: inset, width: f - 2 * inset, height: f - 2 * inset)
    let radius = rect.width * 0.2237

    let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    squircle.addClip()

    let gradient = NSGradient(colorsAndLocations:
        (NSColor(srgbRed: 0.91, green: 0.28, blue: 0.21, alpha: 1), 0.0),
        (NSColor(srgbRed: 0.78, green: 0.19, blue: 0.14, alpha: 1), 0.45),
        (NSColor(srgbRed: 0.44, green: 0.08, blue: 0.05, alpha: 1), 1.0)
    )!
    gradient.draw(in: rect, angle: -90)

    let ptSize = f * 0.52
    let cfg = NSImage.SymbolConfiguration(pointSize: ptSize, weight: .semibold)
    if let base = NSImage(systemSymbolName: "dot.radiowaves.left.and.right", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {
        let glyph = tinted(base, .white)
        let s = glyph.size
        glyph.draw(in: NSRect(x: (f - s.width) / 2, y: (f - s.height) / 2, width: s.width, height: s.height))
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let variants: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for v in variants {
    let url = URL(fileURLWithPath: outDir).appendingPathComponent("\(v.name).png")
    try! makeIcon(pixels: v.px).write(to: url)
    print("wrote \(url.lastPathComponent) (\(v.px)px)")
}
