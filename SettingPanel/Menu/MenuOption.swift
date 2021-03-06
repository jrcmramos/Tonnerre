//
//  MenuOption.swift
//  SettingPanel
//
//  Created by Yaxin Cheng on 2018-11-26.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

final class MenuOption: NSCollectionViewItem {
  
  override var highlightState: NSCollectionViewItem.HighlightState {
    didSet {
      switch highlightState {
      case .forSelection: view.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.3).cgColor
      case .forDeselection: view.layer?.backgroundColor = .clear
      default:
        super.highlightState = highlightState
      }
    }
  }
}
