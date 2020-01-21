//
//  ServerViewController.swift
//  TCP_Socket_POC
//
//  Created by Sumit Anantwar on 03/01/2020.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import UIKit

class ServerViewController: UIViewController {
    
    @IBOutlet var serverName: UILabel!
    @IBOutlet var listenerCount: UILabel!

    var netServiceServer = NetServiceServer()
    var audioPlayer: AudioPlayer?
}

extension ServerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.audioPlayer = AudioPlayer()
        self.serverName.text = "Starting Server..."
        self.netServiceServer.delegate = self
    }
}

extension ServerViewController: NetServiceServerDelegate {
    
    func setListenerCount(count: Int) {
        self.listenerCount.text = "\(count)"
    }
    
    func setServerName(name: String) {
        self.serverName.text = name
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
    
    
}
