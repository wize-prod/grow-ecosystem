import AppKit

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    exit(1)
}

// 1. Deep Matte Midnight Navy Background
let bgRect = CGRect(origin: .zero, size: size)
let darkNavy = CGColor(red: 10/255.0, green: 18/255.0, blue: 36/255.0, alpha: 1.0)
let midNavy = CGColor(red: 16/255.0, green: 30/255.0, blue: 58/255.0, alpha: 1.0)

let colors = [midNavy, darkNavy] as CFArray
let colorSpace = CGColorSpaceCreateDeviceRGB()
if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(gradient, startCenter: CGPoint(x: 512, y: 512), startRadius: 0, endCenter: CGPoint(x: 512, y: 512), endRadius: 650, options: [])
} else {
    ctx.setFillColor(darkNavy)
    ctx.fill(bgRect)
}

// 2. Minimalist Banking Glyph (Targobank / High-End Fintech aesthetic)
ctx.saveGState()

let white = CGColor(red: 248/255.0, green: 250/255.0, blue: 252/255.0, alpha: 1.0)
let subtleTeal = CGColor(red: 56/255.0, green: 189/255.0, blue: 248/255.0, alpha: 0.9)

// Upward growth / vault arch
let path = CGMutablePath()
path.move(to: CGPoint(x: 290, y: 440))
path.addLine(to: CGPoint(x: 512, y: 690))
path.addLine(to: CGPoint(x: 734, y: 440))

ctx.setStrokeColor(white)
ctx.setLineWidth(44)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.addPath(path)
ctx.strokePath()

// Lower solid balance bar
let barPath = CGMutablePath()
barPath.move(to: CGPoint(x: 350, y: 340))
barPath.addLine(to: CGPoint(x: 674, y: 340))

ctx.setStrokeColor(subtleTeal)
ctx.setLineWidth(32)
ctx.setLineCap(.round)
ctx.addPath(barPath)
ctx.strokePath()

// Minimalist central anchor dot
let dotRect = CGRect(x: 512 - 18, y: 510 - 18, width: 36, height: 36)
ctx.setFillColor(white)
ctx.fillEllipse(in: dotRect)

ctx.restoreGState()

image.unlockFocus()

if let tiff = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiff),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    let targetURL = URL(fileURLWithPath: "GrowFinance/GrowFinance/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    try? pngData.write(to: targetURL)
    print("Icon successfully written to \(targetURL.path)")
}
