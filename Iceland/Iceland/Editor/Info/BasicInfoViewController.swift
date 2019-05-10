//
//  BasicInfoViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/5/10.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface

public class BasicInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    enum InfoItem: CaseIterable {
        case wordCount
        case paragraphs
        case editDate
        case creatDate
        case glyphs
        
        var title: String {
            switch self {
            case .wordCount: return "Words"
            case .paragraphs: return "Paragraphs"
            case .editDate: return "Edit Date"
            case .glyphs: return "Glyphs"
            case .creatDate: return "Create Date"
            }
        }
        
        var value: String {
            switch self {
            case .wordCount: return "Words"
            case .paragraphs: return "Paragraphs"
            case .editDate: return "Edit Date"
            case .glyphs: return "Glyphs"
            case .creatDate: return "Create Date"
            }
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(InfoCell.self, forCellReuseIdentifier: InfoCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = InterfaceTheme.Color.background2
        tableView.allowsSelection = false
        return tableView
    }()
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        
        self.view.addSubview(self.tableView)
        self.tableView.allSidesAnchors(to: self.view, edgeInset: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return InfoItem.allCases.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InfoCell.reuseIdentifier, for: indexPath) as! InfoCell
        
        cell.textLabel?.text = InfoItem.allCases[indexPath.section].title
        cell.detailTextLabel?.text = InfoItem.allCases[indexPath.section].value
        
        return cell
    }
}

private class InfoCell: UITableViewCell {
    static let reuseIdentifier: String = "InfoCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: reuseIdentifier)
        
        self.textLabel?.textColor = InterfaceTheme.Color.interactive
        self.textLabel?.font = InterfaceTheme.Font.footnote
        self.detailTextLabel?.font = InterfaceTheme.Font.footnote
        self.detailTextLabel?.textColor = InterfaceTheme.Color.descriptive
        self.backgroundColor = InterfaceTheme.Color.background2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
