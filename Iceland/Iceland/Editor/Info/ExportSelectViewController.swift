//
//  ExportSelectViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public protocol ExportSelectViewControllerDelegate: class {

}

public class ExportSelectViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let _exportManager: ExportManager = ExportManager()
    
    public weak var delegate: ExportSelectViewControllerDelegate?
    
    private let _viewModel: DocumentEditViewModel!
    
    private lazy var _collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ExportItemCell.self, forCellWithReuseIdentifier: ExportItemCell.reuseIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    public init(viewModel: DocumentEditViewModel) {
        self._viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {        
        self.view.addSubview(self._collectionView)
        self._collectionView.backgroundColor = InterfaceTheme.Color.background2
        self._collectionView.allSidesAnchors(to: self.view, edgeInset: 0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self._exportManager.exportMethods.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExportItemCell.reuseIdentifier, for: indexPath) as! ExportItemCell
        
        cell.label.text = self._exportManager.exportMethods[indexPath.row].title
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 120)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self._exportManager.export(exportable: OrgExporter(url: self._viewModel.url), completion: { [weak self] url in
            guard let strongSelf = self else { return }
            strongSelf._exportManager.share(from: strongSelf, url: url)
        }) { error in
            // TODO:
        }
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
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.interactive
        return label
    }()
    
    private func _setupUI() {
        self.backgroundColor = InterfaceTheme.Color.background3
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        
        self.addSubview(self.label)
        
        self.label.centerAnchors(position: [.centerX, .centerY], to: self)
    }
}
