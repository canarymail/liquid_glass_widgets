// Builds a labelled contact sheet from a simulator recording so two runs
// (SwiftUI reference vs Flutter) can be compared frame by frame.
//
//   video_sheet <video.mov> <outPrefix> <t0> <t1> <count> <cols> [cropY0 cropY1 thumbW]
//
// cropY0/cropY1 are fractions (0-1) of the frame height to keep.
import AVFoundation
import AppKit

let a = CommandLine.arguments
guard a.count >= 7 else { print("usage: video_sheet video out t0 t1 count cols [y0 y1 thumbW]"); exit(1) }
let asset = AVAsset(url: URL(fileURLWithPath: a[1]))
let t0 = Double(a[3])!, t1 = Double(a[4])!, n = Int(a[5])!, cols = Int(a[6])!
let y0 = a.count > 7 ? Double(a[7])! : 0, y1 = a.count > 8 ? Double(a[8])! : 1
let tw = a.count > 9 ? Double(a[9])! : 260
let gen = AVAssetImageGenerator(asset: asset)
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = .zero
gen.appliesPreferredTrackTransform = true

var imgs: [(Double, CGImage)] = []
for i in 0..<n {
  let t = n == 1 ? t0 : t0 + (t1 - t0) * Double(i) / Double(n - 1)
  if let cg = try? gen.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) {
    let h = Double(cg.height)
    let r = CGRect(x: 0, y: h * y0, width: Double(cg.width), height: h * (y1 - y0))
    imgs.append((t, cg.cropping(to: r) ?? cg))
  }
}
guard let first = imgs.first else { print("no frames"); exit(2) }
let th = tw * Double(first.1.height) / Double(first.1.width)
let rows = (imgs.count + cols - 1) / cols
let W = Int(tw) * cols, H = Int(th + 18) * rows
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.setFillColor(CGColor(gray: 0.15, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
for (i, (t, img)) in imgs.enumerated() {
  let c = i % cols, r = i / cols
  let x = Double(c) * tw, y = Double(H) - Double(r + 1) * (th + 18)
  ctx.draw(img, in: CGRect(x: x, y: y, width: tw, height: th))
  let s = NSString(string: String(format: "%.2fs", t))
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
  s.draw(at: NSPoint(x: x + 4, y: y + th + 2), withAttributes: [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.white])
  NSGraphicsContext.restoreGraphicsState()
}
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[2]))
print("wrote \(a[2]) \(imgs.count) frames")
