//
//  CatpureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import MapKit

public class CaptureListViewController: UIViewController {
    let viewModel: CaptureListViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CaptureTableCell.self, forCellReuseIdentifier: CaptureTableCell.reuseIdentifier)
        tableView.backgroundColor = InterfaceTheme.Color.background1
        tableView.separatorInset = .zero
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.contentInset = UIEdgeInsets(top: self.view.bounds.height / 4, left: 0, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        button.setImage(Asset.cross.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background1, size: .singlePoint), for: .normal)
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        return button
    }()
    
    public init(viewModel: CaptureListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        self.title = "Captures".localizable
        self.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "capture"), tag: 0)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        self.viewModel.loadAllCapturedData()
    }
    
    private func setupUI() {
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.tableView)
        
        self.cancelButton.sideAnchor(for: [.right, .top], to: self.view, edgeInset: 0)
        self.cancelButton.sizeAnchor(width: 80, height: 80)
        self.cancelButton.columnAnchor(view: self.tableView)
        
        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
    }
    
    @objc private func cancel() {
        self.viewModel.coordinator?.stop()
    }
}

extension CaptureListViewController: CaptureTableCellDelegate {
    public func didTapActions(cell: UITableViewCell) {
        guard let index = self.tableView.indexPath(for: cell)?.row else { return }
        
        let actionsViewController = self.createActionsViewController(index: index)
        
        self.present(actionsViewController, animated: true, completion: nil)
    }
    
    public func didTapActionsWithLink(cell: UITableViewCell, link: String?) {
        guard let index = self.tableView.indexPath(for: cell)?.row else { return }
        
        let actionsViewController = self.createActionsViewController(index: index)
        
        actionsViewController.addAction(icon: nil, title: "open link") { viewController in
            viewController.dismiss(animated: true, completion: {
                if let url = URL(string: link ?? "") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
        }
        
        self.present(actionsViewController, animated: true, completion: nil)
    }
    
    public func didTapActionsWithLocation(cell: UITableViewCell, location: CLLocationCoordinate2D) {
        guard let index = self.tableView.indexPath(for: cell)?.row else { return }
        
        let actionsViewController = self.createActionsViewController(index: index)
        
        actionsViewController.addAction(icon: nil, title: "open location") { viewController in
            viewController.dismiss(animated: true, completion: {
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location, addressDictionary:nil))
                mapItem.openInMaps(launchOptions: [:])
            })
        }
        
        self.present(actionsViewController, animated: true, completion: nil)
    }
    
    private func createActionsViewController(index: Int) -> ActionsViewController {
        let actionsViewController = ActionsViewController()
        
        switch self.viewModel.mode {
        case .manage:
            actionsViewController.addAction(icon: nil, title: "delete".localizable) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.delete(index: index)
                })
            }
            
            actionsViewController.addAction(icon: nil, title: "refile".localizable) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.chooseRefileLocation(index: index)
                })
            }
        case .pick:
            actionsViewController.addAction(icon: nil, title: "insert".localizable) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.selectAttachment(index: index)
                })
            }
        }
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        return actionsViewController
    }
}

extension CaptureListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.cellModels.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CaptureTableCell.reuseIdentifier, for: indexPath) as! CaptureTableCell
        cell.cellModel = self.viewModel.cellModels[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.viewModel.cellModels[indexPath.row].attachmentView.size(for: tableView.bounds.width - 60).height + 120
    }
}

extension CaptureListViewController: UITableViewDelegate {
    // nothing to do yet
}

extension CaptureListViewController: CaptureListViewModelDelegate {
    public func didStartRefile(at index: Int) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? CaptureTableCell {
            cell.showProcessingAnimation()
        }
    }
    
    public func didDeleteCapture(index: Int) {
        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
    }
    
    public func didFail(error: Error) {
        
    }
        
    public func didCompleteRefile(index: Int) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? CaptureTableCell {
            cell.hideProcessingAnimation()
        }
    }
    
    public func didLoadData() {
        self.tableView.reloadData()
    }
}
