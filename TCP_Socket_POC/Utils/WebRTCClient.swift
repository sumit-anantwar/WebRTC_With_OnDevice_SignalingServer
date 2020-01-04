//
//  WebRTCClient.swift
//  SimpleWebRTC
//
//  Created by n0 on 2019/01/06.
//  Copyright © 2019年 n0. All rights reserved.
//

import UIKit
import WebRTC

protocol WebRTCClientDelegate {
    func didGenerateCandidate(iceCandidate: RTCIceCandidate)
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState)
    func didOpenDataChannel()
    func didReceiveData(data: Data)
    func didReceiveMessage(message: String)
    func didConnectWebRTC()
    func didDisconnectWebRTC()
}

class WebRTCClient: NSObject, RTCPeerConnectionDelegate, RTCDataChannelDelegate {

    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection?
    private var localAudioTrack: RTCAudioTrack!
    private var localView: UIView!
    private var remoteView: UIView!
    private var remoteStream: RTCMediaStream?
    private var dataChannel: RTCDataChannel?
    private var channels: (audio: Bool, datachannel: Bool) = (false, false)
    private var customFrameCapturer: Bool = false
    
    var delegate: WebRTCClientDelegate?
    public private(set) var isConnected: Bool = false
    
    override init() {
        super.init()
        print("WebRTC Client initialize")
    }
    
    deinit {
        print("WebRTC Client Deinit")
        self.peerConnectionFactory = nil
        self.peerConnection = nil
    }
    
    // MARK: - Public functions
    func setup(audioTrack: Bool, dataChannel: Bool, customFrameCapturer: Bool){
        print("set up")
        self.channels.audio = audioTrack
        self.channels.datachannel = dataChannel
        self.customFrameCapturer = customFrameCapturer
        
        self.peerConnectionFactory = RTCPeerConnectionFactory()
        
        setupLocalTracks()
    }
    
    func setupLocalViewFrame(frame: CGRect){
        localView.frame = frame
    }
    
    func setupRemoteViewFrame(frame: CGRect){
        remoteView.frame = frame
    }
    
    // MARK: Connect
    func connect(onSuccess: @escaping (RTCSessionDescription) -> Void){
        self.peerConnection = setupPeerConnection()
        self.peerConnection!.delegate = self
        
        if self.channels.audio {
            self.peerConnection!.add(localAudioTrack, streamIds: ["stream0"])
        }
        if self.channels.datachannel {
            self.dataChannel = self.setupDataChannel()
            self.dataChannel?.delegate = self
        }
        
        
        makeOffer(onSuccess: onSuccess)
    }
    
    // MARK: HangUp
    func disconnect(){
        if self.peerConnection != nil{
            self.peerConnection!.close()
        }
    }
    
    // MARK: Signaling Event
    func receiveOffer(offerSDP: RTCSessionDescription, onCreateAnswer: @escaping (RTCSessionDescription) -> Void){
        if(self.peerConnection == nil){
            print("offer received, create peerconnection")
            self.peerConnection = setupPeerConnection()
            self.peerConnection!.delegate = self
            
            if self.channels.audio {
                self.peerConnection!.add(localAudioTrack, streamIds: ["stream-0"])
            }
            if self.channels.datachannel {
                self.dataChannel = self.setupDataChannel()
                self.dataChannel?.delegate = self
            }
            
        }
        
        print("set remote description")
        self.peerConnection!.setRemoteDescription(offerSDP) { (err) in
            if let error = err {
                print("failed to set remote offer SDP")
                print(error)
                return
            }
            
            print("succeed to set remote offer SDP")
            self.makeAnswer(onCreateAnswer: onCreateAnswer)
        }
    }
    
    func receiveAnswer(answerSDP: RTCSessionDescription){
        self.peerConnection!.setRemoteDescription(answerSDP) { (err) in
            if let error = err {
                print("failed to set remote answer SDP")
                print(error)
                return
            }
        }
    }
    
    func receiveCandidate(candidate: RTCIceCandidate){
        self.peerConnection!.add(candidate)
    }
    
