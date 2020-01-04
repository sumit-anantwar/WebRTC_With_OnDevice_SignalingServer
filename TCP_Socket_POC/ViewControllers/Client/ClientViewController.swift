//
//  ClientViewController.swift
//  TCP_Socket_POC
//
//  Created by Sumit Anantwar on 03/01/2020.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import WebRTC

class ClientViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    
    private var netServiceBrowser: NetServiceBrowser!
    private var serverService: NetService!
    private var currentServerService: NetService!

    private var serverList: [NetService] = []
    private var serverAddresses: [Data] = []
    
    private var webRtcClient: WebRTCClient!
    private var hostSocket: GCDAsyncSocket!
    
    
}
// MARK: - ViewController LifeCycle
extension ClientViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.uiSetup()
        self.startBrowser()
    }
    
}

private extension ClientViewController {
    
    func uiSetup() {
        ServerCell.register(with: self.tableView)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 40
    }
    
    func startBrowser() {
        self.webRtcClient = WebRTCClient()
        self.webRtcClient.delegate = self
        self.webRtcClient.setup(audioTrack: true, dataChannel: true, customFrameCapturer: false)
        
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

extension ClientViewController : WebRTCClientDelegate {
    func didGenerateCandidate(iceCandidate: RTCIceCandidate) {
        self.sendCandidate(iceCandidate: iceCandidate)
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

extension ClientViewController : NetServiceDelegate {
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses
            else { return }
        
        self.serverAddresses = addresses
        guard let addr = addresses.first else { return }
        
        let socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        socket.delegate = self
        do {
            try socket.connect(toAddress: addr)
            socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
            self.hostSocket = socket
        } catch {
            return
        }
        
    }
}

// MARK: - NetServiceBrowserDelegate
extension ClientViewController : NetServiceBrowserDelegate {
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        Log.debug(message: "Browser did find Service: \(service.name)", event: .info)
        self.serverList.append(service)
        self.tableView.reloadData()
    }
}

extension ClientViewController : GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        guard let text = String(data: data, encoding: .utf8) else { return }
        
        do {
            let signalingMessage = try JSONDecoder().decode(SignalingMessage.self, from: text.data(using: .utf8)!)
            
            if signalingMessage.type == "offer" {
                self.webRtcClient.receiveOffer(offerSDP: RTCSessionDescription(type: .offer, sdp: (signalingMessage.sessionDescription?.sdp)!), onCreateAnswer: {(answerSDP: RTCSessionDescription) -> Void in
                    self.sendSDP(sessionDescription: answerSDP)
                })
            } else if signalingMessage.type == "candidate" {
                let candidate = signalingMessage.candidate!
                self.webRtcClient.receiveCandidate(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            }
        } catch {
            print(error)
        }
    }
    
}

private extension ClientViewController {
    
    func sendMessage(_ message: String) {
        let terminatorString = "\r\n"
        let messageToSend = "\(message)\(terminatorString)"
        let data = messageToSend.data(using: .utf8)!
        
        if let socket = self.hostSocket {
            socket.write(data, withTimeout: -1, tag: 0)
            socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
        }
    }
    
    func sendSDP(sessionDescription: RTCSessionDescription) {
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
            
            self.sendMessage(message)
            
        } catch {
            print(error)
        }
    }
    
    func sendCandidate(iceCandidate: RTCIceCandidate) {
        let candidate = Candidate.init(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid!)
        let signalingMessage = SignalingMessage.init(type: "candidate",
                                                     sessionDescription: nil,
                                                     candidate: candidate)
        do {
            let data = try JSONEncoder().encode(signalingMessage)
            let message = String(data: data, encoding: String.Encoding.utf8)!
            
            self.sendMessage(message)
        } catch {
            print(error)
        }
    }
}

extension ClientViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.serverList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let server = self.serverList.item(at: indexPath.row)
        else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ServerCell.cellId) as! ServerCell
        cell.serverName.text = server.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.connectToServer(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

