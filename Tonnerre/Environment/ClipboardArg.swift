//
//  ClipboardArg.swift
//  Tonnerre
//
//  Created by Yaxin Cheng on 2019-02-27.
//  Copyright © 2019 Yaxin Cheng. All rights reserved.
//

import Foundation

final class ClipboardArg: EnvArg, SettingSubscriber {
  private let clipboardMonitor: ClipboardMonitor
  let subscribedKey: SettingKey = .disabledServices
  
  init() {
    clipboardMonitor = ClipboardMonitor(interval: 1, repeat: true) { (value, type) in
      let limit = TonnerreSettings.get(fromKey: .clipboardLimit)?.rawValue as? Int ?? 9
      CBRecord.recordInsert(value: value, type: type.rawValue, limit: max(limit, 1))
    }
  }
  
  func setup() {
    clipboardMonitor.start()
  }
  
  func tearDown() {
    clipboardMonitor.stop()
  }
  
  func settingDidChange(_ changes: [NSKeyValueChangeKey : Any]) {
    switch changes[.newKey] {
    case let disabledIds as [String]:
      if disabledIds.contains(BuiltInProviderMap.extractID(from: ClipboardService.self)) {
        setup()
      } else { tearDown() }
    default: return
    }
  }
}