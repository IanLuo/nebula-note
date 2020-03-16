//
//  SettingsPageViewController.swift
//  x3Note
//
//  Created by ian luo on 2020/3/16.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import Core
import Interface

public class SettingsPageViewController: UIViewController , UITableViewDelegate, UITableViewDataSource {
    private var pageData: SettingsViewModel.Page!
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pageData.groups[section].items.count
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.pageData.groups.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.pageData.groups[indexPath.section].items[indexPath.row]
        
        switch item.value {
        case let .list(selected, options, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: PicklistCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = options[selected]
            cell.accessoryType = .disclosureIndicator
            return cell
        case let .switch(current):
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCell.reuseIdentifier, for: indexPath) as! switchCell
            cell.textLabel?.text = item.label
            cell.switchButton.isOn = current
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.pageData.groups[section].title
    }
    
    private var viewModel: SettingsViewModel!
    
    public convenience init(viewModel: SettingsViewModel) {
        self.init()
        self.viewModel = viewModel
        self.pageData = self.viewModel.makeData()
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(switchCell.self, forCellReuseIdentifier: switchCell.reuseIdentifier)
        tableView.register(PicklistCell.self, forCellReuseIdentifier: PicklistCell.reuseIdentifier)
        return tableView
    }()
}

private class switchCell: UITableViewCell {
    static let reuseIdentifier = "switchCell"
    
    let switchButton: UISwitch = {
        let switchButton = UISwitch()
        return switchButton
    }()
}

private class PicklistCell: UITableViewCell {
    static let reuseIdentifier = "PicklistCell"
}
