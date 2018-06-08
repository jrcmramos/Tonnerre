//
//  LaunchServices.swift
//  Tonnerre
//
//  Created by Yaxin Cheng on 2018-05-30.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

struct LaunchService: TonnerreService {
  let keyword: String = ""
  let arguments: [String] = ["query"]
  let hasPreview: Bool = false
  let icon: NSImage = #imageLiteral(resourceName: "tonnerre")
  
  private static let aliasDict: [String: String] = {
    let aliasFile = Bundle.main.path(forResource: "alias", ofType: "plist")!
    return NSDictionary(contentsOfFile: aliasFile) as! [String: String]
  }()
  
  func prepare(input: [String]) -> [Displayable] {
    let indexStorage = IndexStorage()
    let index = indexStorage[.defaultMode]
    let query = input.joined(separator: " ")
    guard !query.starts(with: "http") else { return [] }
    return index.search(query: query + "*", limit: 9 * 9, options: .defaultOption).map {
      let name: String
      if $0.pathExtension == "prefPane" {
        name = LaunchService.aliasDict[$0.lastPathComponent] ?? $0.name
      } else { name = $0.name }
      return BaseDisplayItem(name: name, content: $0.content, icon: $0.icon, innerItem: $0)
    }
  }
  
  func serve(source: Displayable, withCmd: Bool) {
    guard let appURL = (source as? BaseDisplayItem<URL>)?.innerItem else { return }
    let workspace = NSWorkspace.shared
    workspace.open(appURL)
  }
}