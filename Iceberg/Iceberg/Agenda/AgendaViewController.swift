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
import RxSwift

public class AgendaViewController: UIViewController {
    public struct Constants {
        static let besideDateBarHeight: CGFloat = 80
    }
    
    private let viewModel: AgendaViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AgendaTableCell.self, forCellReuseIdentifier: AgendaTableCell.reuseIdentifier)
        tableView.register(DateSectionView.self, forHeaderFooterViewReuseIdentifier: DateSectionView.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        
        tableView.interface { (me, theme) in
            tableView.backgroundColor = theme.color.background1
        }
        return tableView
    }()
    
    private lazy var agendaDateSelectView: AgendaDateSelectView = {
        let agendaDateSelectView = AgendaDateSelectView()
        agendaDateSelectView.delegate = self
        return agendaDateSelectView
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
        self.interface { (me, theme) in
            me.view.backgroundColor = theme.color.background1
        }
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.agendaDateSelectView)
        
        self.agendaDateSelectView.sideAnchor(for: [.top, .left, .right],
                                        to: self.view,
                                        edgeInsets: .init(top: Layout.edgeInsets.top,
                                                          left: 0,
                                                          bottom: 0,
                                                          right: 0),
                                        considerSafeArea: true)
        self.agendaDateSelectView.sizeAnchor(height: Constants.besideDateBarHeight)
        
        self.agendaDateSelectView.columnAnchor(view: self.tableView, space: 20)
        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
    }
    
    @objc private func cancel() {
        self.viewModel.coordinator?.stop()
    }
}

extension AgendaViewController: AgendaDateSelectViewDelegate {
    public func didSelectDate(at index: Int) {
        self.viewModel.loadData(for: index)
    }
    
    public func dates() -> [Date] {
        return self.viewModel.dates
    }
}

extension AgendaViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AgendaTableCell.reuseIdentifier, for: indexPath) as! AgendaTableCell
        let cellModel = self.viewModel.data[indexPath.row]
        cellModel.date = self.viewModel.dates[self.agendaDateSelectView.currentIndex]
        cell.cellModel = cellModel
        return cell
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let dateSectionView = tableView.dequeueReusableHeaderFooterView(withIdentifier: DateSectionView.reuseIdentifier) as! DateSectionView
        dateSectionView.date = self.viewModel.dates[self.agendaDateSelectView.currentIndex]
        return dateSectionView
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return DateSectionView.Constants.height
    }
}

extension AgendaViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let data = self.viewModel.data[indexPath.row]
        self.viewModel.coordinator?.openDocument(url: data.url, location: data.heading.location)
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
    public func didLoadData() {
        self.tableView.reloadData()
    }
    
    public func didCompleteLoadAllData() {
        self.agendaDateSelectView.moveTo(index: 0)
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
        
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.textColor = theme.color.descriptive
            label.font = theme.font.largeTitle
        })
        label.textAlignment = .left
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.textColor = theme.color.descriptive
            label.font = theme.font.largeTitle
        })
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
        self.backgroundView = UIView()
        
        self.contentView.addSubview(self.dateLabel)
        self.contentView.addSubview(self.weekdayLabel)
        
        self.weekdayLabel.sideAnchor(for: [.top, .left, .right],
                                     to: self.contentView,
                                     edgeInset: Layout.edgeInsets.left)
                
        self.weekdayLabel.columnAnchor(view: self.dateLabel, space: 10)
        
        self.dateLabel.sideAnchor(for: [.left, .right, .bottom],
                                  to: self.contentView,
                                  edgeInset: Layout.edgeInsets.left)
        
        self.interface { [weak self] (me, theme) in
            self?.contentView.backgroundColor = theme.color.background1
        }
    }
}
