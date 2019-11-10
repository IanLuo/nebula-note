//
//  CaptureActivity.swift
//  Business
//
//  Created by ian luo on 2019/11/6.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Intents
import CoreSpotlight
import Interface
import MobileCoreServices

public let captureTextActivity = "com.wod.activity.captureText"
public let captureImageActivity = "com.wod.activity.image"
public let captureAudioActivity = "com.wod.activity.audio"
public let captureVideoActivity = "com.wod.activity.video"
public let captureSketchActivity = "com.wod.activity.sketch"
public let captureLinkActivity = "com.wod.activity.link"
public let captureLocationActivity = "com.wod.activity.location"

extension Attachment.Kind {
    fileprivate var activityType: String {
        switch self {
        case .text: return captureTextActivity
        case .link: return captureLinkActivity
        case .image: return captureImageActivity
        case .sketch: return captureSketchActivity
        case .audio: return captureAudioActivity
        case .video: return captureVideoActivity
        case .location: return captureLocationActivity
        }
    }
    
    fileprivate var title: String {
        switch self {
        case .text: return L10n.Activity.Document.CaptureTextActivity.title
        case .link: return L10n.Activity.Document.CaptureLinkActivity.title
        case .image: return L10n.Activity.Document.CaptureImageLibraryActivity.title
        case .sketch: return L10n.Activity.Document.CaptureSketchActivity.title
        case .audio: return L10n.Activity.Document.CaptureAudioActivity.title
        case .video: return L10n.Activity.Document.CaptureVideoActivity.title
        case .location: return L10n.Activity.Document.CaptureLocationActivity.title
        }
    }
    
    fileprivate var phrase: String {
        switch self {
        case .text: return L10n.Activity.Document.CaptureTextActivity.phrase
        case .link: return L10n.Activity.Document.CaptureLinkActivity.phrase
        case .image: return L10n.Activity.Document.CaptureImageLibraryActivity.phrase
        case .sketch: return L10n.Activity.Document.CaptureSketchActivity.phrase
        case .audio: return L10n.Activity.Document.CaptureAudioActivity.phrase
        case .video: return L10n.Activity.Document.CaptureVideoActivity.phrase
        case .location: return L10n.Activity.Document.CaptureLocationActivity.phrase
        }
    }
    
    fileprivate var message: String {
        switch self {
        case .text: return L10n.Activity.Document.CaptureTextActivity.description
        case .link: return L10n.Activity.Document.CaptureLinkActivity.description
        case .image: return L10n.Activity.Document.CaptureImageLibraryActivity.description
        case .sketch: return L10n.Activity.Document.CaptureSketchActivity.description
        case .audio: return L10n.Activity.Document.CaptureAudioActivity.description
        case .video: return L10n.Activity.Document.CaptureVideoActivity.description
        case .location: return L10n.Activity.Document.CaptureLocationActivity.description
        }
    }
}

extension Document {
    public static func createCaptureActivity(kind: Attachment.Kind) -> NSUserActivity {
        let activity = NSUserActivity(activityType: kind.activityType)
        
        if #available(iOS 12.0, *) {
            activity.isEligibleForPrediction = true
            activity.suggestedInvocationPhrase = kind.phrase
            activity.persistentIdentifier = NSUserActivityPersistentIdentifier(createDocumentActivityType)
        }
        
        activity.isEligibleForSearch = true
        
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributes.contentDescription = kind.message
        
        activity.title = kind.title
        activity.contentAttributeSet = attributes
        
        return activity
    }
}
