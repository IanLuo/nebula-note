//
//  AttachmentManagerViewController.swift
//  Icetea
//
//  Created by ian luo on 2020/2/6.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import Core
import RxDataSources
import Interface

public class AttachmentManagerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private var viewModel: AttachmentManagerViewModel!
    private var isSelectMode: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    private let disposeBag = DisposeBag()
    
    public convenience init(viewModel: AttachmentManagerViewModel) {
        self.init()
        self.viewModel = viewModel
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        return collectionView
    }()
    
    public override func viewDidLoad() {
        self.setupUI()
        
        self.bind()
    }
    
    private func setupUI() {
        self.view.addSubview(self.collectionView)
        
        self.collectionView.allSidesAnchors(to: self.view, edgeInset: 0)
    }
    
    private func bind() {
        let datasource = RxCollectionViewSectionedAnimatedDataSource<AttachmentManagerSection>(configureCell: { (datasource, collectionView, indexPath, cellModel) -> UICollectionViewCell in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentManagerCell.reuseIdentifier, for: indexPath) as! AttachmentManagerCell
            
            cell.configure(cellModel: cellModel)
            
            return cell
        })
        
        self.viewModel
            .output
            .attachments
            .asDriver()
            .drive(self.collectionView.rx.items(dataSource: datasource))
            .disposed(by: self.disposeBag)
        
        self.isSelectMode.subscribe(onNext: { [weak self] isSelectMode in
            self?.updateRightBarButtonItems(isSelectMode: isSelectMode)
        }).disposed(by: self.disposeBag)
    }
    
    private func updateRightBarButtonItems(isSelectMode: Bool) {
        if isSelectMode {
            let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
            cancelButton.rx.tap.subscribe(onNext: { [weak self] in
                self?.isSelectMode.accept(false)
            }).disposed(by: self.disposeBag)
            
            let deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: nil, action: nil)
            deleteButton.tintColor = InterfaceTheme.Color.warning
            deleteButton.rx.tap.subscribe(onNext: { [weak self] in
                self?.deleteSelectedItems()
            }).disposed(by: self.disposeBag)
            
            self.navigationItem.rightBarButtonItems = [deleteButton, cancelButton]
        } else {
            let selectButton = UIBarButtonItem(title: "Select", style: .plain, target: nil, action: nil)
            selectButton.rx.tap.subscribe(onNext: { [weak self] in
                self?.isSelectMode.accept(true)
            }).disposed(by: self.disposeBag)
            
            self.navigationItem.rightBarButtonItem = selectButton
        }
    }
    
    private func deleteSelectedItems() {
        let indexs = self.collectionView.indexPathsForSelectedItems?.map {
            $0.row
        } ?? []
        
        self.viewModel.delete(indexs: indexs)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let side = collectionView.bounds.width / 3
        return CGSize(width: side, height: side)
    }
}
