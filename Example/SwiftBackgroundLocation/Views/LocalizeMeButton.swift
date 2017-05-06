import UIKit

class LocalizeMeButton: UIButton {
    typealias LocalizeMeButtonOnTouchListener = ((LocalizeMeState) -> ())
    var listener: LocalizeMeButtonOnTouchListener?
    
    var localizeMeState: LocalizeMeState = .unlocalized {
        didSet {
            switch localizeMeState {
            case .localized:
                setTitle("Localized", for: .normal)
            case .unlocalized:
                setTitle("Unlocalized", for: .normal)
            case .navigated:
                setTitle("Navigated", for: .normal)
            }

            listener?(localizeMeState)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch localizeMeState {
        case .localized:
            localizeMeState = .navigated
        case .unlocalized:
            localizeMeState = .localized
        case .navigated:
            localizeMeState = .localized
        }
    }
    
    enum LocalizeMeState {
        case localized, unlocalized, navigated
    }
}
