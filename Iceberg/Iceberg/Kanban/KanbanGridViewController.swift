//
//  KanbanGridViewController.swift
//  x3Note
//
//  Created by ian luo on 2021/3/30.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import Core
import RxSwift

public class KanbanGridViewController: UIViewController {
    private let viewModel: KanbanViewModel
    
    private var status: [String] = []
    
    public init(viewModel: KanbanViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("shouldn't be here")
    }
    
    private let contentView: UIScrollView = UIScrollView()
    
    private let disposeBag = DisposeBag()
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.contentView)
        self.contentView.allSidesAnchors(to: self.view, edgeInset: 0)
    }
    
    public func showStatus(_ status: [String]) {
        self.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let stackView = UIStackView(subviews: status.map { status in
            let column = KanbanColumn(viewModel: self.viewModel)
            column.sizeAnchor(width: isPhone ? 200 : 300)
            column.showStatus(status,
                              color: self.viewModel.isFinishedStatus(status: status) ? InterfaceTheme.Color.finished : InterfaceTheme.Color.unfinished)
            column.onUpdate = { heading in
                self.viewModel.update(heading: heading, newStatus: status).subscribe(onNext: { [weak self] in
                    self?.viewModel.loadHeadings(for: heading.planning ?? "")
                    self?.viewModel.loadHeadings(for: status)
                }).disposed(by: self.disposeBag)
            }
            return column
        }, axis: .horizontal, distribution: .equalSpacing, alignment: .fill, spacing: 20)
        
        self.contentView.addSubview(stackView)
        stackView.allSidesAnchors(to: self.contentView, edgeInset: 0)
        stackView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
    }
}

private class KanbanColumn: UIView, UITableViewDelegate, UITableViewDataSource, UIDropInteractionDelegate {
    let titleLabel: UILabel = UILabel().textAlignment(.center)
    private lazy var contentTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(KanbanColumnCell.self, forCellReuseIdentifier: KanbanColumnCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        return tableView
    }()
    
    var onUpdate: ((DocumentHeading) -> Void)?
    
    init(viewModel: KanbanViewModel) {
        self.viewModel = viewModel
        
        super.init(frame: .zero)
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.contentTableView)
        
        self.titleLabel.sideAnchor(for: [.left, .right, .top], to: self, edgeInset: 0)
        self.titleLabel.sizeAnchor(height: 44)
        self.titleLabel.columnAnchor(view: self.contentTableView)
        self.contentTableView.sideAnchor(for: [.left, .right, .bottom], to: self, edgeInset: 0)
        self.roundConer(radius: Layout.cornerRadius)
        
        self.contentTableView.interface { (me, theme) in
            let table = me as! UITableView
            table.backgroundColor = theme.color.background2
        }
        
        self.addInteraction(UIDropInteraction(delegate: self))
    }
    
    private var headings: [DocumentHeadingSearchResult] = []
    
    private let viewModel: KanbanViewModel
    
    func showStatus(_ title: String, color: UIColor) {
        self.titleLabel.text = title
        self.titleLabel.backgroundColor = color
        self.reload(title: title)
    }
    
    func reload(title: String? = nil) {
        self.headings = viewModel.headingsMap.value[title ?? self.titleLabel.text ?? ""] ?? []
        self.contentTableView.reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.headings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: KanbanColumnCell.reuseIdentifier, for: indexPath) as! KanbanColumnCell
        
        cell.configCell(searchResult: self.headings[indexPath.row])
        
        return cell
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return true
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: NSString.self) { value in
            do {
                let heading = try JSONDecoder().decode(DocumentHeading.self, from: (value.first as! NSString).data(using: String.Encoding.utf8.rawValue)!)
                self.onUpdate?(heading)
            } catch {
                log.error(error)
            }
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .move)
    }
    
    class KanbanColumnCell: UITableViewCell, UIDragInteractionDelegate {
        static let reuseIdentifier = "KanbanColumnCell"
        
        let textlabel: UILabel = UILabel().numberOfLines(0)
        
        let innerContentView = UIView()
        
        private var searchResult: DocumentHeadingSearchResult?
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.textlabel.interface { (me, theme) in
                let label = me as! UILabel
                label.textColor = theme.color.interactive
                label.font = isPhone ? theme.font.footnote : theme.font.body
            }
            
            self.interface { (me, theme) in
                let cell = me as! KanbanColumnCell
                cell.backgroundColor = theme.color.background2
                cell.innerContentView.backgroundColor = theme.color.background3
            }
            
            self.contentView.addSubview(self.innerContentView)
            
            self.innerContentView.allSidesAnchors(to: self.contentView, edgeInset: 10)
            self.innerContentView.addSubview(self.textlabel)
            self.textlabel.allSidesAnchors(to: self.innerContentView, edgeInset: 10)
            self.innerContentView.roundConer(radius: Layout.cornerRadius)
            
            let interaction = UIDragInteraction(delegate: self)
            interaction.isEnabled = true
            self.addInteraction(interaction)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func configCell(searchResult: DocumentHeadingSearchResult) {
            self.searchResult = searchResult
            self.textlabel.text = searchResult.heading.text
        }
        
        func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
            var headingString = ""
            if let heading = self.searchResult?.heading {
                do {
                    headingString = String(data: try JSONEncoder().encode(heading), encoding: .utf8) ?? ""
                } catch {
                    log.error(error)
                }
            }
            return [UIDragItem(itemProvider: NSItemProvider(object: headingString as NSString))]
        }
    }
}
