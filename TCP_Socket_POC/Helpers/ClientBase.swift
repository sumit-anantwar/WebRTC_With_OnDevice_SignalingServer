//
//  BaseConnect.swift
//  TCP_Socket_POC
//
//  Created by Jayesh Mardiya on 20/01/20.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import UIKit
import WebRTC
import CocoaAsyncSocket

protocol ConnectDelegate {
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState)
    func didReceiveData(data: Data)
    func didReceiveMessage(message: String)
    func didConnectWebRTC()
    func didDisconnectWebRTC()
}

class ClientBase: NSObject {
    
    var remoteStream: RTCMediaStream?
    var dataChannel: RTCDataChannel?
    
    var delegate: ConnectDelegate?
    public private(set) var isConnected: Bool = false
    
    private var socket: GCDAsyncSocket
    var peerConnectionFactory = RTCPeerConnectionFactory()
    
    lazy var peerConnection: RTCPeerConnection = {
        let rtcConf = RTCConfiguration()
        let mediaConstraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        let pc = self.peerConnectionFactory.peerConnection(with: rtcConf, constraints: mediaConstraints, delegate: nil)
        return pc
    }()
    
    init(socket: GCDAsyncSocket) {
        self.socket = socket
        super.init()
        
        self.socket.synchronouslySetDelegate(self)
        self.socket.synchronouslySetDelegateQueue(DispatchQueue.main)
        
        self.peerConnection.delegate = self
        
        self.dataChannel = self.setupDataChannel()
        self.dataChannel?.delegate = self
        
        self.connect()
    }
    
    deinit {
        print("WebRTC Client Deinit")
//        self.peerConnection = nil
    }
    
    func connect() {
        fatalError("Should override in subclass")
    }
    
    func disconnect() {
        self.peerConnection.close()
    }
}

extension ClientBase {
    
    func receiveCandidate(candidate: RTCIceCandidate) {
        self.peerConnection.add(candidate)
    }
    
    func receiveAnswer(answerSDP: RTCSessionDescription) {
        
        self.peerConnection.setRemoteDescription(answerSDP) { (err) in
            if let error = err {
                print("failed to set remote answer SDP")
                print(error)
                return
            }
        }
    }
    
    func receiveOffer(offerSDP: RTCSessionDescription, onCreateAnswer: @escaping (RTCSessionDescription) -> Void) {
        
        print("set remote description")
        self.peerConnection.setRemoteDescription(offerSDP) { (err) in
            if let error = err {
                print("failed to set remote offer SDP")
                print(error)
                return
            }
            
            print("succeed to set remote offer SDP")
            self.makeAnswer(onCreateAnswer: onCreateAnswer)
        }
    }
    
    func makeAnswer(onCreateAnswer: @escaping (RTCSessionDescription) -> Void) {
        
        self.peerConnection.answer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), completionHandler: { (answerSessionDescription, err) in
            
            if let error = err {
                print("failed to create local answer SDP")
                print(error)
                return
            }
            
            print("succeed to create local answer SDP")
            if let answerSDP = answerSessionDescription{
                self.peerConnection.setLocalDescription( answerSDP, completionHandler: { (err) in
                    if let error = err {
                        print("failed to set local ansewr SDP")
                        print(error)
                        return
                    }
                    
                    print("succeed to set local answer SDP")
                    onCreateAnswer(answerSDP)
                })
            }
        })
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
}
private extension ClientBase {
    
    func setupDataChannel() -> RTCDataChannel {
        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.channelId = 0
        
        let _dataChannel = self.peerConnection.dataChannel(forLabel: "dataChannel", configuration: dataChannelConfig)
        return _dataChannel!
    }
    
    func onConnected() {
        
        self.isConnected = true
        
        DispatchQueue.main.async {
            self.delegate?.didConnectWebRTC()
        }
    }
    
    func onDisConnected() {
        
        self.isConnected = false
        
        DispatchQueue.main.async {
            print("--- on dis connected ---")
            self.peerConnection.close()
            self.dataChannel = nil
            self.delegate?.didDisconnectWebRTC()
        }
    }
    
    func sendMessage(_ message: String) {
        
        let terminatorString = "\r\n"
        let messageToSend = "\(message)\(terminatorString)"
        let data = messageToSend.data(using: .utf8)!
        self.socket.write(data, withTimeout: -1, tag: 0)
        self.socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    func sendCandidate(_ iceCandidate: RTCIceCandidate) {
        
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
    
    func sendMessge(message: String) {
        
        if let _dataChannel = self.dataChannel {
            if _dataChannel.readyState == .open {
                let buffer = RTCDataBuffer(data: message.data(using: String.Encoding.utf8)!, isBinary: false)
                _dataChannel.sendData(buffer)
            } else {
                
                print("data channel is not ready state")
            }
        } else {
            print("no data channel")
        }
    }
    
    func sendData(data: Data) {
        if let _dataChannel = self.dataChannel {
            if _dataChannel.readyState == .open {
                let buffer = RTCDataBuffer(data: data, isBinary: true)
                _dataChannel.sendData(buffer)
            }
        }
    }
}

// MARK: - GCDAsyncSocketDelegate Delegeates
extension ClientBase: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        guard let text = String(data: data, encoding: .utf8) else { return }
        
        do {
            let signalingMessage = try JSONDecoder().decode(SignalingMessage.self, from: text.data(using: .utf8)!)
            
            if signalingMessage.type == "answer" {
                let answerSdp = RTCSessionDescription(type: .answer, sdp: (signalingMessage.sessionDescription?.sdp)!)
                self.receiveAnswer(answerSDP: answerSdp)
            } else if signalingMessage.type == "offer" {
                let offerSdp = RTCSessionDescription(type: .offer, sdp: (signalingMessage.sessionDescription?.sdp)!)
                self.receiveOffer(offerSDP: offerSdp, onCreateAnswer: { answerSDP in
                    self.sendSDP(sessionDescription: answerSDP)
                })
            } else if signalingMessage.type == "candidate" {
                let candidate = signalingMessage.candidate!
                self.receiveCandidate(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            }
        } catch {
            print(error)
        }
    }
}

// MARK: - PeerConnection Delegeates
extension ClientBase: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
    
        var state = ""
        if stateChanged == .stable {
            state = "stable"
        }
        
        if stateChanged == .closed {
            state = "closed"
        }
        
        print("signaling state changed: ", state)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
        switch newState {
        case .connected, .completed:
            if !self.isConnected {
                self.onConnected()
            }
        default:
            if self.isConnected {
                self.onDisConnected()
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.didIceConnectionStateChanged(iceConnectionState: newState)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("did add stream")
        self.remoteStream = stream
        
        if let audioTrack = stream.audioTracks.first{
            print("audio track faund")
            audioTrack.source.volume = 8
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.sendCandidate(candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("--- did remove stream ---")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
//        self.delegate?.didOpenDataChannel()
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
}

extension ClientBase: RTCDataChannelDelegate {
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        DispatchQueue.main.async {
            if buffer.isBinary {
                self.delegate?.didReceiveData(data: buffer.data)
            } else {
                self.delegate?.didReceiveMessage(message: String(data: buffer.data, encoding: String.Encoding.utf8)!)
            }
        }
    }
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("data channel did change state")
    }
}
