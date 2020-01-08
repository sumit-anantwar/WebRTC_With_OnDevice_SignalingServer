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
    
    private var connectedClients: [WebRTCClient] = []
    private var tcpPort: UInt16!
    
    var audioPlayer: AudioPlayer?
}

extension ServerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.audioPlayer = AudioPlayer()
        self.startServer()
    }
}

// MARK:- Action Methods -
extension ServerViewController {
    
    @IBAction func recordAudio(_ sender: UIButton) {
        audioPlayer?.recordAudio(with: self.serverName.text!, userType: .presenter)
    }
    
    @IBAction func stopRecording(_ sender: UIButton) {
        audioPlayer?.stopRecording()
    }
    
    @IBAction func playRecordedSound(_ sender: UIButton) {
        audioPlayer?.playRecordedSound()
    }
    
    @IBAction func stopPlaying(_ sender: UIButton) {
        audioPlayer?.stopPlaying()
    }
}

private extension ServerViewController {
    
    func startServer() {
        
        self.serverName.text = "Starting Server..."
        self.updateListenerCount()
        
//        self.webRtcClient.setup(audioTrack: true, dataChannel: true, customFrameCapturer: false)
        
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
        
        let newClient = WebRTCClient(socket: newSocket, isPresenter: true)
        self.connectedClients.append(newClient)
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

