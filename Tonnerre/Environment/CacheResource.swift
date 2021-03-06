//
//  CacheResource.swift
//  Tonnerre
//
//  Created by Yaxin Cheng on 2019-02-27.
//  Copyright © 2019 Yaxin Cheng. All rights reserved.
//

import Foundation

struct CacheResource: EnvResource {
  func export(to env: Environment) {
    URLCache.shared = URLCache(
      memoryCapacity: 1024 * 1024 * 5,
      diskCapacity: 1024 * 1024 * 25,
      diskPath: SupportFolders.cache.path.path
    )
  }
}
