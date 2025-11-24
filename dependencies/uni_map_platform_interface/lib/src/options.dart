import 'package:core_location_fluttify/core_location_fluttify.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'enums.dart';

/// 我的位置选项
@immutable
class MyLocationOption {
  MyLocationOption({
    this.show = true,
    this.myLocationType = MyLocationType.Locate,
    this.interval = Duration.zero,
    this.strokeColor = Colors.transparent,
    this.strokeWidth = 0,
    this.fillColor = Colors.transparent,
    this.iconProvider,
    this.anchorU,
    this.anchorV,
  });

  /// 是否显示
  final bool show;

  /// 定位类型
  final MyLocationType myLocationType;

  /// 定位间隔
  final Duration interval;

  /// 边框颜色
  final Color strokeColor;

  /// 边框宽度
  final double strokeWidth;

  /// 填充颜色
  final Color fillColor;

  /// 图标
  ///
  /// 资源图片则使用[AssetImage], 网络图片则使用[NetworkImage], 文件图片则使用[FileImage]
  final ImageProvider? iconProvider;

  /// 锚点
  final double? anchorU, anchorV;

  @override
  String toString() {
    return 'MyLocationOption{show: $show, myLocationType: $myLocationType, interval: $interval, strokeColor: $strokeColor, strokeWidth: $strokeWidth, fillColor: $fillColor, iconProvider: $iconProvider, anchorU: $anchorU, anchorV: $anchorV}';
  }
}

/// Marker创建参数
@immutable
class MarkerOption {
  MarkerOption({
    required this.coordinate,
    this.title = '',
    this.snippet = '',
    this.widget,
    this.draggable = false,
    this.infoWindowEnabled = true,
    this.visible = true,
    this.rotateAngle = 0,
    this.anchorU = 0.5,
    this.anchorV = 0,
    this.object,
    this.opacity,
    this.iconProvider,
    this.iconsProvider,
    this.animationFps,
    this.infoWindow,
  }) : assert(!(widget != null && iconProvider != null),
            'widget和iconProvider不能同时设置! ');

  /// 经纬度
  final LatLng coordinate;

  /// 标题
  final String title;

  /// 副标题
  final String snippet;

  /// Widget形式的Marker
  ///
  /// 不能和[iconProvider]一起用.
  /// 注意控制Widget的大小, 比如Column默认是max, 会使用地图的高度, 那么此时需要设置成min.
  final Widget? widget;

  /// 是否可拖动
  final bool draggable;

  /// 是否允许弹窗
  final bool infoWindowEnabled;

  /// 是否可见
  final bool visible;

  /// 旋转角度 单位为度(°)
  final double rotateAngle;

  /// 横轴锚点
  final double anchorU;

  /// 纵轴锚点
  final double anchorV;

  /// 自定义数据 理论上可以使用任何类型的数据, 但是为了减少意外情况, 这里一律转换成String来保存
  final String? object;

  /// 透明度
  final double? opacity;

  /// 图标
  final ImageProvider? iconProvider;

  /// 帧动画图标
  final List<ImageProvider>? iconsProvider;

  /// 帧动画帧率
  ///
  /// 最大60, 最小3
  final int? animationFps;

  final Widget? infoWindow;

  @override
  String toString() {
    return 'MarkerOption{coordinate: $coordinate, title: $title, snippet: $snippet, widget: $widget, draggable: $draggable, infoWindowEnabled: $infoWindowEnabled, visible: $visible, rotateAngle: $rotateAngle, anchorU: $anchorU, anchorV: $anchorV, object: $object, iconProvider: $iconProvider}';
  }
}

/// 平滑移动Marker创建参数
@immutable
class SmoothMoveMarkerOption {
  SmoothMoveMarkerOption({
    required this.path,
    required this.duration,
    required this.iconProvider,
  });

  /// 轨迹经纬度列表
  final List<LatLng> path;

  /// 图标
  final ImageProvider iconProvider;

  /// 动画时长
  final Duration duration;

  @override
  String toString() {
    return 'SmoothMoveMarkerOption{path: $path, iconProvider: $iconProvider, duration: $duration}';
  }
}

/// Polyline创建参数
@immutable
class PolylineOption {
  PolylineOption({
    required this.coordinateList,
    this.width = 5,
    this.strokeColor = Colors.green,
    this.textureProvider,
    this.lineCapType,
    this.lineJoinType,
    this.dashType,
  });

  /// 经纬度列表
  final List<LatLng> coordinateList;

  /// 宽度
  final double width;

  /// 颜色
  final Color strokeColor;

  /// 自定义纹理
  final ImageProvider? textureProvider;

  /// 线段末端样式
  final LineCapType? lineCapType;

