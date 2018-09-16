//
//  TonnerreInterpreter.swift
//  Tonnerre
//
//  Created by Yaxin Cheng on 2018-09-15.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation

/**
 The main interpreter access to interpret user input.
 
 It encapsulates different interpreters and the logics of using them
 */
struct TonnerreInterpreter {
  private let generalInterpreter = GeneralInterpreter(loader: GeneralLoader())
  private let delayedInterpreter = GeneralInterpreter(loader: DelayedServiceLoader())
  private let prioritInterpreter = InstantInterpreter(loader: PrioriLoader())
  private let tneInterpreter     = TNEInterpreter()
  private let webExtInterpreter  = WebExtInterpreter()
  private let defaultInterpreter = InstantInterpreter(loader: DefaultLoader())
  
  /**
   Interpret user input into ServicePacks
   - parameter input: user input
   - returns: well structured ServicePacks
  */
  func interpret(input: String) -> [ServicePack] {
    guard !input.isEmpty else { return [] }
    var providedServices = tneInterpreter.interpret(input: input)
    providedServices += webExtInterpreter.interpret(input: input)
    providedServices += generalInterpreter.interpret(input: input)
    providedServices += prioritInterpreter.interpret(input: input)
    if providedServices.isEmpty {
      providedServices += delayedInterpreter.interpret(input: input)
    }
    if providedServices.isEmpty {
      providedServices += defaultInterpreter.interpret(input: input)
    }
    return providedServices
  }
  
  func clearCache() {
    prioritInterpreter.clearCache()
  }
}