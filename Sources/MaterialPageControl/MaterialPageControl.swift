//
//  MaterialPageControl.swift
//
//
//  Created by Alonso on 12/1/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import UIKit

public class MaterialPageControl: UIControl {
    
    private static let materialPageControlBundle = "MaterialPageControl.bundle"
    
    /// The keypath for the content offset of a scrollview.
    private static let materialPageControlScrollViewContentOffset = "bounds.origin"
    
    /// Matches native UIPageControl minimum height.
    private static let pageControlMinimumHeight: CGFloat = 48
    
    /// Delay for revealing indicators staggered towards current page indicator.
    private static let pageControlIndicatorShowDelay: TimeInterval = 0.04
    
    /// Default indicator opacity.
    private static let pageControlIndicatorDefaultOpacity = CGFloat(0.5)
    
    /// Default white level for current page indicator color.
    private static let pageControlCurrentPageIndicatorWhiteColor = CGFloat(0.38)
    
    /// Default white level for page indicator color.
    private static let pageControlPageIndicatorWhiteColor = CGFloat(0.62)
    
    public var currentPage: Int = 0
    public var defersCurrentPageDisplay: Bool = false
    public var respectsUserInterfaceLayoutDirection: Bool = false
    
    public var numberOfPages: Int = 0 {
        didSet {
            resetControl()
        }
    }
    
    public var pageIndicatorTintColor: UIColor = .red {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var currentPageIndicatorTintColor: UIColor = .black {
        didSet {
            setNeedsLayout()
        }
    }

    public var pageIndicatorRadius: CGFloat = 3.5 {
        didSet {
            updateContainerView(with: pageIndicatorRadius)
        }
    }

    private var pageIndicatorMargin: CGFloat {
        return pageIndicatorRadius * 2.5
    }
    
    private static func normalizeValue(_ value: CGFloat, _ minRange: CGFloat, _ maxRange: CGFloat) -> CGFloat {
        let diff = maxRange - minRange
        return (diff > 0) ? ((value - minRange) / diff) : 0
    }
    
    private var containerView: UIView!
    private var containerFrame: CGRect!
    private var indicators: [MaterialPageControlIndicator] = []
    private var indicatorPositions: [NSValue] = []
    private var animatedIndicator: MaterialPageControlIndicator!
    private var trackLayer: MaterialPageControlTrackLayer!
    private var trackLength: CGFloat = 0.0
    private var isDeferredScrolling = false

    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPageControl()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPageControl()
    }

    // MARK: - Lifecycle

    override open func layoutSubviews() {
        super.layoutSubviews()
        if numberOfPages == 0 {
            isHidden = true
            return
        }
        isHidden = false

        for pageNumber in 0..<indicators.count {
            let indicator = indicators[pageNumber]
            if pageNumber == Int(currentPage) {
                indicator.isHidden = true
            }
            indicator.color = pageIndicatorTintColor
        }
        animatedIndicator.color = currentPageIndicatorTintColor
        trackLayer.trackColor = pageIndicatorTintColor
    }

    // MARK: - Private

    private func setupPageControl() {
        let radius = pageIndicatorRadius
        let topEdge = CGFloat(floor(bounds.height - (radius * 2)) / 2)
        containerFrame = CGRect(x: 0, y: topEdge, width: bounds.width, height: radius * 2)
        containerView = UIView(frame: containerFrame)
        
        trackLayer = MaterialPageControlTrackLayer(radius: radius)
        containerView.layer.addSublayer(trackLayer)
        containerView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        addSubview(containerView)
        
        // Default values
        currentPage = 0
        currentPageIndicatorTintColor = UIColor(white: MaterialPageControl.pageControlCurrentPageIndicatorWhiteColor, alpha: 1)
        pageIndicatorTintColor = UIColor(white: MaterialPageControl.pageControlPageIndicatorWhiteColor, alpha: 1)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }

    private func updateContainerView(with pageIndicatorRadius: CGFloat) {
        let topEdge = CGFloat(floor(bounds.height - (pageIndicatorRadius * 2)) / 2)
        containerFrame = CGRect(x: 0, y: topEdge, width: bounds.width, height: pageIndicatorRadius * 2)

        trackLayer = MaterialPageControlTrackLayer(radius: pageIndicatorRadius)
        containerView.layer.addSublayer(trackLayer)
        containerView.layoutIfNeeded()
    }
    
