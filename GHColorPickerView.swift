//
//  GHColorPickerView.swift
//  GHColorPicker
//
//  Created by Mac on 2019/7/15.
//  Copyright © 2019 Mac. All rights reserved.
//

import UIKit

public class GHColorPickerView: UIView {
    
    public var selectedColorCallback: ((_ color: UIColor) -> Void)?
    public var selectedColor: UIColor = .white
    
    public var indicatorRadius: CGFloat = 23
    public var isShowShadow: Bool = true
    
    /// 色盘
    private var colorWheelView: UIView?
    /// 选色指示器
    private var indicatorView: UIView?
    private var selectedEnable = false
    private var selectedEnd = false
    
    /// 色盘直径
    private var dimension: CGFloat {
        return min(self.bounds.width, self.bounds.height)
    }
    /// 色盘半径
    private var radius: CGFloat {
        return dimension * 0.5
    }
    private var factor: Int {
        return 2//Int(UIScreen.main.scale)
    }
    
    private let defaultShadowColor = UIColor.lightGray.cgColor
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override public func layoutSubviews() {
        super.layoutSubviews()
        if colorWheelView == nil {
            colorWheelView = UIView()
            if isShowShadow {
                colorWheelView?.layer.shadowColor = defaultShadowColor
                colorWheelView?.layer.shadowOffset = .zero
                colorWheelView?.layer.shadowOpacity = 0.7
                colorWheelView?.layer.shadowRadius = 20
            }
            addSubview(colorWheelView!)
            colorWheelView!.frame = CGRect(x: (bounds.width-dimension)/2, y: (bounds.height-dimension)/2, width: dimension, height: dimension)
            
            /// 位图渲染生成色盘
            guard let bitmapData = CFDataCreateMutable(nil, 0) else {
                return
            }
            CFDataSetLength(bitmapData, CFIndex(dimension*dimension*CGFloat(factor*factor)))
            self.colorWheelBitmap(CFDataGetMutableBytePtr(bitmapData), CGSize(width: dimension, height: dimension))
            if let image = self.imageWithRGBAData(bitmapData, Int(dimension), Int(dimension)) {
                colorWheelView!.layer.contentsScale = UIScreen.main.scale
                colorWheelView!.layer.contents = image
            }
            
            /// 色盘周围添加白色圆圈
            let circleLayer = CAShapeLayer()
            circleLayer.fillColor = UIColor.clear.cgColor
            circleLayer.lineWidth = 5
            circleLayer.strokeColor = UIColor.white.cgColor
            let bezierPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: dimension, height: dimension), cornerRadius: radius)
            circleLayer.path = bezierPath.cgPath
            colorWheelView!.layer.addSublayer(circleLayer)
            
            /// 色盘添加选中颜色指示图
            let size = CGSize(width: indicatorRadius*2, height: indicatorRadius*2)
            indicatorView = UIView()
            indicatorView?.layer.cornerRadius = size.width/2
            indicatorView?.layer.borderColor = UIColor.white.cgColor
            indicatorView?.layer.borderWidth = 3
            indicatorView?.backgroundColor = .white
            indicatorView?.frame = CGRect(origin: CGPoint.zero, size: size)
            indicatorView?.layer.contentsScale = UIScreen.main.scale
            colorWheelView?.addSubview(indicatorView!)
            indicatorView?.center = CGPoint(x: radius, y: radius)
            
