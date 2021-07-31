//
//  AgendaViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface
import RxSwift

public protocol AgendaViewControllerDelegate: class {
    func didSelectDocument(url: URL, location: Int)
}

public class AgendaViewController: UIViewController {
    public struct Constants {
        static let besideDateBarHeight: CGFloat = 80
    }
    
    let viewModel: AgendaViewModel
    
    public weak var delegate: AgendaViewControllerDelegate?
    
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
    
    public init(viewModel: AgendaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        self.title = L10n.Agenda.title
        self.tabBarItem = UITabBarItem(title: L10n.Agenda.title, image: Asset.SFSymbols.calendar.image, tag: 0)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private let disposeBag = DisposeBag()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.interface { (me, theme) in
            me.view.backgroundColor = theme.color.background1
        }
               
        self.reloadUI()
        
        self.viewModel.loadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        self.viewModel.isConnectingScreen = true
        self.viewModel.loadData()
        
        self.viewModel.all.asDriver().drive(onNext: { [weak self] _ in
            self?.reloadUI()
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewModel.isConnectingScreen = false
    }
    
    private var dashboard: UIView?
    
    private func reloadUI() {
       self.dashboard = UIStackView(subviews: [
            UIStackView(subviews: [
                UIStackView(subviews: [
                    UIScrollView().sizeAnchor(height: 100).childBuilder(topView: self.view, bindTo: self.viewModel.tags.asDriver().asObservable(), builder: {
                UIStackView(subviews: $0.sorted(by: { $0.key < $1.key }).map { tagDict in
                            Padding(child: UIStackView(subviews: [
                                UILabel(text: "\(tagDict.value.count)").interface({ let l = $0 as! UILabel; l.font = $1.font.title; l.textColor = tagDict.value.count > 0 ? $1.color.interactive :  $1.color.descriptive}),
                                UILabel(text: tagDict.key).interface({ let l = $0 as! UILabel; l.font = $1.font.footnote; l.textColor = tagDict.value.count > 0 ? $1.color.interactive : $1.color.descriptive})
                            ], axis: .vertical), all: 30)
                                .sizeAnchor(width: 150, height: 100)
                                .roundConer(radius: Layout.cornerRadius)
                                .interface({ $0.backgroundColor = $1.color.background2 })
                                .tapGesture({ [weak self] in
                                    self?.showHeadings(tag: tagDict.key, from: $0)
                                })
                        }, spacing: 16)
                })], axis: .vertical, alignment: .fill).isHidden(observe: self.viewModel.tags.map({ $0.count == 0 })),
                UIStackView(subviews: [
                    UIScrollView().sizeAnchor(height: 100).childBuilder(topView: self.view, bindTo: self.viewModel.status.asDriver().asObservable(), builder: {
                        UIStackView(subviews: $0.sorted(by: { $0.key < $1.key }).map { statusDict in
                            Padding(child: UIStackView(subviews: [
                                UILabel(text: "\(statusDict.value.count)").interface({ let l = $0 as! UILabel; l.font = $1.font.title; l.textColor = statusDict.value.count > 0 ? $1.color.interactive : $1.color.descriptive}),
                                UILabel(text: statusDict.key).interface({ let l = $0 as! UILabel; l.font = $1.font.footnote; l.textColor = statusDict.value.count > 0 ? $1.color.interactive : $1.color.descriptive})
                            ], axis: .vertical), all: 30)
                                .sizeAnchor(width: 150, height: 100)
                                .roundConer(radius: Layout.cornerRadius)
                                .interface({ $0.backgroundColor = $1.color.background2 })
                                .tapGesture({ [weak self] in
                                    self?.showHeadings(status: statusDict.key, from: $0)
                                })
                        }, spacing: 16)
                })], axis: .vertical, alignment: .fill).isHidden(observe: self.viewModel.status.map({ $0.count == 0 }))
            ], axis: isPhone ? .vertical : .horizontal, distribution: .fillEqually, alignment: .fill, spacing: 20),
            
            UIStackView(subviews: [
                UIStackView(subviews: [
                    UIView().childBuilder(topView: self.view, bindTo: self.viewModel.scheduled.asDriver().asObservable(), position: .center, builder: { scheduled in
                        UIStackView(subviews: [
                            UILabel(text: "\(scheduled.count)").interface({ let l = $0 as! UILabel; l.font = $1.font.largeTitle; l.textColor = scheduled.count > 0 ? $1.color.interactive : $1.color.descriptive}),
                            UILabel(text: L10n.Agenda.Sub.scheduled).interface({ let l = $0 as! UILabel; l.font = $1.font.title; l.textColor = scheduled.count > 0 ? $1.color.interactive : $1.color.descriptive})
                        ], axis: .vertical, distribution: .equalCentering, alignment: .center)
                    }).sizeAnchor(height: 100)
                        .roundConer(radius: Layout.cornerRadius)
                        .tapGesture({ [weak self] in
                            guard let strongSelf = self else { return }
                            self?.showHeadings(data: strongSelf.viewModel.scheduled.value.map { AgendaCellModel(searchResult: $0) }, from: $0)
                        })
                        .interface({ $0.backgroundColor = $1.color.background2 }),
                    UIView().childBuilder(topView: self.view, bindTo: self.viewModel.overdue.asDriver().asObservable(), position: .center, builder: { overdue in
                        UIStackView(subviews: [
                            UILabel(text: "\(overdue.count)").interface({ let l = $0 as! UILabel; l.font = $1.font.largeTitle; l.textColor = overdue.count > 0 ? $1.color.interactive : $1.color.descriptive }),
                            UILabel(text: L10n.Agenda.Sub.overdue).interface({ let l = $0 as! UILabel; l.font = $1.font.title; l.textColor = overdue.count > 0 ? $1.color.interactive : $1.color.descriptive})
                            ], axis: .vertical, distribution: .equalCentering, alignment: .center)
                        }).sizeAnchor(height: 100)
                            .roundConer(radius: Layout.cornerRadius)
                            .tapGesture({ [weak self] in
                                guard let strongSelf = self else { return }
                                self?.showHeadings(data: strongSelf.viewModel.overdue.value.map { AgendaCellModel(searchResult: $0) }, from: $0)
                        })
                        .interface({ $0.backgroundColor = $1.color.background2 }),
                ], distribution: .fillEqually, alignment: .fill, spacing: 20),
                UIStackView(subviews: [
                    UIView().childBuilder(topView: self.view, bindTo: self.viewModel.dueSoon.asDriver().asObservable(), position: .center, builder: { dueSoon in
                        UIStackView(subviews: [
                            UILabel(text: "\(dueSoon.count)").interface({ let l = $0 as! UILabel; l.font = $1.font.largeTitle; l.textColor = dueSoon.count > 0 ? $1.color.interactive : $1.color.descriptive}),
                            UILabel(text: L10n.Agenda.Sub.overdueSoon).interface({ let l = $0 as! UILabel; l.font = $1.font.title; l.textColor = dueSoon.count > 0 ? $1.color.interactive : $1.color.descriptive})
                        ], axis: .vertical, distribution: .equalCentering, alignment: .center)
                    }).sizeAnchor(height: 100)
                        .roundConer(radius: Layout.cornerRadius)
                        .tapGesture({ [weak self] in
                            guard let strongSelf = self else { return }
                            self?.showHeadings(data: strongSelf.viewModel.dueSoon.value.map { AgendaCellModel(searchResult: $0) }, from: $0)
                        })
                        .interface({ $0.backgroundColor = $1.color.background2 }),
                    UIView().childBuilder(topView: self.view, bindTo: self.viewModel.startSoon.asDriver().asObservable(), position: .center, builder: { startSoon in
                        UIStackView(subviews: [
                            UILabel(text: "\(startSoon.count)").interface({ let l = $0 as! UILabel; l.font = $1.font.largeTitle; l.textColor = startSoon.count > 0 ? $1.color.interactive : $1.color.descriptive}),
                            UILabel(text: L10n.Agenda.Sub.startSoon).interface({ let l = $0 as! UILabel; l.font = $1.font.title; l.textColor = startSoon.count > 0 ? $1.color.interactive : $1.color.descriptive})
                            ], axis: .vertical, distribution: .equalCentering, alignment: .center)
                        }).sizeAnchor(height: 100)
                            .roundConer(radius: Layout.cornerRadius)
                            .tapGesture({ [weak self] in
                                guard let strongSelf = self else { return }
                                self?.showHeadings(data: strongSelf.viewModel.startSoon.value.map { AgendaCellModel(searchResult: $0) }, from: $0)
                        })
                        .interface({ $0.backgroundColor = $1.color.background2 }),
                ], distribution: .fillEqually, alignment: .fill, spacing: 20),
            ], axis: isPhone ? .vertical : .horizontal, distribution: .fillEqually, alignment: .fill, spacing: 20),
        ], axis: .vertical, alignment: .fill, spacing: 20)

        if let dashboard = self.dashboard {
            tableView.tableHeaderView = Padding(child: dashboard, horizontal: 20)
        }
        
        self.view.addSubview(tableView)
        tableView.allSidesAnchors(to: self.view, edgeInset: 0, considerSafeArea: true)
        
        let rightItem = UIBarButtonItem(title: L10n.General.help, style: .plain, target: nil, action: nil)
        rightItem.rx.tap.subscribe(onNext: {
            HelpPage.agenda.open(from: self)
        }).disposed(by: self.disposeBag)
        self.navigationItem.rightBarButtonItem = rightItem
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let header = self.tableView.tableHeaderView {
            var frame = header.frame
            frame.size.height = header.systemLayoutSizeFitting(CGSize(width: self.view.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height
            header.frame = frame
            self.tableView.tableHeaderView = header
        }
    }
    
    @objc private func cancel() {
        self.viewModel.context.coordinator?.stop()
    }
    
    private func showHeadings(tag: String, from: UIView) {
        if let data = self.viewModel.tags.value[tag]?.map({ AgendaCellModel(searchResult: $0) }) {
            self.showFiteredHeadings(data: data, from: from)
        }
    }
    
    private func showHeadings(status: String, from: UIView) {
        if let data = self.viewModel.status.value[status]?.map({ AgendaCellModel(searchResult: $0) }) {
            self.showFiteredHeadings(data: data, from: from)
        }
    }
    
    private func showHeadings(data: [AgendaCellModel], from: UIView) {
        guard data.count > 0 else { return }
        self.showFiteredHeadings(data: data, from: from)
    }
    
    private func showFiteredHeadings(data: [AgendaCellModel], from: UIView) {
        let vc = FilteredItemsViewController(data: data)
        vc.onDocumentSelected.subscribe(onNext: {
            self.delegate?.didSelectDocument(url: $0.url, location: $0.location)
            self.dismiss(animated: true)
        }).disposed(by: self.disposeBag)
        
        let nav = Application.createDefaultNavigationControlller(root: vc)
        nav.modalPresentationStyle = .popover
        nav.popoverPresentationController?.sourceView = from
        self.present(nav, animated: true)
    }
}

extension AgendaViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.all.value.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AgendaTableCell.reuseIdentifier, for: indexPath) as! AgendaTableCell
        let cellModel = self.viewModel.all.value[indexPath.row]
        cell.cellModel = cellModel
        return cell
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let dateSectionView = tableView.dequeueReusableHeaderFooterView(withIdentifier: DateSectionView.reuseIdentifier) as! DateSectionView
        dateSectionView.date = Date()
        return dateSectionView
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return DateSectionView.Constants.height
    }
}

extension AgendaViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let data = self.viewModel.all.value[indexPath.row]
        
