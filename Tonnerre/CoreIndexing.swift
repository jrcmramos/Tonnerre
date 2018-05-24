//
//  CoreIndexing.swift
//  Tonnerre
//
//  Created by Yaxin Cheng on 2018-05-20.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Foundation
import TonnerreSearch

class CoreIndexing {
  /**
   A dictionary using file names as keys, and related aliases (if exist) as values
  */
  private lazy var aliasDict: Dictionary<String, String> = {
    guard let aliasFile = Bundle.main.path(forResource: "alias", ofType: "plist") else {
      return [:]
    }
    return NSDictionary(contentsOfFile: aliasFile) as! [String : String]
  }()
  /**
   SearchModel to related exclusion controls
   - defaultMode: []
   - name: extra coding files (e.g.: .pyc or .class) + caches
   - content: extra coding files + caches + media (user cannot search medias with the media content, generally by name only)
  */
  private var controls: [SearchMode: ExclusionControl] = [:]
  /**
   Background queue. When inserting to or deleting from CoreData, they are running in the background
  */
  private let backgroundQ: DispatchQueue = .global(qos: .background)
  /**
   Semaphore. Used to prevent destructive interference for adding to and deleting from CoreData
   */
  private let coreDataSemaphore = DispatchSemaphore(value: 1)
  
  private let indexes = IndexManage()
  /**
    Index the required data to the certain index files
   */
  func fullIndex(modes: SearchMode...) {
    guard let targetPaths: [URL] = modes.first?.indexTargets else { return }
    for mode in modes {
      for path in targetPaths {
        let _: IndexingDir? = safeInsert(data: ["path": path.path, "category": mode.storedInt])
      }
    }
    let queue = DispatchQueue.global(qos: .utility)
    let notificationCentre = NotificationCenter.default
    let beginNotification = modes.count == 2 ? Notification(name: .documentIndexingDidBegin) : Notification(name: .defaultIndexingDidBegin)
    let endNotification = modes.count == 2 ? Notification(name: .documentIndexingDidFinish) : Notification(name: .defaultIndexingDidFinish)
    for mode in modes { indexes[mode] = TonnerreIndex(filePath: mode.indexPath.path, indexType: mode.indexType) }
    queue.async { [unowned self] in
      notificationCentre.post(beginNotification)
      let indeces = modes.compactMap({ self.indexes[$0] })
      for beginURL in targetPaths { self.addContent(in: beginURL, modes: modes, indexes: indeces) }
      notificationCentre.post(endNotification)
    }
  }
  
