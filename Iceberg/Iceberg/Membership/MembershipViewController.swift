//
//  MembershipViewController.swift
//  x3
//
//  Created by ian luo on 2019/12/17.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Interface
import Core

public class MembershipViewController: UIViewController {
    private var viewModel: MembershipViewModel!
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        return scrollView
    }()
    private let contentView: UIView = UIView()
    private let disposeBag = DisposeBag()
    
    public convenience init(viewModel: MembershipViewModel) {
        self.init()
        self.viewModel = viewModel
    }
    
    let titleImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = LabelStyle.description.create()
        
        label.interface { (me, theme) in
            let label = me as! UILabel
            label.textColor = theme.color.descriptive
            label.font = theme.font.body
        }

        label.numberOfLines = 0
        return label
    }()
    
    let functionDescription: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        
        label.interface { (me, theme) in
            let label = me as! UILabel
            label.textColor = theme.color.descriptive
            label.font = theme.font.body
        }
        
        return label
    }()
    
    let monthlyProductView: ProductDescriptionView = ProductDescriptionView()
    let yearlyProductView: ProductDescriptionView = ProductDescriptionView()
    
    let restoreButton: UIButton = {
        let button = UIButton()
        button.roundConer(radius: 8)
        
        button.interface { (me, theme) in
            let button = me as! UIButton
            button.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
            button.setTitleColor(theme.color.interactive, for: .normal)
        }
        
        return button
    }()
    
    lazy var subscriptionInfoButton: UIButton = {
        let button = UIButton()
        
        button.interface { (me, theme) in
            let button = me as! UIButton
            button.setTitleColor(theme.color.spotlight, for: .normal)
            button.titleLabel?.font = theme.font.title
        }
        
        button.setTitle(L10n.Membership.moreHelp, for: .normal)
        
        button.rx.tap.subscribe(onNext: {
            HelpPage.membership.open(from: self)
        }).disposed(by: self.disposeBag)
        
        return button
    }()
    
    lazy var privacyAndTermsView: UIView = {
        let view = UIStackView()
        view.distribution = .equalCentering
        
        let privacyButton = UIButton()
        privacyButton.setTitleColor(InterfaceTheme.Color.spotlight, for: .normal)
        privacyButton.setTitle(L10n.Setting.privacy, for: .normal)
        
        let termsOfServiceButton = UIButton()
        termsOfServiceButton.setTitleColor(InterfaceTheme.Color.spotlight, for: .normal)
        termsOfServiceButton.setTitle(L10n.Setting.terms, for: .normal)
        
        privacyButton.rx.tap.subscribe(onNext: {
            HelpPage.privacyPolicy.open(from: self)
        }).disposed(by: self.disposeBag)
        
        termsOfServiceButton.rx.tap.subscribe(onNext: {
            HelpPage.termsOfService.open(from: self)
        }).disposed(by: self.disposeBag)
        
        view.addArrangedSubview(privacyButton)
        view.addArrangedSubview(termsOfServiceButton)
        
        return view
    }()
    
    public override func viewDidLoad() {
        self.setupUI()
        self.bind()
        self.loadData()
    }
    
    private func setupUI() {
        self.title = L10n.Membership.title
        
        self.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentView)
        self.contentView.addSubview(self.titleImageView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.monthlyProductView)
        self.contentView.addSubview(self.yearlyProductView)
        self.contentView.addSubview(self.restoreButton)
        self.contentView.addSubview(self.functionDescription)
        self.contentView.addSubview(self.subscriptionInfoButton)
        self.contentView.addSubview(self.privacyAndTermsView)
        
        self.scrollView.allSidesAnchors(to: self.view, edgeInset: 0)
        self.contentView.allSidesAnchors(to: self.scrollView, edgeInset: 0)

        self.contentView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        
        self.titleImageView.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInset: 0)
        self.titleImageView.sizeAnchor(height: 50)
        
        self.titleImageView.columnAnchor(view: self.titleLabel, space: Layout.innerViewEdgeInsets.left, alignment: .centerX)
        self.titleLabel.sideAnchor(for: .left, to: self.contentView, edgeInset: Layout.innerViewEdgeInsets.left)
        
        self.titleLabel.columnAnchor(view: self.monthlyProductView, space: Layout.innerViewEdgeInsets.left, alignment: .centerX)
        self.monthlyProductView.sideAnchor(for: .left, to: self.contentView, edgeInset: Layout.innerViewEdgeInsets.left)
        
        self.monthlyProductView.columnAnchor(view: self.yearlyProductView, space: Layout.innerViewEdgeInsets.left, alignment: .centerX)
        self.yearlyProductView.sideAnchor(for: .left, to: self.contentView, edgeInset: Layout.innerViewEdgeInsets.left)
        
        self.yearlyProductView.columnAnchor(view: self.restoreButton, space: Layout.innerViewEdgeInsets.left, alignment: .centerX)
        self.restoreButton.sideAnchor(for: .left, to: self.contentView, edgeInset: Layout.innerViewEdgeInsets.left)
        self.restoreButton.sizeAnchor(height: 60)
        
        self.restoreButton.columnAnchor(view: self.functionDescription, space: 40, alignment: .centerX)
        self.functionDescription.sideAnchor(for: .left, to: self.contentView, edgeInsets: .init(top: 0, left: Layout.innerViewEdgeInsets.left, bottom: 0, right: 0))
        
        self.functionDescription.columnAnchor(view: self.subscriptionInfoButton, space: 40, alignment: .leading)
        self.subscriptionInfoButton.sideAnchor(for: .left, to: self.contentView, edgeInsets: .init(top: 0, left: Layout.innerViewEdgeInsets.left, bottom: 0, right: 0))
        
        self.subscriptionInfoButton.columnAnchor(view: self.privacyAndTermsView, space: 20)
        self.privacyAndTermsView.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInsets: .init(top: 0, left: Layout.innerViewEdgeInsets.left, bottom: 0, right: -Layout.innerViewEdgeInsets.right))
        
        self.interface { (me, theme) in
            me.view.backgroundColor = theme.color.background1
        }
        
        let cancelBarButtonItem = UIBarButtonItem(image: Asset.SFSymbols.chevronDown.image, style: .plain, target: nil, action: nil)
        cancelBarButtonItem.rx.tap.subscribe(onNext: { [unowned self] _ in
            self.dismiss(animated: true)
        }).disposed(by:self.disposeBag)
        self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        
        self.titleLabel.attributedText = NSAttributedString(string: L10n.Membership.letter, attributes: [NSAttributedString.Key.paragraphStyle : NSParagraphStyle.descriptive])
        
        let aString = NSMutableAttributedString(string: L10n.Membership.Function.title + "\n\n")
        let titleLength = aString.length
        for `case` in MemberFunctions.allCases {
            aString.append(NSAttributedString(string: "✓ ", attributes: [NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.spotlight]))
            aString.append(NSAttributedString(string: `case`.name + "\n", attributes: [NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptive]))
        }
        
        aString.addAttributes([NSAttributedString.Key.paragraphStyle : NSParagraphStyle.bulletDescriptive], range: NSRange(location: titleLength, length: aString.length - titleLength))
        
        self.functionDescription.attributedText = aString
        
        self.monthlyProductView.orderButton.setTitle(L10n.Membership.Price.monthly, for: .normal)
        self.yearlyProductView.orderButton.setTitle(L10n.Membership.Price.yearly, for: .normal)
    }
    
    private func bind() {
        self.viewModel
            .output
            .monthlyProduct
            .asDriver()
            .drive(onNext: { [weak self] product in
                self?.monthlyProductView.update(product: product)
            }).disposed(by: self.disposeBag)
        
        self.viewModel
            .output
            .yearlyProduct
            .asDriver()
            .drive(onNext: { [weak self] product in
                self?.yearlyProductView.update(product: product)
            }).disposed(by: self.disposeBag)
        
        self.monthlyProductView
            .orderButton
            .rx
            .tap
            .subscribe(onNext: { [weak self] in
                self?.view.showProcessingAnimation()
                self?.viewModel.purchaseMonthlyMembership()
            })
            .disposed(by: self.disposeBag)
        
        self.yearlyProductView
            .orderButton
            .rx
            .tap
            .subscribe(onNext: { [weak self] in
                self?.view.showProcessingAnimation()
                self?.viewModel.purchaseYearlyMembership()
            })
            .disposed(by: self.disposeBag)
        
        self.restoreButton
            .rx
            .tap
            .subscribe(onNext: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.view.showProcessingAnimation()
                strongSelf.viewModel.restore().subscribe(onNext: {
                    if $0.count > 0 {
                        strongSelf.viewModel.validateAllProducts().subscribe(onNext: {
                            strongSelf.view.hideProcessingAnimation()
                        }).disposed(by: strongSelf.disposeBag)
                    } else {
                        self?.view.hideProcessingAnimation()
                    }
                }).disposed(by: strongSelf.disposeBag)
            })
            .disposed(by: self.disposeBag)
        
        self.viewModel.output.errorOccurs.subscribe(onNext: { [weak self] error in
            self?.showAlert(title: "error", message: "\(error.localizedDescription)")
            self?.view.hideProcessingAnimation()
        }).disposed(by:self.disposeBag)
        
        self.viewModel.output.didFinishTransition.subscribe(onNext: { [weak self] in
            self?.view.hideProcessingAnimation()
        }).disposed(by: self.disposeBag)
    }
    
    private func loadData() {
        self.viewModel.loadProducts()
        self.restoreButton.setTitle(L10n.Membership.restore, for: .normal)
    }
}

