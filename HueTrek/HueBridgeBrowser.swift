//
//  HueBridgeBrowser.swift
//  HueTrek
//
//  Created by Louis Roehrs on 5/26/25.
//


import Foundation
import Network

class HueBridgeBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private var serviceBrowser: NetServiceBrowser!
    private var discoveredServices: [NetService] = []

    override init() {
        super.init()
        serviceBrowser = NetServiceBrowser()
        serviceBrowser.delegate = self
    }

    func startSearching() {
        print("Starting search for Philips Hue Bridges...")
        serviceBrowser.searchForServices(ofType: "_hue._tcp.", inDomain: "")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Found service: \(service)")
        discoveredServices.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses else { return }

        for addressData in addresses {
            addressData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Void in
                let sockaddrPointer = pointer.bindMemory(to: sockaddr.self)
                let addr = sockaddrPointer.baseAddress!
                if addr.pointee.sa_family == sa_family_t(AF_INET) {
                    let data = addressData as NSData
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        let ip = String(cString: hostname)
                        print("Hue Bridge IP: \(ip)")
                    }
                }
            }
        }
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Failed to resolve: \(sender) with error \(errorDict)")
    }
}
