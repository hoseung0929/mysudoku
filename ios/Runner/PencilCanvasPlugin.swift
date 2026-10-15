import Flutter
import UIKit
import UIKit.UIGestureRecognizerSubclass
import Vision

/// 스도쿠 보드 위에 올라가는 Apple Pencil 필기 오버레이.
///
/// - 보드 전체에 하나의 뷰만 올린다(셀마다 캔버스를 만들지 않는다).
/// - Pencil 터치만 받고 손가락 터치는 그대로 Flutter 보드로 통과시킨다.
/// - 짧은 Pencil 탭은 셀 선택(`tap`), 일정 거리 이상의 획은 필기로 처리한다.
/// - 필기 시작 셀을 대상으로 고정하고 획을 그 셀 안으로 클리핑한다.
/// - 마지막 획 뒤 `settleMillis` 동안 추가 획을 기다린 뒤 기기 안(Vision)에서
///   숫자 1~9를 인식해 `result`로 돌려준다. 원본 획은 저장·전송하지 않는다.
/// 디버그 빌드에서만 남기는 진단 로그(릴리즈에서는 아무것도 하지 않는다).
private func pencilLog(_ format: String, _ args: CVarArg...) {
  #if DEBUG
    withVaList(args) { NSLogv(format, $0) }
  #endif
}

final class PencilCanvasPlugin: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel
  private weak var registrar: FlutterPluginRegistrar?
  private var overlay: PencilStrokeView?
  private var recognizer: PencilGestureRecognizer?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "sudoku159/pencil_canvas",
      binaryMessenger: registrar.messenger()
    )
    let instance = PencilCanvasPlugin(channel: channel, registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private init(channel: FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
    self.channel = channel
    self.registrar = registrar
    super.init()
  }

  private func hostView() -> UIView? {
    if let view = registrar?.viewController?.view { return view }
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for window in windowScene.windows {
        if let vc = window.rootViewController as? FlutterViewController {
          return vc.view
        }
      }
    }
    return nil
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "configure":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "bad_args", message: nil, details: nil))
        return
      }
      configure(args)
      result(nil)
    case "clear":
      overlay?.clearStrokes()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func configure(_ args: [String: Any]) {
    let enabled = args["enabled"] as? Bool ?? false
    pencilLog("[PencilCanvas] configure enabled=%@ rect=(%@,%@,%@,%@) blocked=%d",
          enabled ? "true" : "false",
          "\(args["x"] ?? "?")", "\(args["y"] ?? "?")",
          "\(args["width"] ?? "?")", "\(args["height"] ?? "?")",
          ((args["blocked"] as? [Bool]) ?? []).count)
    guard enabled, let host = hostView() else {
      overlay?.isEnabledForPencil = false
      overlay?.clearStrokes()
      overlay?.isHidden = true
      return
    }
    let x = (args["x"] as? NSNumber)?.doubleValue ?? 0
    let y = (args["y"] as? NSNumber)?.doubleValue ?? 0
    let w = (args["width"] as? NSNumber)?.doubleValue ?? 0
    let h = (args["height"] as? NSNumber)?.doubleValue ?? 0
    guard w > 0, h > 0 else { return }

    let view: PencilStrokeView
    if let existing = overlay {
      view = existing
    } else {
      view = PencilStrokeView()
      view.delegate = self
      overlay = view
    }
    if view.superview !== host {
      host.addSubview(view)
    }
    host.bringSubviewToFront(view)
    // Pencil 터치는 hitTest가 아니라 호스트 뷰의 제스처 인식기로 받는다(Flutter
    // 뷰 구조와 무관하게 Pencil 터치만 가로챈다). 손가락은 영향받지 않는다.
    if recognizer == nil || recognizer?.view !== host {
      if let old = recognizer, let oldView = old.view { oldView.removeGestureRecognizer(old) }
      let gr = PencilGestureRecognizer(overlay: view)
      host.addGestureRecognizer(gr)
      recognizer = gr
      pencilLog("[PencilCanvas] gesture recognizer attached to %@", String(describing: type(of: host)))
    }
    pencilLog("[PencilCanvas] host=%@ window=%@ subviews=%d",
          String(describing: type(of: host)), host.window == nil ? "nil" : "ok",
          host.subviews.count)
    let frame = CGRect(x: x, y: y, width: w, height: h)
    if view.frame != frame {
      // 회전·레이아웃 변경 시 진행 중이던 필기는 취소한다.
      view.clearStrokes()
      view.frame = frame
    }
    view.isHidden = false
    view.blocked = (args["blocked"] as? [Bool]) ?? []
    if let color = (args["strokeColor"] as? NSNumber)?.uint32Value {
      view.strokeColor = UIColor(
        red: CGFloat((color >> 16) & 0xFF) / 255,
        green: CGFloat((color >> 8) & 0xFF) / 255,
        blue: CGFloat(color & 0xFF) / 255,
        alpha: 1
      )
    }
    if let settle = (args["settleMillis"] as? NSNumber)?.doubleValue {
      view.settleInterval = settle / 1000.0
    }
    view.isEnabledForPencil = true
  }
}

