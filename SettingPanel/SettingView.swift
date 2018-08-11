//
//  SettingView.swift
//  SettingPanel
//
//  Created by Yaxin Cheng on 2018-08-07.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

final class SettingView: NSScrollView {
  
  private var contentHeight: NSLayoutConstraint!
  @IBOutlet weak var leftPanel: NSStackView!
  @IBOutlet weak var rightPanel: NSStackView!
  @IBOutlet weak var titleLabel: NSTextField!
  
  enum PanelSide {
    case left
    case right
  }
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    // Drawing code here.
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    guard
      let ch = documentView?.constraints.filter({ $0.identifier == "contentHeight" }).first
    else { fatalError("View should contain a layout constraint with identifier \"contentHeight\"") }
    contentHeight = ch
  }
  
  private var leftHeight: CGFloat = 0
  private var rightHeight: CGFloat = 0
  
  func addSubview(_ view: NSView, side: PanelSide) {
    if side == .left {
      leftHeight += view.frame.height
      leftPanel.addView(view, in: .top)
    } else if side == .right {
      rightHeight += view.frame.height
      rightPanel.addView(view, in: .top)
    }
  }
  
  func adjustHeight() {
    let requiredHeight: CGFloat
    if rightPanel.fittingSize.height > leftPanel.fittingSize.height {
      requiredHeight = rightHeight + 48 + 37
    } else {
      requiredHeight = leftHeight + 48 + 23 + 57 + 16
    }
    contentHeight.constant = max(requiredHeight, 560)
  }
}