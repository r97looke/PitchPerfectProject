//
//  PlaySoundViewController.swift
//  PitchPerfectProject
//
//  Created by slchen on 2018/9/7.
//  Copyright © 2018 slchen. All rights reserved.
//

import UIKit
import AVFoundation

class PlaySoundViewController: UIViewController {

    var recordedFilePath: URL!
    var audioFile: AVAudioFile!
    var audioEngine: AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    var audioTimePitchNode: AVAudioUnitTimePitch!
    var audioEchoNode: AVAudioUnitDistortion!
    var audioReverbNode: AVAudioUnitReverb!
    var stopTimer: Timer!

    @IBOutlet weak var slowButton: UIButton!
    @IBOutlet weak var fastButton: UIButton!
    @IBOutlet weak var highPitchButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var lowPitchButton: UIButton!
    @IBOutlet weak var echoButton: UIButton!
    @IBOutlet weak var reverbButton: UIButton!

    enum Filter: Int {
        case slow = 0, fast, highPitch, lowPitch, echo, reverb
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI(false)

        do {
            try audioFile = AVAudioFile(forReading: recordedFilePath)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }

    @IBAction func playButtonTapped(_ sender: UIButton) {

        configureUI(true)

        switch Filter(rawValue: sender.tag)! {
        case .slow:
            playSound(rate: 0.5)
        case .fast:
            playSound(rate: 1.5)
        case .highPitch:
            playSound(pitch: 1000)
        case .lowPitch:
            playSound(pitch: -1000)
        case .echo:
            playSound(echo: true)
        case .reverb:
            playSound(reverb: true)
        }
    }

    @IBAction func stopButtonTapped(_ sender: Any) {
        print("stop button was pressed")

        stopAudio()
    }

    // MARK: private

    func configureUI(_ playing: Bool) {
        if (playing) {
            setPlayButtonEnabled(false)
            stopButton.isEnabled = true
        } else {
            setPlayButtonEnabled(true)
            stopButton.isEnabled = false
        }
    }

    func setPlayButtonEnabled(_ enabled: Bool) {
        slowButton.isEnabled = enabled
        fastButton.isEnabled = enabled
        highPitchButton.isEnabled = enabled
        lowPitchButton.isEnabled = enabled
        echoButton.isEnabled = enabled
        reverbButton.isEnabled = enabled
    }

    func connectAudioNode(_ audioNodes: AVAudioNode...) {
        for i in 0..<audioNodes.count - 1 {
            audioEngine.connect(audioNodes[i], to: audioNodes[i + 1], format: audioFile.processingFormat)
        }
    }

    func playSound(rate: Float = 1.0, pitch: Float = 0, echo: Bool = false, reverb: Bool = false) {
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)

        audioTimePitchNode = AVAudioUnitTimePitch()
        audioEngine.attach(audioTimePitchNode)

        audioEchoNode = AVAudioUnitDistortion()
        audioEchoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(audioEchoNode)

        audioReverbNode = AVAudioUnitReverb()
        audioReverbNode.loadFactoryPreset(.cathedral)
        audioReverbNode.wetDryMix = 50
        audioEngine.attach(audioReverbNode)

        if echo && reverb {
            connectAudioNode(audioPlayerNode, audioTimePitchNode, audioEchoNode, audioReverbNode, audioEngine.outputNode)
        } else if echo {
            connectAudioNode(audioPlayerNode, audioTimePitchNode, audioEchoNode, audioEngine.outputNode)
        } else if reverb {
            connectAudioNode(audioPlayerNode, audioTimePitchNode, audioReverbNode, audioEngine.outputNode)
        } else {
            connectAudioNode(audioPlayerNode, audioTimePitchNode, audioEngine.outputNode)
        }

        audioTimePitchNode.rate = rate
        audioTimePitchNode.pitch = pitch

        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            var delay: Double = 0

            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                delay = Double(self.audioFile.length - playerTime.sampleTime)/Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
            }

            self.stopTimer = Timer(timeInterval: delay, target: self, selector: #selector(PlaySoundViewController.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer, forMode: RunLoopMode.defaultRunLoopMode)
        }
        do {
            try audioEngine.start()
        } catch {
            showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return;
        }

        audioPlayerNode.play()
    }

    @objc func stopAudio() {

        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }

        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }

        configureUI(false)

        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}
