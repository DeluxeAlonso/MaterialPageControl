# MaterialPageControl

[![Version](https://img.shields.io/cocoapods/v/MaterialPageControl.svg?style=flat)](https://cocoapods.org/pods/MaterialPageControl)
[![License](https://img.shields.io/cocoapods/l/MaterialPageControl.svg?style=flat)](https://cocoapods.org/pods/MaterialPageControl)
[![Platform](https://img.shields.io/cocoapods/p/MaterialPageControl.svg?style=flat)](https://cocoapods.org/pods/MaterialPageControl)
[![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://developer.apple.com/swift/)

Swift version of  [material-components-ios/PageControl](https://github.com/material-components/material-components-ios/tree/develop/components/PageControl) which is influenced by [Material Design specifications](https://material.io/develop/ios/components/page-controls/) for animations and layout.

## Requirements

MaterialPageControl requires iOS 13.0 and Swift 5.0 or above.

## Demo

![](Demo.gif)

## Installation

### CocoaPods

MaterialPageControl is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "MaterialPageControl"
```

### Swift Package Manager

To integrate using [Swift Package Manager](https://swift.org/package-manager/), add the following as a dependency to your Package.swift:

```Swift
.package(url: "https://github.com/DeluxeAlonso/MaterialPageControl.git", .upToNextMajor(from: "1.0.0"))
```

## Usage

You can initialize MaterialPageControl programatically or through interface builder and always must setup its numberOfPages property:

```swift
let pageControl = MaterialPageControl()
pageControl.pageIndicatorTintColor = .gray
pageControl.currentPageIndicatorTintColor = .black
pageControl.pageIndicatorRadius = 10.0
pageControl.numberOfPages = 3
```

MaterialPageControl is designed to be used in conjunction with a scroll view. You must implement three scrollview delegate methods (-scrollViewDidScroll, -scrollViewDidEndDecelerating, and -scrollViewDidEndScrollingAnimation) and must forward them to the page control just like this:

```swift
func scrollViewDidScroll(_ scrollView: UIScrollView) {
  pageControl.scrollViewDidScroll(scrollView)
}

func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
  pageControl.scrollViewDidEndDecelerating(scrollView)
}

func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
  pageControl.scrollViewDidEndScrollingAnimation(scrollView)
}
```

If you want to have the page control default tap gesture behaviour you should implement it like this:

```swift
pageControl.addTarget(self, action: #selector(didChangePage(sender:)), for: .valueChanged)

@objc func didChangePage(sender: MaterialPageControl) {
    var offset = collectionView.contentOffset
    offset.x = CGFloat(sender.currentPage) * scrollView.bounds.size.width
    scrollView.setContentOffset(offset, animated: true)
}
```

## Author

Alonso Alvarez, alonso.alvarez.dev@gmail.com

## License

MaterialPageControl is available under the MIT license. See the LICENSE file for more info.
