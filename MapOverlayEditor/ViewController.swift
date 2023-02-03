//
//  ViewController.swift
//  MapOverlayEditor
//
//  Created by jackson on 2/2/23.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var mainMapView: MKMapView!
    var isDragEnabled = false
    var initialDragPoint: CGPoint?
    
    var isPinchEnabled = false
    var initialPinchScale: CGFloat?
    var initialPinchRect: CGRect?
    
    var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 34.4140, longitude: -119.8489)
    var dragOverlay: MKOverlay?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mainMapView.delegate = self
        mainMapView.showsUserLocation = true
        mainMapView.isRotateEnabled = false
        mainMapView.isPitchEnabled = false
        
        dragOverlay = makeImageOverlay(rect: MKMapRect(origin: MKMapPoint(currentLocation), size: MKMapSize(width: 1000, height: 1000)))
        mainMapView.addOverlay(dragOverlay!, level: MKOverlayLevel.aboveLabels)
        
        mainMapView.setRegion(MKCoordinateRegion(center: currentLocation, latitudinalMeters: 1000, longitudinalMeters: 1000), animated: false)
        
        addPanGestureRecognizer(to: mainMapView)
        addPinchGestureRecognizer(to: mainMapView)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            let color: UIColor = .red
            circleRenderer.strokeColor = color
            circleRenderer.fillColor = color.withAlphaComponent(0.3)
            circleRenderer.lineWidth = 2.0
            return circleRenderer
        } else if overlay is ImageMapOverlay {
            let imageRenderer = ImageMapOverlayView(overlay: overlay, overlayImage: UIImage(imageLiteralResourceName: "swego"))
            return imageRenderer
        } else {
            return MKPolylineRenderer()
        }
    }
    
    func makeImageOverlay(rect: MKMapRect) -> MKOverlay {
        return ImageMapOverlay(rect: rect)
    }

    func addPanGestureRecognizer(to map: MKMapView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(respondToPanGesture(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        map.addGestureRecognizer(panGesture)
    }

    @objc func respondToPanGesture(_ sender: UIPanGestureRecognizer) {
        let currentPoint = mainMapView.convert(currentLocation, toPointTo: mainMapView)
        let currentRect = mainMapView.convert(MKCoordinateRegion(dragOverlay!.boundingMapRect), toRectTo: mainMapView)

        switch sender.state {
        case .began:
            if !isPinchEnabled {
                let point = sender.location(in: mainMapView)
                if currentRect.contains(point) {
                    initialDragPoint = currentPoint
                    mainMapView.isScrollEnabled = false
                    isDragEnabled = true
                }
                else {
                    mainMapView.isScrollEnabled = true
                    isDragEnabled = false
                }
            }
        case .changed:
            if isDragEnabled {
                let translation = sender.translation(in: mainMapView)
                let newPoint = CGPoint(x: initialDragPoint!.x + translation.x, y: initialDragPoint!.y + translation.y)
                currentLocation = mainMapView.convert(newPoint, toCoordinateFrom: mainMapView)
                let newOverlay = makeImageOverlay(rect: MKMapRect(origin: MKMapPoint(currentLocation), size: dragOverlay!.boundingMapRect.size))
                mainMapView.removeOverlay(dragOverlay!)
                mainMapView.addOverlay(newOverlay, level: MKOverlayLevel.aboveLabels)
                dragOverlay = newOverlay
            }
        case .ended, .failed, .cancelled:
            mainMapView.isScrollEnabled = true
            isDragEnabled = false
        case .possible:
            break
        default:
            break
        }
    }
    
    func addPinchGestureRecognizer(to map: MKMapView) {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(respondToPinchGesture(_:)))
        pinchGesture.delegate = self
        map.addGestureRecognizer(pinchGesture)
    }
    
    @objc func respondToPinchGesture(_ sender: UIPinchGestureRecognizer) {
        let currentRect = mainMapView.convert(MKCoordinateRegion(dragOverlay!.boundingMapRect), toRectTo: mainMapView)
        
        switch sender.state {
        case .began:
            if !isDragEnabled {
                let point = sender.location(in: mainMapView)
                if currentRect.contains(point) {
                    initialPinchScale = sender.scale
                    initialPinchRect = currentRect
                    mainMapView.isZoomEnabled = false
                    mainMapView.isScrollEnabled = false
                    isPinchEnabled = true
                }
                else {
                    mainMapView.isZoomEnabled = true
                    mainMapView.isScrollEnabled = true
                    isPinchEnabled = false
                }
            }
        case .changed:
            if isPinchEnabled {
                let scaleChange = sender.scale/initialPinchScale!
                let newRect = CGRect(origin: initialPinchRect!.origin, size: initialPinchRect!.size.applying(CGAffineTransform(scaleX: scaleChange, y: scaleChange)))
                
                let newOverlay = makeImageOverlay(rect: mainMapView.convert(newRect, toRegionFrom: mainMapView).toRect())
                mainMapView.removeOverlay(dragOverlay!)
                mainMapView.addOverlay(newOverlay, level: MKOverlayLevel.aboveLabels)
                dragOverlay = newOverlay
            }
        case .ended, .failed, .cancelled:
            mainMapView.isZoomEnabled = true
            mainMapView.isScrollEnabled = false
            isPinchEnabled = false
        case .possible:
            break
        default:
            break
        }
    }

    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension CGPoint {
    func distance(from: CGPoint, to: CGPoint) -> CGFloat {
      return CGFloat(sqrt((from.x - to.x)*(from.x - to.x) + (from.y - to.y)*(from.y - to.y)))
    }

    func radiusContainsPoint(radius: CGFloat, point center: CGPoint) -> Bool {
      return distance(from: center, to: self) <= radius
    }
}

extension MKCoordinateRegion {
    func toRect() -> MKMapRect {
        let topLeft = CLLocationCoordinate2D(latitude: self.center.latitude + (self.span.latitudeDelta/2), longitude: self.center.longitude - (self.span.longitudeDelta/2))
        let bottomRight = CLLocationCoordinate2D(latitude: self.center.latitude - (self.span.latitudeDelta/2), longitude: self.center.longitude + (self.span.longitudeDelta/2))

        let a = MKMapPoint(topLeft)
        let b = MKMapPoint(bottomRight)
        
        return MKMapRect(origin: MKMapPoint(x:min(a.x,b.x), y:min(a.y,b.y)), size: MKMapSize(width: abs(a.x-b.x), height: abs(a.y-b.y)))
    }
}