            /// 色盘当前选中指示色
            selectedColorWithRGB(selectedColor)
        }
    }
    override public func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
    }
    
    
    /// 根据RGB值指定相应的颜色选择位置显示
    public func selectedColorWithRGB(_ color: UIColor) {
        selectedColor = color
        indicatorView?.backgroundColor = color
        let point = locatedPointWithRGB()
        indicatorView?.center = point
        var red: CGFloat = 1, green: CGFloat = 1, blue: CGFloat = 1, alpha: CGFloat = 1
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let rgb = RGB(red, green, blue, alpha)
        let hsb = rgb_to_hsb(rgb)
        colorWheelView?.layer.shadowColor = hsb.saturation < 0.2 ? defaultShadowColor : color.cgColor
    }
    
    /// 根据给定的RGB值计算相应的CGPoint
    ///
    /// - Returns: CGPoint
    private func locatedPointWithRGB() -> CGPoint {
        var rgb = RGB(1, 1, 1, 1)
        var red: CGFloat = 1, green: CGFloat = 1, blue: CGFloat = 1, alpha: CGFloat = 1
        if selectedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            rgb = RGB(red, green, blue, alpha)
        }
        let hsb = rgb_to_hsb(rgb)
        let hue = hsb.hue
        let saturation = hsb.saturation
        let angle = hue * CGFloat(2.0*Double.pi)
        let pointX = cos(angle) * (saturation * radius) + radius
        let pointY = sin(angle) * (saturation * radius) + radius
        let point = CGPoint(x: pointX, y: pointY)
        return point
    }
    
    //MARK: - hitTest  indicatorView超出俯视图区域部分有响应
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == nil {
            for subView in subviews {
                if subView == colorWheelView {
                    for subV in subView.subviews {
                        if subV == indicatorView {
                            return subV
                        }
                    }
                }
            }
        }
        return view
    }
    
    //MARK: - touch color picker
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first?.tapCount == 1 {
            if let position: CGPoint = touches.first?.location(in: colorWheelView) {
                if positionIsInColorWheel(position) || touchIndicatorView(position) {
                    selectedEnable = true
                    selectedColorWithPosition(position)
                    
                    
                    let spring = CASpringAnimation(keyPath: "transform")
                    spring.damping = 40;
                    spring.stiffness = 900;
                    spring.mass = 3;
                    spring.initialVelocity = 50;
                    spring.fromValue = CATransform3DMakeScale(1, 1, 1)
                    spring.toValue = CATransform3DMakeScale(1.5, 1.5, 1)
                    spring.fillMode = .forwards
                    spring.isRemovedOnCompletion = false
                    spring.duration = spring.settlingDuration;
                    indicatorView?.layer.add(spring, forKey: spring.keyPath);
                    
                }
            }
        }
    }
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let position: CGPoint = touches.first?.location(in: colorWheelView) {
            if selectedEnable {
                selectedColorWithPosition(position)
            }
        }
    }
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let position: CGPoint = touches.first?.location(in: colorWheelView) {
            if selectedEnable {
                selectedEnd = true
                selectedColorWithPosition(position)
                
                if let temp = self.selectedColorCallback {
                    temp(selectedColor)
                }
                
                let spring = CASpringAnimation(keyPath: "transform")
                spring.damping = 60
                spring.stiffness = 800
                spring.mass = 3
                spring.initialVelocity = 20
                spring.fromValue = CATransform3DMakeScale(1.5, 1.5, 1)
                spring.toValue = CATransform3DMakeScale(1, 1, 1)
                spring.fillMode = .forwards
                spring.isRemovedOnCompletion = false
                spring.duration = spring.settlingDuration;
                indicatorView?.layer.add(spring, forKey: spring.keyPath)
                
            }
        }
        selectedEnable = false
    }
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectedEnable = false
    }
    
    /// 根据位置设置当前颜色
    private func selectedColorWithPosition(_ point: CGPoint) {
        var position = point
        var hue: CGFloat = 0, saturation: CGFloat = 0
        if positionIsInColorWheel(position) {
            indicatorView?.center = CGPoint(x: position.x, y: position.y - 40)//position
            if selectedEnd {
                selectedEnd = false
                UIView.animate(withDuration: 0.1, animations: {
                    self.indicatorView?.center = position
                }) { (isfinished) in
                }
            }
        }else{
            position = edgeIntersectionPoint(position)
            indicatorView?.center = position
            if selectedEnd {
                selectedEnd = false
                indicatorView?.center = position
            }
        }
        colorWheelValueWithPosition(position, &hue, &saturation)
        selectedColor = UIColor(hue: hue, saturation: saturation, brightness: 1.0, alpha: 1)
        indicatorView?.backgroundColor = selectedColor
        colorWheelView?.layer.shadowColor = saturation < 0.2 ? defaultShadowColor : selectedColor.cgColor
    }
    
    /// 判断当前选择的点是否在色盘之内
    private func positionIsInColorWheel(_ point: CGPoint) -> Bool {
        let dx = abs(point.x - radius)
        let dy = abs(point.y - radius)
        let dis = hypot(dx, dy)
        return dis <= radius
    }
    
    /// touch的点在色盘之外 则计算选取与色盘边缘交点
    private func edgeIntersectionPoint(_ position: CGPoint) -> CGPoint {
        let center = CGPoint(x: radius, y: radius)
        
        let mx = center.x - position.x
        let my = center.y - position.y
        let dist = CGFloat(sqrt(mx*mx + my*my))
        
        let pointY = center.y - ((center.y - position.y)/dist * radius)
        let pointX = center.x - ((center.x - position.x)/dist * radius)
        
        let point = CGPoint(x: pointX, y: pointY)
        return point
    }
    
    /// 判断是否触摸在indicatorView之上
    private func touchIndicatorView(_ point: CGPoint) -> Bool {
        if (indicatorView?.frame.contains(point))! {
            return true
        }
        return false
    }
    
    /// shadow闪烁
    public func startShadowFlash() {
        if isShowShadow {
            let animation = CABasicAnimation(keyPath: "shadowOpacity")
            animation.repeatCount = MAXFLOAT
            animation.duration = 0.4
            animation.fromValue = 0.4
            animation.toValue = 0.8
            animation.autoreverses = true
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            colorWheelView?.layer.add(animation, forKey: animation.keyPath)
        }
    }
    
    /// 停止闪烁
    public func stopShadowFlash() {
        colorWheelView?.layer.removeAllAnimations()
    }
    
    deinit {
        indicatorView?.layer.removeAllAnimations()
        //        print("=========== deinit: \(self.classForCoder)")
    }
}


