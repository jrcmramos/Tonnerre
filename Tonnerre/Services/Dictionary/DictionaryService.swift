//
//  DictionaryService.swift
//  Tonnerre
//
//  Created by Yaxin Cheng on 2018-06-08.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import CoreServices
import Cocoa

struct DictionarySerivce: BuiltInProvider {
  let icon: NSImage = .dictionary
  let content: String = "Find definition for word in dictionary"
  let name: String = "Define words..."
  let keyword: String = "define"
  let argLowerBound: Int = 1
  let argUpperBound: Int = Int.max
  private let spellChecker: NSSpellChecker
  
  init() {
    spellChecker = .shared
    spellChecker.automaticallyIdentifiesLanguages = true
  }
  
  func prepare(withInput input: [String]) -> [DisplayProtocol] {
    guard input.count > 0, !input[0].isEmpty else { return [self] }
    let text = input.joined(separator: " ")
    return [wrapQuery(text)]
  }
  
  func supply(withInput input: [String], callback: @escaping ([DisplayProtocol])->Void) {
    guard input.count > 0, !input[0].isEmpty else {
      callback([])
      return
    }
    let text = input.joined(separator: " ")
    let suggestions = spellChecker.completions(forPartialWordRange: NSRange(text.startIndex..., in: text), in: text, language: nil, inSpellDocumentWithTag: NSSpellChecker.uniqueSpellDocumentTag()) ?? []
    callback(suggestions.compactMap {wrap($0, filterWord: text) } )
  }
  
  func serve(service: DisplayProtocol, withCmd: Bool) {
    guard let request = service as? DisplayableContainer<URL>, let url = request.innerItem else { return }
    NSWorkspace.shared.open(url)
  }
  
  private func define(_ query: String) -> (String, String)? {
    let termRange = DCSGetTermRangeInString(nil, query as CFString, 0)
    guard
      termRange.location != kCFNotFound,
      let definition = DCSCopyTextDefinition(nil, query as CFString, termRange)?.takeRetainedValue()
    else { return nil }
    let startIndex = query.index(query.startIndex, offsetBy: termRange.location)
    let endIndex = query.index(startIndex, offsetBy: termRange.length)
    let foundTerm = String(query[startIndex ..< endIndex])
    return (foundTerm, String(definition))
  }
  
  private func wrapQuery(_ query: String) -> DisplayableContainer<URL> {
    let (headWord, content): (String, String)
    if let (foundTerm, definition) = define(query) {
      headWord = foundTerm
      content = definition
    } else {
      headWord = query
      content = "Cannot find definition for \"\(query)\""
    }
    let urlEncoded = headWord.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? headWord
    let dictURL = URL(string: String(format: "dict://%@", urlEncoded))!
    return DisplayableContainer(name: headWord, content: content, icon: icon, innerItem: dictURL, placeholder: "")
  }
  
  private func wrap(_ query: String, filterWord: String) -> DisplayableContainer<URL>? {
    guard
      let (foundTerm, definition) = define(query),
      foundTerm.caseInsensitiveCompare(filterWord) != .orderedSame
    else { return nil }
    let headWord = foundTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? foundTerm
    let dictURL = URL(string: String(format: "dict://%@", headWord))!
    return DisplayableContainer(name: foundTerm, content: definition, icon: icon, innerItem: dictURL)
  }
}