        if let dateAndTimeRange = data.dateAndTimeRange {
            self.delegate?.didSelectDocument(url: data.url, location: dateAndTimeRange.upperBound)
        } else {
            self.delegate?.didSelectDocument(url: data.url, location: data.heading.range.upperBound)
        }
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

extension AgendaViewController: EmptyContentPlaceHolderProtocol {
    public var text: String {
        return L10n.Selector.empty
    }
    
    public var viewToShowImage: UIView {
        return self.tableView
    }
    
    public var image: UIImage {
        return Asset.Assets.smallIcon.image.fill(color: InterfaceTheme.Color.secondaryDescriptive)
    }
}

private class DateSectionView: UITableViewHeaderFooterView {
    public static let reuseIdentifier = "DateSectionView"
    public struct Constants {
        static let height: CGFloat = 80
    }
    
    private lazy var weekdayLabel: UILabel = {
        let label = UILabel()
        
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.font = theme.font.body
            label.textColor = theme.color.descriptive
        })
        label.textAlignment = .left
        return label
    }()
    
    lazy var dateLabel: UILabel = {
        let label = UILabel()
        
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.font = theme.font.body
            label.textColor = theme.color.descriptive
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
            self.dateLabel.textColor = InterfaceTheme.Color.descriptive
            self.weekdayLabel.textColor = InterfaceTheme.Color.descriptive
        }
    }
    
    private func setupUI() {
        self.backgroundView = UIView()
        
        self.contentView.addSubview(self.dateLabel)
        self.contentView.addSubview(self.weekdayLabel)
                
        self.weekdayLabel.sideAnchor(for: [.top, .left, .bottom],
                                     to: self.contentView,
                                     edgeInset: Layout.edgeInsets.left)
                
        self.weekdayLabel.rowAnchor(view: self.dateLabel, space: 10)
        
        self.dateLabel.sideAnchor(for: [.top, .bottom],
                                  to: self.contentView,
                                  edgeInset: Layout.edgeInsets.left)
        
        self.interface { [weak self] (me, theme) in
            self?.contentView.backgroundColor = theme.color.background1
        }
    }
}
