//
//  AudioPlayer.swift
//  TCP_Socket_POC
//
//  Created by Jayesh on 06/01/2020.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation
import AVFoundation

var SKIP_TIME = 0.0
var SKIP_INTERVAL = 0.2

enum UserType {
    case listener
    case presenter
}

enum AudioPlayerState {
    case playing
    case pause
    case stop
    case completed
}

protocol AudioPlayerDelegate: class {
    func updateButton(audioState: AudioPlayerState)
    func updateCurrentTime(currTime: Double)
    func updateCurrentLevelforPlayer(currLevel: Float)
}

class AudioPlayer: NSObject, AVAudioRecorderDelegate {
    
    private var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    weak var audioPlayerDelegate: AudioPlayerDelegate?

    private var mySession: AVAudioSession?
    private var updateTimer: Timer?
    private var rewTimer: Timer?
    private var ffwTimer: Timer?

    private var inBackground: Bool = false

    private var playerTimer: Timer?
    private var levelValue: Float = 0.0
    private var mute: Bool = false
    var isRecording = false
    var audioService = AudioService(nil)

    override init() {
        super.init()

        self.registerForBackgroundNotifications()

        self.updateTimer = nil
        self.rewTimer = nil
        self.ffwTimer = nil

        self.mute = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioServiceDidUpdateData), name: .audioServiceDidUpdateData, object: nil)
    }

    func setupAudioPlayer(with fileUrl: URL) throws {

        self.mySession = AVAudioSession.sharedInstance()
        try self.mySession?.setCategory(.playback)
        try self.mySession?.setActive(true, options: .notifyOthersOnDeactivation)

        try self.audioPlayer = AVAudioPlayer(contentsOf: fileUrl)

        if let player = self.audioPlayer {
            player.isMeteringEnabled = true
            player.delegate = self
            player.setVolume(1.0, fadeDuration: .greatestFiniteMagnitude)
        }

        if self.playerTimer == nil {
            self.playerTimer = Timer.scheduledTimer(timeInterval: 0.001,
                                                    target: self,
                                                    selector: #selector(monitorAudioPlayer),
                                                    userInfo: nil, repeats: true)
        }
    }
    
    func recordAudio(with fileName: String, userType: UserType) {
        
        if userType == .listener {
            
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playAndRecord)))
                try session.setActive(false)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        if let docsDir = FileUtils.createFolderInDocumentDir(folderName: userType == UserType.listener ? "Stream" : "Record") {

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmss"

            let fileName = "\(userType == UserType.listener ? "Stream" : "Record")__\(fileName)_\(formatter.string(from: Date())).wav"
            let soundFilePath = docsDir.appendingPathComponent(path: fileName)
            
            let url = URL(fileURLWithPath: soundFilePath)
            
            let recordSettings:[String:Any] = [
                AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                AVEncoderBitRateKey: 16,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0
            ]
            do {
                audioRecorder = try AVAudioRecorder(url: url, settings: recordSettings)
                audioRecorder?.delegate = self
            } catch {
                print(error.localizedDescription)
            }
        }
        
        self.audioRecorder?.prepareToRecord()
        self.audioRecorder?.record()
        self.isRecording = true
    }
    
    func stopRecording() {
        if self.audioRecorder != nil {
            self.audioRecorder?.stop()
            self.isRecording = false
        }
    }
    
    func playRecordedSound() {
        if self.isRecording == false {
            self.audioPlayer?.stop()
            self.audioPlayer?.currentTime = 0.0
            self.audioPlayer?.play()
        }
    }
    
    func stopPlaying() {
        if self.isRecording == false {
            self.audioPlayer?.stop()
            self.audioPlayer?.currentTime = 0.0
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag == true {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: recorder.url)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func getDuration() -> Double {
        return self.audioPlayer?.duration ?? 0.0
    }

    func play() {
        if let player = self.audioPlayer {
            player.prepareToPlay()
            player.play()
            self.audioPlayerDelegate?.updateButton(audioState: .playing)
            self.updateViewForPlayerState(player: player)
        }
    }

    func pause() {
        if let player = self.audioPlayer {
            if player.isPlaying {
                player.pause()
            }

            self.audioPlayerDelegate?.updateButton(audioState: .pause)
            self.updateViewForPlayerState(player: player)
        }
    }

    func stop() {
        if let player = self.audioPlayer {
            player.stop()
            player.currentTime = 0
            self.audioPlayerDelegate?.updateButton(audioState: .stop)
            self.updateViewForPlayerState(player: player)
        }
    }

    @objc func rewind() {
        if let timer = self.rewTimer {
            if let player: AVAudioPlayer = timer.userInfo as? AVAudioPlayer {
                player.currentTime -= SKIP_TIME
                self.updateCurrentTimeForPlayer(player: player)
            }
        }
    }

    @objc func forward() {
        if let timer = self.ffwTimer {
            if let player: AVAudioPlayer = timer.userInfo as? AVAudioPlayer {
                player.currentTime -= SKIP_TIME
                self.updateCurrentTimeForPlayer(player: player)
            }
        }
    }

    func rewindPressed() {
        if let timer = self.rewTimer {
            timer.invalidate()
        }

        self.rewTimer = Timer(timeInterval: SKIP_INTERVAL,
                              target: self,
                              selector: #selector(rewind),
                              userInfo: self.audioPlayer, repeats: true)
    }

    func rewindReleased() {
        if let timer = self.rewTimer {
            timer.invalidate()
        }
        self.rewTimer = nil
    }

    func forwardPressed() {
        if let timer = self.ffwTimer {
            timer.invalidate()
        }
        self.ffwTimer = Timer(timeInterval: SKIP_INTERVAL,
                              target: self,
                              selector: #selector(forward),
                              userInfo: self.audioPlayer, repeats: true)
    }

    func forwardReleased() {
        if let timer = self.ffwTimer {
            timer.invalidate()
        }
        self.ffwTimer = nil
    }

    func adjustProgress(progress: Float) {
        if let player = self.audioPlayer {
            player.currentTime = TimeInterval(progress)
            self.updateCurrentTimeForPlayer(player: player)
        }
    }

    func registerForBackgroundNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setInBackgroundFlag),
                                               name: NSNotification.Name.NSExtensionHostWillResignActive,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(clearInBackgroundFlag),
                                               name: NSNotification.Name.NSExtensionHostWillEnterForeground,
                                               object: nil)
    }

    @objc func setInBackgroundFlag() {
        self.inBackground = true
    }

    @objc func clearInBackgroundFlag() {
        self.inBackground = false
    }

    func closeAudioSession() {
        self.mySession = nil
        self.playerTimer?.invalidate()
        self.updateTimer?.invalidate()
    }

    func muteVolume() {
        if !self.mute {
            self.audioPlayer?.volume = 0
        } else {
            self.audioPlayer?.volume = 1
        }

        self.mute = !self.mute
    }

    @objc func monitorAudioPlayer() {
        if let player = self.audioPlayer {
            player.updateMeters()
            let numberOfChannels: Int = player.numberOfChannels

            for index in 0...numberOfChannels {

                let percentage = pow(10, (0.05 * player.averagePower(forChannel: index)))
                self.audioPlayerDelegate?.updateCurrentLevelforPlayer(currLevel: percentage)
            }
        }
    }

    func updateCurrentTimeForPlayer(player: AVAudioPlayer?) {
        self.audioPlayerDelegate?.updateCurrentTime(currTime: player!.currentTime)
    }

    @objc func updateCurrentTime() {
        self.updateCurrentTimeForPlayer(player: self.audioPlayer)
    }

    func updateViewForPlayerState(player: AVAudioPlayer?) {
        self.updateCurrentTimeForPlayer(player: player!)

        if let timer = self.updateTimer {
            timer.invalidate()
        }

        if let player = player {
            if player.isPlaying {
                self.updateTimer = Timer.scheduledTimer(timeInterval: 0.001,
                                                        target: self,
                                                        selector: #selector(updateCurrentTime),
                                                        userInfo: nil, repeats: true)
            } else {
                self.updateTimer = nil
            }
        }
    }

    func updateViewForPlayerStateInBackground(player: AVAudioPlayer?) {
        self.updateCurrentTimeForPlayer(player: player!)
        self.audioPlayerDelegate?.updateButton(audioState: .pause)
    }
    
    @objc private func audioServiceDidUpdateData(notification: Notification) {
        
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.audioPlayerDelegate?.updateButton(audioState: .completed)
    }

    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        if self.inBackground {
            self.updateViewForPlayerStateInBackground(player: player)
        } else {
            self.updateViewForPlayerState(player: player)
        }
    }

    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        self.play()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
    return input.rawValue
}
