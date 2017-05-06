import MapKit

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func didDragMap(gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            localizeMeButton.localizeMeState = .unlocalized
        }
    }
    
    func setUpLocalizeMeButton() {
        
        let mapDragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didDragMap(gestureRecognizer:)))
        mapDragRecognizer.delegate = self
        self.view.addGestureRecognizer(mapDragRecognizer)
        
        localizeMeButton.listener = { [weak self] localizeMeState in
            switch localizeMeState {
            case .localized:
                self?.localizeMeManager.stop()
                self?.localizeMeManager.manager(for: .whenInUse, completion: { result in
                    if case let .Success(manager) = result {
                        manager.startUpdatingLocation(isHeadingEnabled: false) { [weak self] result in
                            if case let .Success(locationHeading) = result, let location = locationHeading.location {
                                self?.mapView.centerCamera(to: location)
                            }
                        }
                    }
                })
            case .unlocalized:
                self?.localizeMeManager.stop()
            case .navigated:
                self?.localizeMeManager.stop()
                self?.localizeMeManager.manager(for: .whenInUse, completion: { result in
                    if case let .Success(manager) = result {
                        manager.startUpdatingLocation(isHeadingEnabled: true) { [weak self] result in
                            if case let .Success(locationHeading) = result {
                                self?.mapView.centerCamera(to: locationHeading.location, heading: locationHeading.heading?.trueHeading)
                            }
                        }
                    }
                })
            }
        }
    }
}
