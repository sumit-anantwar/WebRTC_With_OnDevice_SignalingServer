//
//  NetServiceServer.swift
//  TCP_Socket_POC
//
//  Created by Jayesh Mardiya on 21/01/20.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import WebRTC

protocol NetServiceServerDelegate {
    func setListenerCount(count: Int)
    func setServerName(name: String)
}

class NetServiceServer: NSObject {
    
    private var netService: NetService!
    private var asyncSocketServer: GCDAsyncSocket!
    private var connectedSockets: [GCDAsyncSocket] = []
    
    private var connectedClients: [ClientListener] = []
    private var tcpPort: UInt16!
    var delegate: NetServiceServerDelegate?
    
    override init() {
        super.init()
        self.startServer()
    }
    
    func startServer() {
        
        self.updateListenerCount()

        self.asyncSocketServer = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        if let server = self.asyncSocketServer {
            server.delegate = self
            
            do {
                try server.accept(onPort: 0)
            } catch {
                return
            }
            
            self.tcpPort = server.localPort
            
            server.perform {
                server.enableBackgroundingOnSocket()
            }
            
            server.autoDisconnectOnClosedReadStream = false

            self.netService = NetService(domain: "", type: "_populi._tcp.", name: "SPEAKER", port: Int32(self.tcpPort))
            self.netService.schedule(in: RunLoop.current, forMode: .common)
            self.netService.publish()
            self.netService.delegate = self
        }
    }
    
    func updateListenerCount() {
        let count = self.connectedSockets.count
        self.delegate?.setListenerCount(count: count)
    }
}

extension NetServiceServer: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
        self.connectedSockets.append(newSocket)
        self.updateListenerCount()
        
        let newClient = ClientListener(socket: newSocket)
        self.connectedClients.append(newClient)
    }
}

extension NetServiceServer: NetServiceDelegate {
    
    func netServiceDidPublish(_ sender: NetService) {
        Log.debug(message: "NetService did publish: \(sender.name)", event: .info)
        self.delegate?.setServerName(name: sender.name)
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        Log.debug(message: "NetService did not publish", event: .info)
    }
    
    func netServiceDidStop(_ sender: NetService) {
        Log.debug(message: "NetService did stop", event: .info)
    }
}
