import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  AppSettings({
    this.isDarkMode = false,
    this.fontSize = 1,
    this.notificationEnabled = false,
    this.notificationMonth = 4,
    this.lastOpenedAt,
    this.isOnboardingDone = false,
  });

  factory AppSettings.defaults() => AppSettings();

  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  int fontSize;

  @HiveField(2)
  bool notificationEnabled;

  @HiveField(3)
  int notificationMonth;

  @HiveField(4)
  DateTime? lastOpenedAt;

  @HiveField(5)
  bool isOnboardingDone;

  AppSettings copyWith({
    bool? isDarkMode,
    int? fontSize,
    bool? notificationEnabled,
    int? notificationMonth,
    DateTime? lastOpenedAt,
    bool? isOnboardingDone,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSize: fontSize ?? this.fontSize,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationMonth: notificationMonth ?? this.notificationMonth,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      isOnboardingDone: isOnboardingDone ?? this.isOnboardingDone,
    );
  }
}
