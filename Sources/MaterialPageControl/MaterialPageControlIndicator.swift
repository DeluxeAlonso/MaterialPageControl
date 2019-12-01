//
//  MaterialPageControlIndicator.swift
//  
//
//  Created by Alonso on 12/1/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import UIKit
import QuartzCore

public class MaterialPageControlIndicator: CAShapeLayer {
  
  private let kPageControlIndicatorAnimationDuration = 0.3;
  private let kPageControlIndicatorAnimationKey = "fadeInScaleUp"
  
  var color: UIColor? {
    didSet {
      guard let color = color else { return }
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      let cgColor = color.cgColor
      fillColor = cgColor
      self.opacity = 1
      CATransaction.commit()
    }
  }
  var isAnimating: Bool = false
  
  init(center: CGPoint, radius: CGFloat) {
    super.init()
    frame = .init(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    path = circlePath(with: radius)
    zPosition = 1
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
  
  // MARK: - Private
  
  private func circlePath(with radius: CGFloat) -> CGPath? {
    return UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2), cornerRadius: radius).cgPath
  }
  
  // MARK: - Public
  
  func revealIndicator() {
    // Scale indicator from zero to full size while fading in.
    let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
    scaleAnimation.fromValue = NSValue(caTransform3D: CATransform3DMakeScale(0.0, 0.0, 0.0))
    scaleAnimation.toValue = NSValue(caTransform3D: CATransform3DIdentity)
    
    let fadeAnimation = CABasicAnimation(keyPath: "opacity")
    fadeAnimation.fromValue = NSNumber(value: 0)
    fadeAnimation.toValue = NSNumber(value: opacity)
    
    let group = CAAnimationGroup()
    group.duration = kPageControlIndicatorAnimationDuration
    group.fillMode = .forwards
    group.isRemovedOnCompletion = true
    group.animations = [scaleAnimation, fadeAnimation]
    add(group, forKey: kPageControlIndicatorAnimationKey)
    
    isHidden = false
  }
  
  func updateIndicatorTransformX(_ transformX: CGFloat, animated: Bool, duration: TimeInterval, mediaTimingFunction timingFunction: CAMediaTimingFunction?) {
    CATransaction.begin()
    CATransaction.setDisableActions(!animated)
    CATransaction.setAnimationDuration(CFTimeInterval(duration))
    CATransaction.setAnimationTimingFunction(timingFunction)
    transform = CATransform3DMakeTranslation(transformX, 0, 0)
    CATransaction.commit()
  }
  
  func updateIndicatorTransformX(_ transformX: CGFloat) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    transform = CATransform3DMakeTranslation(transformX, 0, 0)
    CATransaction.commit()
  }
}
