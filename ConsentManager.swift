import UserMessagingPlatform
import GoogleMobileAds

class ConsentManager {
    static let shared = ConsentManager()
    
    private var consentForm: UMPConsentForm?
    
    func checkAndRequestConsent(isRelease: Bool, completion: @escaping (Bool) -> Void) {
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false // Set to true if your app is directed to children under the age of consent
        
        if isRelease == false{
            let debugSettings = UMPDebugSettings()
            debugSettings.geography = .EEA // Simulates being in the European Economic Area
            debugSettings.testDeviceIdentifiers = [""]
            //UMPConsentInformation.sharedInstance.debugSettings = debugSettings
            
        }
        
        // Load the consent information
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            if let error = error {
                Helpers.myLog(text: "Failed to update consent info: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            let consentStatus = UMPConsentInformation.sharedInstance.consentStatus
            Helpers.myLog(text: "Consent status: \(consentStatus.rawValue) - canRequestAds: \(UMPConsentInformation.sharedInstance.canRequestAds)")
            
            // If consent is required, load and show the form
            if UMPConsentInformation.sharedInstance.formStatus == .available {
                Helpers.myLog(text: "Consent form status 1 : \(UMPConsentInformation.sharedInstance.formStatus)")
                self?.loadAndShowForm(completion: completion)
            } else {
                Helpers.myLog(text: "Consent form status 2: \(UMPConsentInformation.sharedInstance.formStatus)")
                // Consent is not required or already collected
                completion(consentStatus == .obtained || consentStatus == .notRequired)
            }
        }
    }
    
    private func loadAndShowForm(completion: @escaping (Bool) -> Void) {
        UMPConsentForm.load { [weak self] form, error in
            if let error = error {
                Helpers.myLog(text: "Failed to load consent form: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            self?.consentForm = form
            
            // Show the form if required
            if UMPConsentInformation.sharedInstance.consentStatus == .required {
                form?.present(from: UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()) { dismissError in
                    if let dismissError = dismissError {
                        Helpers.myLog(text: "Failed to present consent form: \(dismissError.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    // Check consent status after dismissal
                    let consentStatus = UMPConsentInformation.sharedInstance.consentStatus
                    completion(consentStatus == .obtained || consentStatus == .notRequired)
                }
            } else {
                completion(true)
            }
        }
    }
    
    public func resetConsent(){
        UMPConsentInformation.sharedInstance.reset()

    }
}
