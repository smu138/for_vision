//
//  MapViewController.swift
//  Контроллер для показа сохраненных местоположений
//
//  Created by Admin on 02.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import RealmSwift
import MapKit


class MapViewController: UIViewController {
    
    var mainTabBarController: MainTabBarController?
    @IBOutlet weak var mapView: MKMapView!
    public var annotations: [CustomMapAnnotation] = []
    public var filterDates: [Date] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let mainTabBarController = tabBarController as? MainTabBarController else { fatalError("Main Tab Bar Controller Not Exist")}
        self.mainTabBarController = mainTabBarController
        
        bundleMapView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        removeAnnotationsFromMap()
        addAllAnnotationsOnMap {
            //just refreshing
        }
    }
    
    private func bundleMapView() -> Void
    {
        mapView.delegate = mainTabBarController?.mainService.mapViewDelegate
        
        mapView.register(FoundAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(FoundClusterView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        //для обратной связи
        mainTabBarController?.mainService.mapViewDelegate.viewControllerDelegate = self
    }
 
    //MARK: Add ALL Annotations
    public func addAllAnnotationsOnMap(completion: @escaping () -> ()) -> Void
    {
        mainTabBarController?.mainService.foundService.getAll(completion: { [unowned self] (resultM, error) in
            if error != nil {
                completion()
                return
            }
            
            guard let resultMs = resultM else {
                completion()
                return
            }

            resultMs.forEach { (foundM) in
                let annotation = CustomMapAnnotation(coordinate: foundM.clLocation.coordinate, title: foundM.code, subtitle: foundM.date?.toString(format: "yyyy-MM-dd"))
                DispatchQueue.main.async { [unowned self] in
                    self.annotations.append(annotation)
                }
            }

            self.centerMapOnLocation(clLocationCoordinate: resultMs.last?.clLocation.coordinate)
            DispatchQueue.main.async {
                completion()
                self.mapView.addAnnotations(self.annotations)
            }
        })
    }
    
    public func removeAnnotationsFromMap() -> Void
    {
        DispatchQueue.main.async {
            self.filterDates = []
            self.mapView.removeAnnotations(self.annotations)
            self.annotations = []
        }
    }
    
    //MARK: FILTER MAP by Days
    public func filterMapByDates(dates: [Date]!, completion: @escaping () -> ()) -> Void
    {
        removeAnnotationsFromMap()
        
        mainTabBarController?.mainService.foundService.getByDates(dates: dates, completion: { [unowned self] (customMapAnnotations, error) in
            if error != nil {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Ошибка", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                completion()
                return
            }

            self.filterDates = dates
            self.centerMapOnLocation(clLocationCoordinate: customMapAnnotations.last?.coordinate)
            
            DispatchQueue.main.async {
                completion()
                self.annotations = customMapAnnotations
                self.mapView.addAnnotations(customMapAnnotations)
            }

        })
    }

    //MARK: Map centering
    private func centerMapOnLocation(clLocationCoordinate: CLLocationCoordinate2D?) -> Void
    {
        if let clLocationCoordinate = clLocationCoordinate {
            let region = MKCoordinateRegion(center: clLocationCoordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            
            DispatchQueue.main.async {
                self.mapView.setRegion(region, animated: true)
            }
        }
    }

    @IBAction func getCurrentLocation(_ sender: Any) {
        mainTabBarController?.mainService.singleLocationRequestService.initService(completion: { (clLocation, error) in
            print(clLocation?.coordinate)
        })
    }
    
    //добавим тестовый регион для текущих координат юзера
    @IBAction func testAddRegion(_ sender: Any) {
        mainTabBarController?.mainService.addRegionForMonitoring()
    }

    @IBAction func testStopMonitoring(_ sender: Any) {
        //пройдем по всем регионам и удалим их и остановим мониторинг
        TestData.shared.regions.forEach { (region) in
            mainTabBarController?.mainService.regionService.stopMonitoringRegion(region: region)
        }
        
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let destination = segue.destination as? CalendarViewController {
            destination.mapViewControllerDelegate = self
        }
    }
    

}
