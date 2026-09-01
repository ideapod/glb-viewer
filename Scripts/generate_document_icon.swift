#!/usr/bin/env swift
//
// Generates Scripts/icon-source/document_icon_1024.png — the fallback file
// icon macOS shows for .glb files in list/column view, in "Get Info", and anywhere else
// Quick Look's live-rendered thumbnail (see ThumbnailExtension) isn't in play. Follows the
// standard macOS document-icon convention: a page silhouette with a folded corner, carrying
// a smaller version of the app's cube glyph.
//
// Run with: swift Scripts/generate_document_icon.swift
// Then: Scripts/render_icon_sizes.sh Scripts/icon-source/document_icon_1024.png App/Assets.xcassets/DocumentIcon.appiconset

import AppKit
import CoreGraphics

let size = 1024.0
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size),
    pixelsHigh: Int(size),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// Page silhouette with a folded top-right corner.
let leftX = size * 0.19, rightX = size * 0.81
let bottomY = size * 0.11, topY = size * 0.89
let fold = size * 0.15

let pagePath = CGMutablePath()
pagePath.move(to: CGPoint(x: leftX, y: bottomY))
pagePath.addLine(to: CGPoint(x: rightX, y: bottomY))
pagePath.addLine(to: CGPoint(x: rightX, y: topY - fold))
pagePath.addLine(to: CGPoint(x: rightX - fold, y: topY))
pagePath.addLine(to: CGPoint(x: leftX, y: topY))
pagePath.closeSubpath()

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.012), blur: size * 0.03, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
ctx.setFillColor(CGColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1))
ctx.addPath(pagePath)
ctx.fillPath()
ctx.restoreGState()

ctx.setStrokeColor(CGColor(red: 0.72, green: 0.75, blue: 0.78, alpha: 1))
ctx.setLineWidth(size * 0.004)
ctx.addPath(pagePath)
ctx.strokePath()

// The folded corner itself, shaded to read as turned-over paper.
let foldPath = CGMutablePath()
foldPath.move(to: CGPoint(x: rightX - fold, y: topY))
foldPath.addLine(to: CGPoint(x: rightX, y: topY - fold))
foldPath.addLine(to: CGPoint(x: rightX - fold, y: topY - fold))
foldPath.closeSubpath()
ctx.setFillColor(CGColor(red: 0.83, green: 0.86, blue: 0.88, alpha: 1))
ctx.addPath(foldPath)
ctx.fillPath()
ctx.setStrokeColor(CGColor(red: 0.72, green: 0.75, blue: 0.78, alpha: 1))
ctx.addPath(foldPath)
ctx.strokePath()

// A smaller version of the app's isometric-cube glyph, panel-tinted rather than white so it
// reads on the light page background.
let center = CGPoint(x: size / 2, y: size * 0.42)
let r = size * 0.155

func iso(_ dx: Double, _ dy: Double, _ dz: Double) -> CGPoint {
    let x = center.x + (dx - dz) * (r * 0.866)
    let y = center.y + (dx + dz) * (r * 0.5) - dy * r
    return CGPoint(x: x, y: y)
}

let top = [iso(-1, 1, -1), iso(1, 1, -1), iso(1, 1, 1), iso(-1, 1, 1)]
let left = [iso(-1, 1, 1), iso(-1, 1, -1), iso(-1, -1, -1), iso(-1, -1, 1)]
let right = [iso(1, 1, 1), iso(1, 1, -1), iso(1, -1, -1), iso(1, -1, 1)]

func fill(_ pts: [CGPoint], _ color: CGColor) {
    ctx.setFillColor(color)
    ctx.beginPath()
    ctx.move(to: pts[0])
    for p in pts.dropFirst() { ctx.addLine(to: p) }
    ctx.closePath()
    ctx.fillPath()
}

fill(top, CGColor(red: 0.10, green: 0.42, blue: 0.46, alpha: 1))
fill(left, CGColor(red: 0.08, green: 0.24, blue: 0.34, alpha: 1))
fill(right, CGColor(red: 0.09, green: 0.33, blue: 0.40, alpha: 1))

ctx.setStrokeColor(CGColor(red: 0.05, green: 0.10, blue: 0.14, alpha: 0.9))
ctx.setLineWidth(size * 0.006)
ctx.setLineJoin(.round)
for face in [top, left, right] {
    ctx.beginPath()
    ctx.move(to: face[0])
    for p in face.dropFirst() { ctx.addLine(to: p) }
    ctx.closePath()
    ctx.strokePath()
}

let vertices = [
    iso(-1, 1, -1), iso(1, 1, -1), iso(1, 1, 1), iso(-1, 1, 1),
    iso(-1, -1, -1), iso(-1, -1, 1), iso(1, -1, 1)
]
let nodeRadius = size * 0.014
for v in vertices {
    let dot = CGRect(x: v.x - nodeRadius, y: v.y - nodeRadius, width: nodeRadius * 2, height: nodeRadius * 2)
    ctx.setFillColor(CGColor(red: 1, green: 0.65, blue: 0.25, alpha: 1))
    ctx.fillEllipse(in: dot)
    ctx.setStrokeColor(CGColor(red: 0.05, green: 0.10, blue: 0.14, alpha: 0.9))
    ctx.setLineWidth(size * 0.003)
    ctx.strokeEllipse(in: dot)
}

// ".glb" label near the bottom of the page.
let label = "GLB" as NSString
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: size * 0.075, weight: .bold),
    .foregroundColor: NSColor(red: 0.35, green: 0.39, blue: 0.42, alpha: 1),
    .paragraphStyle: paragraph
]
NSGraphicsContext.current?.cgContext.saveGState()
NSGraphicsContext.current?.saveGraphicsState()
label.draw(
    in: CGRect(x: leftX, y: size * 0.18, width: rightX - leftX, height: size * 0.1),
    withAttributes: attrs
)
NSGraphicsContext.current?.restoreGraphicsState()

NSGraphicsContext.restoreGraphicsState()

let outputPath = "Scripts/icon-source/document_icon_1024.png"
guard let data = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}
try! data.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