  /// 线段连接处样式
  final LineJoinType? lineJoinType;

  /// 是否虚线
  final DashType? dashType;

  @override
  String toString() {
    return 'PolylineOption{latLngList: $coordinateList, width: $width, strokeColor: $strokeColor, textureProvider: $textureProvider, lineCapType: $lineCapType, lineJoinType: $lineJoinType, dashType: $dashType}';
  }
}

/// Polygon创建参数
@immutable
class PolygonOption {
  PolygonOption({
    required this.coordinateList,
    this.width = 5,
    this.strokeColor = Colors.green,
    this.fillColor = Colors.transparent,
    this.zIndex,
  });

  /// 经纬度列表
  final List<LatLng> coordinateList;

  /// 宽度
  final double width;

  /// 边框颜色
  final Color strokeColor;

  /// 填充颜色
  final Color fillColor;

  /// z index
  final double? zIndex;

  @override
  String toString() {
    return 'PolygonOption{latLngList: $coordinateList, width: $width, strokeColor: $strokeColor, fillColor: $fillColor}';
  }
}

/// Circle创建参数
@immutable
class CircleOption {
  /// 中心点经纬度
  final LatLng center;

  /// 宽度
  final double radius;

  /// 宽度
  final double width;

  /// 边框颜色
  final Color strokeColor;

  /// 填充颜色
  final Color fillColor;

  CircleOption({
    required this.center,
    required this.radius,
    this.width = 5,
    this.strokeColor = Colors.green,
    this.fillColor = Colors.transparent,
  });

  @override
  String toString() {
    return 'CircleOption{center: $center, radius: $radius, width: $width, strokeColor: $strokeColor, fillColor: $fillColor}';
  }
}

/// TileOverlay创建参数
@immutable
class HeatmapTileOption {
  HeatmapTileOption({
    required this.coordinateList,
    this.gradient,
  });

  /// 中心点经纬度
  final List<LatLng> coordinateList;

  /// 热力图渐变色配置
  ///
  /// [RadialGradient.stops]的值范围为(0,1), 默认值为[0.2,0.5,0.9]
  /// [RadialGradient.stops]和[RadialGradient.colors]列表的长度必须一致
  final RadialGradient? gradient;

  @override
  String toString() {
    return 'HeatmapTileOption{latLngList: $coordinateList}';
  }
}

/// 图片覆盖物创建参数
@immutable
class GroundOverlayOption {
  GroundOverlayOption({
    required this.southWest,
    required this.northEast,
    required this.imageProvider,
  });

  final LatLng southWest;
  final LatLng northEast;
  final ImageProvider imageProvider;

  @override
  String toString() {
    return 'GroundOverlayOption{southWest: $southWest, northEast: $northEast, imageProvider: $imageProvider}';
  }
}

/// 瓦片图创建参数
@immutable
class UrlTileOption {
  UrlTileOption({
    required this.width,
    required this.height,
    required this.urlTemplate,
  });

  /// 单位瓦片图宽度
  final int width;

  /// 单位瓦片图高度
  final int height;

  /// 瓦片图地址模板
  ///
  /// 瓦片图地址模板是一个包含"{x}","{y}","{z}","{scale}"的字符串,"{x}","{y}","{z}","{scale}"会被tile path的值所替换，
  /// 并生成用来加载tile图片数据的URL 。例如 http://server/path?x={x}&y={y}&z={z}&scale={scale}
  final String urlTemplate;

  @override
  String toString() {
    return 'UrlTileOption{width: $width, height: $height, urlTemplate: $urlTemplate}';
  }
}

/// 海量点创建参数
@immutable
class MultiPointOption {
  MultiPointOption({
    required this.pointList,
    this.iconProvider,
  });

  /// 点列表
  final List<PointOption> pointList;

  /// 图标
  final ImageProvider? iconProvider;

  @override
  String toString() {
    return 'MultiPointOption{pointList: $pointList, iconProvider: $iconProvider}';
  }
}

/// 海量点中单个点的创建参数
@immutable
class PointOption {
  PointOption({
    required this.coordinate,
    this.id,
    this.title,
    this.snippet,
    this.object,
  });

  /// 经纬度
  final LatLng coordinate;

  /// 点的id列表, 用来区分点
  final String? id;

  /// 标题列表
  final String? title;

  /// 副标题列表
  final String? snippet;

  /// 自定义数据
  final String? object;

  @override
  String toString() {
    return 'PointOption{coordinate: $coordinate, id: $id, title: $title, snippet: $snippet, object: $object}';
  }
}

/// 地图移动
@immutable
class MapMove {
  MapMove({
    this.coordinate,
    this.zoom,
    this.tilt,
    this.bearing,
    this.isAbroad,
  });

  /// 经纬度
  final LatLng? coordinate;

