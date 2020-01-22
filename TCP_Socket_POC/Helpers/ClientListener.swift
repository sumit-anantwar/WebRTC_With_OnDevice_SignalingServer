//
//  ClientPresenter.swift
//  TCP_Socket_POC
//
//  Created by Jayesh Mardiya on 18/01/20.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import UIKit
import WebRTC
import CocoaAsyncSocket

class ClientListener: ClientBase {

    private lazy var localAudioTrack: RTCAudioTrack = {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.peerConnectionFactory.audioSource(with: audioConstrains)
        let audioTrack = self.peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }()
    
    // MARK: Connect
    override func connect() {
        
        self.peerConnection.add(localAudioTrack, streamIds: ["stream0"])
        self.makeOffer { offerSdp in
            self.sendSDP(sessionDescription: offerSdp)
        }
    }
    
    // MARK: - Signaling Offer/Answer
    private func makeOffer(onSuccess: @escaping (RTCSessionDescription) -> Void) {
        self.peerConnection.offer(for: RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)) { (sdp, err) in
            if let error = err {
                print("error with make offer")
                print(error)
                return
            }
            
            if let offerSDP = sdp {
                print("make offer, created local sdp")
                self.peerConnection.setLocalDescription(offerSDP, completionHandler: { (err) in
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
}
