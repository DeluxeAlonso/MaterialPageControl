//
//  MaterialPageControlTrackLayer.swift
//  
//
//  Created by Alonso on 12/1/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import UIKit
import QuartzCore

class MaterialPageControlTrackLayer: CAShapeLayer {

    let pageControlKeyframeCount = 2

    private var radius: CGFloat = 3.5

    var trackColor: UIColor? {
        didSet {
            guard let trackColor = trackColor else { return }
            fillColor = trackColor.cgColor
            backgroundColor = trackColor.cgColor
        }
    }

    var trackHidden: Bool = true
    var isAnimating: Bool = false

    var startPoint: CGPoint! = .zero
    var midPoint: CGPoint!
    var endPoint: CGPoint!

    // MARK: - Initializers

    override init(layer: Any) {
        super.init(layer: layer)
        self.cornerRadius = radius
    }

    override init() {
        super.init()
        self.cornerRadius = radius
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(radius: CGFloat) {
        self.radius = radius
        super.init()
        self.cornerRadius = radius
    }

    // MARK: - Private

    private func isPointZero(_ point: CGPoint) -> Bool {
        return point == CGPoint.zero
    }

    private func degreesToRadians(degrees: CGFloat) -> CGFloat {
        return degrees * .pi / 180.0
    }

    func pointOnCircle(withRadius radius: CGFloat, angleInDegrees: CGFloat, origin: CGPoint) -> CGPoint {
        // Returns a point along a circles edge at given angle.
        let locationX = (radius * cos(degreesToRadians(degrees: angleInDegrees))) + origin.x
        let locationY = (radius * sin(degreesToRadians(degrees: angleInDegrees))) + origin.y
        return CGPoint(x: locationX, y: locationY)
    }

    private func resetTrackFrame() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.frame = .zero
        CATransaction.commit()
    }

    private func resetHidden(_ hidden: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.isHidden = hidden
        CATransaction.commit()
    }

    private func midPoint(from startPoint: CGPoint, to endPoint: CGPoint) -> CGPoint {
        return CGPoint(x: (startPoint.x + endPoint.x) / 2 , y: (startPoint.y + endPoint.y) / 2)
    }

    private func updateTrackFrame(animated: Bool, completion: (() -> Void)?) {
        resetHidden(false)
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        CATransaction.setCompletionBlock({
            completion?()
        })
        self.frame = CGRect(x: startPoint.x - radius,
                            y: startPoint.y - radius,
                            width: endPoint.x - startPoint.x + (radius * 2),
                            height: radius * 2)
        CATransaction.commit()
    }

    private func addRoundedEndpoint(to bezierPath: UIBezierPath, at point: CGPoint) {
        bezierPath.move(to: .init(x: point.x, y: radius * 2))
        bezierPath.addArc(withCenter: point, radius: radius, startAngle: 0, endAngle: degreesToRadians(degrees: 360), clockwise: true)
    }

