//
//  Location.swift
//  Business
//
//  Created by ian luo on 2019/1/12.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import CoreLocation
import Result

public enum LocationError: Error {
    case timeout
    case unAuthorized
    case failed(String)
}

public class Location: NSObject, CLLocationManagerDelegate {
    private var responseReceived = false
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.distanceFilter = kCLDistanceFilterNone
        manager.delegate = self
        return manager
    }()
    
    private var completionAction: ((Result<CLPlacemark, LocationError>) -> Void)?
    private var timeout: TimeInterval
    public init(timeout: TimeInterval, completion action: @escaping (Result<CLPlacemark, LocationError>) -> Void) {
        self.timeout = timeout
        self.completionAction = action
        super.init()
    }
    
    public func start() {
        authorizationHandler()
    }
    
    private var keeper: Any?
    private func authorizationHandler() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            keeper = self
            locationManager.requestWhenInUseAuthorization()
        case .denied: fallthrough
        case .restricted: completionAction?(.failure(LocationError.unAuthorized)); self.responseReceived = true
        case .authorizedWhenInUse: fallthrough
        case .authorizedAlways: startLocate(timeout: timeout)
        }
    }
    
    private func startLocate(timeout: TimeInterval) {
        locationManager.startUpdatingLocation()
        responseReceived = false
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeout) {
            if !self.responseReceived {
                self.completionAction?(.failure(LocationError.timeout))
                self.locationManager.stopUpdatingLocation()
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        responseReceived = true
        locationManager.stopUpdatingLocation()
        if let location = locations.last {
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: { [weak self] in
                guard let placemark = $0?.last else { self?.completionAction?(.failure(LocationError.failed("no result"))); return }
                
                self?.completionAction?(.success(placemark))
                
                if let error = $1 {
                    self?.completionAction?(.failure(LocationError.failed(error.localizedDescription)))
                }
            })
        }
    }
    
    public func reverseLocation(for location: CLLocationCoordinate2D, completion: @escaping ([CLPlacemark]?, Error?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude),
                                            completionHandler: { placemark, error in
                                                
            completion(placemark, error)
        })
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.completionAction?(.failure(LocationError.failed(error.localizedDescription)))
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        keeper = nil
        authorizationHandler()
    }
}

