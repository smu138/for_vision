//
//  MapViewDelegate.swift
//
//  Created by Admin on 21.06.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation
import MapKit

class MapViewDelegate: NSObject, MKMapViewDelegate {
    
    private let mapViewDistance: CLLocationDistance = 10000.0

    weak var mainService: MainService?
    
    //для вызывающего контроллера
    weak var viewControllerDelegate: UIViewController?
    
    func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
        print("Map Start Rendering")
    }
    
    //MARK: Tap on mark events
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let foundClusterView = view as? FoundMClusterView else {
            return
        }
        if let clusterAnnotation = foundClusterView.getAnnotation() {
            mapView.showAnnotations(clusterAnnotation.memberAnnotations, animated: false)
            //mapView.setRegion(region, animated: true)
        }
    }
}

//MARK: методы хелперы
extension MapViewDelegate {
    
    public func getLastFoundRegion(completion: @escaping (MKCoordinateRegion?, Error?) -> ()) -> Void
    {

        mainService?.foundService.getLastFound(completion: { [unowned self] (foundMs, error) in
            if error != nil {
                completion(nil, error)
                return
            }
            
            //база найденных пустая - берем текузее местоположение юзера
            guard let foundM = foundMs else {

                self.mainService?.singleLocationRequestService.initService(completion: { [unowned self] (clLocation, singleLocationError) in
                    if singleLocationError != nil {
                        completion(nil, SingleRequestError.locationNotAvailable)
                        return
                    }
                    
                    guard let clLocation = clLocation else {
                        completion(nil, SingleRequestError.locationNotAvailable)
                        return
                    }

                    let region = MKCoordinateRegion(center: clLocation.coordinate, latitudinalMeters: self.mapViewDistance, longitudinalMeters: self.mapViewDistance)
                    
                    completion(region, nil)
                    return
                })
                
                return
            }
            
            let clLocation = foundM.clLocation
            let region = MKCoordinateRegion(center: clLocation.coordinate, latitudinalMeters: self.mapViewDistance, longitudinalMeters: self.mapViewDistance)
            
            completion(region, nil)
            return
        })
    }
}
