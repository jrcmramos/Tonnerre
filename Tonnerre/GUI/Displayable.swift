//
//  Displayable.swift
//  Tonnerre
//
//  Created by Yaxin Cheng on 2018-05-30.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

protocol Displayable {
  var icon: NSImage { get }
  var name: String { get }
  var content: String { get }
  var alterContent: String? { get }
  var alterIcon: NSImage? { get }
  var itemIdentifier: NSUserInterfaceItemIdentifier { get }
}

extension Displayable {
  var name: String { return "\(Self.self)" }
  var content: String { return "" }
  var alterContent: String? { return nil }
  var alterIcon: NSImage? { return nil }
  var itemIdentifier: NSUserInterfaceItemIdentifier { return .ServiceCell }
}

extension URL: Displayable {
  var name: String {
    return self.deletingPathExtension().lastPathComponent
  }
  
  var content: String {
    return self.path
  }
  
  var icon: NSImage {
    let workspace = NSWorkspace.shared
    let path: String
    if isFileURL || isDirectory || isSymlink {
      path = self.path
    } else {
      guard let browser = workspace.urlForApplication(toOpen: self) else { return #imageLiteral(resourceName: "safari") }
      path = browser.path
    }
    let icon = workspace.icon(forFile: path)
    icon.size = NSSize(width: 96, height: 96)
    return icon
  }
}
