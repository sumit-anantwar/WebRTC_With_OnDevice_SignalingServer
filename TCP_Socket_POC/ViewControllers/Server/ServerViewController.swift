//
//  ServerViewController.swift
//  TCP_Socket_POC
//
//  Created by Sumit Anantwar on 03/01/2020.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import WebRTC

class ServerViewController: UIViewController {
    
    @IBOutlet var serverName: UILabel!
    @IBOutlet var listenerCount: UILabel!
    
    
    private var netService: NetService!
    private var asyncSocketServer: GCDAsyncSocket!
    private var connectedSockets: [GCDAsyncSocket] = []
    
    private var webRtcClient: WebRTCClient!
    private var tcpPort: UInt16!
}

extension ServerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.startServer()
    }
    
}

private extension ServerViewController {
    
    func startServer() {
        
        self.serverName.text = "Starting Server..."
        self.updateListenerCount()
        
        self.webRtcClient = WebRTCClient()
        self.webRtcClient.delegate = self
        self.webRtcClient.setup(audioTrack: true, dataChannel: true, customFrameCapturer: false)
        
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
        self.listenerCount.text = "Listeners: \(count)"
    }
    
}

extension ServerViewController : WebRTCClientDelegate {
    func didGenerateCandidate(iceCandidate: RTCIceCandidate) {
        let socket = self.connectedSockets.first!
        self.sendCandidate(iceCandidate: iceCandidate, to: socket)
    }
    
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

extension ServerViewController : GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
        self.connectedSockets.append(newSocket)
        self.updateListenerCount()
        
        self.webRtcClient.connect { offerSdp in
            self.sendSDP(sessionDescription: offerSdp, to: newSocket)
        }
        
//
//        let string = "Hello from the Server\r\n"
//        let data = string.data(using: .utf8)!
//        newSocket.write(data, withTimeout: -1, tag: 0)
//        newSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        
        do {
            let signalingMessage = try JSONDecoder().decode(SignalingMessage.self, from: text.data(using: .utf8)!)
            
            if signalingMessage.type == "answer" {
                self.webRtcClient.receiveAnswer(answerSDP: RTCSessionDescription(type: .answer, sdp: (signalingMessage.sessionDescription?.sdp)!))
            }else if signalingMessage.type == "candidate" {
                let candidate = signalingMessage.candidate!
                self.webRtcClient.receiveCandidate(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            }
        } catch {
            print(error)
        }
        
//        if let string = String(data: data, encoding: .utf8) {
//            Log.debug(message: string, event: .info)
//
//            let string = "Hello from the Server\r\n"
//            let d = string.data(using: .utf8)!
//            sock.write(d, withTimeout: -1, tag: 0)
//            sock.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
//        }
    }
}

private extension ServerViewController {
    
    func sendMessage(_ message: String, to socket: GCDAsyncSocket) {
        let terminatorString = "\r\n"
        let messageToSend = "\(message)\(terminatorString)"
        let data = messageToSend.data(using: .utf8)!
        socket.write(data, withTimeout: -1, tag: 0)
        socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    func sendSDP(sessionDescription: RTCSessionDescription, to socket: GCDAsyncSocket) {
        var type = ""
        if sessionDescription.type == .offer {
            type = "offer"
        } else if sessionDescription.type == .answer {
            type = "answer"
        }
        
        let sdp = SDP.init(sdp: sessionDescription.sdp)
        let signalingMessage = SignalingMessage.init(type: type,
                                                     sessionDescription: sdp,
                                                     candidate: nil)
        do {
            let data = try JSONEncoder().encode(signalingMessage)
            let message = String(data: data, encoding: String.Encoding.utf8)!
            
            self.sendMessage(message, to: socket)
            
        } catch {
            print(error)
        }
    }
    
    func sendCandidate(iceCandidate: RTCIceCandidate, to socket: GCDAsyncSocket) {
        let candidate = Candidate.init(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid!)
        let signalingMessage = SignalingMessage.init(type: "candidate",
                                                     sessionDescription: nil,
                                                     candidate: candidate)
        do {
            let data = try JSONEncoder().encode(signalingMessage)
            let message = String(data: data, encoding: String.Encoding.utf8)!
            
            self.sendMessage(message, to: socket)
        } catch {
            print(error)
        }
    }
}

extension ServerViewController : NetServiceDelegate {
    
    func netServiceDidPublish(_ sender: NetService) {
        Log.debug(message: "NetService did publish: \(sender.name)", event: .info)
        
        self.serverName.text = sender.name
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        Log.debug(message: "NetService did not publish", event: .info)
    }
    
    func netServiceDidStop(_ sender: NetService) {
        Log.debug(message: "NetService did stop", event: .info)
    }
}

