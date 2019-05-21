//
//  AgendaViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public class AgendaViewController: UIViewController {
    public struct Constants {
        static let besideDateBarHeight: CGFloat = 80
    }
    
    private let viewModel: AgendaViewModel
    
    private var _shouldChangeBesideDateBarContentOffset: Bool = true
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AgendaTableCell.self, forCellReuseIdentifier: AgendaTableCell.reuseIdentifier)
        tableView.register(DateSectionView.self, forHeaderFooterViewReuseIdentifier: DateSectionView.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = InterfaceTheme.Color.background1
        return tableView
    }()
    
    private lazy var besideDatesView: BesideDatesView = {
        let besideDatesView = BesideDatesView()
        besideDatesView.delegate = self
        return besideDatesView
    }()
    
    public init(viewModel: AgendaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        viewModel.delegate = self
        
        self.title = L10n.Agenda.title
        self.tabBarItem = UITabBarItem(title: L10n.Agenda.title, image: Asset.Assets.agenda.image, tag: 0)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        self.viewModel.loadData()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.viewModel.isConnectingScreen = true
        self.viewModel.loadData()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewModel.isConnectingScreen = false
    }
    
    private func setupUI() {
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.besideDatesView)
        
        self.besideDatesView.sideAnchor(for: [.top, .left, .right],
                                        to: self.view,
                                        edgeInsets: .init(top: Layout.edgeInsets.top, left: 0, bottom: 0, right: 0),
                                        considerSafeArea: true)
        self.besideDatesView.sizeAnchor(height: Constants.besideDateBarHeight)
        
        self.besideDatesView.columnAnchor(view: self.tableView)
        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
    }
    
    @objc private func cancel() {
        self.viewModel.coordinator?.stop()
    }
}

extension AgendaViewController: BesideDatesViewDelegate {
    public func didSelectDate(at index: Int) {
        self._shouldChangeBesideDateBarContentOffset = false
        UIView.animate(withDuration: 0.3, animations: {
            let frame = self.tableView.rectForHeader(inSection: index)
            self.tableView.setContentOffset(CGPoint(x: 0, y: frame.origin.y), animated: false)
        }) {
            if $0 {
                self._shouldChangeBesideDateBarContentOffset = true
            }
        }
    }
    
    public func dates() -> [Date] {
        return self.viewModel.dates
    }
}

extension AgendaViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.dates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.cellModels(at: section).count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AgendaTableCell.reuseIdentifier, for: indexPath) as! AgendaTableCell
        cell.cellModel = self.viewModel.dateOrderedData[indexPath.section][indexPath.row]
        cell.delegate = self
        return cell
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let dateSectionView = tableView.dequeueReusableHeaderFooterView(withIdentifier: DateSectionView.reuseIdentifier) as! DateSectionView
        dateSectionView.date = self.viewModel.dates[section]
        return dateSectionView
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return DateSectionView.Constants.height
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self._shouldChangeBesideDateBarContentOffset else { return }

        self.besideDatesView.moveTo(index: self.tableView.firstVisibleHeaderIndex)
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return DateSectionView.Constants.height
    }
}

extension AgendaViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let data = self.viewModel.dateOrderedData[indexPath.section][indexPath.row]
        self.viewModel.coordinator?.openDocument(url: data.url, location: data.heading.location)
    }
}

extension AgendaViewController: AgendaTableCellDelegate {
    public func didTapActionButton(cellModel: AgendaCellModel) {
//        let actionsViewController = ActionsViewController()
        
//        actionsViewController.title = L10n.Agenda.Actions.title
        
//        actionsViewController.addAction(icon: nil, title: L10n.Agenda.Actions.markDone) { viewController in
//            viewController.dismiss(animated: true, completion: {
//
//            })
//        }
        
//        actionsViewController.addAction(icon: nil, title: L10n.Agenda.Actions.delay) { viewController in
//            viewController.dismiss(animated: true, completion: {
//                self.viewModel.coordinator?.showDateSelector(title: L10n.Agenda.Actions.delay, current: cellModel.dateAndTime, add: { [unowned self] dateAndTime in
//                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
//                    self.viewModel.updateDate(cellModel: cellModel, dateAndTime)
//                    }, delete: { [unowned self] in
//                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
//                        self.viewModel.updateDate(cellModel: cellModel, nil)
//                    }, cancel: {})
//            })
//        }
        
//        actionsViewController.setCancel { viewController in
//            viewController.dismiss(animated: true, completion: {
//                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
//            })
//        }
        
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
//            self.present(actionsViewController, animated: true, completion: nil)
//            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
//        }
    }
}

extension UITableView {
    var firstVisibleHeaderIndex: Int {
        let visibleRect = CGRect(x: 0, y: self.contentOffset.y, width: self.bounds.width, height: self.bounds.height)
        for i in 0..<self.numberOfSections {
            if self.rectForHeader(inSection: i).intersects(visibleRect) {
                return i
            }
        }
        return 0
    }
}

extension AgendaViewController: AgendaViewModelDelegate {
    public func didCompleteLoadAllData() {
        self.tableView.reloadData()
        
        self.besideDatesView.moveTo(index: self.viewModel.indexOfToday)
        
        self._shouldChangeBesideDateBarContentOffset = false
        let frame = self.tableView.rectForHeader(inSection: self.viewModel.indexOfToday)
        self.tableView.setContentOffset(CGPoint(x: 0, y: frame.origin.y), animated: false)
        self._shouldChangeBesideDateBarContentOffset = true
    }
    
    public func didFailed(_ error: Error) {
        log.error(error)
    }
}

private class DateSectionView: UITableViewHeaderFooterView {
    public static let reuseIdentifier = "DateSectionView"
    public struct Constants {
        static let height: CGFloat = 80
    }
    
    private let weekdayLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.body
        label.textAlignment = .left
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.body
        label.textAlignment = .left
        return label
    }()
    
    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var date: Date? {
        didSet {
            guard let date = date else { return }
            
            self.dateLabel.text = "\(date.day), \(date.monthStringLong),  \(date.weekOfYearString), \(date.year)"
            self.weekdayLabel.text = date.weekDayString
            
            if date.isToday() {
                self.dateLabel.textColor = InterfaceTheme.Color.interactive
                self.weekdayLabel.textColor = InterfaceTheme.Color.interactive
            } else {
                self.dateLabel.textColor = InterfaceTheme.Color.descriptive
                self.weekdayLabel.textColor = InterfaceTheme.Color.descriptive
            }
        }
    }
    
    private func setupUI() {
        self.contentView.addSubview(self.dateLabel)
        self.contentView.addSubview(self.weekdayLabel)
        
        self.weekdayLabel.sideAnchor(for: .left,
                                     to: self.contentView,
                                     edgeInset: Layout.edgeInsets.left)
        
        self.weekdayLabel.centerAnchors(position: .centerY, to: self.contentView)
        
        self.weekdayLabel.rowAnchor(view: self.dateLabel, space: 20)
        
        self.dateLabel.sideAnchor(for: .right, to: self.contentView, edgeInset: Layout.edgeInsets.right)
        
        self.weekdayLabel.lastBaselineAnchor.constraint(equalTo: self.dateLabel.lastBaselineAnchor).isActive = true
        
        self.contentView.backgroundColor = InterfaceTheme.Color.background1
    }
}