    private func setCurrentPage(_ currentPage: Int, animated: Bool) {
        setCurrentPage(currentPage, animated: animated, duration: 0)
    }
    
    private func setCurrentPage(_ currentPage: Int, animated: Bool, duration: TimeInterval) {
        let previousPage = self.currentPage
        let shouldReverse = previousPage > currentPage
        self.currentPage = currentPage
        
        if numberOfPages == 0 { return }
        
        if animated {
            var startPoint = indicatorPositions[previousPage].cgPointValue
            var endPoint = indicatorPositions[currentPage].cgPointValue
            if shouldReverse {
                startPoint = indicatorPositions[currentPage].cgPointValue
                endPoint = indicatorPositions[previousPage].cgPointValue
            }
            let completionBlock: (() -> Void)? = {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(duration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                    self.trackLayer.removeTrackTowardsPoint(shouldReverse ? startPoint : endPoint) {
                        // Once track is removed, reveal indicators oncE more to ensure
                        // no hidden indicators remain.
                        self.revealIndicatorsReversed(shouldReverse)
                    }
                    self.revealIndicatorsReversed(shouldReverse)
                })
            }
            trackLayer.drawAndExtendTrack(fromStart: startPoint, toEnd: endPoint, completion: completionBlock)
        } else {
            let point = indicatorPositions[currentPage].cgPointValue
            animatedIndicator.updateIndicatorTransformX(point.x - pageIndicatorRadius)
            trackLayer.reset(at: point)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            indicators[previousPage].isHidden = false
            CATransaction.commit()
        }
    }
    
    private func isPageIndexValid(_ nextPage: Int) -> Bool {
        return nextPage >= 0 && nextPage < numberOfPages
    }

}

// MARK: - UIView(UIViewGeometry)

extension MaterialPageControl {

    override open var intrinsicContentSize: CGSize {
        return sizeForNumber(forPageCount: numberOfPages,
                             indicatorRadius: pageIndicatorRadius,
                             indicatorMargin: pageIndicatorMargin)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeForNumber(forPageCount: numberOfPages,
                             indicatorRadius: pageIndicatorRadius,
                             indicatorMargin: pageIndicatorMargin)
    }
    
    func sizeForNumber(forPageCount pageCount: Int,
                       indicatorRadius: CGFloat,
                       indicatorMargin: CGFloat) -> CGSize {
        let width = CGFloat(pageCount) * ((indicatorRadius * 2) + indicatorMargin) - indicatorMargin
        let height = max(MaterialPageControl.pageControlMinimumHeight, indicatorRadius * 2)
        return CGSize(width: width, height: height)
    }

}

// MARK: - Scrolling

extension MaterialPageControl {

    func scrolledPageNumber(_ scrollView: UIScrollView?) -> Int {
        let unboundedPageNumberLTR = lround(Double((scrollView?.contentOffset.x ?? 0.0) / (scrollView?.frame.size.width ?? 0.0)))
        let scrolledPageNumberLTR = max(0, min(numberOfPages - 1, unboundedPageNumberLTR))
        if isRTL() {
            return numberOfPages - 1 - scrolledPageNumberLTR
        }
        return scrolledPageNumberLTR
    }
    
    func scrolledPercentage(_ scrollView: UIScrollView?) -> CGFloat {
        // Returns scrolled percentage of scrollView from 0 to 1. If the scrollView has bounced past
        // the edge of its content, it will return either a negative value or value above 1.
        return MaterialPageControl.normalizeValue((scrollView?.contentOffset.x)!, 0, (scrollView?.contentSize.width ?? 0.0) - (scrollView?.frame.size.width ?? 0.0))
    }

}

// MARK: - UIScrollViewDelegate

