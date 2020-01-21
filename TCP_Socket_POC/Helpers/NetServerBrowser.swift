//
//  NetServerBrowser.swift
//  TCP_Socket_POC
//
//  Created by Jayesh Mardiya on 21/01/20.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import WebRTC

protocol NetServerBrowserDelegate {
    
    func didUpdateServiceList(serviceList: [NetService])
}

class NetServerBrowser: NSObject {
    
    private var netServiceBrowser: NetServiceBrowser!
    private var serverService: NetService!
    private var currentServerService: NetService!

    private var serverList: [NetService] = []
    private var serverAddresses: [Data] = []
    
    private var clientPresenter: ClientPresenter!
    private var hostSocket: GCDAsyncSocket!
    var delegate: NetServerBrowserDelegate?
    
    override init() {
        super.init()
        
        self.startBrowser()
    }
    
    func startBrowser() {
        self.netServiceBrowser = NetServiceBrowser()
        self.netServiceBrowser.delegate = self
        self.netServiceBrowser.searchForServices(ofType: "_populi._tcp.", inDomain: "")
    }
    
    func connectToServer(at index: Int) {
        guard let server = self.serverList.item(at: index)
        else { return }
        
        server.delegate = self
        server.resolve(withTimeout: 5.0)
    }
}

extension NetServerBrowser : NetServiceDelegate, GCDAsyncSocketDelegate {
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses
            else { return }
        
        self.serverAddresses = addresses
        guard let addr = addresses.first else { return }
        
        let socket = GCDAsyncSocket()
        do {
            self.clientPresenter = ClientPresenter(socket: socket)
            self.clientPresenter.delegate = self
            
            try socket.connect(toAddress: addr)
            socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
        } catch {
            return
        }
    }
}

// MARK: - NetServiceBrowserDelegate
extension NetServerBrowser : NetServiceBrowserDelegate {
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        Log.debug(message: "Browser did find Service: \(service.name)", event: .info)
        self.serverList.append(service)
        self.delegate?.didUpdateServiceList(serviceList: self.serverList)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        
        Log.debug(message: "Browser did remove Service: \(service.name)", event: .info)
        if let index = self.serverList.firstIndex(of: service) {
            self.serverList.remove(at: index)
            self.delegate?.didUpdateServiceList(serviceList: self.serverList)
        }
    }
}

extension NetServerBrowser: ConnectDelegate {
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {
        
    }
    
    func didOpenDataChannel() {
        
    }
    
    func didReceiveData(data: Data) {
        
    }
    
    func didReceiveMessage(message: String) {
        
    }
    
    func didConnectWebRTC() {
        
    }
    
    func didDisconnectWebRTC() {
        
    }
}
