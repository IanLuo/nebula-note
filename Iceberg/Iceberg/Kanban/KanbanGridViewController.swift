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
        
        self.status = status.sorted(by: { (s1, s2) -> Bool in
            switch (self.viewModel.isFinishedStatus(status: s1), self.viewModel.isFinishedStatus(status: s2)) {
            case (true, true):
                return s1 < s2
            case (false, false):
                return s1 < s2
            case (true, false):
                return false
            case (false, true):
                return true
            }
        })
        
        let stackView = UIStackView(subviews: self.status.filter({ [weak self] in
            self?.viewModel.ignoredStatus.value.contains($0) == false
        }).map { status in
            let column = KanbanColumn(viewModel: self.viewModel)
            column.sizeAnchor(width: isPhone ? 200 : 300)
            column.showStatus(status,
                              color: self.viewModel.isFinishedStatus(status: status) ? InterfaceTheme.Color.finished : InterfaceTheme.Color.unfinished)
            column.onUpdate = { heading in
                self.update(heading: heading, status: status)
            }
            
            column.didSelectCellActionButton = {
                self.showActions(heading: $0, from: $1)
            }
            return column
        }, axis: .horizontal, distribution: .equalSpacing, alignment: .fill, spacing: 10)
        
        self.contentView.addSubview(stackView)
        stackView.allSidesAnchors(to: self.contentView, edgeInset: 0)
        stackView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
    }
    
    private func showActions(heading: DocumentHeading, from: UIView) {
        let selector = SelectorViewController()
        
        for s in self.status {
            selector.addItem(attributedString: NSAttributedString(string: s, attributes: [NSAttributedString.Key.backgroundColor: OutlineTheme.planningStyle(isFinished: self.viewModel.isFinishedStatus(status: s)).buttonColor, NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.spotlitTitle]))
        }
        
        selector.onSelection = { index, viewController in
            viewController.dismiss(animated: true) {
                self.update(heading: heading, status: self.status[index])
            }
        }
        
        selector.present(from: self, at: from)
    }
    
    private func update(heading: DocumentHeading, status: String) {
        self.viewModel.update(heading: heading, newStatus: status).subscribe(onNext: { [weak self] in
            self?.viewModel.loadheadings([heading.planning ?? "", status])
        }).disposed(by: self.disposeBag)
    }
}