    private func path(at keyframe: Int) -> CGPath {
        let r = radius
        let d = radius * 2.0

        let bezierPath = UIBezierPath()

        if keyframe == 0 {
            // Create circles at start and end points.
            addRoundedEndpoint(to: bezierPath, at: startPoint)
            addRoundedEndpoint(to: bezierPath, at: endPoint)

            // Create an arc from top of startpoint circle to midpoint.
            bezierPath.move(to: pointOnCircle(withRadius: r, angleInDegrees: 300, origin: startPoint))
            bezierPath.addQuadCurve(to: midPoint, controlPoint: CGPoint(x: midPoint.x - r / 2, y: r))

            // Create an arc from midpoint to top of endpoint circle.
            bezierPath.addQuadCurve(to: pointOnCircle(withRadius: r, angleInDegrees: 240, origin: endPoint), controlPoint: CGPoint(x: midPoint.x + r / 2, y: r))

            // Create a line from top of endpoint circle to bottom of endpoint circle.
            bezierPath.addLine(to: pointOnCircle(withRadius: r, angleInDegrees: 120, origin: endPoint))

            bezierPath.addQuadCurve(to: midPoint, controlPoint: .init(x: midPoint.x + r / 2, y: r))

            bezierPath.addQuadCurve(to: pointOnCircle(withRadius: r,
                                                      angleInDegrees: 60, origin: startPoint),
                                    controlPoint: .init(x: midPoint.x - r / 2, y: r))

            bezierPath.addLine(to: pointOnCircle(withRadius: r, angleInDegrees: 300, origin: startPoint))

            bezierPath.close()
        } else if keyframe == 1 {
            addRoundedEndpoint(to: bezierPath, at: startPoint)
            addRoundedEndpoint(to: bezierPath, at: endPoint)
            bezierPath.move(to: CGPoint(x: startPoint.x, y: 0))
            bezierPath.addLine(to: CGPoint(x: midPoint.x, y: 0))
            bezierPath.addLine(to: CGPoint(x: endPoint.x, y: 0))
            bezierPath.addLine(to: CGPoint(x: endPoint.x, y: d))
            bezierPath.addLine(to: CGPoint(x: midPoint.x, y: d))
            bezierPath.addLine(to: CGPoint(x: startPoint.x, y: d))
            bezierPath.close()
        }
        return bezierPath.cgPath
    }

    private func reset() {
        // Reset track frame without implicit animation.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        removeAllAnimations()
        isAnimating = false
        trackHidden = true
        resetHidden(true)
        CATransaction.commit()
    }

    // MARK: - Internal

    func drawTrack(from startPoint: CGPoint, to endPoint: CGPoint) {
        if isAnimating || !trackHidden || isPointZero(startPoint) || isPointZero(endPoint) {
            return
        }

        resetTrackFrame()
        isAnimating = true

        self.startPoint = startPoint
        self.endPoint = endPoint
        self.midPoint = midPoint(from: startPoint, to: endPoint)

        resetHidden(false)

        CATransaction.begin()
        CATransaction.setCompletionBlock({
            self.removeAnimation(forKey: "drawTrack")
            self.updateTrackFrame(animated: false, completion: nil)
            self.trackHidden = false
            self.isAnimating = false
        })

        var values: [CGPath] = []
        for i in 0..<pageControlKeyframeCount {
            values.append(path(at: i))
        }

        let animation = CAKeyframeAnimation(keyPath: "path")
        animation.duration = 0.2
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.values = values
        add(animation, forKey: "drawTrack")
        CATransaction.commit()
    }

    func removeTrackTowardsPoint(_ point: CGPoint, completion: @escaping () -> Void) {
        // Animate the track removal towards a single point.
        startPoint = point
        endPoint = point
        updateTrackFrame(animated: true) {
            self.reset()
            completion()
        }
    }

    func reset(at point: CGPoint) {
        // Resets the track at single point without animation.
        startPoint = point
        endPoint = point
        updateTrackFrame(animated: false) {
            self.reset()
        }
    }

    func drawAndExtendTrack(fromStart startPoint: CGPoint, toEnd endPoint: CGPoint, completion: (() -> Void)?) {
        trackHidden = false
        if isPointZero(self.startPoint) {
            self.startPoint = startPoint
            self.endPoint = endPoint
            updateTrackFrame(animated: false) {
                self.updateTrackFrame(animated: true) {
                    if completion != nil {
                        completion?()
                    }
                }
            }
        } else {
            self.startPoint = startPoint
            self.endPoint = endPoint
            updateTrackFrame(animated: true) {
                if completion != nil {
                    completion?()
                }
            }
        }
    }

    func extendTrack(fromStart startPoint: CGPoint, toEnd endPoint: CGPoint) {
        if trackHidden || isPointZero(startPoint) || isPointZero(endPoint) {
            return
        }

        // Extend track to encompass minimum startPoint and maximum endPoint.
        self.startPoint = (startPoint.x < self.startPoint.x) ? startPoint : self.startPoint
        self.endPoint = (endPoint.x > self.endPoint.x) ? endPoint : self.endPoint

        updateTrackFrame(animated: true, completion: nil)
    }
    
}
