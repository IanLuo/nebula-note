//
//  CreateDocumentActivity.swift
//  Business
//
//  Created by ian luo on 2019/11/2.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Intents
import CoreSpotlight
import Interface
import MobileCoreServices

public let createDocumentActivityType = "com.wod.activity.createDocument"

extension Document {
    public static func createDocumentActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: createDocumentActivityType)
        if #available(iOS 12.0, *) {
            activity.isEligibleForPrediction = true
            activity.suggestedInvocationPhrase = L10n.Activity.Document.CreateDocument.phrase
            activity.persistentIdentifier = NSUserActivityPersistentIdentifier(createDocumentActivityType)
        }
        
        activity.isEligibleForSearch = true
        
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributes.contentDescription = L10n.Activity.Document.CreateDocument.description
        
        activity.title = L10n.Activity.Document.CreateDocument.title
        activity.contentAttributeSet = attributes
        
        return activity
    }
}
