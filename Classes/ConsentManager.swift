import UserMessagingPlatform
import GoogleMobileAds

public class ConsentManager {
    public static let shared = ConsentManager()
    
    public var consentForm: ConsentForm?
    
    public func checkAndRequestConsent(isRelease: Bool, completion: @escaping (Bool) -> Void) {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false // Set to true if your app is directed to children under the age of consent
        
        if isRelease == false{
            let debugSettings = DebugSettings()
            debugSettings.geography = .EEA // Simulates being in the European Economic Area
            debugSettings.testDeviceIdentifiers = [""]
            //UMPConsentInformation.sharedInstance.debugSettings = debugSettings
            
        }
        
        // Load the consent information
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            if let error = error {
                MyHelpers.myLog(text: "Failed to update consent info: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            let consentStatus = ConsentInformation.shared.consentStatus
            MyHelpers.myLog(text: "Consent status: \(consentStatus.rawValue) - canRequestAds: \(ConsentInformation.shared.canRequestAds)")
            
            // If consent is required, load and show the form
            if ConsentInformation.shared.formStatus == .available {
                //MyHelpers.myLog(text: "Consent form status 1 : \(ConsentInformation.shared.formStatus)")
                self?.loadAndShowForm(completion: completion)
            } else {
                //MyHelpers.myLog(text: "Consent form status 2: \(ConsentInformation.shared.formStatus)")
                // Consent is not required or already collected
                completion(consentStatus == .obtained || consentStatus == .notRequired)
            }
        }
    }
    
    public func loadAndShowForm(completion: @escaping (Bool) -> Void) {
        ConsentForm.load { [weak self] form, error in
            if let error = error {
                MyHelpers.myLog(text: "Failed to load consent form: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            self?.consentForm = form
            
            // Show the form if required
            if ConsentInformation.shared.consentStatus == .required {
                form?.present(from: UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()) { dismissError in
                    if let dismissError = dismissError {
                        MyHelpers.myLog(text: "Failed to present consent form: \(dismissError.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    // Check consent status after dismissal
                    let consentStatus = ConsentInformation.shared.consentStatus
                    completion(consentStatus == .obtained || consentStatus == .notRequired)
                }
            } else {
                completion(true)
            }
        }
    }
    
    public func resetConsent(){
        ConsentInformation.shared.reset()

    }
}
