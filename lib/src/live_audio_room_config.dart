// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import 'package:zego_uikit/zego_uikit.dart';

// Project imports:
import 'live_audio_room_defines.dart';
import 'live_audio_room_translation.dart';

enum ZegoLiveAudioRoomRole {
  host,
  speaker,
  audience,
}

class ZegoUIKitPrebuiltLiveAudioRoomConfig {
  ZegoUIKitPrebuiltLiveAudioRoomConfig.host()
      : role = ZegoLiveAudioRoomRole.host,
        turnOnMicrophoneWhenJoining = true,
        useSpeakerWhenJoining = true,
        showInRoomMessageButton = true,
        audioVideoViewConfig = ZegoPrebuiltAudioVideoViewConfig(
          showSoundWavesInAudioMode: true,
        ),
        bottomMenuBarConfig = ZegoBottomMenuBarConfig(),
        memberListConfig = ZegoMemberListConfig(),
        inRoomMessageViewConfig = ZegoInRoomMessageViewConfig(),
        effectConfig = ZegoEffectConfig(),
        translationText = ZegoTranslationText(),
        confirmDialogInfo = ZegoDialogInfo(
          title: "Stop the live",
          message: "Are you sure to stop the live?",
          cancelButtonName: "Cancel",
          confirmButtonName: "Stop it",
        );

  ZegoUIKitPrebuiltLiveAudioRoomConfig.audience()
      : role = ZegoLiveAudioRoomRole.audience,
        turnOnMicrophoneWhenJoining = false,
        useSpeakerWhenJoining = true,
        showInRoomMessageButton = true,
        audioVideoViewConfig = ZegoPrebuiltAudioVideoViewConfig(
          showSoundWavesInAudioMode: true,
        ),
        bottomMenuBarConfig = ZegoBottomMenuBarConfig(),
        memberListConfig = ZegoMemberListConfig(),
        inRoomMessageViewConfig = ZegoInRoomMessageViewConfig(),
        effectConfig = ZegoEffectConfig(),
        translationText = ZegoTranslationText();

  ZegoUIKitPrebuiltLiveAudioRoomConfig({
    this.turnOnMicrophoneWhenJoining = true,
    this.useSpeakerWhenJoining = true,
    ZegoPrebuiltAudioVideoViewConfig? audioVideoViewConfig,
    ZegoBottomMenuBarConfig? bottomMenuBarConfig,
    ZegoMemberListConfig? memberListConfig,
    ZegoInRoomMessageViewConfig? messageConfig,
    ZegoEffectConfig? effectConfig,
    this.showInRoomMessageButton = true,
    this.confirmDialogInfo,
    this.onLeaveConfirmation,
    this.onLeaveLiveAudioRoom,
    this.avatarBuilder,
    ZegoTranslationText? translationText,
  })  : audioVideoViewConfig =
            audioVideoViewConfig ?? ZegoPrebuiltAudioVideoViewConfig(),
        bottomMenuBarConfig = bottomMenuBarConfig ?? ZegoBottomMenuBarConfig(),
        memberListConfig = memberListConfig ?? ZegoMemberListConfig(),
        inRoomMessageViewConfig =
            messageConfig ?? ZegoInRoomMessageViewConfig(),
        effectConfig = effectConfig ?? ZegoEffectConfig(),
        translationText = translationText ?? ZegoTranslationText();

  /// specify if a host or audience, speaker
  ZegoLiveAudioRoomRole role = ZegoLiveAudioRoomRole.audience;

  /// whether to enable the microphone by default, the default value is true
  bool turnOnMicrophoneWhenJoining;

  /// whether to use the speaker by default, the default value is true;
  bool useSpeakerWhenJoining;

  /// configs about bottom menu bar
  ZegoBottomMenuBarConfig bottomMenuBarConfig;

  /// support :
  /// 1. Face beautification
  /// 2. Voice changing
  /// 3. Reverb
  ZegoEffectConfig effectConfig;

  /// support message if set true
  bool showInRoomMessageButton;

  /// alert dialog information of leave
  /// if confirm info is not null, APP will pop alert dialog when you hang up
  ZegoDialogInfo? confirmDialogInfo;

  /// It is often used to customize the process before exiting the live interface.
  /// The liveback will triggered when user click hang up button or use system's return,
  /// If you need to handle custom logic, you can set this liveback to handle (such as showAlertDialog to let user determine).
  /// if you return true in the liveback, prebuilt page will quit and return to your previous page, otherwise will ignore.
  Future<bool> Function(BuildContext context)? onLeaveConfirmation;

  /// customize handling after leave audio room
  VoidCallback? onLeaveLiveAudioRoom;

  /// customize your user's avatar, default we use userID's first character as avatar
  /// User avatars are generally stored in your server, ZegoUIKitPrebuiltLiveAudioRoom does not know each user's avatar, so by default, ZegoUIKitPrebuiltLiveAudioRoom will use the first letter of the user name to draw the default user avatar, as shown in the following figure,
  ///
  /// |When the user is not speaking|When the user is speaking|
  /// |--|--|
  /// |<img src="https://doc.oa.zego.im/Pics/ZegoUIKit/Flutter/_default_avatar_nowave.jpg" width="10%">|<img src="https://doc.oa.zego.im/Pics/ZegoUIKit/Flutter/_default_avatar.jpg" width="10%">|
  ///
  /// If you need to display the real avatar of your user, you can use the avatarBuilder to set the user avatar builder method (set user avatar widget builder), the usage is as follows:
  ///
  /// ```dart
  ///
  ///  // eg:
  ///  avatarBuilder: (BuildContext context, Size size, ZegoUIKitUser? user, Map extraInfo) {
  ///    return user != null
  ///        ? Container(
  ///            decoration: BoxDecoration(
  ///              shape: BoxShape.circle,
  ///              image: DecorationImage(
  ///                image: NetworkImage(
  ///                  'https://your_server/app/avatar/${user.id}.png',
  ///                ),
  ///              ),
  ///            ),
  ///          )
  ///        : const SizedBox();
  ///  },
  ///
  /// ```
  ///
  ZegoAvatarBuilder? avatarBuilder;

