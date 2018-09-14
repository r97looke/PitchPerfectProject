//
//  RecordSoundViewController.swift
//  PitchPerfectProject
//
//  Created by slchen on 2018/9/7.
//  Copyright © 2018 slchen. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundViewController: UIViewController, AVAudioRecorderDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    var audioRecorder: AVAudioRecorder!

    override func viewDidLoad() {
        super.viewDidLoad()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch {
            showAlert(Alerts.AudioSessionError, message: String(describing: error))
        }

        updateUIWithRecording(false)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playSound" {
            let playSoundVC = segue.destination as! PlaySoundViewController
            let recordedFilePath = sender as! URL
            playSoundVC.recordedFilePath = recordedFilePath
        }
    }

    @IBAction func recordButtonTapped(_ sender: Any) {
        updateUIWithRecording(true)
        recordAudio()
    }

    @IBAction func stopButtonTapped(_ sender: Any) {
        updateUIWithRecording(false)
        stopRecord()
    }

    func updateUIWithRecording(_ recording: Bool) {
        if (recording) {
            statusLabel.text = "Tap to finish recording"
            recordButton.isHidden = true
            recordButton.isEnabled = false
            stopButton.isHidden = false
            stopButton.isEnabled = true
        } else {
            statusLabel.text = "Tap to start recording"
            recordButton.isHidden = false
            recordButton.isEnabled = true
            stopButton.isHidden = true
            stopButton.isEnabled = false
        }
    }

    func recordAudio() {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileName = "recorded.wav"
        let pathArray = [dir, fileName]
        let filePath = URL(string: pathArray.joined(separator: "/"))

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            showAlert(Alerts.AudioSessionError, message: String(describing: error))
            return;
        }

        do {
            try audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        } catch {
            showAlert(Alerts.AudioRecorderError, message: String(describing: error))
            return;
        }

        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }

    func stopRecord() {
        audioRecorder.stop()

        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }

    // MARK: AVAudioRecorderDelegate

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            performSegue(withIdentifier: "playSound", sender: recorder.url)
        } else {
            showAlert(Alerts.RecordingFailedTitle, message: Alerts.RecordingFailedMessage)
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            showAlert(Alerts.RecordingFailedTitle, message: String(describing: error))
        } else {
            showAlert(Alerts.RecordingFailedTitle, message: Alerts.RecordingFailedMessage)
        }
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}


