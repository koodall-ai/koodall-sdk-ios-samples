import UIKit
import BNBSdkApi
import BNBSdkCore

class ViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    static let effectBasePath = "effects/"

    static let effects: [EffectConfig] = {
       [
        .init(effectName: "test_gestures", preview: .fromEffect(pathToEffect: effectBasePath + "test_gestures")),
        .init(effectName: "test_HandSkelet", preview: .fromEffect(pathToEffect: effectBasePath + "test_HandSkelet")),
        .init(effectName: "test_Ring", preview:  .fromEffect(pathToEffect: effectBasePath + "test_Ring")),
        .init(effectName: "test_Watch", preview:  .fromEffect(pathToEffect: effectBasePath + "test_Watch")),
       ]
    }()

    // Output surface for the `Player`
    @IBOutlet weak var effectView: EffectPlayerView!
    @IBOutlet weak var effectCollectionView: UICollectionView!
    
    private var selectedEffect: EffectConfig = effects.first!
    private var effectsDataSource: UICollectionViewDiffableDataSource<Int, EffectPreviewCellViewModel>!
    
    // Input stream for the `Player`
    private let cameraDevice = CameraDevice(
        cameraMode: .BackCameraSession,
        captureSessionPreset: .hd1280x720
    )
    
    // `Player` process frames from the input and render them into the outputs
    private var player: Player?
    
    // Current effect
    private var effect: BNBEffect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        effectCollectionView.registerReusableCell(EffectPreviewCell.self)
        setupDataSource()
        
        player = Player()
        
        // Connect `CameraDevice` and `EffectPlayerView` to `Player`
        player?.use(input: Camera(cameraDevice: cameraDevice))
        player?.use(outputs: [effectView])
        
        _ = player?.load(effect: ViewController.effectBasePath + "test_gestures")
        
        // Start feeding frames from camera
        cameraDevice.start()
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        EffectPreviewCell.cellSize
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        let cellWidth = EffectPreviewCell.cellSize.width
        let cvWidth = effectCollectionView.bounds.width
        let inset = (cvWidth - cellWidth) / 2
        return .init(top: 0, left: inset, bottom: 0, right: inset)
    }

    // MARK: - UICollectionViewDelegate
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let newEffect = ViewController.effects[indexPath.item]
        guard newEffect != selectedEffect else { return }
        selectedEffect = newEffect
        
        applyUpdatedEffectPreviewModels()
        
        Task {
            player?.load(effect: ViewController.effectBasePath + newEffect.effectName, sync: true)
        }
        
        effectCollectionView.scrollToItem(
            at: indexPath,
            at: .centeredHorizontally,
            animated: true
        )
    }
    
    // MARK: - Data source
    private func setupDataSource() {
        effectsDataSource = UICollectionViewDiffableDataSource(
            collectionView: effectCollectionView,
            cellProvider: { (collectionView, indexPath, model) ->
                UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: EffectPreviewCell.reuseIdentifier,
                    for: indexPath
                ) as? EffectPreviewCell
                cell?.update(with: model)
                return cell
            })
        
        applyUpdatedEffectPreviewModels()
    }
        
    private func applyUpdatedEffectPreviewModels() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, EffectPreviewCellViewModel>()
        snapshot.appendSections([0])
        let models = ViewController.effects.map {
            EffectPreviewCellViewModel(preview: $0.preview, isSelected: $0 == selectedEffect)
        }
        snapshot.appendItems(models)
        effectsDataSource.apply(snapshot, animatingDifferences: false)
    }
}