private extension GHColorPickerView {
    
    /// red green blue
    struct RGB {
        var red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat
        init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) {
            self.red = r
            self.green = g
            self.blue = b
            self.alpha = a
        }
    }
    
    /// hue saturation brightness
    struct HSB {
        var hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat
        init(_ h: CGFloat, _ s: CGFloat, _ b: CGFloat, _ a: CGFloat) {
            self.hue = h
            self.saturation = s
            self.brightness = b
            self.alpha = a
        }
    }
    
    /// 位图渲染色盘
    ///
    /// - Parameters:
    ///   - bitmap: bitmap
    ///   - size: 尺寸大小
    func colorWheelBitmap(_ bitmap: UnsafeMutablePointer<UInt8>?, _ size: CGSize) {
        if size.width <= 0 || size.height <= 0 {
            return
        }
        
        for y in 0..<Int(size.width) {
            for x in 0..<Int(size.height) {
                var hue: CGFloat = 0, saturation: CGFloat = 0, alpha: CGFloat = 0.0
                self.colorWheelValueWithPosition(CGPoint(x: x, y: y), &hue, &saturation)
                
                var rgb: RGB = RGB(1, 1, 1, 0)
                
                if saturation < 1.0 {
                    //                    if saturation > 0.99 {
                    //                        alpha = (1.0 - saturation) * 100
                    //                    }else{
                    alpha = 1.0
                    //                    }
                    let hsb: HSB = HSB(hue, saturation, 1.0, alpha)
                    rgb = hsb_to_rgb(hsb)
                }
                
                let i: Int = factor*factor*(x+y*Int(size.width))
                bitmap?[i] = UInt8(rgb.red * 0xff)
                bitmap?[i + 1] = UInt8(rgb.green * 0xff)
                bitmap?[i + 2] = UInt8(rgb.blue * 0xff)
                bitmap?[i + 3] = UInt8(rgb.alpha * 0xff)
            }
        }
    }
    
    /// 指定位置计算hsb值
    ///
    /// - Parameters:
    ///   - position: point位置
    ///   - hue: hue
    ///   - saturation: saturation
    func colorWheelValueWithPosition(_ position: CGPoint, _ hue: inout CGFloat, _ saturation: inout CGFloat) {
        let dx: CGFloat = (position.x - radius)/radius
        let dy: CGFloat = (position.y - radius)/radius
        let d: CGFloat = CGFloat(sqrt(Double(dx*dx + dy*dy)))
        
        saturation = d
        
        if d == 0 {
            hue = 0
        }else{
            hue = acos(dx / d) / CGFloat.pi / 2.0
            if dy < 0 {
                hue = 1.0 - hue
            }
        }
    }
    
    /// 根据bitmap渲染数据 合成图片
    ///
    /// - Parameters:
    ///   - data: bitmap数据
    ///   - width: 宽
    ///   - height: 高
    /// - Returns: CGImage
    func imageWithRGBAData(_ data: CFData, _ width: Int, _ height: Int) -> CGImage? {
        guard let dataProvider = CGDataProvider(data: data) else {
            return nil
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let imageRef = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width*factor*factor, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: dataProvider, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)
        return imageRef
    }
    
    /// HSB转RGB
    func hsb_to_rgb(_ hsb: HSB) -> RGB {
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0
        
        let i: Int = Int(hsb.hue * 6)
        let f = hsb.hue * 6 - CGFloat(i)
        let p = hsb.brightness * (1 - hsb.saturation)
        let q = hsb.brightness * (1 - f * hsb.saturation)
        let t = hsb.brightness * (1 - (1 - f) * hsb.saturation)
        
        switch i % 6 {
        case 0:
            r = hsb.brightness
            g = t
            b = p
        case 1:
            r = q
            g = hsb.brightness
            b = p
        case 2:
            r = p
            g = hsb.brightness
            b = t
        case 3:
            r = p
            g = q
            b = hsb.brightness
        case 4:
            r = t
            g = p
            b = hsb.brightness
        case 5:
            r = hsb.brightness
            g = p
            b = q
        default:
            break
        }
        
        return RGB(r, g, b, hsb.alpha)
    }
    
    /// RGB转HSB
    func rgb_to_hsb(_ rgb: RGB) -> HSB {
        let red = Double(rgb.red)
        let green = Double(rgb.green)
        let blue = Double(rgb.blue)
        let max = fmax(red, fmax(green, blue))
        let min = fmin(red, fmin(green, blue))
        
        var hue = 0.0, brightness = max
        
        let d = max - min
        
        let saturation = max == 0 ? 0 : d/max
        
        if max == min {
            hue = 0
        }else{
            if max == red {
                hue = (green - blue) / d + (green < blue ? 6 : 0)
            }else if max == green {
                hue = (blue - red) / d + 2
            }else if max == blue {
                hue = (red - green) / d + 4
            }
            hue /= 6
        }
        
        return HSB(CGFloat(hue), CGFloat(saturation), CGFloat(brightness), CGFloat(rgb.alpha))
    }
}
