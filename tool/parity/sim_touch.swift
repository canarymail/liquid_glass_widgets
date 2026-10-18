// Injects a real mouse press (the simulator maps it to a touch) onto one of the
// two side-by-side Device Hub / Simulator windows, so touch-and-hold gestures
// can be driven identically on the native SwiftUI reference and the Flutter
// harness.
//
//   swiftc tool/parity/sim_touch.swift -o /tmp/lgw/sim_touch
//   sim_touch <flutter|swift> <deviceX> <deviceY> <holdSeconds> [dx dy]
//   sim_touch <flutter|swift> -s <step>...        (scripted multi-step gesture)
//
// Script steps (device points / milliseconds):
//   m,x,y        move the cursor (no press)
//   d,x,y        touch down at x,y
//   g,x,y,ms     drag (16ms steps, linear) from the current point to x,y over ms
//   w,ms         wait
//   u            touch up at the current point
// e.g. reorder: -s m,60,640 d,60,640 w,600 g,60,700,500 w,300 u
//
// deviceX/deviceY are in iOS points (402x874 for iPhone 18 Pro). The leftmost
// "iPhone" window is treated as Flutter, the rightmost as the Swift reference.
// An optional dx/dy drags the touch to that offset (device points) during the
// final 200ms of the hold. Requires Accessibility permission.
import Cocoa

func windows() -> [(Int, CGRect)] {
  let l = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
  var out: [(Int, CGRect)] = []
  for w in l {
    guard (w[kCGWindowOwnerName as String] as? String) == "Device Hub" ||
          (w[kCGWindowOwnerName as String] as? String) == "Simulator" else { continue }
    guard let name = w[kCGWindowName as String] as? String, name.contains("iPhone") else { continue }
    let b = w[kCGWindowBounds as String] as! [String: Any]
    let r = CGRect(x: b["X"] as! Double, y: b["Y"] as! Double,
                   width: b["Width"] as! Double, height: b["Height"] as! Double)
    out.append((w[kCGWindowNumber as String] as! Int, r))
  }
  return out.sorted { $0.1.minX < $1.1.minX }
}

let a = CommandLine.arguments
let scripted = a.count >= 4 && a[2] == "-s"
guard scripted || a.count >= 5 else {
  print("usage: sim_touch <flutter|swift> x y hold [dx dy]")
  exit(1)
}
let ws = windows()
guard ws.count >= 2 else { print("need two simulator windows, found \(ws.count)"); exit(2) }
let win = (a[1] == "flutter" ? ws.first! : ws.last!).1
let dx = scripted ? 0 : Double(a[2])!, dy = scripted ? 0 : Double(a[3])!
let hold = scripted ? 0 : Double(a[4])!
let ddx = !scripted && a.count > 6 ? Double(a[5])! : 0
let ddy = !scripted && a.count > 6 ? Double(a[6])! : 0

// Device screen geometry inside a window: calibrated on iPhone 18 Pro.
func point(_ x: Double, _ y: Double) -> CGPoint {
  let ox = win.minX + win.width * 0.0775
  let oy = win.minY + 67.0
  let s = win.width * 0.8655 / 402.0
  return CGPoint(x: ox + x * s, y: oy + y * s)
}

// Device Hub only accepts events from the combined session source posted on
// the session tap (HID-state source/tap clicks are ignored).
let src = CGEventSource(stateID: .combinedSessionState)
func post(_ type: CGEventType, _ p: CGPoint) {
  let e = CGEvent(mouseEventSource: src, mouseType: type, mouseCursorPosition: p, mouseButton: .left)!
  e.setIntegerValueField(.mouseEventClickState, value: 1)
  e.setDoubleValueField(.mouseEventPressure, value: type == .leftMouseUp || type == .mouseMoved ? 0.0 : 1.0)
  e.post(tap: .cgSessionEventTap)
}

if scripted {
  var cur = (x: 0.0, y: 0.0)
  var down = false
  for tok in a[3...] {
    let f = tok.split(separator: ",").map(String.init)
    switch f[0] {
    case "m":
      cur = (Double(f[1])!, Double(f[2])!)
      post(.mouseMoved, point(cur.x, cur.y))
    case "d":
      cur = (Double(f[1])!, Double(f[2])!)
      post(.leftMouseDown, point(cur.x, cur.y)); down = true
    case "g":
      let tx = Double(f[1])!, ty = Double(f[2])!, ms = Double(f[3])!
      let n = max(1, Int(ms / 16.0))
      for i in 1...n {
        let t = Double(i) / Double(n)
        let p = point(cur.x + (tx - cur.x) * t, cur.y + (ty - cur.y) * t)
        post(down ? .leftMouseDragged : .mouseMoved, p)
        usleep(16_000)
      }
      cur = (tx, ty)
    case "w":
      usleep(UInt32(Double(f[1])! * 1000))
    case "u":
      post(.leftMouseUp, point(cur.x, cur.y)); down = false
    default: break
    }
  }
  exit(0)
}

let p0 = point(dx, dy)
post(.mouseMoved, p0)
usleep(150_000)
post(.leftMouseDown, p0)
if ddx != 0 || ddy != 0 {
  usleep(UInt32(max(0, hold - 0.2) * 1_000_000))
  let steps = 10
  for i in 1...steps {
    let f = Double(i) / Double(steps)
    post(.leftMouseDragged, point(dx + ddx * f, dy + ddy * f))
    usleep(20_000)
  }
} else {
  usleep(UInt32(hold * 1_000_000))
}
post(.leftMouseUp, point(dx + ddx, dy + ddy))
