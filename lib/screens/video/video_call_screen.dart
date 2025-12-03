// lib/screens/video/video_call_screen.dart

import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../utils/zego_config.dart';

class VideoCallScreen extends StatelessWidget {
  final String
  sessionId; // Firestore session doc id (not used directly by Zego)
  final String callId; // Zego call/room id
  final String localUserId;
  final String localUserName;

  const VideoCallScreen({
    super.key,
    required this.sessionId,
    required this.callId,
    required this.localUserId,
    required this.localUserName,
  });

  @override
  Widget build(BuildContext context) {
    // Base config from the UIKit
    final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
      // make sure camera + mic start ON
      ..turnOnCameraWhenJoining = true
      ..turnOnMicrophoneWhenJoining = true;

    return SafeArea(
      child: Scaffold(
        body: ZegoUIKitPrebuiltCall(
          appID: ZegoConfig.appId,
          appSign: ZegoConfig.appSign,
          callID: callId,
          userID: localUserId,
          userName: localUserName,
          config: config,
        ),
      ),
    );
  }
}
