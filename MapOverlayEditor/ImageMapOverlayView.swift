//
//  ImageMapOverlayView.swift
//  MapOverlayEditor
//
//  Created by jackson on 2/2/23.
//

import MapKit

class ImageMapOverlayView: MKOverlayRenderer {
    var overlayImage: UIImage

    init(overlay:MKOverlay, overlayImage:UIImage) {
        self.overlayImage = overlayImage
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let imageReference = overlayImage.cgImage else { return }

        let rect = self.rect(for: overlay.boundingMapRect)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -rect.size.height)
        context.setAlpha(0.5)
        context.draw(imageReference, in: rect)
    }
}