// MARK: -

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
    var didSelectCellActionButton: ((DocumentHeading, UIView) -> Void)?
    
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
        
        self.titleLabel.interface { (me, theme) in
            let label = me as! UILabel
            label.textColor = theme.color.spotlitTitle
        }
        
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
        self.headings = viewModel.headingsMap.value[title ?? self.titleLabel.text ?? ""]?.filter({ [weak self] in
            self?.viewModel.ignoredDocuments.value.contains($0.documentInfo.name) == false
        }).sorted(by: { (head1, head2) -> Bool in
            switch (head1.heading.priority, head2.heading.priority) {
            case (nil, nil):
                return head1.heading.text < head2.heading.text
            case (_, nil):
                return true
            case (nil, _):
                return false
            case (let p1?, let p2?):
                return p1 < p2
            }
        }) ?? []
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
        cell.onActionButtonTapped = {
            self.didSelectCellActionButton?($0, $1)
        }
        
        cell.onHeadingTapped = {
            let heading = self.headings[indexPath.row]
            self.viewModel.dependency.eventObserver.emit(OpenDocumentEvent(url: heading.documentInfo.url, location: heading.heading.location))
        }
        
        return cell
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return true
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        self.border(color: InterfaceTheme.Color.spotlight, width: 0)

        session.loadObjects(ofClass: NSString.self) { value in
            do {
                let heading = try JSONDecoder().decode(DocumentHeading.self, from: (value.first as! NSString).data(using: String.Encoding.utf8.rawValue)!)
                
                guard heading.planning != self.titleLabel.text else { return }
                self.onUpdate?(heading)
            } catch {
                log.error(error)
            }
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        self.border(color: InterfaceTheme.Color.spotlight, width: 2)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        self.border(color: InterfaceTheme.Color.spotlight, width: 0)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .move)
    }
    
    // MARK: - 
    
    class KanbanColumnCell: UITableViewCell, UIDragInteractionDelegate {
        static let reuseIdentifier = "KanbanColumnCell"
        
        let textlabel: UILabel = UILabel().numberOfLines(0)
        let documentNameLabel: UILabel = UILabel()
        let priorityLabel: UILabel = UILabel()
        let tagsView: UIScrollView = UIScrollView()
        let innerContentView = UIView()
        let actionButton: UIButton = UIButton()
        
        var onActionButtonTapped: ((DocumentHeading, UIButton) -> Void)?
        var onHeadingTapped: (() -> Void)?
        
        private let disposeBag = DisposeBag()
        
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
            
            self.documentNameLabel.interface { (me, theme) in
                let label = me as! UILabel
                label.font = theme.font.footnote
                label.textColor = theme.color.descriptive
            }
            
            self.priorityLabel.interface { (me, theme) in
                let label = me as! UILabel
                label.textColor = theme.color.spotlitTitle
                label.font = theme.font.footnote
            }
            
            self.actionButton.interface { (me, theme) in
                let button = me as! UIButton
                button.image(Asset.SFSymbols.ellipsis.image.fill(color: theme.color.interactive), for: .normal)
            }
            
            self.contentView.addSubview(self.innerContentView)
            
            self.innerContentView.allSidesAnchors(to: self.contentView, edgeInset: 10)
            self.innerContentView.roundConer(radius: Layout.cornerRadius)
            self.innerContentView.addSubview(self.textlabel)
            self.innerContentView.addSubview(self.documentNameLabel)
            self.innerContentView.addSubview(self.priorityLabel)
            self.innerContentView.addSubview(self.tagsView)
            self.innerContentView.addSubview(self.actionButton)
            
            self.actionButton.sideAnchor(for: [.right, .top], to: self.innerContentView, edgeInset: 10)
            self.priorityLabel.sideAnchor(for: [.top, .left], to: self.innerContentView, edgeInset: 10)
            self.actionButton.columnAnchor(view: self.documentNameLabel, space: 8, alignment: .right)
            self.documentNameLabel.sideAnchor(for: [.left, .right], to: self.innerContentView, edgeInset: 10)
            self.documentNameLabel.columnAnchor(view: self.textlabel, space: 8, alignment: .leading)
            self.textlabel.sideAnchor(for: [.left, .right], to: self.innerContentView, edgeInset: 10)
            self.textlabel.columnAnchor(view: self.tagsView, space: 8, alignment: .leading)
            self.tagsView.sideAnchor(for: [.leading, .bottom, .traling], to: self.innerContentView, edgeInset: 10).sizeAnchor(height: 20)
            
            let interaction = UIDragInteraction(delegate: self)
            interaction.isEnabled = true
            self.addInteraction(interaction)
            
            self.actionButton.rx.tap.subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                guard let heading = self?.searchResult?.heading else { return }
                self?.onActionButtonTapped?(heading, strongSelf.actionButton)
            }).disposed(by: self.disposeBag)
            
            let tap = UITapGestureRecognizer()
            tap.rx.event.subscribe(onNext: { event in
                if event.state == .ended {
                    self.onHeadingTapped?()
                }
            }).disposed(by: self.disposeBag)
            self.innerContentView.addGestureRecognizer(tap)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func showActions() {
        }
               
        func configCell(searchResult: DocumentHeadingSearchResult) {
            self.searchResult = searchResult
            self.textlabel.text = searchResult.heading.text.trimmingCharacters(in: CharacterSet.whitespaces)
            self.documentNameLabel.text = searchResult.documentInfo.name
            
            self.priorityLabel.text = searchResult.heading.priority
            if let priority = searchResult.heading.priority {
                self.priorityLabel.textColor = OutlineTheme.priorityStyle(priority).buttonColor
            }
            
            self.tagsView.constraint(for: .height)?.constant = self.searchResult?.heading.tags == nil ? 0 : 20
            
            self.tagsView.subviews.forEach { $0.removeFromSuperview() }
                        
            let stackView = UIStackView(subviews: (self.searchResult?.heading.tags?.compactMap {
                UILabel(text: " \($0) ").font(InterfaceTheme.Font.caption2).sizeAnchor(height: 20).roundConer(radius: Layout.cornerRadius).backgroundColor(InterfaceTheme.Color.background2).textColor(InterfaceTheme.Color.descriptive)
            } ?? []), spacing: 2)
            stackView.addArrangedSubview(UIView())
            
            self.tagsView.addSubview(stackView)
            stackView.allSidesAnchors(to: self.tagsView, edgeInset: 0)
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
