import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  UserProfile _profile = UserProfile.getFakeProfile();

  UserProfile get profile => _profile;

  void updateProfile(UserProfile newProfile) {
    _profile = newProfile;
    notifyListeners();
  }
}

