import Foundation

enum EffectPreview: Hashable {
    case uniqueIcon(named: String)
    case color(hex: Int)
    case templatedIcon(named: String, letter: Character)
    case fromEffect(pathToEffect: String)
    case none
}

struct EffectConfig: Equatable {
    let effectName: String
    let preview: EffectPreview
    
    static func == (lhs: EffectConfig, rhs: EffectConfig) -> Bool {
        lhs.effectName == rhs.effectName
    }
    
    init(
        effectName: String,
        preview: EffectPreview
    ) {
        self.effectName = effectName
        self.preview = preview
    }
}
