import 'package:core_location_fluttify/core_location_fluttify.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'options.dart';

abstract class IOverlay {
  Future<void> remove();
}

/// 地图标记
abstract class IMarker extends IOverlay {
  /// 获取标题
  Future<String> get title;

  /// 获取副标题
  Future<String> get snippet;

  /// 获取定位信息
  Future<LatLng> get coordinate;

  /// 获取自定义信息
  Future<String> get object;

  /// 设置坐标
  Future<void> setCoordinate(LatLng coordinate);

  /// 设置可见性
  Future<void> setVisible(bool visible);

  /// 显示弹窗
  Future<void> showInfoWindow();

  /// 关闭弹窗
  Future<void> hideInfoWindow();

  /// 设置图标
  Future<void> setIcon(
    ImageProvider iconProvider,
    ImageConfiguration configuration,
  );

  /// 设置动画
  Future<void> startAnimation(MarkerAnimation animation);

  /// 设置角度
  ///
  /// 单位度(°)
  Future<void> setAngle(double angle);

  /// 设置标题
  Future<void> setTitle(String title);

  /// 设置副标题
  Future<void> setSnippet(String snippet);
}

/// 平滑移动点
abstract class ISmoothMoveMarker extends IOverlay {
  Future<void> stop();
}

/// 折线
abstract class IPolyline extends IOverlay {
  /// 重新设置折线点列表
  ///
  /// 可用于轨迹记录
  Future<void> setCoordinateList(List<LatLng> coordinateList);
}

/// 多边形
abstract class IPolygon extends IOverlay {
  Future<bool> contains(LatLng target);
}

/// 圆形
abstract class ICircle extends IOverlay {
  /// 设置坐标
  Future<void> setCoordinate(LatLng coordinate);

  /// 设置半径
  Future<void> setRadius(double radius);
}

/// 热力图
abstract class IHeatmapOverlay extends IOverlay {}

/// 瓦片图
abstract class IUrlTileOverlay extends IOverlay {}

/// 图片覆盖物
abstract class IGroundOverlay extends IOverlay {}

/// 海量点
abstract class IMultiPointOverlay extends IOverlay {}

/// 回放轨迹
abstract class IPlaybackTrace extends IOverlay {
  Future<void> stop();
}
