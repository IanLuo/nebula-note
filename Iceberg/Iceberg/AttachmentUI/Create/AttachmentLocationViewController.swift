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
import Core
import Interface

public class AttachmentLocationViewController: AttachmentViewController, AttachmentViewModelDelegate, MKMapViewDelegate {
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.delegate = self
        self.showLocationPicker()
        
        self.addChild(self.actionsViewController)
    }
    
    let actionsViewController = ActionsViewController()
    
    private func showLocationPicker() {
        let mapView = MKMapView()

        actionsViewController.accessoryView = mapView
        
        actionsViewController.title = L10n.Location.title
        
        mapView.sizeAnchor(width: self.view.bounds.width, height: self.view.bounds.width)
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.delegate = self
        
        actionsViewController.addAction(icon: nil, title: L10n.Location.current) { viewController in
            self.showCurrentLocation(on: mapView, animated: true)
        }
        
        actionsViewController.setCancel { viewController in
            self.viewModel.coordinator?.stop()
            self.delegate?.didCancelAttachment()
        }
        
        actionsViewController.addAction(icon: nil, title: L10n.General.Button.Title.save, style: ActionsViewController.Style.highlight) { viewController in
            let jsonEncoder = JSONEncoder()
            do {
                let data = try jsonEncoder.encode(mapView.centerCoordinate)
                if let string = String(data: data, encoding: String.Encoding.utf8) {
                    self.viewModel.save(content: string, kind: .location, description: "location choosen by user")
                } else {
                    log.error("can't encode for location: \(mapView.centerCoordinate)")
                }
            } catch {
                log.error(error)
            }
        }
        
        self.view.addSubview(actionsViewController.view)
        self.actionsViewController.view.allSidesAnchors(to: self.view, edgeInset: 0, considerSafeArea: true)
        self.actionsViewController.didMove(toParent: self)
        
        self.showCurrentLocation(on: mapView, animated: false)
    }
    
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapView.annotations.forEach { mapView.removeAnnotation($0) }
        let anno = MKPointAnnotation()
        anno.coordinate = mapView.centerCoordinate
        mapView.addAnnotation(anno)
    }
    
    private func showCurrentLocation(on map: MKMapView, animated: Bool) {
        let location = Location(timeout: 10, completion: { result in
            switch result {
            case .success(let placeMark):
                if let coordinate = placeMark.location?.coordinate {
                    map.annotations.forEach { map.removeAnnotation($0) }
                    map.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)), animated: animated)
                    let anno = MKPointAnnotation()
                    anno.coordinate = coordinate
                    map.addAnnotation(anno)
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
        self.viewModel.coordinator?.stop(animated: false)
    }
    
    public func didFailToSave(error: Error, content: String, kind: Attachment.Kind, descritpion: String) {
        log.error(error)
    }
}