class ProductDescriptionView: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        
        label.interface { (me, theme) in
            let label = me as! UILabel
            label.font = theme.font.body
            label.textColor = theme.color.interactive
        }
        
        return label
    }()
    
    let orderButton: UIButton = {
        let button = UIButton()
        
        button.interface { (me, theme) in
            let button = me as! UIButton
            
            button.setBackgroundImage(UIImage.create(with: theme.color.spotlight, size: .singlePoint), for: .normal)
            button.setTitleColor(theme.color.spotlitTitle, for: .normal)
            button.titleLabel?.font = theme.font.title
        }
        
        button.roundConer(radius: 8)
        return button
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        
        label.interface { (me, theme) in
            let label = me as! UILabel
            label.font = theme.font.footnote
            label.textColor = theme.color.descriptive
        }
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(self.titleLabel)
        self.addSubview(self.orderButton)
        self.addSubview(self.descriptionLabel)
        
        self.titleLabel.sideAnchor(for: [.left, .top, .right], to: self, edgeInset: 0)
        self.titleLabel.columnAnchor(view: self.orderButton, space: 10, alignment: .centerX)
        
        self.orderButton.sideAnchor(for: [.left, .right], to: self, edgeInset: 0)
        self.orderButton.columnAnchor(view: self.descriptionLabel, space: 10, alignment: .centerX)
        self.orderButton.sizeAnchor(height: 60)
        
        self.descriptionLabel.sideAnchor(for: [.left, .right, .bottom], to: self, edgeInset: 0)
    }
    
    public func update(product: Product) {
        self.titleLabel.text = product.name
        self.descriptionLabel.text = product.description
        
        if let expireDate = product.expireDate, expireDate.compare(Date()) == .orderedDescending  {
            self.orderButton.setTitle("\(L10n.Membership.ordered) (\(expireDate.shortDateString))", for: .normal)
            self.orderButton.isEnabled = false
        } else {
            if let price = product.price {
                self.orderButton.setTitle(price, for: .normal)
            }
            self.orderButton.isEnabled = true
        }
    }
}