extension MaterialPageControl: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrolledPercentageValue = scrolledPercentage(scrollView)
        
        if let animationKeys = scrollView.layer.animationKeys(),
           animationKeys.contains(MaterialPageControl.materialPageControlScrollViewContentOffset),
           let animation = scrollView.layer.animation(forKey: MaterialPageControl.materialPageControlScrollViewContentOffset) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(animation.beginTime * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                let currentPage = self.scrolledPageNumber(scrollView)
                self.setCurrentPage(currentPage, animated: true, duration: animation.duration)
                
                let transformX: CGFloat = scrolledPercentageValue * self.trackLength
                self.animatedIndicator.updateIndicatorTransformX(transformX, animated: true, duration: animation.duration, mediaTimingFunction: animation.timingFunction)
            })
        } else if scrolledPercentageValue >= 0 && scrolledPercentageValue <= 1 && numberOfPages > 0 {
            // Update active indicator position.
            let transformX: CGFloat = scrolledPercentageValue * trackLength
            if !isDeferredScrolling {
                animatedIndicator.updateIndicatorTransformX(transformX)
            }
            // Determine endpoints for drawing track depending on direction scrolled.
            let scrolledPageNumberValue = scrolledPageNumber(scrollView)
            var startPoint = indicatorPositions[scrolledPageNumberValue].cgPointValue
            var endPoint = startPoint
            let radius = pageIndicatorRadius
            if transformX > startPoint.x - radius {
                if isRTL() {
                    endPoint = (indicatorPositions[scrolledPageNumberValue - 1]).cgPointValue
                } else {
                    endPoint = (indicatorPositions[scrolledPageNumberValue + 1]).cgPointValue
                }
            } else if transformX < startPoint.x - radius {
                if isRTL() {
                    startPoint = (indicatorPositions[scrolledPageNumberValue + 1]).cgPointValue
                } else {
                    startPoint = (indicatorPositions[scrolledPageNumberValue - 1]).cgPointValue
                }
            }
            
            if scrollView.isDragging {
                // Draw or extend track.
                if trackLayer.trackHidden {
                    trackLayer.drawTrack(from: startPoint, to: endPoint)
                } else {
                    trackLayer.extendTrack(fromStart: startPoint, toEnd: endPoint)
                }
            }
            
            // Hide indicators to be shown with animated reveal once track is removed.
            if !isDeferredScrolling {
                indicators[scrolledPageNumberValue].isHidden = true
            }
            
        }
    }
    
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let scrolledPageNumberValue = scrolledPageNumber(scrollView)
        let point = indicatorPositions[scrolledPageNumberValue].cgPointValue
        let shouldReverse = currentPage > scrolledPageNumberValue
        let sendAction = currentPage != scrolledPageNumberValue
        currentPage = scrolledPageNumberValue
        
        trackLayer.removeTrackTowardsPoint(point) {
            // Animate hidden indicators once more when completed to ensure all
            // indicators
            // have been revealed.
            self.revealIndicatorsReversed(shouldReverse)
        }
        
        // Animate hidden indicators staggered towards current page indicator. Show indicators
        // in reverse if scrolling to left.
        revealIndicatorsReversed(shouldReverse)
        
        // Send notification if new scrolled page.
        if sendAction {
            sendActions(for: .valueChanged)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isDeferredScrolling = false
        let scrolledPageNumber = self.scrolledPageNumber(scrollView)
        let shouldReverse = currentPage > scrolledPageNumber
        currentPage = scrolledPageNumber
        revealIndicatorsReversed(shouldReverse)
    }
}

// MARK: - Indicators

extension MaterialPageControl {
    func revealIndicatorsReversed(_ reversed: Bool) {
        var count = 0
        let block: ((MaterialPageControlIndicator?, Int, Bool) -> Void)? = { indicator, index, stop in
            let isCurrentPageIndicator = index == self.currentPage
            
            // Reveal indicators if hidden and not current page indicator.
            if indicator!.isHidden && !isCurrentPageIndicator {
                let delay: Double = (Double(Int(MaterialPageControl.pageControlIndicatorShowDelay) * count) * Double(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
                let popTime = (DispatchTime.now() + delay)
                
                DispatchQueue.main.asyncAfter(deadline: popTime, execute: {
                    indicator?.revealIndicator()
                })
                
                count += 1
            }
        }
        
        if let block = block {
            for (index, indicator) in indicators.enumerated() {
                block(indicator, index, false)
            }
        }
    }
}

// MARK: - Gesture Recognizer

extension MaterialPageControl {
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer?) {
        let touchPoint = gesture?.location(in: self)
        let willDecrement = (touchPoint?.x ?? 0.0) < bounds.midX
        var nextPage: Int
        if willDecrement {
            nextPage = currentPage - 1
        } else {
            nextPage = currentPage + 1
        }
        
        // Quit if scrolling past bounds.
        if isPageIndexValid(nextPage) {
            if defersCurrentPageDisplay {
                isDeferredScrolling = true
                currentPage = nextPage
            } else {
                setCurrentPage(nextPage, animated: true)
            }
            sendActions(for: .valueChanged)
        }
    }
    
    func updateCurrentPageDisplay() {
        // If defersCurrentPageDisplay = true, then update control only when this method is called.
        if defersCurrentPageDisplay && isPageIndexValid(currentPage) {
            self.setCurrentPage(currentPage, animated: false)
            
            // Reset hidden state of indicators.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            for i in 0..<numberOfPages {
                let indicator = indicators[i]
                indicator.isHidden = (i == currentPage) ? true : false
            }
            CATransaction.commit()
        }
    }
}

