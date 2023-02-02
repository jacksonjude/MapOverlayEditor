//
//  ImageMapOverlay.swift
//  MapOverlayEditor
//
//  Created by jackson on 2/2/23.
//

import MapKit

class ImageMapOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect

    init(rect: MKMapRect) {
        boundingMapRect = rect
        coordinate = CLLocationCoordinate2DMake(boundingMapRect.origin.x + boundingMapRect.size.width / 2, boundingMapRect.origin.y + boundingMapRect.size.height / 2)
    }
}
