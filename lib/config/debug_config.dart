class DebugConfig {
  static bool _isDebugMode = false;
  static bool _showTrueValues = false;
  static bool _showAccuracyDetails = false;
  static bool _showCalculationDetails = false;
  static bool _showPotentials = false;

  // デバッグモードの切り替え
  static bool get isDebugMode => _isDebugMode;
  static set isDebugMode(bool value) => _isDebugMode = value;

  // 真の能力値表示
  static bool get showTrueValues => _showTrueValues;
  static set showTrueValues(bool value) => _showTrueValues = value;

  // 精度詳細表示
  static bool get showAccuracyDetails => _showAccuracyDetails;
  static set showAccuracyDetails(bool value) => _showAccuracyDetails = value;

  // 計算詳細表示
  static bool get showCalculationDetails => _showCalculationDetails;
  static set showCalculationDetails(bool value) => _showCalculationDetails = value;

  // ポテンシャル表示
  static bool get showPotentials => _showPotentials;
  static set showPotentials(bool value) => _showPotentials = value;

  // デバッグモードの切り替え
  static void toggleDebugMode() {
    _isDebugMode = !_isDebugMode;
  }

  // 全デバッグ機能の切り替え
  static void toggleAllDebugFeatures() {
    _isDebugMode = !_isDebugMode;
    if (_isDebugMode) {
      _showTrueValues = true;
      _showAccuracyDetails = true;
      _showCalculationDetails = true;
      _showPotentials = true;
    } else {
      _showTrueValues = false;
      _showAccuracyDetails = false;
      _showCalculationDetails = false;
      _showPotentials = false;
    }
  }

  // デバッグ設定のリセット
  static void resetDebugSettings() {
    _isDebugMode = false;
    _showTrueValues = false;
    _showAccuracyDetails = false;
    _showCalculationDetails = false;
    _showPotentials = false;
  }
} 