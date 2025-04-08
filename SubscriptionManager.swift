import Foundation
import StoreKit

class SubscriptionManager {
    static let shared = SubscriptionManager()
    
    func checkPurchaseStatus(idSharedSecretInappPurchase: String, lifetimeProductId: String?, completion: @escaping ((Bool, Bool, String)?) -> Void) {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL).base64EncodedString() else {
            Helpers.myLog(text: "Không tìm thấy receipt")
            completion(nil) // ❌ Lỗi -> Trả về nil
            return
        }
        
        let requestData: [String: Any] = [
            "receipt-data": receiptData,
            "password": idSharedSecretInappPurchase,
            "exclude-old-transactions": true
        ]
        
        verifyReceipt(url: "https://buy.itunes.apple.com/verifyReceipt", requestData: requestData, lifetimeProductId: lifetimeProductId, completion: completion)
    }
    
    private func verifyReceipt(url: String, requestData: [String: Any], lifetimeProductId: String?, completion: @escaping ((Bool, Bool, String)?) -> Void) {
        guard let requestURL = URL(string: url) else {
            completion(nil) // ❌ Lỗi -> Trả về nil
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestData)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                Helpers.myLog(text: "Lỗi khi kiểm tra receipt: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil) // ❌ Lỗi mạng -> Trả về nil
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // 🔥 Nếu là môi trường Sandbox, chuyển API
                    if let status = json["status"] as? Int, status == 21007 {
                        Helpers.myLog(text: "Receipt từ Sandbox -> Chuyển sang Sandbox API")
                        self.verifyReceipt(url: "https://sandbox.itunes.apple.com/verifyReceipt", requestData: requestData, lifetimeProductId: lifetimeProductId, completion: completion)
                        return
                    }
                    
                    var isSubscriptionActive = false
                    var isLifetimePurchased = false
                    var idSubPurchased = ""
                    
                    // 🔥 Kiểm tra danh sách giao dịch
                    if let latestReceiptInfo = json["latest_receipt_info"] as? [[String: Any]] {
                        for transaction in latestReceiptInfo {
                            if let productId = transaction["product_id"] as? String {
                                Helpers.myLog(text: "🔥 Đã mua gói: \(productId)") // 🛠 In ra ID của subscription
                                
                                // 🚀 Kiểm tra nếu là gói lifetime (nếu có truyền vào)
                                if let lifetimeId = lifetimeProductId, productId == lifetimeId {
                                    isLifetimePurchased = true
                                }
                                
                                // 🔥 Kiểm tra nếu là subscription (có ngày hết hạn)
                                if let expiresDateMs = transaction["expires_date_ms"] as? String,
                                   let expiresDate = Double(expiresDateMs) {
                                    let expirationDate = Date(timeIntervalSince1970: expiresDate / 1000)
                                    Helpers.myLog(text: "⏳ Hết hạn: \(expirationDate)")
                                    if expirationDate > Date() {
                                        isSubscriptionActive = true
                                        idSubPurchased = productId
                                    }
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        completion((isSubscriptionActive, isLifetimePurchased, idSubPurchased))
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(nil) // ❌ Lỗi parse JSON -> Trả về nil
                }
            } catch {
                Helpers.myLog(text: "Lỗi khi parse JSON: \(error.localizedDescription). Response: \(String(data: data, encoding: .utf8) ?? "Không thể đọc dữ liệu")")
                DispatchQueue.main.async {
                    completion(nil) // ❌ Lỗi ngoại lệ JSON -> Trả về nil
                }
            }
        }
        task.resume()
    }
}
