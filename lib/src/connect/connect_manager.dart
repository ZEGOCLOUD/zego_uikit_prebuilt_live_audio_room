// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/cupertino.dart';

// Project imports:
import 'package:zego_uikit_prebuilt_live_audio_room/src/components/dialogs.dart';
import 'package:zego_uikit_prebuilt_live_audio_room/src/components/permissions.dart';
import 'package:zego_uikit_prebuilt_live_audio_room/src/components/toast.dart';
import 'package:zego_uikit_prebuilt_live_audio_room/src/connect/defines.dart';
import 'package:zego_uikit_prebuilt_live_audio_room/src/seat/seat_manager.dart';
import 'package:zego_uikit_prebuilt_live_audio_room/zego_uikit_prebuilt_live_audio_room.dart';

class ZegoLiveConnectManager {
  ZegoLiveConnectManager({
    required this.config,
    required this.seatManager,
    required this.prebuiltController,
    required this.innerText,
    required this.contextQuery,
  }) {
    listenStream();
  }

  final ZegoUIKitPrebuiltLiveAudioRoomConfig config;
  final ZegoLiveSeatManager seatManager;
  final ZegoLiveAudioRoomController? prebuiltController;
  final BuildContext Function() contextQuery;
  final ZegoInnerText innerText;

  /// current audience connection state
  final audienceLocalConnectStateNotifier =
      ValueNotifier<ConnectState>(ConnectState.idle);

  /// audiences which requesting to take seat
  final audiencesRequestingTakeSeatNotifier =
      ValueNotifier<List<ZegoUIKitUser>>([]);

  /// audiences which host invite to take seat
  final List<String> _audienceIDsInvitedTakeSeatByHost = [];

  ///  invite dialog's visibility of audience
  bool _isInvitedTakeSeatDlgVisible = false;

  final List<StreamSubscription<dynamic>?> _subscriptions = [];

  void init() {
    _subscriptions
        .add(ZegoUIKit().getUserLeaveStream().listen(onUserListLeaveUpdated));
  }

  void uninit() {
    audienceLocalConnectStateNotifier.value = ConnectState.idle;
    audiencesRequestingTakeSeatNotifier.value = [];
    _isInvitedTakeSeatDlgVisible = false;
    _audienceIDsInvitedTakeSeatByHost.clear();

    for (final subscription in _subscriptions) {
      subscription?.cancel();
    }
  }

  void listenStream() {
    if (seatManager.plugins.plugins.isNotEmpty) {
      _subscriptions
        ..add(ZegoUIKit()
            .getSignalingPlugin()
            .getInvitationReceivedStream()
            .listen(onInvitationReceived))
        ..add(ZegoUIKit()
            .getSignalingPlugin()
            .getInvitationAcceptedStream()
            .listen(onInvitationAccepted))
        ..add(ZegoUIKit()
            .getSignalingPlugin()
            .getInvitationCanceledStream()
            .listen(onInvitationCanceled))
        ..add(ZegoUIKit()
            .getSignalingPlugin()
            .getInvitationRefusedStream()
            .listen(onInvitationRefused))
        ..add(ZegoUIKit()
            .getSignalingPlugin()
            .getInvitationTimeoutStream()
            .listen(onInvitationTimeout))
        ..add(ZegoUIKit()
            .getSignalingPlugin()
            .getInvitationResponseTimeoutStream()
            .listen(onInvitationResponseTimeout));
    }
  }

