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
        case editDate
        case wordCount
        case paragraphs
        case creatDate
        
        var title: String {
            switch self {
            case .editDate: return "Edit Date"
            case .wordCount: return "Words"
            case .paragraphs: return "Paragraphs"
            case .creatDate: return "Create Date"
            }
        }
        
        func value(viewModel: DocumentEditViewModel) -> String {
            switch self {
            case .wordCount: return "\(viewModel.wordCount)"
            case .paragraphs: return "\(viewModel.paragraphCount)"
            case .editDate: return "\(viewModel.editeDate)"
            case .creatDate: return "\(viewModel.createDate)"
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
    
    private var _viewModel: DocumentEditViewModel!
    
    public convenience init(viewModel: DocumentEditViewModel) {
        self.init(nibName: nil, bundle: nil)
        
        self._viewModel = viewModel
        self.view.addSubview(self.tableView)
        self.tableView.allSidesAnchors(to: self.view, edgeInset: 0)
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
        cell.detailTextLabel?.text = InfoItem.allCases[indexPath.section].value(viewModel: self._viewModel)
        
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
