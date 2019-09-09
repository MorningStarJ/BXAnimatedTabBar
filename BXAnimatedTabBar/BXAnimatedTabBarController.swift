//
//  BxTabBarController.swift
//  BXAnimatedTabBar
//
//  Created by Mars on 2019/9/8.
//  Copyright © 2019 Mars. All rights reserved.
//

import UIKit

open class BXAnimatedTabBarController: UITabBarController {
  /// The animated items.
  open var animatedItems: [BXAnimatedTabBarItem] {
    return tabBar.items as? [BXAnimatedTabBarItem] ?? []
  }
  
  /// Containers
  var containers: [String: UIView] = [:]
  var arrViews = [UIView]()
  var arrBottomAnchor = [NSLayoutConstraint]()
  
  open override var viewControllers: [UIViewController]? {
    didSet {
      initializeContainers()
    }
  }
  
  open override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
    super.setViewControllers(viewControllers, animated: animated)
    initializeContainers()
  }
  
  fileprivate func initializeContainers() {
    containers.values.forEach { $0.removeFromSuperview() }
    containers = createViewContainers()

    if !containers.isEmpty {
        createCustomIcons(containers)
    }
  }
  
  /// -
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    initializeContainers()
  }
  
//  override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//    coordinator.animate(alongsideTransition: { (transitionCoordinatorContext) -> Void in
//      for (index, var layoutAnchor) in self.arrBottomAnchor.enumerated() {
//        layoutAnchor.isActive = false
//        layoutAnchor = self.arrViews[index].bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
//
//        self.arrBottomAnchor[index] = layoutAnchor
//        self.arrBottomAnchor[index].isActive = true
//      }
//      self.view.updateConstraints()
//    }, completion: { (transitionCoordinatorContext) -> Void in
//        //refresh view once rotation is completed not in will transition as it returns incorrect frame size.Refresh here
//    })
//    super.viewWillTransition(to: size, with: coordinator)
//  }
  
  /// - MARK: creation methods
  
  fileprivate func createCustomIcons(_ containers: [String: UIView]) {
    guard let items = tabBar.items, items.count <= 5 else {
      fatalError("More than 5 items is not supported.")
    }
    
    guard animatedItems.count != 0 else {
      fatalError("Items must be BXAnimatedTabBarItem.")
    }
    
    var index = 0
    
    for item in animatedItems {
      guard let container = containers["container\(index)"] else {
        fatalError("Container \(items.count - 1) does not exist.")
      }
      
      container.tag = index
      
      let renderMode: UIImage.RenderingMode = item.iconColor.cgColor.alpha == 0 ? .alwaysOriginal : .alwaysTemplate
      
      let iconImage = item.image ?? item.iconView?.icon.image
      let iconView = UIImageView(image: iconImage?.withRenderingMode(renderMode))
      iconView.translatesAutoresizingMaskIntoConstraints = false
      iconView.tintColor = item.iconColor
      iconView.highlightedImage = item.selectedImage?.withRenderingMode(renderMode)
      iconView.contentMode = .scaleAspectFill
      
      let textLabel = UILabel()
      if let title = item.title, !title.isEmpty {
        textLabel.text = title
      } else {
        textLabel.text = item.iconView?.label.text
      }
      
      textLabel.backgroundColor = UIColor.clear
      textLabel.textColor = item.textColor
//      textLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
      textLabel.font = item.textFont
      textLabel.textAlignment = NSTextAlignment.center
      textLabel.translatesAutoresizingMaskIntoConstraints = false

      container.backgroundColor = item.bgDefaultColor
      
      container.addSubview(iconView)
      
      createConstraints(iconView, container: container, width: 26, height: 26, yOffset: -4 - item.yOffSet)
      container.addSubview(textLabel)
      let textLabelWidth = tabBar.frame.size.width / CGFloat(items.count) - 5.0
      createConstraints(textLabel, container: container, width: textLabelWidth, yOffset: 16 - item.yOffSet)

      if item.isEnabled == false {
          iconView.alpha = 0.5
          textLabel.alpha = 0.5
      }
      item.iconView = (icon: iconView, label: textLabel)
      
      if 0 == index { // selected first elemet
          item.selectedState()
          container.backgroundColor = item.bgSelectedColor
      } else {
          item.deselectedState()
          container.backgroundColor = item.bgDefaultColor
      }

      item.image = nil
      item.title = ""
      index += 1
    }
  }
  
  fileprivate func createConstraints(
    _ view: UIView, container: UIView, width: CGFloat? = nil, height: CGFloat? = nil, yOffset: CGFloat = 0) {
    let centerX = view.centerXAnchor.constraint(equalTo: container.centerXAnchor)
    let centerY = view.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: yOffset)
    NSLayoutConstraint.activate([centerX, centerY])
    
    if let width = width {
      view.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    if let height = height {
      view.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
  }
  
  fileprivate func createViewContainers() -> [String: UIView] {
    guard let items = tabBar.items, items.count > 0 else { return [:] }
    
    var containerDict = [String: UIView]()
    
    for index in 0 ..< items.count {
      let viewContainer = createViewContainer()
      containerDict["container\(index)"] = viewContainer
    }
    
    var vfs = "H:|-(0)-[container0]"
    for index in 1 ..< items.count {
      vfs += "-(0)-[container\(index)(==container0)]"
    }
    
    vfs += "-(0)-|"
    
    let constraints = NSLayoutConstraint.constraints(
      withVisualFormat: vfs,
      options: .directionLeftToRight,
      metrics: nil,
      views: (containerDict as [String: AnyObject]))
    
    view.addConstraints(constraints)
    
    return containerDict
  }
  
  fileprivate func createViewContainer() -> UIView {
    let viewContainer = UIView()
    viewContainer.translatesAutoresizingMaskIntoConstraints = false
    viewContainer.isExclusiveTouch = true
    view.addSubview(viewContainer)
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(BXAnimatedTabBarController.tapHandler(_:)))
    tapGesture.numberOfTouchesRequired = 1
    viewContainer.addGestureRecognizer(tapGesture)
    arrViews.append(viewContainer)
    
    let bottomAnchor = viewContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    arrBottomAnchor.append(bottomAnchor)
    bottomAnchor.isActive = true
    
    let height = viewContainer.heightAnchor.constraint(equalToConstant: 48)
    height.isActive = true
    
    return viewContainer
  }
  
  /// - MARK: actions
  @objc open func tapHandler(_ gesture: UIGestureRecognizer) {
    guard let items = tabBar.items as? [BXAnimatedTabBarItem],
      let gestureView = gesture.view else {
      fatalError("Items must be a BXAnimatedTabBarItem.")
    }
    
    let currentIndex = gestureView.tag
    
    if items[currentIndex].isEnabled == false { return }
    
    let controller = children[currentIndex]
    
    if let shouldSelect = delegate?.tabBarController?(self, shouldSelect: controller), !shouldSelect { return }
    
    if selectedIndex != currentIndex {
      // Tap a different tab
      let animationItem = items[currentIndex]
      animationItem.selectAnimation()
      
      let deselectItem = items[selectedIndex]
      
      let containerPrevious: UIView = deselectItem.iconView!.icon.superview!
      containerPrevious.backgroundColor = items[selectedIndex].bgDefaultColor
      
      deselectItem.deselectAnimation()
      
      let container: UIView = animationItem.iconView!.icon.superview!
      container.backgroundColor = items[currentIndex].bgSelectedColor
      
      selectedIndex = gestureView.tag
    }
    else {
      // Tap the same tab
      if let navVC = self.viewControllers![selectedIndex] as? UINavigationController {
        navVC.popToRootViewController(animated: true)
      }
    }
    
    delegate?.tabBarController?(self, didSelect: controller)
  }
}

