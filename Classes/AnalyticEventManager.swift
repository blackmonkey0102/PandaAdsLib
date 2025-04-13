import FirebaseAnalytics
import Foundation
import Adjust

public class AnalyticEventManager {
    
    public static func logEventAdImpressionAdjust(){
        guard let event = ADJEvent(eventToken: PandaAds.shared.adjustAdImpression) else { return }
        Adjust.trackEvent(event)
    }
    
    public static func logEventPurchaseAdjust(amount: Double, currency: String){
        guard let event = ADJEvent(eventToken: PandaAds.shared.adjustIapPurchase) else { return }
        event.setRevenue(amount, currency: currency)
        Adjust.trackEvent(event)
    }
    
    public static func adsLogEvent(_ key: AnalyticEventKeyAds, parameters: [String: Any]? = nil){
           print("Event ads logged: \(key.rawValue), Parameters: \(parameters ?? [:])")
           Analytics.logEvent(key.rawValue, parameters: parameters)
       }
    
    public enum AnalyticEventKeyAds: String {
         case ad_open_call_load
         case ad_open_request
         case ad_open_loaded
         case ad_open_load_failed
         case ad_open_call_show
         case ad_open_open
         case ad_open_show_failed
         case ad_open_clicked
         case ad_open_closed
         case ad_open_paid
         
         case ad_banner_create
         case ad_banner_load
         case ad_banner_loaded
         case ad_banner_load_failed
         case ad_banner_clicked
         case ad_banner_paid
         case ad_banner_opened // miss
         case ad_banner_closed // miss
         
         case ad_inter_call_load
         case ad_inter_request
         case ad_inter_loaded
         case ad_inter_load_failed
         case ad_inter_call_show
         case ad_inter_open
         case ad_inter_show_failed
         case ad_inter_clicked
         case ad_inter_closed
         case ad_inter_paid
         
         case ad_reward_call_load
         case ad_reward_request
         case ad_reward_loaded
         case ad_reward_load_failed
         case ad_reward_call_show
         case ad_reward_open
         case ad_reward_show_failed
         case ad_reward_clicked
         case ad_reward_closed
         case ad_reward_paid
         case ad_reward_receive
         
         case ad_native_call_load
         case ad_native_request
         case ad_native_loaded
         case ad_native_load_failed
         case ad_native_call_show
         case ad_native_open
         case ad_native_clicked
         case ad_native_paid
     }
}