extension PencilCanvasPlugin: PencilStrokeViewDelegate {
  fileprivate func strokeView(_ view: PencilStrokeView, send method: String, args: [String: Any]) {
    channel.invokeMethod(method, arguments: args)
  }
}

private protocol PencilStrokeViewDelegate: AnyObject {
  func strokeView(_ view: PencilStrokeView, send method: String, args: [String: Any])
}

/// Pencil 터치만 받는 투명 오버레이 뷰.
private final class PencilStrokeView: UIView {
  weak var delegate: PencilStrokeViewDelegate?

  var isEnabledForPencil = false
  var blocked: [Bool] = []
  var strokeColor: UIColor = UIColor(red: 0.29, green: 0.25, blue: 0.6, alpha: 1)
  var settleInterval: TimeInterval = 0.38

  // 이 거리(pt) 이상 움직이면 탭이 아니라 필기로 본다.
  private let strokeThreshold: CGFloat = 8
  private let lineWidth: CGFloat = 3.2

  private let shapeLayer = CAShapeLayer()

  // 현재 필기(여러 획)
  private var targetRow = -1
  private var targetCol = -1
  private var strokes: [[CGPoint]] = []
  private var current: [CGPoint] = []
  private var isDrawing = false
  private var startPoint = CGPoint.zero
  private var settleTimer: Timer?
  private var gestureStartedBlocked = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isOpaque = false
    isMultipleTouchEnabled = false
    // 터치는 호스트 뷰의 PencilGestureRecognizer가 받아 아래 handle* 메서드로
    // 전달한다(이 뷰는 그리기만 한다).
    isUserInteractionEnabled = false
    shapeLayer.fillColor = nil
    shapeLayer.lineCap = .round
    shapeLayer.lineJoin = .round
    layer.addSublayer(shapeLayer)
    // iPadOS Scribble이 이 영역의 Pencil 터치를 가로채(취소) 획이 사라지지 않도록
    // 이 뷰에서는 시스템 손글씨 인식을 시작하지 않게 한다(iOS 14+).
    if #available(iOS 14.0, *) {
      addInteraction(UIScribbleInteraction(delegate: self))
    }
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  // MARK: - Geometry

  private var cellExtent: CGFloat { bounds.width / 9 }

  private func cell(at point: CGPoint) -> (row: Int, col: Int)? {
    guard bounds.width > 0 else { return nil }
    let col = Int(point.x / cellExtent)
    let row = Int(point.y / cellExtent)
    guard (0..<9).contains(row), (0..<9).contains(col) else { return nil }
    return (row, col)
  }

  private func isBlocked(row: Int, col: Int) -> Bool {
    let index = row * 9 + col
    return index < blocked.count ? blocked[index] : true
  }

  private func cellRect(row: Int, col: Int) -> CGRect {
    CGRect(
      x: CGFloat(col) * cellExtent,
      y: CGFloat(row) * cellExtent,
      width: cellExtent,
      height: cellExtent
    )
  }

  private func clamp(_ p: CGPoint, to rect: CGRect) -> CGPoint {
    CGPoint(
      x: min(max(p.x, rect.minX), rect.maxX),
      y: min(max(p.y, rect.minY), rect.maxY)
    )
  }

  // MARK: - Touches

  func handleBegan(_ touch: UITouch) {
    pencilLog("[PencilCanvas] began type=%ld enabled=%@", touch.type.rawValue,
          isEnabledForPencil ? "true" : "false")
    guard isEnabledForPencil, touch.type == .pencil else { return }
    let point = touch.location(in: self)
    startPoint = point
    isDrawing = false
    current = [point]
    guard let target = cell(at: point) else { return }

    // 대기 중인 필기가 있는데 다른 셀에서 새 획이 시작되면 이전 필기는 취소.
    if !strokes.isEmpty, (target.row != targetRow || target.col != targetCol) {
      cancelPending(notify: true)
    }
    settleTimer?.invalidate()
    settleTimer = nil

    if strokes.isEmpty {
      targetRow = target.row
      targetCol = target.col
    }
    gestureStartedBlocked = isBlocked(row: target.row, col: target.col)
    pencilLog("[PencilCanvas] began cell=(%d,%d) blocked=%@ blockedCount=%d bounds=%@",
          target.row, target.col, gestureStartedBlocked ? "true" : "false",
          blocked.count, NSCoder.string(for: bounds))
  }

  func handleMoved(_ touch: UITouch, event: UIEvent?) {
    guard isEnabledForPencil, touch.type == .pencil else { return }
    let point = touch.location(in: self)

    if !isDrawing {
      let dx = point.x - startPoint.x
      let dy = point.y - startPoint.y
      guard sqrt(dx * dx + dy * dy) >= strokeThreshold else { return }
      // 주어진 숫자·힌트 셀에서는 필기를 시작하지 않는다(탭으로만 처리).
      guard !gestureStartedBlocked, targetRow >= 0 else {
            pencilLog("[PencilCanvas] move ignored blocked=%@ targetRow=%d",
              gestureStartedBlocked ? "true" : "false", targetRow)
            return
      }
      isDrawing = true
        pencilLog("[PencilCanvas] drawing started at cell (%d,%d)", targetRow, targetCol)
        if strokes.isEmpty {
        delegate?.strokeView(
          self, send: "strokeBegan", args: ["row": targetRow, "col": targetCol])
      }
    }

    let rect = cellRect(row: targetRow, col: targetCol)
    let coalesced = event?.coalescedTouches(for: touch) ?? [touch]
    for t in coalesced {
      current.append(clamp(t.location(in: self), to: rect))
    }
    redraw()
  }

  func handleEnded(_ touch: UITouch) {
    guard isEnabledForPencil, touch.type == .pencil else { return }
    if isDrawing {
      strokes.append(current)
      current = []
      isDrawing = false
      redraw()
      delegate?.strokeView(
        self, send: "strokeEnded", args: ["row": targetRow, "col": targetCol])
      scheduleRecognition()
      return
    }
    // 움직임이 임계값을 넘지 않았다: 탭 → 셀 선택.
    let point = touch.location(in: self)
    if let tapped = cell(at: point), strokes.isEmpty {
      delegate?.strokeView(self, send: "tap", args: ["row": tapped.row, "col": tapped.col])
    }
    current = []
  }

  func handleCancelled() {
    pencilLog("[PencilCanvas] cancelled drawing=%@ strokes=%d", isDrawing ? "true" : "false", strokes.count)
    // 시스템이 터치를 취소해도 그리던 획은 버리지 않고 확정한다(획이 갑자기
    // 사라져 보이지 않게).
    if isDrawing, current.count > 1 {
      strokes.append(current)
      current = []
      isDrawing = false
      redraw()
      delegate?.strokeView(
        self, send: "strokeEnded", args: ["row": targetRow, "col": targetCol])
      scheduleRecognition()
      return
    }
    current = []
    isDrawing = false
    if strokes.isEmpty {
      redraw()
    } else {
      scheduleRecognition()
    }
  }

  // MARK: - Drawing

  private func redraw() {
    let path = UIBezierPath()
    for stroke in strokes + (current.isEmpty ? [] : [current]) {
      guard let first = stroke.first else { continue }
      path.move(to: first)
      if stroke.count == 1 {
        path.addLine(to: CGPoint(x: first.x + 0.1, y: first.y))
      }
      for p in stroke.dropFirst() { path.addLine(to: p) }
    }
    // 암시적 애니메이션 없이 즉시 그린다(필기 지연·깜빡임 방지).
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    shapeLayer.frame = bounds
    shapeLayer.strokeColor = strokeColor.cgColor
    shapeLayer.lineWidth = lineWidth
    shapeLayer.path = path.cgPath
    CATransaction.commit()
  }

  func clearStrokes() {
    settleTimer?.invalidate()
    settleTimer = nil
    strokes = []
    current = []
    isDrawing = false
    targetRow = -1
    targetCol = -1
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    shapeLayer.path = nil
    CATransaction.commit()
  }

  private func cancelPending(notify: Bool) {
    clearStrokes()
    if notify { delegate?.strokeView(self, send: "cancelled", args: [:]) }
  }

  // MARK: - Recognition

  private func scheduleRecognition() {
    settleTimer?.invalidate()
    settleTimer = Timer.scheduledTimer(withTimeInterval: settleInterval, repeats: false) {
      [weak self] _ in
      self?.recognize()
    }
  }

  private func recognize() {
    settleTimer = nil
    guard !strokes.isEmpty, targetRow >= 0 else { return }
    let row = targetRow
    let col = targetCol
    let captured = strokes
    let rect = cellRect(row: row, col: col)
    pencilLog("[PencilCanvas] recognize strokes=%d points=%d", captured.count, captured.flatMap { $0 }.count)

    DigitRecognizer.recognize(strokes: captured, in: rect) { [weak self] digit, candidates in
      DispatchQueue.main.async {
        guard let self = self, self.targetRow == row, self.targetCol == col else { return }
            pencilLog("[PencilCanvas] result digit=%@ candidates=%@", "\(digit ?? -1)", "\(candidates)")
            var args: [String: Any] = ["row": row, "col": col, "candidates": candidates]
        if let digit = digit { args["digit"] = digit }
        self.delegate?.strokeView(self, send: "result", args: args)
      }
    }
  }
}

