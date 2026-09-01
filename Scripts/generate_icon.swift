#!/usr/bin/env swift
//
// Generates Scripts/icon-source/app_icon_1024.png — an original icon (not the
// Khronos glTF logo, which is a trademark meant to signal format compatibility, not something
// a third-party viewer should adopt as its own launcher icon).
//
// Motif: an isometric wireframe cube with vertex nodes (a "mesh"), inside a faint orbit ring,
// on a dark viewport-style gradient — nods to both "3D model" and the orbit camera controls.
// Run with: swift Scripts/generate_icon.swift
// Then: Scripts/render_icon_sizes.sh Scripts/icon-source/app_icon_1024.png App/Assets.xcassets/AppIcon.appiconset

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

let rect = CGRect(x: 0, y: 0, width: size, height: size)

// macOS Big Sur-style squircle background.
let cornerRadius = size * 0.2237
let bgPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
ctx.addPath(bgPath)
ctx.clip()

let colors = [
    CGColor(red: 0.09, green: 0.11, blue: 0.24, alpha: 1),
    CGColor(red: 0.05, green: 0.32, blue: 0.36, alpha: 1),
    CGColor(red: 0.06, green: 0.55, blue: 0.52, alpha: 1)
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)
ctx.resetClip()

let center = CGPoint(x: size / 2, y: size / 2 - size * 0.02)

// Faint orbit ring, suggesting the camera-orbit interaction.
ctx.saveGState()
ctx.translateBy(x: center.x, y: center.y)
ctx.rotate(by: -0.18)
let ring = CGRect(x: -size * 0.37, y: -size * 0.15, width: size * 0.74, height: size * 0.30)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.28))
ctx.setLineWidth(size * 0.012)
ctx.strokeEllipse(in: ring)
ctx.restoreGState()

// Isometric cube.
let r = size * 0.225
func iso(_ dx: Double, _ dy: Double, _ dz: Double) -> CGPoint {
    // Standard isometric basis vectors for the three cube axes.
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

fill(top, CGColor(red: 1, green: 1, blue: 1, alpha: 0.92))
fill(left, CGColor(red: 1, green: 1, blue: 1, alpha: 0.55))
fill(right, CGColor(red: 1, green: 1, blue: 1, alpha: 0.74))

ctx.setStrokeColor(CGColor(red: 0.05, green: 0.10, blue: 0.14, alpha: 0.9))
ctx.setLineWidth(size * 0.008)
ctx.setLineJoin(.round)
for face in [top, left, right] {
    ctx.beginPath()
    ctx.move(to: face[0])
    for p in face.dropFirst() { ctx.addLine(to: p) }
    ctx.closePath()
    ctx.strokePath()
}

// Vertex nodes at the 7 visible cube corners, echoing "mesh vertices."
let vertices = [
    iso(-1, 1, -1), iso(1, 1, -1), iso(1, 1, 1), iso(-1, 1, 1),
    iso(-1, -1, -1), iso(-1, -1, 1), iso(1, -1, 1)
]
let nodeRadius = size * 0.019
for v in vertices {
    let dot = CGRect(x: v.x - nodeRadius, y: v.y - nodeRadius, width: nodeRadius * 2, height: nodeRadius * 2)
    ctx.setFillColor(CGColor(red: 1, green: 0.65, blue: 0.25, alpha: 1))
    ctx.fillEllipse(in: dot)
    ctx.setStrokeColor(CGColor(red: 0.05, green: 0.10, blue: 0.14, alpha: 0.9))
    ctx.setLineWidth(size * 0.004)
    ctx.strokeEllipse(in: dot)
}

NSGraphicsContext.restoreGraphicsState()

let outputPath = "Scripts/icon-source/app_icon_1024.png"
guard let data = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}
try! data.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
