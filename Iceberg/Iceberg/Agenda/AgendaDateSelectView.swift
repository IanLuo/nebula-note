//
//  BesideDatesView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/26.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public protocol AgendaDateSelectViewDelegate: class {
    func didSelectDate(at index: Int)
    func dates() -> [Date]
}

public class AgendaDateSelectView: UIView {
    public weak var delegate: AgendaDateSelectViewDelegate?
    
    public var currentIndex: Int = 0
        
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.interface({ (me, theme) in
            me.backgroundColor = theme.color.background1
        })
        collectionView.register(DateCell.self, forCellWithReuseIdentifier: DateCell.reuseIdentifier)
        return collectionView
    }()
    
    public func reload() {
        self.collectionView.reloadData()
        self.moveTo(index: 0)
    }
    
    public func moveTo(index: Int) {
        self.currentIndex = index
        self.collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: UICollectionView.ScrollPosition.centeredHorizontally)
        if let frame = self.collectionView.layoutAttributesForItem(at: IndexPath(row: index, section: 0))?.frame {
            self.collectionView.scrollRectToVisible(frame, animated: false)
        } else {
            self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: UICollectionView.ScrollPosition.centeredHorizontally, animated: false)
        }
        self.delegate?.didSelectDate(at: index)
    }
    
    public init() {
        super.init(frame: .zero)
        
        self.addSubview(self.collectionView)
        
        self.collectionView.allSidesAnchors(to: self, edgeInset: 0)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AgendaDateSelectView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.currentIndex = indexPath.row
        self.delegate?.didSelectDate(at: indexPath.row)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: Layout.edgeInsets.right)
    }
}

extension AgendaDateSelectView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.delegate?.dates().count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateCell.reuseIdentifier, for: indexPath) as! DateCell
        cell.update(date: self.delegate!.dates()[indexPath.row])
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension AgendaDateSelectView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width / 5,
                      height: collectionView.bounds.height)
    }
}

private class DateCell: UICollectionViewCell {
    static let reuseIdentifier = "DateCell"
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    public let todayLabel: UILabel = {
        let label = UILabel()
        label.text = "•"
        label.textAlignment = .center
        
        label.interface({ (me, theme) in
            let me = me as! UILabel
            me.font = theme.font.title
        })
        return label
    }()
    
    private let background: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private var date: Date = Date()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.background)
        self.contentView.addSubview(self.todayLabel)
        self.contentView.addSubview(self.titleLabel)
        
        self.background.allSidesAnchors(to: self.contentView, edgeInset: 5)

        self.titleLabel.allSidesAnchors(to: self.contentView, edgeInset: 0)
        
        self.todayLabel.sideAnchor(for: .bottom, to: self, edgeInset: 5)
        self.todayLabel.centerAnchors(position: .centerX, to: self.contentView)
        
        self.interface { [weak self] (me, theme) in
            guard let s = self else { return }
            let isSelected = s.isSelected
            s.isSelected = isSelected // triger update interface when change interface theme
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.updateFor(isSelected: isSelected)
        }
    }
    
    public func update(date: Date) {
        self.date = date
        
        self.updateFor(isSelected:  self.isSelected)
        
        self.todayLabel.isHidden = !date.isToday()
    }
    
    private func updateFor(isSelected: Bool) {
        let weekString = self.date.weekDayShortString
        let dateString = "\(self.date.day)"
        let string = "\(weekString)\n\(dateString)"
        let attr = NSMutableAttributedString(string: string)
        
        if isSelected {
            attr.addAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.spotlitTitle,
                                NSAttributedString.Key.font : InterfaceTheme.Font.footnote],
                               range: (string as NSString).range(of: weekString))
            attr.addAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.spotlitTitle,
                                NSAttributedString.Key.font : InterfaceTheme.Font.title],
                               range: (string as NSString).range(of: dateString))
            background.backgroundColor = InterfaceTheme.Color.spotlight
            self.todayLabel.textColor = InterfaceTheme.Color.spotlitTitle
        } else {
            attr.addAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptive,
                                NSAttributedString.Key.font : InterfaceTheme.Font.footnote],
                               range: (string as NSString).range(of: weekString))
            attr.addAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptive,
                                NSAttributedString.Key.font : InterfaceTheme.Font.title],
                               range: (string as NSString).range(of: dateString))
            background.backgroundColor = InterfaceTheme.Color.background2
            self.todayLabel.textColor = InterfaceTheme.Color.descriptive
        }
        
        self.titleLabel.attributedText = NSAttributedString(attributedString: attr)
    }
    
    public init() {
        super.init(frame: .zero)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