/// 필기 숫자를 1~9로 판별한다(기기 안에서만 처리).
///
/// 획 → 28×28 이미지(MNIST와 같은 규격) → 작은 MLP 분류기(MNIST 학습, 앱에 내장).
/// 확률이 높으면 확정, 애매하면 후보 선택, 낮으면 실패. 애매할 때만 Vision을
/// 보조로 쓴다. 원본 획·이미지는 저장하거나 외부로 전송하지 않는다.
private enum DigitRecognizer {
  private static let clearProbability: Float = 0.80
  private static let ambiguousFloor: Float = 0.30
  private static let candidateFloor: Float = 0.12

  static func recognize(
    strokes: [[CGPoint]],
    in cell: CGRect,
    completion: @escaping (_ digit: Int?, _ candidates: [Int]) -> Void
  ) {
    // 거의 수직인 한 획은 "1"로 먼저 판단한다.
    if let digit = verticalLineDigit(strokes) {
      completion(digit, [])
      return
    }
    guard let input = mnistInput(strokes), let probs = classifier.predict(input) else {
      completion(nil, [])
      return
    }
    // 0은 입력 대상이 아니므로 1~9만 다시 정규화한다.
    let p0 = probs[0]
    var p = Array(probs[1...9])
    let sum = max(p.reduce(0, +), 1e-6)
    p = p.map { $0 / sum }
    let ranked = p.enumerated().map { (digit: $0.offset + 1, prob: $0.element) }
      .sorted { $0.prob > $1.prob }
    pencilLog("[PencilCanvas] mlp %@ p0=%.2f", ranked.prefix(3).map {
      "\($0.digit):" + String(format: "%.2f", $0.prob)
    }.joined(separator: " "), p0)

    guard let best = ranked.first else {
      completion(nil, [])
      return
    }
    if p0 > 0.6 {  // 0처럼 보이면 실패.
      completion(nil, [])
      return
    }
    if best.prob >= clearProbability {
      completion(best.digit, [])
      return
    }
    if best.prob >= ambiguousFloor {
      let near = ranked.filter { $0.prob >= candidateFloor }.prefix(3).map { $0.digit }
      // 후보가 둘 이상일 때만 Vision으로 확정을 시도한다.
      visionFallback(strokes: strokes, allowed: Array(near)) { digit, _ in
        if let digit = digit {
          completion(digit, [])
        } else {
          completion(nil, near.count >= 2 ? Array(near) : [])
        }
      }
      return
    }
    completion(nil, [])
  }

