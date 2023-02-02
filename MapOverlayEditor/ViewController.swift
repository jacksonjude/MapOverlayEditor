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
    var currentPoint: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 34.4140, longitude: -119.8489)
    var circleOverlay: MKOverlay?
    let circleRadius: CGFloat = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mainMapView.delegate = self
        mainMapView.showsUserLocation = true
        mainMapView.isRotateEnabled = false
        mainMapView.isPitchEnabled = false
        
        circleOverlay = makeCircleOverlay(at: currentPoint)
        mainMapView.addOverlay(circleOverlay!)
        
        mainMapView.setRegion(MKCoordinateRegion(center: currentPoint, latitudinalMeters: 1000, longitudinalMeters: 1000), animated: false)
        
        addPanGestureRecognizer(to: mainMapView)
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
    
    func makeCircleOverlay(at center: CLLocationCoordinate2D) -> MKOverlay {
        return MKCircle(center: center, radius: circleRadius)
    }

    func addPanGestureRecognizer(to map: MKMapView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(respondToPanGesture(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        map.addGestureRecognizer(panGesture)
    }

    @objc func respondToPanGesture(_ sender: UIPanGestureRecognizer) {
        let circlePoint = mainMapView.convert(currentPoint, toPointTo: mainMapView) // circle center in View coordinate system

        switch sender.state {
        case .began:
            let point = sender.location(in: mainMapView)
            // Set touch radius in points, not meters to support different map zoom levels
            if point.radiusContainsPoint(radius: circleRadius, point: circlePoint) {
                // set class property to store initial circle position before start dragging
                initialDragPoint = circlePoint
                mainMapView.isScrollEnabled = false
                isDragEnabled = true
            }
            else {
                mainMapView.isScrollEnabled = true
                isDragEnabled = false
            }
        case .changed:
            if isDragEnabled {
                let translation = sender.translation(in: mainMapView)
                let newPoint = CGPoint(x: initialDragPoint!.x + translation.x, y: initialDragPoint!.y + translation.y)
                currentPoint = mainMapView.convert(newPoint, toCoordinateFrom: mainMapView)
                let newOverlay = makeCircleOverlay(at: currentPoint)
                mainMapView.removeOverlay(circleOverlay!)
                mainMapView.addOverlay(newOverlay)
                circleOverlay = newOverlay
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
