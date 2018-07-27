//
//  TerminalService.swift
//  Tonnerre
//
//  Created by Yaxin Cheng on 2018-07-22.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

struct TerminalService: TonnerreService, TonnerreInstantService, AsyncLoadingProtocol {
  static let keyword: String = ">"
  let name: String = "Run shell commands here"
  let content: String = "Click enter to execute it"
  let argLowerBound: Int = 1
  let argUpperBound: Int = Int.max
  let icon: NSImage = .terminal
  let mode: LoadingMode = .replaced
  
  func prepare(input: [String]) -> [Displayable] {
    let cmd = input.joined(separator: " ")
    return [DisplayableContainer(name: cmd, content: "Run \(cmd) in terminal", icon: icon, innerItem: input)]
  }
  
  func serve(source: Displayable, withCmd: Bool) {
    guard let cmd = (source as? DisplayableContainer<[String]>)?.innerItem else { return }
    DispatchQueue.global(qos: .userInitiated).async {
      let process = Process()
      process.arguments = cmd
      process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
      let outputPipe = Pipe()
      process.standardOutput = outputPipe
      do {
        try process.run()
        let returnedData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let resultString = String(data: returnedData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        let result = resultString.components(separatedBy: "\n").map { DisplayableContainer(name: $0, content: "Result of \"\(cmd.joined(separator: " "))\"", icon: self.icon, innerItem: $0) }
        let notification = Notification(name: .suggestionDidFinish, object: self, userInfo: ["suggestions": result])
        NotificationCenter.default.post(notification)
      } catch {
        let errorInfo = DisplayableContainer(name: "\(error)", content: "Error happened when running \(cmd.joined(separator: " "))", icon: self.icon, innerItem: error.localizedDescription)
        let notification = Notification(name: .suggestionDidFinish, object: self, userInfo: ["suggestions": errorInfo])
        NotificationCenter.default.post(notification)
      }
    }
  }
  
  func present(suggestions: [Any]) -> [ServiceResult] {
    guard suggestions is [Displayable] else { return [] }
    return (suggestions as! [Displayable]).map { ServiceResult(service: self, value: $0) }
  }
}