    // MARK: DataChannel Event
    func sendMessge(message: String){
        if let _dataChannel = self.dataChannel {
            if _dataChannel.readyState == .open {
                let buffer = RTCDataBuffer(data: message.data(using: String.Encoding.utf8)!, isBinary: false)
                _dataChannel.sendData(buffer)
            }else {
                
                print("data channel is not ready state")
            }
        }else{
            print("no data channel")
        }
    }
    
    func sendData(data: Data){
        if let _dataChannel = self.dataChannel {
            if _dataChannel.readyState == .open {
                let buffer = RTCDataBuffer(data: data, isBinary: true)
                _dataChannel.sendData(buffer)
            }
        }
    }
    
    // MARK: - Private functions
    // MARK: - Setup
    private func setupPeerConnection() -> RTCPeerConnection{
        let rtcConf = RTCConfiguration()
//        rtcConf.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        let mediaConstraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        let pc = self.peerConnectionFactory.peerConnection(with: rtcConf, constraints: mediaConstraints, delegate: nil)
        return pc
    }
    
    //MARK: - Local Media
    private func setupLocalTracks(){
        
        if self.channels.audio == true {
            self.localAudioTrack = createAudioTrack()
        }
    }
    
    private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.peerConnectionFactory.audioSource(with: audioConstrains)
        let audioTrack = self.peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        
        // audioTrack.source.volume = 10
        return audioTrack
    }
    
    // MARK: - Local Data
    private func setupDataChannel() -> RTCDataChannel{
        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.channelId = 0
        
        let _dataChannel = self.peerConnection?.dataChannel(forLabel: "dataChannel", configuration: dataChannelConfig)
        return _dataChannel!
    }
    
    // MARK: - Signaling Offer/Answer
    private func makeOffer(onSuccess: @escaping (RTCSessionDescription) -> Void) {
        self.peerConnection?.offer(for: RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)) { (sdp, err) in
            if let error = err {
                print("error with make offer")
                print(error)
                return
            }
            
            if let offerSDP = sdp {
                print("make offer, created local sdp")
                self.peerConnection!.setLocalDescription(offerSDP, completionHandler: { (err) in
                    if let error = err {
                        print("error with set local offer sdp")
                        print(error)
                        return
                    }
                    print("succeed to set local offer SDP")
                    onSuccess(offerSDP)
                })
            }
            
        }
    }
    
    private func makeAnswer(onCreateAnswer: @escaping (RTCSessionDescription) -> Void){
        self.peerConnection!.answer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), completionHandler: { (answerSessionDescription, err) in
            if let error = err {
                print("failed to create local answer SDP")
                print(error)
                return
            }
            
            print("succeed to create local answer SDP")
            if let answerSDP = answerSessionDescription{
                self.peerConnection!.setLocalDescription( answerSDP, completionHandler: { (err) in
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
    
    // MARK: - Connection Events
    private func onConnected(){
        self.isConnected = true
        
        DispatchQueue.main.async {
            self.delegate?.didConnectWebRTC()
        }
    }
    
    private func onDisConnected(){
        self.isConnected = false
        
        DispatchQueue.main.async {
            print("--- on dis connected ---")
            self.peerConnection!.close()
            self.peerConnection = nil
            self.dataChannel = nil
            self.delegate?.didDisconnectWebRTC()
        }
    }
}

// MARK: - PeerConnection Delegeates
extension WebRTCClient {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        var state = ""
        if stateChanged == .stable{
            state = "stable"
        }
        
        if stateChanged == .closed{
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
            if self.isConnected{
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
        self.delegate?.didGenerateCandidate(iceCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("--- did remove stream ---")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.delegate?.didOpenDataChannel()
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
}

// MARK: - RTCVideoView Delegate
extension WebRTCClient{
    
}

// MARK: - RTCDataChannelDelegate
extension WebRTCClient {
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        DispatchQueue.main.async {
            if buffer.isBinary {
                self.delegate?.didReceiveData(data: buffer.data)
            }else {
                self.delegate?.didReceiveMessage(message: String(data: buffer.data, encoding: String.Encoding.utf8)!)
            }
        }
    }
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("data channel did change state")
    }
}
