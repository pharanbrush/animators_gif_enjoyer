import 'package:package_info_plus/package_info_plus.dart';

PackageInfo? packageInfo;

void initializePackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
}

String get buildName {
  if (packageInfo == null) return 'x.x+x';
  return '${packageInfo!.version}.${packageInfo!.buildNumber}';
}
