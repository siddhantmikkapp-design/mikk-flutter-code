import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class GlobalUnityController {
  static final GlobalUnityController _instance = GlobalUnityController._internal();
  factory GlobalUnityController() => _instance;
  GlobalUnityController._internal();

  UnityWidgetController? controller;
  Widget? _unityWidget;
  bool _isVisible = true;



  String _avatarUrl = "";
  String _roomName = "";
  int counter = 0;

  bool _clientConnected = false;
  bool _lobbySceneReady = false;


  // NEW: tracks a pending leave-confirmation wait
  Completer<void>? _leaveConfirmationCompleter;



  void setAvatarUrl(String url) {
    _avatarUrl = url;
  }

  String get avatarUrl => _avatarUrl;

  void setRoomName(String name){
    _roomName = name;
  }

  String get roomName => _roomName;

  Widget getUnityWidget({Function(UnityWidgetController)? onCreated}) {
    _unityWidget ??= UnityWidget(
      onUnityCreated: (controller) {
        this.controller = controller;
        if (onCreated != null) onCreated(controller);
      },
      onUnityMessage: onUnityMessage,

      fullscreen: true,
    );
    return _unityWidget!;
  }

  bool get isVisible => _isVisible;




  void showUnity() {
    _isVisible = true;
  }

  void hideUnity() {
    _isVisible = false;
  }

  void pauseUnity() {
    controller?.pause();

  }

  void resumeUnity() {
    controller?.resume();
    if(counter > 1) {
      startUnityOperation();
    }



  }


  void increment() {
    counter++;
  }


  // so a dead connection can't hang the UI forever.
  Future<void> waitForLeaveConfirmation({Duration timeout = const Duration(seconds: 3)}) async {
    _leaveConfirmationCompleter = Completer<void>();
    try {
      await _leaveConfirmationCompleter!.future.timeout(timeout);
    } catch (_) {
      // Timed out — proceed anyway rather than block the back button forever.
    } finally {
      _leaveConfirmationCompleter = null;
    }
  }






  void onUnityMessage(message) {
    if (message == "StartScreen" && counter <= 1) {
      _clientConnected = true;
      _tryStartUnityOperation();
    } else if (message == "LobbySceneReady") {
      _lobbySceneReady = true;
      _tryStartUnityOperation();
    } else if (message == "LeaveRoomConfirmed" || message == "LeaveRoomFailed") {
      if (_leaveConfirmationCompleter != null && !_leaveConfirmationCompleter!.isCompleted) {
        _leaveConfirmationCompleter!.complete();
      }
    }
  }

  void  _tryStartUnityOperation() {
    if (counter <= 1 && _lobbySceneReady) {
      increment();
      startUnityOperation();
    }

  }





  void startUnityOperation() async {
    GlobalUnityController().controller?.postMessage("CreateRoomMenu", "obtainNewSlide", _roomName);
    GlobalUnityController().controller?.postMessage("CreateRoomMenu", "obtainNewUrl", _avatarUrl);
    await Future.delayed(const Duration(seconds: 1));
    GlobalUnityController().controller?.postMessage("NetworkHudCanvas", "StartFlutterScreen", "");
  }




}







/*


class GlobalUnityController {
  static final GlobalUnityController _instance = GlobalUnityController._internal();
  factory GlobalUnityController() => _instance;
  GlobalUnityController._internal();

  UnityWidgetController? controller;
  Widget? _unityWidget;
  bool _isVisible = true;

  String _avatarUrl = "";
  String _roomName = "";
  void setAvatarUrl(String url) {
    _avatarUrl = url;
  }

  String get avatarUrl => _avatarUrl;

  void setRoomName(String name){
    _roomName = name;
  }

  String get roomName => _roomName;

  Widget getUnityWidget({Function(UnityWidgetController)? onCreated}) {
    _unityWidget ??= UnityWidget(
      onUnityCreated: (controller) {
        this.controller = controller;
        if (onCreated != null) onCreated(controller);
      },
      onUnityMessage: onUnityMessage,

      fullscreen: true,
    );
    return _unityWidget!;
  }

  bool get isVisible => _isVisible;

  void showUnity() {
    _isVisible = true;
  }

  void hideUnity() {
    _isVisible = false;
  }

  void pauseUnity() {
    controller?.pause();
  }

  void resumeUnity(bool isStart) {
    controller?.resume();
    if(isStart){
      StartUnityOperation();
    } else {
      //do nothing
    }
  }





  void onUnityMessage(message) {



  }

  void StartUnityOperation() async {
    GlobalUnityController().controller?.postMessage("CreateRoomMenu", "getroomname", "ava");
    GlobalUnityController().controller?.postMessage("CreateRoomMenu", "getavatarurl", _avatarUrl);
    await Future.delayed(Duration(seconds: 2));
    GlobalUnityController().controller?.postMessage("NetworkHudCanvas", "StartFlutterScreen", "");

  }
*/