  /// configs about audio video view
  ZegoPrebuiltAudioVideoViewConfig audioVideoViewConfig;

  /// configs about member list
  ZegoMemberListConfig memberListConfig;

  /// configs about message view
  ZegoInRoomMessageViewConfig inRoomMessageViewConfig;

  ZegoTranslationText translationText;
}

class ZegoPrebuiltAudioVideoViewConfig {
  /// hide avatar of audio video view if set false
  bool showAvatarInAudioMode;

  /// hide sound level of audio video view if set false
  bool showSoundWavesInAudioMode;

  /// customize your foreground of audio video view, which is the top widget of stack
  /// <br><img src="https://doc.oa.zego.im/Pics/ZegoUIKit/Flutter/_default_avatar_nowave.jpg" width="5%">
  /// you can return any widget, then we will put it on top of audio video view
  ZegoAudioVideoViewForegroundBuilder? foregroundBuilder;

  /// customize your background of audio video view, which is the bottom widget of stack
  ZegoAudioVideoViewBackgroundBuilder? backgroundBuilder;

  ZegoPrebuiltAudioVideoViewConfig({
    this.foregroundBuilder,
    this.backgroundBuilder,
    this.showAvatarInAudioMode = true,
    this.showSoundWavesInAudioMode = true,
  });
}

class ZegoBottomMenuBarConfig {
  /// these buttons will displayed on the menu bar, order by the list
  List<ZegoMenuBarButtonName> hostButtons = [];
  List<ZegoMenuBarButtonName> speakerButtons = [];
  List<ZegoMenuBarButtonName> audienceButtons = [];

  /// these buttons will sequentially added to menu bar,
  /// and auto added extra buttons to the pop-up menu
  /// when the limit [maxCount] is exceeded
  List<Widget> hostExtendButtons = [];
  List<Widget> speakerExtendButtons = [];
  List<Widget> audienceExtendButtons = [];

  /// limited item count display on menu bar,
  /// if this count is exceeded, More button is displayed
  int maxCount;

  ZegoBottomMenuBarConfig({
    this.hostButtons = const [
      ZegoMenuBarButtonName.soundEffectButton,
      ZegoMenuBarButtonName.toggleMicrophoneButton,
      ZegoMenuBarButtonName.showMemberListButton,
    ],
    this.speakerButtons = const [
      ZegoMenuBarButtonName.soundEffectButton,
      ZegoMenuBarButtonName.toggleMicrophoneButton,
      ZegoMenuBarButtonName.showMemberListButton,
    ],
    this.audienceButtons = const [
      ZegoMenuBarButtonName.showMemberListButton,
    ],
    this.hostExtendButtons = const [],
    this.speakerExtendButtons = const [],
    this.audienceExtendButtons = const [],
    this.maxCount = 5,
  });
}

class ZegoMemberListConfig {
  /// show microphone state or not
  bool showMicrophoneState;

  /// customize your item view of member list
  ZegoMemberListItemBuilder? itemBuilder;

  ZegoMemberListConfig({
    this.showMicrophoneState = true,
    this.itemBuilder,
  });
}

class ZegoInRoomMessageViewConfig {
  /// customize your item view of message list
  ZegoInRoomMessageItemBuilder? itemBuilder;

  ZegoInRoomMessageViewConfig({
    this.itemBuilder,
  });
}

class ZegoEffectConfig {
  List<VoiceChangerType> voiceChangeEffect;
  List<ReverbType> reverbEffect;

  ZegoEffectConfig({
    this.voiceChangeEffect = const [
      VoiceChangerType.littleGirl,
      VoiceChangerType.deep,
      VoiceChangerType.robot,
      VoiceChangerType.ethereal,
      VoiceChangerType.littleBoy,
      VoiceChangerType.female,
      VoiceChangerType.male,
      VoiceChangerType.optimusPrime,
      VoiceChangerType.crystalClear,
      VoiceChangerType.cMajor,
      VoiceChangerType.aMajor,
      VoiceChangerType.harmonicMinor,
    ],
    this.reverbEffect = const [
      ReverbType.ktv,
      ReverbType.hall,
      ReverbType.concert,
      ReverbType.rock,
      ReverbType.smallRoom,
      ReverbType.largeRoom,
      ReverbType.valley,
      ReverbType.recordingStudio,
      ReverbType.basement,
      ReverbType.popular,
      ReverbType.gramophone,
    ],
  });

  ZegoEffectConfig.none({
    this.voiceChangeEffect = const [],
    this.reverbEffect = const [],
  });

  bool get isSupportVoiceChange => voiceChangeEffect.isNotEmpty;

  bool get isSupportReverb => reverbEffect.isNotEmpty;
}