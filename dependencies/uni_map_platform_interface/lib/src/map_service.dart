/// 除了地图以外的功能放在这里, 比如说sdk初始化
abstract class IMapService {
  /// 设置ios和android的app key
  Future<void> init({
    String? iosKey,
    String? androidKey,
    String? webKey,
  });
}