  // MARK: Classifier

  private static let classifier = MLPClassifier()

  private final class MLPClassifier {
    private var w1: [Float] = []
    private var b1: [Float] = []
    private var w2: [Float] = []
    private var b2: [Float] = []

    init() {
      guard let data = Data(base64Encoded: DigitModelData.base64) else { return }
      let bytes = [UInt8](data)
      let n1 = 784 * 128, nb1 = 128, n2 = 128 * 10, nb2 = 10
      guard bytes.count >= n1 + nb1 + n2 + nb2 else { return }
      func slice(_ start: Int, _ count: Int, _ scale: Float) -> [Float] {
        (0..<count).map { Float(Int8(bitPattern: bytes[start + $0])) * scale }
      }
      w1 = slice(0, n1, DigitModelData.w1Scale)
      b1 = slice(n1, nb1, DigitModelData.b1Scale)
      w2 = slice(n1 + nb1, n2, DigitModelData.w2Scale)
      b2 = slice(n1 + nb1 + n2, nb2, DigitModelData.b2Scale)
    }

    func predict(_ x: [Float]) -> [Float]? {
      guard x.count == 784, w1.count == 784 * 128, w2.count == 128 * 10 else { return nil }
      var h = b1
      for i in 0..<784 {
        let xi = x[i]
        if xi == 0 { continue }
        let base = i * 128
        for j in 0..<128 { h[j] += xi * w1[base + j] }
      }
      for j in 0..<128 where h[j] < 0 { h[j] = 0 }
      var o = b2
      for j in 0..<128 {
        let hj = h[j]
        if hj == 0 { continue }
        let base = j * 10
        for k in 0..<10 { o[k] += hj * w2[base + k] }
      }
      let m = o.max() ?? 0
      var e = o.map { expf($0 - m) }
      let total = e.reduce(0, +)
      e = e.map { $0 / max(total, 1e-9) }
      return e
    }
  }

