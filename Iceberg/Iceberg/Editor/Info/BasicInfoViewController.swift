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
        case characterCount
        case paragraphs
        case creatDate
        case backlink
        
        var title: String {
            switch self {
            case .editDate: return L10n.Document.Info.editDate
            case .wordCount: return L10n.Document.Info.wordCount
            case .paragraphs: return L10n.Document.Info.paragraphCount
            case .creatDate: return L10n.Document.Info.createDate
            case .characterCount: return L10n.Document.Info.characterCount
            case .backlink: return L10n.Document.Edit.backlink
            }
        }
        
        func value(viewModel: DocumentEditorViewModel) -> String {
            switch self {
            case .wordCount: return "\(viewModel.wordCount)"
            case .paragraphs: return "\(viewModel.paragraphCount)"
            case .editDate: return "\(viewModel.editeDate)"
            case .creatDate: return "\(viewModel.createDate)"
            case .characterCount: return "\(viewModel.characterCount)"
            case .backlink: return "\(viewModel.backlinks.value.count)"
            }
        }
        
        var interactive: Bool {
            switch self {
            case .backlink:
                return true
            default:
                return false
            }
        }
        
        func onTap(viewController: UIViewController, view: UIView, viewModel: DocumentEditorViewModel) {
            switch self {
            case .backlink:
                let choose = SelectorViewController()
                for link in viewModel.backlinks.value {
                    choose.addItem(title: link.packageName)
                }
                choose.onSelection = { index, v in
                    // dismiss selector
                    v.dismiss(animated: true) {
                        // dismiss info view
                        viewController.dismiss(animated: true) {
                            viewModel.context.coordinator?.openDocument(url: viewModel.backlinks.value[index])
                        }
                    }
                }
                
                choose.onCancel = {
                    $0.dismiss(animated: true)
                }
                choose.present(from: viewController, at: view)
            default:
                break
            }
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(InfoCell.self, forCellReuseIdentifier: InfoCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = InterfaceTheme.Color.background1
        return tableView
    }()
    
    private var _viewModel: DocumentEditorViewModel!
    
    public convenience init(viewModel: DocumentEditorViewModel) {
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
        cell.accessoryType = InfoItem.allCases[indexPath.section].interactive ? .disclosureIndicator : .none
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) {
            InfoItem.allCases[indexPath.section].onTap(viewController: self, view: cell, viewModel: self._viewModel)
        }
    }
}

private class InfoCell: UITableViewCell {
    static let reuseIdentifier: String = "InfoCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: reuseIdentifier)
        
        self.interface { [weak self] (me, theme) in
            self?.textLabel?.textColor = theme.color.interactive
            self?.textLabel?.font = theme.font.footnote
            self?.detailTextLabel?.font = theme.font.footnote
            self?.detailTextLabel?.textColor = theme.color.descriptive
            self?.backgroundColor = theme.color.background1
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
