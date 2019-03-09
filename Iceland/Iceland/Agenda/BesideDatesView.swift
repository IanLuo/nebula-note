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

public protocol BesideDatesViewDelegate: class {
    func didSelectDate(date: Date)
}

public class BesideDatesView: UIView {
    public weak var delegate: BesideDatesViewDelegate?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = InterfaceTheme.Color.background1
        collectionView.register(DateCell.self, forCellWithReuseIdentifier: DateCell.reuseIdentifier)
        return collectionView
    }()
    
    public var currentDate: Date
    
    public func moveToToday(animated: Bool) {
        self.collectionView.selectItem(at: IndexPath(row: 500, section: 0), animated: animated, scrollPosition: UICollectionView.ScrollPosition.centeredHorizontally)
        
        self.currentDate = Date()
        self.delegate?.didSelectDate(date: Date())
    }
    
    public init() {
        self.currentDate = Date()
        
        super.init(frame: .zero)
        
        self.addSubview(self.collectionView)
        
        self.collectionView.frame = self.bounds
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BesideDatesView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let offset = indexPath.row - 500
        
        self.currentDate = Date().dayAfter(offset)
        self.delegate?.didSelectDate(date: self.currentDate)
    }
}

extension BesideDatesView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 999
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateCell.reuseIdentifier, for: indexPath) as! DateCell
        let offset = indexPath.row - 500
        cell.update(offset: offset)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension BesideDatesView: UICollectionViewDelegateFlowLayout {
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
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.title
        return label
    }()
    
    private var date: Date = Date()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.todayLabel)
        self.contentView.addSubview(self.titleLabel)

        self.titleLabel.allSidesAnchors(to: self.contentView, edgeInset: 0)
        self.todayLabel.sideAnchor(for: .bottom, to: self, edgeInset: 16)
        self.todayLabel.centerAnchors(position: .centerX, to: self.contentView)
        
//        let unit = frame.width / 5 / 11
        
        self.setBorder(position: [.top, .bottom, .left],
                       style: .solid,//Border.Style.dash(unit, unit * 10),
                       color: InterfaceTheme.Color.background3,
                       width: 0.5,//10,
                       insets: .none)//Border.Insect.tail(unit * 10))
    }
    
    override var isSelected: Bool {
        didSet {
            self.updateFor(isSelected: isSelected)
        }
    }
    
    public func update(offset: Int) {
        self.date = Date().dayAfter(offset)
        
        self.updateFor(isSelected: self.isSelected)
        
        self.todayLabel.isHidden = !date.isToday()
    }
    
    private func updateFor(isSelected: Bool) {
        let weekString = self.date.weekDayShortString
        let dateString = "\(self.date.day)"
        let string = "\(weekString)\n\(dateString)"
        let attr = NSMutableAttributedString(string: string)
        
        if isSelected {
            attr.addAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.interactive,
                                NSAttributedString.Key.font : InterfaceTheme.Font.footnote],
                               range: (string as NSString).range(of: weekString))
            attr.addAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.interactive,
                                NSAttributedString.Key.font : InterfaceTheme.Font.title],
                               range: (string as NSString).range(of: dateString))
        } else {
            attr.addAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptive,
                                NSAttributedString.Key.font : InterfaceTheme.Font.footnote],
                               range: (string as NSString).range(of: weekString))
            attr.addAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptive,
                                NSAttributedString.Key.font : InterfaceTheme.Font.title],
                               range: (string as NSString).range(of: dateString))
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
