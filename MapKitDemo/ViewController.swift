//
//  ViewController.swift
//  MapKitDemo
//
//  Created by GLB-312-PC on 28/08/18.
//  Copyright © 2018 IOSISFUN. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    let regionInMeteers : Double = 10000
    var previousLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       mapView.delegate = self
        checkLocationServices()
    }
    
    
    func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy  = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation(){
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegionMakeWithDistance(location, regionInMeteers, regionInMeteers)
            mapView.setRegion(region, animated: true)
        }
        
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        }
        else{
            //show error mesage
        }
        
    }
    func getCenterLocation(for mapView:MKMapView) -> CLLocation {
        let latitutude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitutude, longitude: longitude)
        
    }
    func checkLocationAuthorization(){
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            startTrackingUserLocation()
        
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        
        case .restricted:
            //show alerat message
            break
        case .denied:
            // show alert message
            break
        case .authorizedAlways:
            // authorization
           break
        }
        
        
    }

    
    func startTrackingUserLocation (){
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
        
    }

}

extension ViewController:CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        guard let previousLocation = self.previousLocation  else {
            return
        }
        
        guard  center.distance(from: previousLocation) > 60 else {
            return
        }
        self.previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center) { [weak self](placemarks , error) in
            
            guard let weakSelf = self else {return}
            
            if let _ = error {
                return
            }
            guard let placemark = placemarks?.first else{
                return
            }
            DispatchQueue.main.async {
                weakSelf.addressLabel.text = weakSelf.getCompleteAddressofPlacemark(placemark: placemark)
            }
        }
    }
    
    
    func getCompleteAddressofPlacemark(placemark:CLPlacemark) -> String{
        
        let streetNumber = placemark.postalCode ?? ""
        let streetName = placemark.locality ?? ""
        let country = placemark.country ?? ""
        let statename = placemark.administrativeArea ?? ""
        let sublocality = placemark.subLocality ?? ""
        let landmark = placemark.subAdministrativeArea ?? ""
        
        return "\(streetNumber) \(streetName) \(sublocality) \(landmark) \(statename) \(country)"
    }
}
