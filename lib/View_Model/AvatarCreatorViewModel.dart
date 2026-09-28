import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../utils/LogHelper.dart';
import 'SettingsDetailViewModel/PersonalInformationViewModel.dart';

class AvatarCreatorViewModel extends ChangeNotifier {
  InAppWebViewController? webViewController;
  String? avatarUrl;

  bool isLoader = false;

  updateWebViewController({required InAppWebViewController newWebViewController}) {
    webViewController = newWebViewController;
    notifyListeners();
  }

  updateAvatar({required ConsoleMessage consoleMessage}) {
    try {
      setLoading(true);
      final text = consoleMessage.message;
      notifyListeners();
      LogHelper("consoleMessage.message $text");

      if (text.contains("Avatar URL:")) {
        final url = text.split("Avatar URL:")[1].trim();
        avatarUrl = url;
        notifyListeners();
        LogHelper('New avatar Url: $url');
        PersonalInformationViewModel().updateUserProfile(avatarUrl: url, profilePic: url.replaceAll(".glb", ".jpg")).then(
          (value) {
            setLoading(false);
          },
        );
      }
    } catch (e) {
      LogHelper("Error $e");
      setLoading(false);
    }
  }

  setLoading(bool value) {
    isLoader = value;
    notifyListeners();
  }
}
