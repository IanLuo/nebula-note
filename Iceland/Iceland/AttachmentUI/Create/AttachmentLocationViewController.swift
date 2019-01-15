//
//  AttachmentLocationViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit
import Business

public class AttachmentLocationViewController: AttachmentViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showLocationPicker()
    }
    
    let actionsViewController = ActionsViewController()
    
    private func showLocationPicker() {
        let mapView = MKMapView()

        actionsViewController.accessoryView = mapView
        
        actionsViewController.title = "Find your location".localizable
        
        mapView.sizeAnchor(width: self.view.bounds.width, height: self.view.bounds.width)
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        
        actionsViewController.addAction(icon: nil, title: "current location".localizable) { viewController in
            self.showCurrentLocation(on: mapView, animated: true)
        }
        
        actionsViewController.setCancel { viewController in
            self.viewModel.dependency?.stop()
        }
        
        actionsViewController.addAction(icon: nil, title: "save", style: ActionsViewController.Style.highlight) { viewController in
            let jsonEncoder = JSONEncoder()
            do {
                let data = try jsonEncoder.encode(mapView.centerCoordinate)
                if let string = String(data: data, encoding: String.Encoding.utf8) {
                    self.viewModel.save(content: string, type: Attachment.AttachmentType.location, description: "location choosen by user")
                } else {
                    log.error("can't encode for location: \(mapView.centerCoordinate)")
                }
            } catch {
                log.error(error)
            }
        }
        
        self.view.addSubview(actionsViewController.view)
        
        self.showCurrentLocation(on: mapView, animated: false)
    }
    
    private func showCurrentLocation(on map: MKMapView, animated: Bool) {
        let location = Location(timeout: 10, completion: { result in
            switch result {
            case .success(let placeMark):
                if let coordinate = placeMark.location?.coordinate {
                    map.setCenter(coordinate, animated: animated)
                    map.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)), animated: animated)
                } else {
                    log.error("can't get location")
                }
            case .failure(let error):
                log.error(error)
            }
        })
        
        location.start()
    }
    
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
        self.viewModel.dependency?.stop(animated: false)
    }
    
    public func didFailToSave(error: Error, content: String, type: Attachment.AttachmentType, descritpion: String) {
        log.error(error)
    }
}

extension CLLocationCoordinate2D: Codable {
    public enum Keys: CodingKey {
        case longitude
        case latitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        self.init()
        self.latitude = try container.decode(Double.self, forKey: CLLocationCoordinate2D.Keys.latitude)
        self.longitude = try container.decode(Double.self, forKey: CLLocationCoordinate2D.Keys.longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(self.latitude, forKey: CLLocationCoordinate2D.Keys.latitude)
        try container.encode(self.longitude, forKey: CLLocationCoordinate2D.Keys.longitude)
    }
}
