import ApiVideoLiveStream
import CoreGraphics
import Foundation

@objc(RNLiveStreamViewManager)
class RNLiveStreamViewManager: RCTViewManager {
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    override func view() -> (RNLiveStreamViewImpl) {
        return RNLiveStreamViewImpl()
    }

    @objc(startStreaming:withRequestId:withStreamKey:withUrl:)
    func startStreaming(_ reactTag: NSNumber, withRequestId requestId: NSNumber, streamKey: String, url: String?) {
        guard let bridge = bridge else { return }
        bridge.uiManager.addUIBlock { (_: RCTUIManager?, viewRegistry: [NSNumber: UIView]?) in
            guard let view = viewRegistry?[reactTag] as? RNLiveStreamViewImpl else { return }
            view.startStreaming(requestId: Int(truncating: requestId), streamKey: streamKey, url: url)
        }
    }

    @objc(stopStreaming:)
    func stopStreaming(_ reactTag: NSNumber) {
        guard let bridge = bridge else { return }
        bridge.uiManager.addUIBlock { (_: RCTUIManager?, viewRegistry: [NSNumber: UIView]?) in
            guard let view = viewRegistry?[reactTag] as? RNLiveStreamViewImpl else { return }
            view.stopStreaming()
        }
    }

    @objc(setZoomRatioCommand:withZoomRatio:)
    func setZoomRatioCommand(_ reactTag: NSNumber, zoomRatio: NSNumber) {
        guard let bridge = bridge else { return }
        bridge.uiManager.addUIBlock { (_: RCTUIManager?, viewRegistry: [NSNumber: UIView]?) in
            guard let view = viewRegistry?[reactTag] as? RNLiveStreamViewImpl else { return }
            view.zoomRatio = zoomRatio.floatValue
        }
    }
}
