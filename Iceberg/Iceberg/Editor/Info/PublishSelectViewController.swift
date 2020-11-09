//
//  ExportSelectViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import Core

public protocol PublishSelectViewControllerDelegate: class {
    func didSelectPublisher(_ type: PublishFactory.Publisher)
}

public class PublishSelectViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var _exportManager: ExportManager!
    private var _publishFactory: PublishFactory!
    
    public weak var delegate: PublishSelectViewControllerDelegate?
    
    private let _titleLabel: UILabel = {
        let label = UILabel()
        
        label.interface({ (me, theme) in
            let me = me as! UILabel
            me.font = theme.font.body
            me.textColor = theme.color.descriptive
        })
        label.text = L10n.Document.Export.title
        return label
    }()
    
    private lazy var _collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ExportItemCell.self, forCellWithReuseIdentifier: ExportItemCell.reuseIdentifier)
        return collectionView
    }()
    
    public init(exporterManager: ExportManager, publishFactory: PublishFactory) {
        super.init(nibName: nil, bundle: nil)
        self._exportManager = exporterManager
        self._publishFactory = publishFactory
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {        
        self.view.addSubview(self._collectionView)
        self.view.addSubview(self._titleLabel)
        
        self._titleLabel.sideAnchor(for: [.left, .right, .top], to: self.view, edgeInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
        
        self._titleLabel.columnAnchor(view: self._collectionView, space: 10)
        
        self._collectionView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
        
        self._collectionView.backgroundColor = InterfaceTheme.Color.background1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self._publishFactory.allPublishers.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExportItemCell.reuseIdentifier, for: indexPath) as! ExportItemCell
        
        cell.label.text = self._publishFactory.allPublishers[indexPath.row].title
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 80)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.didSelectPublisher(self._publishFactory.allPublishers[indexPath.row])
    }
}

private class ExportItemCell: UICollectionViewCell {
    static let reuseIdentifier = "ExportItemCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self._setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        
        label.interface({ (me, theme) in
            let me = me as! UILabel
            me.font = theme.font.footnote
            me.textColor = theme.color.interactive
        })
        return label
    }()
    
    private func _setupUI() {
        self.interface { (me, theme) in
            me.backgroundColor = theme.color.background2
        }
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        
        self.addSubview(self.label)
        
        self.label.centerAnchors(position: [.centerX, .centerY], to: self)
    }
}
