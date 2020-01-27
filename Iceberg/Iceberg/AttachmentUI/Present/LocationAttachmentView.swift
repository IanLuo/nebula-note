//
//  LocationAttachmentView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import MapKit

public class LocationAttachmentView: UIView, AttachmentViewProtocol {
    public var attachment: Attachment!
    
    public func size(for width: CGFloat) -> CGSize {
        return CGSize(width: width, height: width / 2)
    }
    
    public let mapView: MKMapView  = MKMapView()
    
    public func setup(attachment: Attachment) {
        self.mapView.isUserInteractionEnabled = false
        self.addSubview(self.mapView)
        self.mapView.allSidesAnchors(to: self, edgeInset: 0)
        
        do {
            let jsonDecoder = JSONDecoder()
            let data = try Data(contentsOf: attachment.url)
            let coordinate = try jsonDecoder.decode(CLLocationCoordinate2D.self, from: data)
            
            self.attachment = attachment
            mapView.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: false)
            let anno = MKPointAnnotation()
            anno.coordinate = coordinate
            mapView.addAnnotation(anno)
        } catch {
            log.error(error)
        }
    }
}
