/// Describes this installation to the API, so the account can list where
/// it is signed in.
class DeviceInfo {
  const DeviceInfo({this.name, this.platform, this.appVersion});

  final String? name;
  final String? platform;
  final String? appVersion;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (platform != null) 'platform': platform,
    if (appVersion != null) 'app_version': appVersion,
  };
}
