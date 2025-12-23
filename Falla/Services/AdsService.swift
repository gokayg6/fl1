import Foundation
import GoogleMobileAds

// MARK: - Ads Service (Singleton)
final class AdsService: NSObject {
    static let shared = AdsService()
    
    // MARK: - Ad Unit IDs (Production - from Dart project)
    static let bannerAdUnitId = "ca-app-pub-5956124359067452/3098716914"
    static let interstitialAdUnitId = "ca-app-pub-5956124359067452/9225141569"
    static let rewardedAdUnitId = "ca-app-pub-5956124359067452/6477643001"
    
    // MARK: - Ad Instances
    private var interstitialAd: GADInterstitialAd?
    private var rewardedAd: GADRewardedAd?
    
    // MARK: - Ad State
    private(set) var isInterstitialLoaded = false
    private(set) var isRewardedLoaded = false
    
    // MARK: - Analytics
    private(set) var adImpressions = 0
    private(set) var adClicks = 0
    
    private override init() {
        super.init()
    }
    
    // MARK: - Initialize SDK
    static func initialize() {
        GADMobileAds.sharedInstance().start { status in
            print("🎯 AdMob SDK initialized")
            for (adapter, state) in status.adapterStatusesByClassName {
                print("  - \(adapter): \(state.state.rawValue)")
            }
        }
    }
    
    // MARK: - Load Interstitial Ad
    func loadInterstitialAd(completion: ((Bool) -> Void)? = nil) {
        let request = GADRequest()
        
        GADInterstitialAd.load(
            withAdUnitID: AdsService.interstitialAdUnitId,
            request: request
        ) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Interstitial ad failed to load: \(error.localizedDescription)")
                self.isInterstitialLoaded = false
                completion?(false)
                return
            }
            
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.isInterstitialLoaded = true
            self.adImpressions += 1
            print("🎯 Interstitial ad loaded successfully")
            completion?(true)
        }
    }
    
    // MARK: - Show Interstitial Ad
    func showInterstitialAd(from viewController: UIViewController, completion: (() -> Void)? = nil) {
        guard let ad = interstitialAd, isInterstitialLoaded else {
            print("❌ Interstitial ad not loaded")
            completion?()
            return
        }
        
        ad.present(fromRootViewController: viewController)
        completion?()
    }
    
    // MARK: - Load Rewarded Ad
    func loadRewardedAd(completion: ((Bool) -> Void)? = nil) {
        let request = GADRequest()
        
        GADRewardedAd.load(
            withAdUnitID: AdsService.rewardedAdUnitId,
            request: request
        ) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Rewarded ad failed to load: \(error.localizedDescription)")
                self.isRewardedLoaded = false
                completion?(false)
                return
            }
            
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            self.isRewardedLoaded = true
            self.adImpressions += 1
            print("🎯 Rewarded ad loaded successfully")
            completion?(true)
        }
    }
    
    // MARK: - Show Rewarded Ad
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (GADAdReward?) -> Void) {
        guard let ad = rewardedAd, isRewardedLoaded else {
            print("❌ Rewarded ad not loaded")
            completion(nil)
            return
        }
        
        ad.present(fromRootViewController: viewController) {
            let reward = ad.adReward
            print("🎯 User earned reward: \(reward.amount) \(reward.type)")
            completion(reward)
        }
    }
    
    // MARK: - Dispose Ads
    func disposeInterstitialAd() {
        interstitialAd = nil
        isInterstitialLoaded = false
    }
    
    func disposeRewardedAd() {
        rewardedAd = nil
        isRewardedLoaded = false
    }
    
    func disposeAllAds() {
        disposeInterstitialAd()
        disposeRewardedAd()
    }
}

// MARK: - Full Screen Content Delegate
extension AdsService: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("🎯 Ad dismissed")
        // Reload ads after dismissal
        if ad is GADInterstitialAd {
            isInterstitialLoaded = false
            loadInterstitialAd()
        } else if ad is GADRewardedAd {
            isRewardedLoaded = false
            loadRewardedAd()
        }
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad failed to present: \(error.localizedDescription)")
        if ad is GADInterstitialAd {
            isInterstitialLoaded = false
        } else if ad is GADRewardedAd {
            isRewardedLoaded = false
        }
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        adClicks += 1
        print("🎯 Ad clicked")
    }
    
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("🎯 Ad impression recorded")
    }
}

// MARK: - Banner Ad View (SwiftUI)
import SwiftUI

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    
    init(adUnitID: String = AdsService.bannerAdUnitId) {
        self.adUnitID = adUnitID
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        
        // Get root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootVC
        }
        
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
