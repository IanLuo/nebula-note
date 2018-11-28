//
//  Page.swift
//  Iceland
//
//  Created by ian luo on 2018/11/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class PageViewController: UIViewController {
    private let textView: UITextView
    private let pageController: PageController
    
    public init() {
        pageController = PageController(parser: OutlineParser())
        
        self.textView = UITextView(frame: .zero, textContainer: pageController.textContainer)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.frame = self.view.bounds
        
        self.view.addSubview(self.textView)
        
        self.textView.text = """
* inbox
[[https://www.invisionapp.com/inside-design/color-accessibility-product-design?utm_campaign=Weekly%2520Digest&utm_source=hs_email&utm_medium=email&utm_content=66546546&_hsenc=p2ANqtz-_IzMtRKTy2QAwnuekFaqEkHghsbhiMwguIzI3Wa_iXNpUmX_-_qcO50lKJ4Vzjdg2St3YAd8Bvd5Vz1doJXA2ILGJKEQ&_hsmi=66547077][color accessibility guide]]
[[https://nshipster.com/nsdataasset/?utm_campaign%3DiOS%252BDev%252BWeekly&utm_medium%3Demail&utm_source%3DiOS%252BDev%252BWeekly%252BIssue%252B367][NSDataAsset]]
[[https://book.systemsapproach.org/foundation/problem.html][network system approch]]
[[https://medium.com/@adhorn/patterns-for-resilient-architecture-part-1-d3b60cd8d2b6][patterns for resilient architecture]]
new itunes connct api
:LOGBOOK:
- Note taken on [2018-07-26 Thu 09:37] \\ see if it is possible to make an app
:END:
** fastlane design
[[https://github.com/fastlane/fastlane][fastlane official site]]
[[https://fastlane.tools][fastlane docs]]
** iOS platform structure [[file:iOS_graph.org][project]]
1. list the structure
2. make a tool to do it
remember for random task
day plan
review the upcoming week
reschedule
priority of task
log state change
clear complete task
new task while a taks in progress, move to inbound queue
review and summary
use voice to record remember task is handy


*** swift package manager design ideas
dddd        sdfsfsd
asdfasdfsafa
        
*** asdfsafs
"""
    }
}


