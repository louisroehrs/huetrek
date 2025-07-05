import Foundation
import Security
import CommonCrypto

class CertificateManager: NSObject, URLSessionDelegate {
    static let shared = CertificateManager()
    
    private var certificates: [SecCertificate] = []
    
    func loadCertificate(fromPEM pemString: String) {
        // Remove PEM header and footer
        let pemContent = pemString
            .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        // Convert base64 to data
        guard let certificateData = Data(base64Encoded: pemContent) else {
            print("Failed to decode certificate data")
            return
        }
        
        // Create certificate from data
        guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            print("Failed to create certificate")
            return
        }
        
        certificates.append(certificate)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // If we have pinned certificates, verify against them
        if !certificates.isEmpty {
            let _ = NSArray(array: [SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)])
            let isServerTrusted = SecTrustEvaluateWithError(serverTrust, nil)
            
            if isServerTrusted {
                if let serverCertificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] {
                    let _ = Set(
                        serverCertificates.map { SecCertificateCopyData($0) as Data }
                    )
                    
                    
                    // Check if any of our pinned certificates match the server's certificates
                    let isCertificateValid = serverCertificates.contains { serverCertificate in
                        certificates.contains { pinnedCertificate in
                            SecCertificateCopyData(serverCertificate) == SecCertificateCopyData(pinnedCertificate)
                        }
                    }
                    
                    if isCertificateValid {
                        let credential = URLCredential(trust: serverTrust)
                        completionHandler(.useCredential, credential)
                        return
                    }
                }
            }
            
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // If no certificates are pinned, use default validation
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
}

// Extension to calculate SHA-256 hash
extension Data {
    func sha256() -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(count), &hash)
        }
        return hash
    }
} 
