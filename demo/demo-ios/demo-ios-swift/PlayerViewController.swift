//
//  PlayerViewController.swift
//  demo-ios-swift
//
//  Created by Maksim Alyabyshev on 06.02.2018.
//  Copyright © 2018 single. All rights reserved.
//

import SGAVPlayer

class PlayerViewController: UIViewController {
    
    var player = SGAVPlayer.init()
    
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var progressSilder: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    var isProgressSilderTouching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        sg_registerNotification(
            for: player,
            playbackStateAction: #selector(playbackStateAction(_:)),
            loadStateAction: #selector(loadStateAction(_:)),
            currentTimeAction: #selector(currentTimeAction(_:)),
            loadedAction: #selector(loadedTimeAction(_:)),
            errorAction: #selector(errorAction(_:))
        )
        view.insertSubview(player.view, at: 0)
        let contentURL = URL(fileURLWithPath: Bundle.main.path(forResource: "i-see-fire", ofType: "mp4") ?? "")
        //    NSURL * contentURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
        player.replace(withContentURL: contentURL)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        player.view.frame = view.bounds
    }
    
    @IBAction func back(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func play(_ sender: Any) {
        player.play()
    }
    @IBAction func pause(_ sender: Any) {
        player.pause()
    }
    @IBAction func progressTouchDown(_ sender: Any) {
        isProgressSilderTouching = true
    }
    @IBAction func progressTouchUp(_ sender: Any) {
        isProgressSilderTouching = false
        player.seek(toTime: TimeInterval(Float(player.duration) * progressSilder.value))
    }
    
//    /**
//     *  Notification Name
//     */
//    SGPLAYER_EXTERN NSString * const SGPlayerPlaybackStateDidChangeNotificationName;
//    SGPLAYER_EXTERN NSString * const SGPlayerLoadStateDidChangeNotificationName;
//    SGPLAYER_EXTERN NSString * const SGPlayerCurrentTimeDidChangeNotificationName;
//    SGPLAYER_EXTERN NSString * const SGPlayerLoadedTimeDidChangeNotificationName;
//    SGPLAYER_EXTERN NSString * const SGPlayerDidErrorNotificationName;
//    /**
//     *  Notification Userinfo Key
//     */
//    SGPLAYER_EXTERN NSString * const SGPlayerNotificationUserInfoObjectKey;    // Common Object Key.

    @objc func playbackStateAction(_ notification: NSNotification) {
        let userInfo: [AnyHashable : Any]? = notification.userInfo!
        let playbackStateModel = userInfo!["SGPlayerNotificationUserInfoObjectKey"] as! SGPlaybackStateModel
        print("====> STATE  playback  SGPlaybackStateModel:", playbackStateModel.current ," = ", playbackStateModel.current.rawValue)
        
        var text: String
        switch playbackStateModel.current {
        case SGPlayerPlaybackState.idle:
            text = "Idle"
        case SGPlayerPlaybackState.playing:
            text = "Playing"
        case SGPlayerPlaybackState.seeking:
            text = "Seeking"
        case SGPlayerPlaybackState.paused:
            text = "Paused"
        case SGPlayerPlaybackState.interrupted:
            text = "Interrupted"
        case SGPlayerPlaybackState.stopped:
            text = "Stopped"
        case SGPlayerPlaybackState.finished:
            text = "Finished"
        case SGPlayerPlaybackState.failed:
            text = "Failed"
        }
        stateLabel.text = text
    }
    
    @objc func loadStateAction(_ notification: Notification) {
        let userInfo: [AnyHashable : Any]? = notification.userInfo!
        let loadStateModel = userInfo!["SGPlayerNotificationUserInfoObjectKey"] as! SGLoadedStateModel
        print("====> STATE  loaded  SGLoadedStateModel:", loadStateModel.current ," = ", loadStateModel.current.rawValue)

        if loadStateModel.current.rawValue == SGPlayerLoadState.playable.rawValue {
            if player.playbackState.rawValue == SGPlayerLoadState.idle.rawValue {
                player.play()
            }
        }
    }
    
    @objc func currentTimeAction(_ notification: Notification) {
//        let currentTimeModel: SGTimeModel? = notification.userInfo.sg_currentTimeModel()
        let userInfo: [AnyHashable : Any]? = notification.userInfo!
        let currentTimeModel = userInfo!["SGPlayerNotificationUserInfoObjectKey"] as! SGTimeModel
        print("====> STATE  time  currentTimeAction:", currentTimeModel.current ," = ", currentTimeModel.current.hashValue)
        
        if !isProgressSilderTouching {
            progressSilder.value = Float(currentTimeModel.percent)
        }
        currentTimeLabel.text = timeString(fromSeconds: CGFloat(currentTimeModel.current))
        totalTimeLabel.text = timeString(fromSeconds: CGFloat(currentTimeModel.duration))
        print("====> STATE  time  totalTimeLabel:", currentTimeModel.duration)
    }
    @objc func loadedTimeAction(_ notification: Notification) {
//        let loadedTimeModel: SGTimeModel? = notification.userInfo?.sg_loadedTimeModel()
        let userInfo: [AnyHashable : Any]? = notification.userInfo!
        let loadedTimeModel = userInfo!["SGPlayerNotificationUserInfoObjectKey"] as! SGTimeModel
        print("====> STATE  time  loadedTimeAction:", loadedTimeModel.current ," = ", loadedTimeModel.current.hashValue)
    }
    @objc func errorAction(_ notification: Notification) {
//        let error: Error? = notification.userInfo?.sg_error()
        let error = player.error
        print("====> ERROR: \(String(describing: error))")
    }
    func timeString(fromSeconds seconds: CGFloat) -> String {
        let minutes = String(Int((seconds / 60)))
        var seconds = String(Int(seconds) % 60)
        if seconds.count < 2 {
            seconds.insert("0", at: seconds.startIndex)
        }
        return minutes+":"+seconds
    }
    
    deinit {
        sg_removeNotification(for: player)
    }

}