  /// 缩放等级
  final double? zoom;

  /// 倾斜度
  final double? tilt;

  /// 朝向
  final double? bearing;

  /// 是否是国外
  final bool? isAbroad;

  @override
  String toString() {
    return 'MapMove{latLng: $coordinate, zoom: $zoom, tilt: $tilt, bearing: $bearing, isAbroad: $isAbroad}';
  }
}

/// 屏幕坐标
@immutable
class TraceLocation {
  TraceLocation({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bearing,
    required this.time,
  });

  final double latitude;
  final double longitude;
  final double speed;
  final double bearing;
  final int time;

  @override
  String toString() {
    return 'TraceLocation{latitude: $latitude, longitude: $longitude, speed: $speed, bearing: $bearing, time: $time}';
  }
}

/// 交通配置
@immutable
class TrafficOption {
  TrafficOption({
    required this.show,
    this.goodColor = Colors.green,
    this.badColor = Colors.yellow,
    this.terribleColor = Colors.red,
    this.unknownColor = Colors.blue,
  });

  /// 是否显示
  final bool show;

  /// 通畅路段颜色
  final Color goodColor;

  /// 缓行路段颜色
  final Color badColor;

  /// 拥堵路段颜色
  final Color terribleColor;

  /// 未知路段颜色
  final Color unknownColor;

  @override
  String toString() {
    return 'TrafficOption{show: $show, goodColor: $goodColor, badColor: $badColor, terribleColor: $terribleColor, unknownColor: $unknownColor}';
  }
}

/// marker动画基类
@immutable
class MarkerAnimation {
  MarkerAnimation(
    this.duration,
    this.repeatCount,
    this.repeatMode,
    this.fromValue,
    this.toValue,
  );

  final Duration duration;
  final int repeatCount;
  final RepeatMode repeatMode;
  final double? fromValue;
  final double? toValue;

  @override
  String toString() {
    return 'MarkerAnimation{duration: $duration, repeatCount: $repeatCount, repeatMode: $repeatMode, fromValue: $fromValue, toValue: $toValue}';
  }
}

/// marker缩放动画
@immutable
class ScaleMarkerAnimation extends MarkerAnimation {
  ScaleMarkerAnimation({
    Duration duration = const Duration(seconds: 1),
    int repeatCount = 1,
    RepeatMode repeatMode = RepeatMode.Reverse,
    double? fromValue,
    double? toValue,
  }) : super(duration, repeatCount, repeatMode, fromValue, toValue);

  @override
  String toString() {
    return 'ScaleMarkerAnimation{fromValue: $fromValue, toValue: $toValue}';
  }
}

/// marker透明度动画
@immutable
class AlphaMarkerAnimation extends MarkerAnimation {
  AlphaMarkerAnimation({
    Duration duration = const Duration(seconds: 1),
    int repeatCount = 1,
    RepeatMode repeatMode = RepeatMode.Reverse,
    double? fromValue,
    double? toValue,
  }) : super(duration, repeatCount, repeatMode, fromValue, toValue);

  @override
  String toString() {
    return 'AlphaMarkerAnimation{fromValue: $fromValue, toValue: $toValue}';
  }
}

/// marker旋转动画
@immutable
class RotateMarkerAnimation extends MarkerAnimation {
  RotateMarkerAnimation({
    Duration duration = const Duration(seconds: 1),
    int repeatCount = 1,
    RepeatMode repeatMode = RepeatMode.Reverse,
    double? fromValue,
    double? toValue,
  }) : super(duration, repeatCount, repeatMode, fromValue, toValue);

  @override
  String toString() {
    return 'RotateMarkerAnimation{fromValue: $fromValue, toValue: $toValue}';
  }
}

/// marker移动动画
@immutable
class TranslateMarkerAnimation extends MarkerAnimation {
  TranslateMarkerAnimation({
    Duration duration = const Duration(seconds: 1),
    int repeatCount = 1,
    RepeatMode repeatMode = RepeatMode.Reverse,
    required this.coordinate,
  }) : super(duration, repeatCount, repeatMode, null, null);

  final LatLng coordinate;

  @override
  String toString() {
    return 'TranslateMarkerAnimation{toValue: $coordinate}';
  }
}

/// marker动画集合
@immutable
class MarkerAnimationSet extends MarkerAnimation {
  MarkerAnimationSet({
    this.animationSet,
    required Duration duration,
    int repeatCount = 1,
    RepeatMode repeatMode = RepeatMode.Reverse,
  }) : super(duration, repeatCount, repeatMode, null, null);

  final List<MarkerAnimation>? animationSet;

  @override
  String toString() {
    return 'MarkerAnimationSet{animationSet: $animationSet}';
  }
}
