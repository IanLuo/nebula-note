//
//  MetadataItem+property.swift
//  Business
//
//  Created by ian luo on 2019/5/18.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

/*
 - 0 : "kMDItemFSContentChangeDate"
 - 1 : "NSMetadataUbiquitousSharedItemOwnerNameComponentsKey"
 - 2 : "NSMetadataUbiquitousSharedItemLastEditorNameComponentsKey"
 - 3 : "NSMetadataUbiquitousItemIsDownloadingKey"
 - 4 : "NSMetadataUbiquitousSharedItemRoleKey"
 - 5 : "BRMetadataItemFileObjectIdentifierKey"
 - 6 : "BRURLTagNamesKey"
 - 7 : "NSMetadataUbiquitousSharedItemOwnerNameKey"
 - 8 : "NSMetadataUbiquitousSharedItemLastEditorNameKey"
 - 9 : "NSMetadataUbiquitousSharedItemCurrentUserRoleKey"
 - 10 : "BRMetadataUbiquitousItemUploadingSizeKey"
 - 11 : "kMDItemDisplayName"
 - 12 : "NSMetadataItemIsUbiquitousKey"
 - 13 : "kMDItemContentTypeTree"
 - 14 : "NSMetadataUbiquitousItemPercentUploadedKey"
 - 15 : "BRMetadataItemParentFileIDKey"
 - 16 : "NSMetadataUbiquitousItemContainerDisplayNameKey"
 - 17 : "NSMetadataUbiquitousItemIsUploadingKey"
 - 18 : "NSMetadataUbiquitousItemDownloadingStatusKey"
 - 19 : "kMDItemFSSize"
 - 20 : "NSMetadataItemContainerIdentifierKey"
 - 21 : "kMDItemFSName"
 - 22 : "NSMetadataUbiquitousItemUploadingErrorKey"
 - 23 : "NSMetadataUbiquitousItemIsSharedKey"
 - 24 : "NSMetadataUbiquitousItemHasUnresolvedConflictsKey"
 - 25 : "kMDItemFSCreationDate"
 - 26 : "NSMetadataUbiquitousItemPercentDownloadedKey"
 - 27 : "kMDItemPath"
 - 28 : "NSMetadataUbiquitousItemIsExternalDocumentKey"
 - 29 : "NSMetadataUbiquitousSharedItemPermissionsKey"
 - 30 : "NSMetadataUbiquitousItemURLInLocalContainerKey"
 - 31 : "NSMetadataUbiquitousItemDownloadingErrorKey"
 - 32 : "kMDItemURL"
 - 33 : "NSMetadataUbiquitousSharedItemCurrentUserPermissionsKey"
 - 34 : "NSMetadataUbiquitousItemIsUploadedKey"
 - 35 : "kMDItemContentType"
 - 36 : "NSMetadataUbiquitousItemIsDownloadedKey"
 - 37 : "NSMetadataUbiquitousItemDownloadRequestedKey"
 - 38 : "BRMetadataUbiquitousItemDownloadingSizeKey"
 */
extension NSMetadataItem {
    public var isUbiquitouse: Bool? {
        return self.value(forAttribute: "NSMetadataItemIsUbiquitousKey") as? Bool
    }
    
    public var parentFileID: String? {
        return self.value(forAttribute: "BRMetadataItemParentFileIDKey") as? String
    }
    
    public var fileIdentifier: String? {
        return self.value(forAttribute: "BRMetadataItemFileObjectIdentifierKey") as? String
    }
    
    public var containerIdentifier: String? {
        return self.value(forAttribute: "NSMetadataItemContainerIdentifierKey") as? String
    }
    
    public var containerDisplayName: String? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemContainerDisplayNameKey") as? String
    }
    
    public var url: URL? {
        return self.value(forAttribute: "kMDItemURL") as? URL
    }
    
    public var tags: Any? {
        return self.value(forAttribute: "BRURLTagNamesKey")
    }
    
    public var path: String? {
        return self.value(forAttribute: "kMDItemPath") as? String
    }
    
    public var fileSize: Int? {
        return self.value(forAttribute: "kMDItemFSSize") as? Int
    }
    
    public var fileName: String? {
        return self.value(forAttribute: "kMDItemFSName") as? String
    }
    
    public var contentType: String? {
        return self.value(forAttribute: "kMDItemContentType") as? String
    }
    
    public var creatingDate: Date? {
        return self.value(forAttribute: "kMDItemFSCreationDate") as? Date
    }
    
    public var changeDate: Date? {
        return self.value(forAttribute: "kMDItemFSContentChangeDate") as? Date
    }
    
    public var isInConflict: Bool? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemHasUnresolvedConflictsKey") as? Bool
    }
    
    // share
    public var isShared: Bool? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemIsSharedKey") as? Bool
    }
    
    public var sharedItemCurrentUserRole: String? {
        return self.value(forAttribute: "NSMetadataUbiquitousSharedItemCurrentUserRoleKey") as? String
    }
    
    public var sharedItemLastEditorName: String? {
        return self.value(forAttribute: "NSMetadataUbiquitousSharedItemLastEditorNameKey") as? String
    }
    
    public var sharedItemOwnerName: String? {
        return self.value(forAttribute: "NSMetadataUbiquitousSharedItemOwnerNameKey") as? String
    }
    
    public var sharedItemRole: String? {
        return self.value(forAttribute: "NSMetadataUbiquitousSharedItemRoleKey") as? String
    }
    
    public var lastEditorNameComponents: Any? {
        return self.value(forAttribute: "NSMetadataUbiquitousSharedItemLastEditorNameComponentsKey")
    }
    
    // download
    public var isDownloading: Bool? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemIsDownloadingKey") as? Bool
    }
    
    public var downloadPercentage: Int? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemPercentDownloadedKey") as? Int
    }
    
    public var isDownloaded: Bool? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemIsDownloadedKey") as? Bool
    }
    
    public var isDownloadingRequested: Bool? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemDownloadRequestedKey") as? Bool
    }
    
    public var downloadingStatus: String? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemDownloadingStatusKey") as? String
    }
    
    public var downloadingSize: Int? {
        return self.value(forAttribute: "BRMetadataUbiquitousItemDownloadingSizeKey") as? Int
    }
    
    public var downloadingError: Error? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemDownloadingErrorKey") as? Error
    }
    
    // upload
    public var uploadingError: Error? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemUploadingErrorKey") as? Error
    }
    
    public var isUploaded: Bool? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemIsUploadedKey") as? Bool
    }
    
    public var isUploading: Bool? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemIsUploadingKey") as? Bool
    }
    
    public var uploadPercentage: Int? {
        return self.value(forAttribute: "NSMetadataUbiquitousItemPercentUploadedKey") as? Int
    }
    
    public var uploadingSize: Int? {
        return self.value(forAttribute: "BRMetadataUbiquitousItemUploadingSizeKey") as? Int
    }
}
