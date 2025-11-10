import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StealthProvider with ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  
  bool _isStealthMode = false;
  String _disguiseName = 'Calculator';
  String _disguiseIcon = 'calculator';
  
  bool get isStealthMode => _isStealthMode;
  String get disguiseName => _disguiseName;
  String get disguiseIcon => _disguiseIcon;
  
  /// Initialize stealth mode settings
  Future<void> initialize() async {
    final stealthEnabled = await _secureStorage.read(key: 'stealth_mode');
    final name = await _secureStorage.read(key: 'disguise_name');
    final icon = await _secureStorage.read(key: 'disguise_icon');
    
    _isStealthMode = stealthEnabled == 'true';
    _disguiseName = name ?? 'Calculator';
    _disguiseIcon = icon ?? 'calculator';
    
    notifyListeners();
  }
  
  /// Toggle stealth mode
  Future<void> toggleStealthMode() async {
    _isStealthMode = !_isStealthMode;
    await _secureStorage.write(key: 'stealth_mode', value: _isStealthMode.toString());
    notifyListeners();
  }
  
  /// Set disguise name and icon
  Future<void> setDisguise(String name, String icon) async {
    _disguiseName = name;
    _disguiseIcon = icon;
    await _secureStorage.write(key: 'disguise_name', value: name);
    await _secureStorage.write(key: 'disguise_icon', value: icon);
    notifyListeners();
  }
  
  /// Get available disguise options
  List<DisguiseOption> getDisguiseOptions() {
    return [
      DisguiseOption(name: 'Calculator', icon: 'calculator'),
      DisguiseOption(name: 'Notes', icon: 'notes'),
      DisguiseOption(name: 'Weather', icon: 'weather'),
      DisguiseOption(name: 'Clock', icon: 'clock'),
      DisguiseOption(name: 'Compass', icon: 'compass'),
      DisguiseOption(name: 'Flashlight', icon: 'flashlight'),
    ];
  }
}

class DisguiseOption {
  final String name;
  final String icon;
  
  DisguiseOption({required this.name, required this.icon});
}
