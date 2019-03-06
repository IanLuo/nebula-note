//
//  OpenningFilesView.swift
//  Iceland
//
//  Created by ian luo on 2019/1/25.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol RecentFilesViewDelegate: class {
    func didSelectDocument(url: URL)
    func dataChanged(count: Int)
    func recentFilesData() -> [RecentDocumentInfo]
}

public class OpenningFilesView: UIView {
    private var eventObserver: EventObserver?
    public init(eventObserver: EventObserver?) {
        self.eventObserver = eventObserver
        super.init(frame: .zero)
        
        self.setupUI()
        
        self.eventObserver?.registerForEvent(on: self, eventType: UpdateDocumentEvent.self, queue: .main, action: { [weak self] (event: UpdateDocumentEvent) in
            self?.onFileInfoChanged(event: event)
        })
        
        self.eventObserver?.registerForEvent(on: self, eventType: DeleteDocumentEvent.self, queue: .main, action: { [weak self] (event: DeleteDocumentEvent) in
            self?.onFileInfoChanged(event: event)
        })
        
        self.eventObserver?.registerForEvent(on: self, eventType: OpenDocumentEvent.self, queue: .main, action: { [weak self] (event: OpenDocumentEvent) in
            self?.onFileInfoChanged(event: event)
        })
        
        self.eventObserver?.registerForEvent(on: self, eventType: RecentDocumentRenamedEvent.self, queue: .main, action: { [weak self] (event: RecentDocumentRenamedEvent) in
            self?.onFileInfoChanged(event: event)
        })
        
        self.eventObserver?.registerForEvent(on: self, eventType: ChangeDocumentCoverEvent.self, queue: .main, action: { [weak self] (changeDocumentEvent: ChangeDocumentCoverEvent) in
            self?.onCoverChange(event: changeDocumentEvent)
        })

    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.eventObserver?.unregister(for: self, eventType: ChangeDocumentCoverEvent.self)
    }

    public weak var delegate: RecentFilesViewDelegate?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = InterfaceTheme.Color.background1
        collectionView.register(OpenningFileCell.self, forCellWithReuseIdentifier: OpenningFileCell.reuseIdentifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        return collectionView
    }()
    
    public override func didMoveToSuperview() {
        if self.superview != nil {
            self.loadData()
        }
    }
    
    private var data: [RecentDocumentInfo] = []
    
    private func setupUI() {
        self.addSubview(self.collectionView)
        self.collectionView.allSidesAnchors(to: self, edgeInset: 0)
    }
    
    @objc private func onCoverChange(event: ChangeDocumentCoverEvent) {
        for (index, documentInfo) in self.data.enumerated() {
            if documentInfo.url.documentRelativePath == event.url.documentRelativePath {
                let indexPath = IndexPath(row: index, section: 0)
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    @objc private func onFileInfoChanged(event: Event) {
        self.loadData()
        self.collectionView.reloadData()
    }
    
    @objc private func onFileOpened(event: OpenDocumentEvent) {
//        if let url = notification.userInfo?["url"] as? URL {
            var oldIndex: Int = 0
            
            for (index, documentInfo) in self.data.enumerated() {
                if documentInfo.url.documentRelativePath == event.url.documentRelativePath {
                    oldIndex = index
                    self.data = self.delegate?.recentFilesData() ?? []
                    if self.data.count > 0 {
                        self.collectionView.moveItem(at: IndexPath(row: oldIndex, section: 0), to: IndexPath(row: 0, section: 0))
                    }
                    return
                }
            }
            
            self.data = self.delegate?.recentFilesData() ?? []
            self.collectionView.reloadData()
//        }
    }
    
    private func loadData() {
        self.data = self.delegate?.recentFilesData() ?? []
        self.delegate?.dataChanged(count: self.data.count)
    }
}

extension OpenningFilesView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OpenningFileCell.reuseIdentifier, for: indexPath) as! OpenningFileCell
        cell.coverView.image = self.data[indexPath.row].cover?.resize(upto: CGSize(width: collectionView.bounds.width, height: collectionView.bounds.width))
        cell.titleLabel.text = self.data[indexPath.row].name
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.didSelectDocument(url: self.data[indexPath.row].url)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.height * 2 / 3, height: collectionView.bounds.height)
    }
}

// MARK: - cell -

private class OpenningFileCell: UICollectionViewCell {
    static let reuseIdentifier: String = "OpenningFileCell"
    
    let coverView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.interactive
        label.font = InterfaceTheme.Font.footnote
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.backgroundColor = InterfaceTheme.Color.background2
        
        self.contentView.addSubview(self.coverView)
        self.contentView.addSubview(self.titleLabel)
        
        self.coverView.allSidesAnchors(to: self.contentView, edgeInset: 0)
        self.titleLabel.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 0)
        self.titleLabel.centerAnchors(position: .centerY, to: self.contentView)
    }
}