  // MARK: Stroke → 28×28 (MNIST 규격: 20px 상자, 무게중심 맞춤)

  private static func mnistInput(_ strokes: [[CGPoint]]) -> [Float]? {
    let all = strokes.flatMap { $0 }
    guard let minX = all.map({ $0.x }).min(), let maxX = all.map({ $0.x }).max(),
      let minY = all.map({ $0.y }).min(), let maxY = all.map({ $0.y }).max()
    else { return nil }
    let size = max(max(maxX - minX, maxY - minY), 1e-6)
    let big = 112
    let scale = 80.0 / size
    let offX = (CGFloat(big) - (maxX - minX) * scale) / 2
    let offY = (CGFloat(big) - (maxY - minY) * scale) / 2

    guard
      let ctx = CGContext(
        data: nil, width: big, height: big, bitsPerComponent: 8, bytesPerRow: big,
        space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
    else { return nil }
    ctx.setFillColor(gray: 0, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: big, height: big))
    ctx.setStrokeColor(gray: 1, alpha: 1)
    ctx.setLineWidth(8)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setShouldAntialias(true)
    func map(_ p: CGPoint) -> CGPoint {
      CGPoint(x: (p.x - minX) * scale + offX, y: CGFloat(big) - ((p.y - minY) * scale + offY))
    }
    for stroke in strokes {
      guard let first = stroke.first else { continue }
      ctx.beginPath()
      let start = map(first)
      ctx.move(to: start)
      if stroke.count == 1 { ctx.addLine(to: CGPoint(x: start.x + 0.1, y: start.y)) }
      for p in stroke.dropFirst() { ctx.addLine(to: map(p)) }
      ctx.strokePath()
    }
    guard let raw = ctx.data else { return nil }
    let px = raw.bindMemory(to: UInt8.self, capacity: big * big)

    // 4×4 평균으로 28×28.
    var img = [Float](repeating: 0, count: 28 * 28)
    for y in 0..<28 {
      for x in 0..<28 {
        var acc = 0
        for dy in 0..<4 { for dx in 0..<4 { acc += Int(px[(y * 4 + dy) * big + (x * 4 + dx)]) } }
        img[y * 28 + x] = Float(acc) / 16.0 / 255.0
      }
    }
    // 무게중심을 (14,14)로 이동(이중선형).
    var total: Float = 0, cx: Float = 0, cy: Float = 0
    for y in 0..<28 {
      for x in 0..<28 {
        let v = img[y * 28 + x]
        total += v; cx += v * Float(x); cy += v * Float(y)
      }
    }
    guard total > 0 else { return nil }
    cx /= total; cy /= total
    let shiftX = 14 - cx, shiftY = 14 - cy
    var out = [Float](repeating: 0, count: 28 * 28)
    for y in 0..<28 {
      for x in 0..<28 {
        let sx = Float(x) - shiftX, sy = Float(y) - shiftY
        let x0 = Int(floorf(sx)), y0 = Int(floorf(sy))
        let fx = sx - Float(x0), fy = sy - Float(y0)
        func at(_ xx: Int, _ yy: Int) -> Float {
          (0..<28).contains(xx) && (0..<28).contains(yy) ? img[yy * 28 + xx] : 0
        }
        out[y * 28 + x] =
          at(x0, y0) * (1 - fx) * (1 - fy) + at(x0 + 1, y0) * fx * (1 - fy)
          + at(x0, y0 + 1) * (1 - fx) * fy + at(x0 + 1, y0 + 1) * fx * fy
      }
    }
    return out
  }

