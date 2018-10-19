//
//  LiteTableViewController.swift
//  Tonnerre
//
//  Created by Yaxin Cheng on 2018-10-18.
//  Copyright © 2018 Yaxin Cheng. All rights reserved.
//

import Cocoa

class LiteTableViewController: NSViewController {
  
  var datasource: [ServicePack] = [] {
    didSet {
      (view as! LiteTableView).reload()
    }
  }
  let CellHeight: CGFloat = 56
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    
    if let tableView = view as? LiteTableView {
      tableView.liteDelegate   = self
      tableView.liteDataSource = self
      tableView.register(nib: NSNib(nibNamed: "ServiceCell", bundle: .main)!, withIdentifier: .ServiceCell)
      let allowedKeys: [UInt16] = []
    }
  }
  
}

extension LiteTableViewController: LiteTableDelegate, LiteTableDataSource {
  func viewDidScroll(_ tableView: LiteTableView) {
    for (index, cell) in tableView.visibleCells.enumerated() {
      (cell as? ServiceCell)?.cmdLabel.stringValue = "⌘\(index + 1)"
    }
  }
  
  func cellReuseThreshold(_ tableView: LiteTableView) -> Int {
    return 9
  }
  
  func numberOfCells(_ tableView: LiteTableView) -> Int {
    return datasource.count
  }
  
  func cellHeight(_ tableView: LiteTableView) -> CGFloat {
    return CellHeight
  }
  
  func prepareCell(_ tableView: LiteTableView, at index: Int) -> LiteTableCell {
    let cell = tableView.dequeueCell(withIdentifier: .ServiceCell) as! ServiceCell
    let data = datasource[index]
    cell.iconView.image = data.icon
    cell.serviceLabel.stringValue = data.name
    cell.introLabel.stringValue = data.content
    cell.cmdLabel.stringValue = "⌘\(index % 9 + 1)"
    return cell
  }
}
