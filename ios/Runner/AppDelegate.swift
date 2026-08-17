import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(name: "com.vidyaloan/audio_check",
                                            binaryMessenger: controller.binaryMessenger)
    
    audioChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "isInCallOrMeet" {
        let isOtherAudioPlaying = AVAudioSession.sharedInstance().isOtherAudioPlaying
        let secondaryAudioSilenced = AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint
        result(isOtherAudioPlaying || secondaryAudioSilenced)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

