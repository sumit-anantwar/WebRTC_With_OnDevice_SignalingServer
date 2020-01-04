//
//  WebRTCModels.swift
//  VoW
//
//  Created by Sumit Anantwar on 23/12/2019.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import Foundation

struct SignalingMessage: Codable {
    let type: String
    let sessionDescription: SDP?
    let candidate: Candidate?
}

struct SDP: Codable {
    let sdp: String
}

struct Candidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String
}