extension BXAnimatedTabBarController {

    /**
     Change selected color for each UITabBarItem
     - parameter textSelectedColor: set new color for text
     - parameter iconSelectedColor: set new color for icon
     */
    open func changeSelectedColor(_ textSelectedColor: UIColor, iconSelectedColor: UIColor) {
      for index in 0 ..< animatedItems.count {
        let item = animatedItems[index]

        item.animation.textSelectedColor = textSelectedColor
        item.animation.iconSelectedColor = iconSelectedColor

        if item == tabBar.selectedItem {
            item.selectedState()
        }
      }
    }

    /**
     Hide UITabBarController
     - parameter isHidden: A Boolean indicating whether the UITabBarController is displayed
     */
    open func tabBarHidden(_ isHidden: Bool, animated: Bool) {
      func _tabBarHidden(_ isHidden: Bool) {
        let direction: CGFloat = isHidden ? 1 : -1
        
        for item in self.animatedItems {
          if let iconView = item.iconView {
            iconView.icon.superview?.center.y += (200 * direction)
          }
        }
        
        self.tabBar.center.y += (200 * direction)
      }
      
      if animated {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn], animations: {
          _tabBarHidden(isHidden)
        })
      }
      else {
        _tabBarHidden(isHidden)
      }
    }

    /**
     Selected UITabBarItem with animaton
     - parameter from: Index for unselected animation
     - parameter to:   Index for selected animation
     */
    open func setSelectIndex(from: Int, to: Int) {
      selectedIndex = to

      let containerFrom = animatedItems[from].iconView?.icon.superview
      containerFrom?.backgroundColor = animatedItems[from].bgDefaultColor
      animatedItems[from].deselectAnimation()

      let containerTo = animatedItems[to].iconView?.icon.superview
      containerTo?.backgroundColor = animatedItems[to].bgSelectedColor
      animatedItems[to].selectAnimation()
    }
}