  /**
   Recover the unfinished indexing and failed indexing
  */
  func recoverFromErrors() {
    let context = getContext()
    let queryErrors: (String)->[NSManagedObject] = {// Function to query from CoreData
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: $0)
      return (try? context.fetch(fetchRequest)) ?? []
    }
    guard
      let failedPathes = queryErrors(CoreDataEntities.FailedPath.rawValue) as? [FailedPath],
      let ongoingPathes = queryErrors(CoreDataEntities.IndexingDir.rawValue) as? [IndexingDir]
    else { return }// Get failedPath and unfinished IndexingDir
    let (failedDefault, failedDocuments) = failedPathes.bipartite { $0.category == 0 }// Separate default & docs
    let (ongoingDefault, ongoingDocuments) = ongoingPathes.bipartite { $0.category == 0 }
    let queue = DispatchQueue.global(qos: .utility)
    let dealFailure: (FailedPath, TonnerreIndex) -> Void = { [unowned self] in// FailedPath dealing
      // Re-try adding the FailedPath into the index files, but do not recursively go to its content
      do {
        let pathURL = URL(fileURLWithPath: $0.path!)
        _ = try $1.addDocument(atPath: pathURL, additionalNote: self.getAlias(name: pathURL.lastPathComponent))
      } catch { debugPrint(error) }
      context.delete($0)// delete anyway even if it fails
      try? context.save()
    }
    let notificationCentre = NotificationCenter.default
    let userDefaults = UserDefaults.standard
    queue.async { [unowned self] in // Restore for defaults
      notificationCentre.post(Notification(name: .defaultIndexingDidBegin))
      let defaultIndex = self.indexes[.defaultMode]
      for fd in failedDefault { dealFailure(fd, defaultIndex) }
      let ongoingDefaultURL = ongoingDefault.map({ URL(fileURLWithPath: $0.path!) })
      for od in ongoingDefaultURL { self.addContent(in: od, modes: [.defaultMode], indexes: [defaultIndex]) }
      userDefaults.set(true, forKey: StoredKeys.defaultInxFinished.rawValue)
      notificationCentre.post(Notification(name: .defaultIndexingDidFinish))
    }
    queue.async { [unowned self] in // Restore for documents
      notificationCentre.post(Notification(name: .documentIndexingDidBegin))
      let nameIndex = self.indexes[.name]
      let contentIndex = self.indexes[.content]
      for fd in failedDocuments {
        let index = fd.category == 1 ? nameIndex : contentIndex
        dealFailure(fd, index)
      }
      for od in ongoingDocuments {
        let index = od.category == 1 ? nameIndex : contentIndex
        let mode: SearchMode = od.category == 1 ? .name : .content
        let url = URL(fileURLWithPath: od.path!)
        self.addContent(in: url, modes: [mode], indexes: [index])
      }
      userDefaults.set(true, forKey: StoredKeys.documentInxFinished.rawValue)
      notificationCentre.post(Notification(name: .documentIndexingDidFinish))
    }
    
    
  }
  
  /**
   Get alias for specific file names
   
   - parameter name: a file name. An alias is generated or retrieved based on the name
   - returns: an alias generated by compact the first letter of each word in the name or retrieved from the file
   */
  private func getAlias(name: String) -> String {
    var alias = aliasDict[name, default: ""]
    if alias.contains(" ") {// Get initial of words, such as Activity Manager -> AM
      let elements = alias.components(separatedBy: " ").compactMap({ $0.first }).map({ String($0) })
      alias += " \(elements.joined(separator: ""))"
    }
    return alias
  }
  
  /**
   The key function to recursively iterate through the file system structure and add files to index files
   - parameter path: the path to begin. This path and its children content (if path is a directory) will be added to the index files
   - parameter searchModes: the search modes are used to find the correct exclusion lists and correct index files
   */
  private func addContent(in path: URL, modes searchModes: SearchMode..., indexes: [TonnerreIndex]) {
    addContent(in: path, modes: searchModes, indexes: indexes)
  }
  
  /**
   The key function to recursively iterate through the file system structure and add files to index files
   - parameter path: the path to begin. This path and its children content (if path is a directory) will be added to the index files
   - parameter searchModes: the search modes are used to find the correct exclusion lists and correct index files
  */
  private func addContent(in path: URL, modes searchModes: [SearchMode], indexes: [TonnerreIndex]) {
    if path.isSymlink { return }// Do not add symlink to the index file
    var content: [URL] = []// The content of the path (if the path is a directory)
    do {
      if !path.isDirectory {// If it is not a directory
        for (mode, index) in zip(searchModes, indexes) {// Add file to related index files
          let fileExtension = path.pathExtension.lowercased()// get the extension
          if (controls[mode]?.contains(fileExtension) ?? false) { continue }// Exclude the unwanted types
          _ = try index.addDocument(atPath: path, additionalNote: getAlias(name: path.lastPathComponent))// add to the index file
        }
      } else {// If it is a directory
        for (mode, index) in zip(searchModes, indexes) where mode.includeDir == true {// Add to the index file if the index file accepts directory
          _ = try index.addDocument(atPath: path)
        }
        // Find all content files of this path
        content = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
      }
    } catch {// If any error happened
      backgroundQ.async { [unowned self] in // Insert a failed path to CoreData
        for mode in searchModes {
          let _: FailedPath? = self.safeInsert(data: ["path": path.path, "reason": "\(error)", "category": mode.storedInt])
        }
      }
    }
    if path.isDirectory {// This is simply for the tail recursion to separate from above
      let orderedContent = separate(paths: content)// Separate file URLs and directory URLs
      for filePath in orderedContent[0] { addContent(in: filePath, modes: searchModes, indexes: indexes) }// Add files to index files
      // Filter out certain directory with specific names: cache, logs, locales
      let filteredDir = orderedContent[1].filter { !ExclusionControl.isExcludedDir(name: $0.lastPathComponent.lowercased()) && !ExclusionControl.isExcludedURL(url: $0) }
      backgroundQ.async { [unowned self] in
        for mode in searchModes { // When each single file is indexed, we remove the path from CoreData
          self.safeDelete(data: ["path": path.path, "category": mode.storedInt], dataType: IndexingDir.self)
        // Then we add each sub-directory in this path to the CoreData
          for dirPath in filteredDir {
              let _: IndexingDir? = self.safeInsert(data: ["path": dirPath.path, "category": mode.storedInt])
          }
      }// So finally, there will be no data left in the IndexingDir
      }
      debugPrint(path)
      for dirPath in filteredDir { addContent(in: dirPath, modes: searchModes, indexes: indexes) }// Recursion to add each of them
    }
  }
  
  /**
    Separate the URL to file URLs and directory URLs
   - parameter paths: a list of URLs need to be separated
   - returns: an array with 2 elements, in which the first one is the file URLs, and  the second one is directory URLs
   */
  private func separate(paths: [URL]) -> [[URL]] {
    var result: [[URL]] = [[], []]
    for path in paths {
      if path.isDirectory {
        result[1].append(path)
      } else {
        result[0].append(path)
      }
    }
    return result
  }
  
  /**
   Insert a new data safely (avoid duplicates) into the CoreData
   - parameter data: A dictionary with keys as attributes of the object, and values as related values
   - returns: nil for not inserted (either failed or data already existed), the object itself for the success
  */
  private func safeInsert<T: NSManagedObject>(data: [String: Any]) -> T? {
    let context = getContext()
    let fetchRequest = NSFetchRequest<T>(entityName: "\(T.self)")
    let queryStr = data.keys.map({ $0 + "=%@" }).joined(separator: " AND ")
    let query = data.reduce([], {$0 + [$1.value]})
    fetchRequest.predicate = NSPredicate(format: queryStr, argumentArray: query)
    defer { coreDataSemaphore.signal() }
    coreDataSemaphore.wait()
    if let fetchedCount = try? context.count(for: fetchRequest) {
      if fetchedCount > 0 { return nil }
    }
    let newRecord = T(context: context)
    for (key, value) in data {
      newRecord.setValue(value, forKey: key)
    }
    try? context.save()
    return newRecord
  }
  
  /**
   Delete a data safely (avoid duplicates) into the CoreData
   - parameter data: A dictionary with keys as attributes of the object, and values as related values
   - parameter dataType: The dataType is used to locate the entityName in the CoreData
   */
  private func safeDelete<T: NSManagedObject>(data: [String: Any], dataType: T.Type) {
    let context = getContext()
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "\(T.self)")
    let queryStr = data.keys.map({ $0 + "=%@" }).joined(separator: " AND ")
    let query = data.reduce([], {$0 + [$1.value]})
    fetchRequest.predicate = NSPredicate(format: queryStr, argumentArray: query)
    let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    coreDataSemaphore.wait()
    _ = try? context.execute(batchDelete)
    try? context.save()
    coreDataSemaphore.signal()
  }
}
