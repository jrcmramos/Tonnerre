//
//  MapService.swift
//  Tonnerre
//
//  Created by Yaxin Cheng on 2018-06-05.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

struct GoogleMapService: WebService {
  let argUpperBound: Int = .max
  
  func parse(suggestionData: Data?) -> [String] {
    guard
      let jsonData = suggestionData,
      let jsonObject = JSON(data: jsonData),
      (jsonObject["status"] as? String) == "OK",
      let predictions: [[String: Any]] = jsonObject["predictions"]
    else { return [] }
    return predictions.compactMap { $0["description"] as? String }
  }
  let defaultKeyword: String = "map"
  let argLowerBound: Int = 1
  let name: String = "Google Maps"
  let contentTemplate: String = "Search \"%@\" on Google Maps"
  let icon: NSImage = #imageLiteral(resourceName: "googlemap")
  var alterIcon: NSImage? {
    return AppFetcher.fetchIcon(bundleID: "com.apple.maps")
  }
  
  func serve(service: DisplayItem, withCmd: Bool) {
    guard let request = (service as? DisplayContainer<URL>)?.innerItem else { return }
    let workspace = NSWorkspace.shared
    if withCmd {
      let appleMapURL = request.absoluteString.replacingOccurrences(of: "maps\\.google\\.\\w+?\\/", with: "maps.apple.com/", options: .regularExpression)
      workspace.open(URL(string: appleMapURL)!)
    } else {
      workspace.open(request)
    }
  }
}
