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
    @IBOutlet weak var Gobutton: UIButton!
    
    let locationManager = CLLocationManager()
    let regionInMeteers : Double = 10000
    var previousLocation: CLLocation?
    var directionsArray: [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        checkLocationServices()
        Gobutton.layer.cornerRadius = Gobutton.frame.size.height/2
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
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            //TODO : inform user we don't have their current locations
            print("We dont have user locations ")
            return
        }
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        directions.calculate { (response , error) in
            
            
            
            if  let errors = error {
                print("error  occured ")
                print("\(errors)")
                
            }
            guard let response = response else {
                print("Response not available")
                return
            }
            
            
            
            for route in response.routes {
                self.mapView.add(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
            
        }
    }
    
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D)-> MKDirectionsRequest{
        
        let destinationCoorinate                 = getCenterLocation(for: mapView).coordinate
        let startingLocation                         = MKPlacemark(coordinate: coordinate)
        let destination                                   = MKPlacemark(coordinate: destinationCoorinate)
        let request                                           = MKDirectionsRequest()
        request.source                                     = MKMapItem(placemark: startingLocation)
        request.destination                            = MKMapItem(placemark: destination)
        request.transportType                      = .automobile
        request.requestsAlternateRoutes   = true
        return request
    }
    
    func resetMapView(withNew directions:MKDirections){
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map{$0.cancel()}
        
    }
    
    @IBAction func goDirectionButtonTapped(_ sender: Any) {
        getDirections()
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
    
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
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
