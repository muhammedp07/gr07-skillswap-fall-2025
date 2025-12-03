// lib/screens/video/video_call_screen.dart

import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../utils/zego_config.dart'; // wherever you put your appId/appSign

class VideoCallScreen extends StatelessWidget {
  final String callId;
  final String localUserId;
  final String localUserName;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.localUserId,
    required this.localUserName,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: ZegoUIKitPrebuiltCall(
          appID: ZegoConfig.appId, // from zego_config.dart
          appSign: ZegoConfig.appSign,
          callID: callId,
          userID: localUserId,
          userName: localUserName,

          // one-on-one video call layout
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
          // if we later want custom behaviour when the user leaves,
          // we can use other callbacks from this config.
        ),
      ),
    );
  }
}