  Future<bool> inviteAudienceConnect(ZegoUIKitUser invitee) async {
    ZegoLoggerService.logInfo(
      'invite audience take seat, ${invitee.id} ${invitee.name}',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    if (invitee.isEmpty()) {
      ZegoLoggerService.logInfo(
        'invitee is empty',
        tag: 'live audio',
        subTag: 'connect manager',
      );
    }

    if (_audienceIDsInvitedTakeSeatByHost.contains(invitee.id)) {
      ZegoLoggerService.logInfo(
        'audience is inviting take seat',
        tag: 'live audio',
        subTag: 'connect manager',
      );
      return false;
    }

    _audienceIDsInvitedTakeSeatByHost.add(invitee.id);

    return ZegoUIKit()
        .getSignalingPlugin()
        .sendInvitation(
          inviterName: ZegoUIKit().getLocalUser().name,
          invitees: [invitee.id],
          timeout: 60,
          type: ZegoInvitationType.inviteToTakeSeat.value,
          data: '',
        )
        .then((result) {
      if (result.error != null) {
        _audienceIDsInvitedTakeSeatByHost.remove(invitee.id);

        config.onInviteAudienceToTakeSeatFailed?.call();

        showDebugToast('Failed to invite take seat, please try again.');
      }

      return result.error != null;
    });
  }

  void onInvitationReceived(Map<String, dynamic> params) {
    if (seatManager.isLeavingRoom) {
      ZegoLoggerService.logInfo(
        'on invitation received, but is leaving room...',
        tag: 'live audio',
        subTag: 'connect manager',
      );
      return;
    }

    final ZegoUIKitUser inviter = params['inviter']!;
    final int type = params['type']!; // call type
    final String data = params['data']!; // extended field

    final invitationType = ZegoInvitationTypeExtension.mapValue[type]!;

    ZegoLoggerService.logInfo(
      'on invitation received, data:${inviter.toString()},'
      ' $type($invitationType) $data',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    if (seatManager.localIsAHost) {
      if (ZegoInvitationType.requestTakeSeat == invitationType) {
        audiencesRequestingTakeSeatNotifier.value =
            List<ZegoUIKitUser>.from(audiencesRequestingTakeSeatNotifier.value)
              ..add(inviter);

        config.onSeatTakingRequested?.call(inviter);
      }
    } else {
      if (ZegoInvitationType.inviteToTakeSeat == invitationType) {
        onAudienceReceivedTakeSeatInvitation(inviter);
      }
    }
  }

  void onAudienceReceivedTakeSeatInvitation(ZegoUIKitUser host) {
    if (_isInvitedTakeSeatDlgVisible) {
      ZegoLoggerService.logInfo(
        'invite to take seat dialog is visible',
        tag: 'live audio',
        subTag: 'connect manager',
      );
      return;
    }

    if (-1 != seatManager.getIndexByUserID(ZegoUIKit().getLocalUser().id)) {
      ZegoLoggerService.logInfo(
        'audience is take on seat now',
        tag: 'live audio',
        subTag: 'connect manager',
      );
      return;
    }

    config.onHostSeatTakingInviteSent?.call();

    /// self-cancellation if requesting when host invite you
    ZegoLoggerService.logInfo(
      'audience self-cancel take seat request if requesting',
      tag: 'live audio',
      subTag: 'connect manager',
    );
    audienceCancelTakeSeatRequest().then((value) {
      showAudienceReceivedTakeSeatInvitationDialog(host);
    });
  }

  void showAudienceReceivedTakeSeatInvitationDialog(ZegoUIKitUser host) {
    final translation = innerText.hostInviteTakeSeatDialog;

    _isInvitedTakeSeatDlgVisible = true;
    showLiveDialog(
      context: contextQuery(),
      title: translation.title,
      content: translation.message,
      leftButtonText: translation.cancelButtonName,
      leftButtonCallback: () {
        _isInvitedTakeSeatDlgVisible = false;

        ZegoUIKit()
            .getSignalingPlugin()
            .refuseInvitation(inviterID: host.id, data: '')
            .then((result) {
          ZegoLoggerService.logInfo(
            'refuse take seat invite, result:$result',
            tag: 'live audio',
            subTag: 'connect manager',
          );
        });

        Navigator.of(contextQuery()).pop();
      },
      rightButtonText: translation.confirmButtonName,
      rightButtonCallback: () {
        _isInvitedTakeSeatDlgVisible = false;

        ZegoLoggerService.logInfo(
          'accept take seat invite',
          tag: 'live audio',
          subTag: 'connect manager',
        );

        ZegoUIKit()
            .getSignalingPlugin()
            .acceptInvitation(inviterID: host.id, data: '')
            .then((result) {
          ZegoLoggerService.logInfo(
            'accept take seat invite, result:$result',
            tag: 'live audio',
            subTag: 'connect manager',
          );

          if (result.error != null) {
            showDebugToast('accept take seat error: ${result.error}');
            return;
          }

          requestPermissions(
            context: contextQuery(),
            isShowDialog: true,
            innerText: innerText,
          ).then((_) {
            /// agree host's host, take seat, find the nearest seat index
            final targetSeatIndex = seatManager.getNearestEmptyIndex();
            ZegoLoggerService.logInfo(
              'accept take seat invite, target seat index is $targetSeatIndex',
              tag: 'live audio',
              subTag: 'connect manager',
            );
            seatManager
                .takeOnSeat(
              targetSeatIndex,
              isForce: false,
              isDeleteAfterOwnerLeft: true,
            )
                .then((result) {
              if (result) {
                ZegoUIKit().turnMicrophoneOn(true);
              }
            });
          });
        });

        Navigator.of(contextQuery()).pop();
      },
    );
  }

  void onInvitationAccepted(Map<String, dynamic> params) {
    final ZegoUIKitUser invitee = params['invitee']!;
    final String data = params['data']!; // extended field

    ZegoLoggerService.logInfo(
      'on invitation accepted, invitee:${invitee.toString()}, data:$data',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    if (seatManager.localIsAHost) {
      _audienceIDsInvitedTakeSeatByHost.remove(invitee.id);
    } else {
      requestPermissions(
        context: contextQuery(),
        isShowDialog: true,
        innerText: innerText,
      ).then((value) {
        /// host agree take seat, find the nearest seat index
        final targetSeatIndex = seatManager.getNearestEmptyIndex();
        if (targetSeatIndex < 0) {
          ZegoLoggerService.logInfo(
            'on invitation accepted, target seat index is $targetSeatIndex invalid',
            tag: 'live audio',
            subTag: 'connect manager',
          );

          updateAudienceConnectState(ConnectState.idle);
          return;
        }

        ZegoLoggerService.logInfo(
          'on invitation accepted, target seat index is $targetSeatIndex',
          tag: 'live audio',
          subTag: 'connect manager',
        );

        seatManager
            .takeOnSeat(
          targetSeatIndex,
          isForce: false,
          isDeleteAfterOwnerLeft: true,
        )
            .then((result) {
          ZegoLoggerService.logInfo(
            'on invitation accepted, take on seat result:$result',
            tag: 'live audio',
            subTag: 'connect manager',
          );

          if (result) {
            ZegoUIKit().turnMicrophoneOn(true);
          }
        });
      });
    }
  }

  void onInvitationCanceled(Map<String, dynamic> params) {
    final ZegoUIKitUser inviter = params['inviter']!;
    final String data = params['data']!; // extended field

    ZegoLoggerService.logInfo(
      'on invitation canceled, data:${inviter.toString()}, $data',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    if (seatManager.localIsAHost) {
      audiencesRequestingTakeSeatNotifier.value =
          List<ZegoUIKitUser>.from(audiencesRequestingTakeSeatNotifier.value)
            ..removeWhere((user) => user.id == inviter.id);

      config.onSeatTakingRequestCanceled?.call(inviter);
    }

    /// hide invite take seat dialog
    if (_isInvitedTakeSeatDlgVisible) {
      _isInvitedTakeSeatDlgVisible = false;
      Navigator.of(contextQuery()).pop();
    }
  }

  void onInvitationRefused(Map<String, dynamic> params) {
    final ZegoUIKitUser invitee = params['invitee']!;
    final String data = params['data']!; // extended field

    ZegoLoggerService.logInfo(
      'on invitation refused, data: $data, invitee:${invitee.toString()}',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    if (seatManager.localIsAHost) {
      _audienceIDsInvitedTakeSeatByHost.remove(invitee.id);

      /// host's invite is rejected by audience
      config.onSeatTakingInviteRejected?.call();

      showDebugToast(
          'Your request to take seat has been refused by ${ZegoUIKit().getUser(invitee.id)?.name ?? ''}');
    } else {
      /// audience's request is rejected by host
      config.onSeatTakingRequestRejected?.call();

      showDebugToast('Your request to take seat has been refused.');
      updateAudienceConnectState(ConnectState.idle);
    }
  }

  void onInvitationTimeout(Map<String, dynamic> params) {
    final ZegoUIKitUser inviter = params['inviter']!;
    final String data = params['data']!; // extended field

    ZegoLoggerService.logInfo(
      'on invitation timeout, data:${inviter.toString()}, $data',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    if (seatManager.localIsAHost) {
      audiencesRequestingTakeSeatNotifier.value =
          List<ZegoUIKitUser>.from(audiencesRequestingTakeSeatNotifier.value)
            ..removeWhere((user) => user.id == inviter.id);
    } else {
      /// hide invite take seat dialog
      if (_isInvitedTakeSeatDlgVisible) {
        _isInvitedTakeSeatDlgVisible = false;
        Navigator.of(contextQuery()).pop();
      }
    }
  }

  void onInvitationResponseTimeout(Map<String, dynamic> params) {
    final List<ZegoUIKitUser> invitees = params['invitees']!;
    final String data = params['data']!; // extended field

    ZegoLoggerService.logInfo(
      'on invitation response timeout, data: $data, '
      'invitees:${invitees.map((e) => e.toString())}',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    if (seatManager.localIsAHost) {
      for (final invitee in invitees) {
        _audienceIDsInvitedTakeSeatByHost.remove(invitee.id);
      }
    } else {
      config.onSeatTakingRequestFailed?.call();

      updateAudienceConnectState(ConnectState.idle);
    }
  }

  void removeRequestCoHostUsers(ZegoUIKitUser targetUser) {
    audiencesRequestingTakeSeatNotifier.value =
        List<ZegoUIKitUser>.from(audiencesRequestingTakeSeatNotifier.value)
          ..removeWhere((user) => user.id == targetUser.id);
  }

  void updateAudienceConnectState(ConnectState state) {
    if (state == audienceLocalConnectStateNotifier.value) {
      ZegoLoggerService.logInfo(
        'audience connect state is same: $state',
        tag: 'live audio',
        subTag: 'connect manager',
      );
      return;
    }

    ZegoLoggerService.logInfo(
      'update audience connect state: $state',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    switch (state) {
      case ConnectState.idle:
        ZegoUIKit().resetSoundEffect();

        ZegoUIKit().turnMicrophoneOn(false);

        /// hide invite join take seat dialog
        if (_isInvitedTakeSeatDlgVisible) {
          _isInvitedTakeSeatDlgVisible = false;
          Navigator.of(contextQuery()).pop();
        }

        break;
      case ConnectState.connecting:
        break;
      case ConnectState.connected:
        ZegoUIKit().turnMicrophoneOn(true);
        break;
    }

    audienceLocalConnectStateNotifier.value = state;
  }

  void onSeatLockedChanged(bool isLocked) {
    ZegoLoggerService.logInfo(
      'on seat locked changed: $isLocked',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    /// cancel if still requesting when room locked/unlocked
    audienceCancelTakeSeatRequest();

    if (!isLocked) {
      /// hide invite take seat dialog
      if (_isInvitedTakeSeatDlgVisible) {
        _isInvitedTakeSeatDlgVisible = false;
        Navigator.of(contextQuery()).pop();
      }
    }
  }

  void hostCancelTakeSeatInvitation() {
    ZegoLoggerService.logInfo(
      'host cancel take seat invitation',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    _audienceIDsInvitedTakeSeatByHost
      ..forEach((audienceID) {
        ZegoUIKit().getSignalingPlugin().cancelInvitation(
          invitees: [audienceID],
          data: '',
        );
      })
      ..clear();
  }

  Future<bool> audienceCancelTakeSeatRequest() async {
    ZegoLoggerService.logInfo(
      'audience cancel take seat request, connect state: ${audienceLocalConnectStateNotifier.value}',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    if (audienceLocalConnectStateNotifier.value == ConnectState.connecting) {
      return ZegoUIKit()
          .getSignalingPlugin()
          .cancelInvitation(
            invitees: seatManager.hostsNotifier.value,
            data: '',
          )
          .then((ZegoSignalingPluginCancelInvitationResult result) {
        updateAudienceConnectState(ConnectState.idle);

        ZegoLoggerService.logInfo(
          'audience cancel take seat request finished, '
          'code:${result.error?.code}, '
          'message:${result.error?.message}, '
          'errorInvitees:${result.errorInvitees}',
          tag: 'audio room',
          subTag: 'controller',
        );

        return result.error?.code.isNotEmpty ?? true;
      });
    }

    return true;
  }

  void onUserListLeaveUpdated(List<ZegoUIKitUser> users) {
    ZegoLoggerService.logInfo(
      'users leave, ${users.map((e) => e.toString()).toList()}',
      tag: 'live audio',
      subTag: 'connect manager',
    );

    final userIDs = users.map((e) => e.id).toList();
    _audienceIDsInvitedTakeSeatByHost
        .removeWhere((userID) => userIDs.contains(userID));
  }
}
