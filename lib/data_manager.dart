import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();

  factory DataManager() {
    return _instance;
  }

  DataManager._internal();

  Position? _position;
  Map<String, String>? _prayerTimes;
  String? _location;
  String? _country;
  DateTime? _date;

  Position? get position => _position;
  Map<String, String>? get prayerTimes => _prayerTimes;
  String? get location => _location;
  String? get country => _country;
  DateTime? get date => _date;

  void setPosition(Position position) {
    _position = position;
    print('Position set: $position');
  }

  void setPrayerTimes(Map<String, String> prayerTimes, DateTime date) {
    _prayerTimes = prayerTimes;
    _date = date;
    print('Prayer times set: $prayerTimes for date: $date');
  }

  void setLocation(String location) {
    _location = location;
    print('Location set: $location');
  }

  void setCountry(String country) {
    _country = country;
    print('Country set: $country');
  }

  void setDate(DateTime date) {
    _date = date;
    print('Date set: $date');
  }

  void clearData() {
    _position = null;
    _prayerTimes = null;
    _location = null;
    _country = null;
    _date = null;
    print('Data cleared');
  }

  bool isCachedDataValid(String location, String country, DateTime date) {
    return _location == location &&
        _country == country &&
        _date != null &&
        _date!.year == date.year &&
        _date!.month == date.month &&
        _date!.day == date.day;
  }

  // New methods for saving and retrieving notification settings
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    settings.forEach((prayer, isEnabled) {
      prefs.setBool('notification_$prayer', isEnabled);
    });
  }

  Future<Map<String, bool>> getNotificationSettings(List<String> prayerNames) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, bool> settings = {};
    for (var prayer in prayerNames) {
      settings[prayer] = prefs.getBool('notification_$prayer') ?? false;
    }
    return settings;
  }
}