  private static func verticalLineDigit(_ strokes: [[CGPoint]]) -> Int? {
    guard strokes.count == 1, let stroke = strokes.first, stroke.count >= 4 else { return nil }
    let xs = stroke.map { $0.x }
    let ys = stroke.map { $0.y }
    guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max()
    else { return nil }
    let w = maxX - minX
    let h = maxY - minY
    guard h > 12 else { return nil }
    return (w / h) < 0.22 ? 1 : nil
  }

  // MARK: Vision (애매할 때 보조)

  private static let confusables: [Character: Int] = [
    "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
    "l": 1, "I": 1, "|": 1, "!": 1, "i": 1, "Z": 2, "z": 2, "S": 5, "s": 5,
    "G": 6, "b": 6, "T": 7, "B": 8, "g": 9, "q": 9,
  ]

  private static func visionFallback(
    strokes: [[CGPoint]],
    allowed: [Int],
    completion: @escaping (_ digit: Int?, _ candidates: [Int]) -> Void
  ) {
    guard let image = render(strokes: strokes), let cg = image.cgImage else {
      completion(nil, [])
      return
    }
    let request = VNRecognizeTextRequest { request, _ in
      var scores: [Int: Float] = [:]
      let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
      for observation in observations {
        for candidate in observation.topCandidates(5) {
          let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
          guard text.count == 1, let ch = text.first, let digit = confusables[ch],
            allowed.contains(digit)
          else { continue }
          scores[digit] = max(scores[digit] ?? 0, candidate.confidence)
        }
      }
      let ranked = scores.sorted { $0.value > $1.value }
      pencilLog("[PencilCanvas] vision %@", "\(ranked.map { "\($0.key):\($0.value)" })")
      if let best = ranked.first, best.value >= 0.6 {
        completion(best.key, [])
      } else {
        completion(nil, [])
      }
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    request.customWords = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try VNImageRequestHandler(cgImage: cg, options: [:]).perform([request])
      } catch {
        completion(nil, [])
      }
    }
  }

  private static func render(strokes: [[CGPoint]]) -> UIImage? {
    let all = strokes.flatMap { $0 }
    guard let minX = all.map({ $0.x }).min(), let maxX = all.map({ $0.x }).max(),
      let minY = all.map({ $0.y }).min(), let maxY = all.map({ $0.y }).max()
    else { return nil }
    let w = max(maxX - minX, 1)
    let h = max(maxY - minY, 1)
    let side: CGFloat = 224
    let inner: CGFloat = 128
    let scale = inner / max(w, h)
    let offsetX = (side - w * scale) / 2
    let offsetY = (side - h * scale) / 2
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
    return renderer.image { context in
      UIColor.white.setFill()
      context.fill(CGRect(x: 0, y: 0, width: side, height: side))
      UIColor.black.setStroke()
      let path = UIBezierPath()
      path.lineWidth = 9
      path.lineCapStyle = .round
      path.lineJoinStyle = .round
      for stroke in strokes {
        guard let first = stroke.first else { continue }
        let map: (CGPoint) -> CGPoint = {
          CGPoint(x: ($0.x - minX) * scale + offsetX, y: ($0.y - minY) * scale + offsetY)
        }
        path.move(to: map(first))
        if stroke.count == 1 {
          path.addLine(to: CGPoint(x: map(first).x + 0.1, y: map(first).y))
        }
        for p in stroke.dropFirst() { path.addLine(to: map(p)) }
      }
      path.stroke()
    }
  }
}