// MARK: - Accesibility

extension MaterialPageControl {
    override public var isAccessibilityElement: Bool {
        get { return true }
        set { super.isAccessibilityElement = newValue }
    }
    
    override public var accessibilityLabel: String? {
        get { return MaterialPageControl.materialPageControlBundle }
        set { super.accessibilityLabel = newValue }
    }
    
    override public var accessibilityTraits: UIAccessibilityTraits {
        get { return .adjustable}
        set { super.accessibilityTraits = newValue }
    }
    
    override public func accessibilityIncrement() {
        // Quit if scrolling past bounds.
        let nextPage = currentPage + 1
        if isPageIndexValid(nextPage) {
            setCurrentPage(nextPage, animated: true)
            sendActions(for: .valueChanged)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: accessibilityLabel)
        }
    }
    
    override public func accessibilityDecrement() {
        // Quit if scrolling past bounds.
        let nextPage = currentPage - 1
        if isPageIndexValid(nextPage) {
            setCurrentPage(nextPage, animated: true)
            sendActions(for: .valueChanged)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: accessibilityLabel)
        }
    }
}

extension MaterialPageControl {
    
    private func isRTL() -> Bool {
        if #available(iOS 10.0, *) {
            return respectsUserInterfaceLayoutDirection && (effectiveUserInterfaceLayoutDirection == .rightToLeft)
        } else {
            return false
        }
    }
    
    private func resetControl() {
        invalidateIntrinsicContentSize()
        
        // Clear indicators.
        for layer in containerView.layer.sublayers! {
            if layer != trackLayer {
                layer.removeFromSuperlayer()
            }
        }
        indicators = []
        indicatorPositions = []
        
        if numberOfPages == 0 {
            setNeedsLayout()
            return
        }
        
        // Create indicators.
        let radius = pageIndicatorRadius
        let margin = pageIndicatorMargin
        for i in 0..<numberOfPages {
            let offsetX = CGFloat(i) * (margin + (radius * 2))
            let offsetY = radius
            let center = CGPoint(x: offsetX + radius, y: offsetY)
            let indicator = MaterialPageControlIndicator(center: center, radius: radius)
            indicator.opacity = Float(MaterialPageControl.pageControlIndicatorDefaultOpacity)
            containerView.layer.addSublayer(indicator)
            if isRTL() {
                indicators.insert(indicator, at: 0)
                indicatorPositions.insert(NSValue(cgPoint: indicator.position), at: 0)
            } else {
                indicators.append(indicator)
                indicatorPositions.append(NSValue(cgPoint: indicator.position))
            }
        }
        
        // Resize container view to keep indicators centered.
        let frameWidth = containerView.frame.size.width
        let controlSize = sizeForNumber(forPageCount: numberOfPages,
                                        indicatorRadius: pageIndicatorRadius,
                                        indicatorMargin: pageIndicatorMargin)
        containerView.frame = containerView.frame.insetBy(dx: (frameWidth - controlSize.width) / 2, dy: 0)
        trackLength = containerView.frame.width - (radius * 2)
        
        // Add animated indicator that will travel freely across the container. Its transform will be
        // updated by calling its -updateIndicatorTransformX method.
        let center = CGPoint(x: radius, y: radius)
        let point = indicatorPositions[currentPage].cgPointValue
        animatedIndicator = MaterialPageControlIndicator(center: center, radius: radius)
        animatedIndicator.updateIndicatorTransformX(point.x - pageIndicatorRadius)
        containerView.layer.addSublayer(animatedIndicator)
        
        setNeedsLayout()
    }
    
}