@available(iOS 14.0, *)
extension PencilStrokeView: UIScribbleInteractionDelegate {
  func scribbleInteraction(
    _ interaction: UIScribbleInteraction, shouldBeginAt location: CGPoint
  ) -> Bool {
    false
  }
}

/// 호스트(FlutterViewController.view)에 붙어 Pencil 터치만 받는 제스처 인식기.
/// 보드 위(오버레이 영역)에서 시작한 Pencil 터치만 인식하고, 나머지(손가락 및
/// 보드 밖 Pencil)는 즉시 실패해 Flutter로 그대로 전달된다.
private final class PencilGestureRecognizer: UIGestureRecognizer {
  private weak var overlay: PencilStrokeView?
  private var tracked: UITouch?

  init(overlay: PencilStrokeView) {
    self.overlay = overlay
    super.init(target: nil, action: nil)
    allowedTouchTypes = [NSNumber(value: UITouch.TouchType.pencil.rawValue)]
    cancelsTouchesInView = true
    delaysTouchesBegan = true
    delaysTouchesEnded = false
    requiresExclusiveTouchType = false
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    guard tracked == nil, let overlay = overlay, overlay.isEnabledForPencil,
      !overlay.isHidden, let touch = touches.first, touch.type == .pencil
    else {
      state = .failed
      return
    }
    let point = touch.location(in: overlay)
    guard overlay.bounds.contains(point) else {
      state = .failed
      return
    }
    tracked = touch
    state = .began
    overlay.handleBegan(touch)
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let touch = tracked, touches.contains(touch) else { return }
    overlay?.handleMoved(touch, event: event)
    state = .changed
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let touch = tracked, touches.contains(touch) else { return }
    overlay?.handleEnded(touch)
    tracked = nil
    state = .ended
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let touch = tracked, touches.contains(touch) else { return }
    overlay?.handleCancelled()
    tracked = nil
    state = .cancelled
  }

  override func reset() {
    tracked = nil
  }
}
