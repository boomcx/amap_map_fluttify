import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:core_location_fluttify/core_location_fluttify.dart';
import 'package:flutter/material.dart';

import 'enums.dart';
import 'models.dart';
import 'options.dart';

/// marker点击事件回调签名 输入[Marker]对象
typedef OnMarkerClicked = FutureOr<void> Function(IMarker marker);

/// 地图点击事件回调签名
typedef OnMapClicked = FutureOr<void> Function(LatLng latLng);

/// 地图移动事件回调签名
typedef OnMapMove = FutureOr<void> Function(MapMove move);

/// Marker拖动回调签名
typedef OnMarkerDrag = FutureOr<void> Function(IMarker marker);

/// 地图控制类
abstract class IMapController {
  /// Dispose map controller.
  Future<void> dispose();

  /// Add tile overlay.
  Future<IUrlTileOverlay> addUrlTileOverlay(UrlTileOption option);

  /// Get current location.
  Future<LatLng?> getLocation();

  /// Show my location with [option].
  Future<void> showMyLocation(MyLocationOption option);

  /// 设置我的位置图标旋转角度
  Future<void> setMyLocationRotateAngle(double angle);

  /// 是否显示室内地图
  Future<void> showIndoorMap(bool show);

  /// 选择显示图层
  Future<void> setMapType(MapType mapType);

  /// 显示路况信息
  Future<void> showTraffic(bool enable);

  /// 显示缩放控件
  Future<void> showZoomControl(bool enable);

  /// 显示指南针
  Future<void> showCompass(bool enable);

  /// 显示定位按钮
  Future<void> showLocateControl(bool enable);

  /// 显示比例尺控件
  Future<void> showScaleControl(bool enable);

  /// 缩放手势使能
  Future<void> setZoomGesturesEnabled(bool enable);

  /// 滑动手势使能
  Future<void> setScrollGesturesEnabled(bool enable);

  /// 旋转手势使能
  Future<void> setRotateGesturesEnabled(bool enable);

  /// 旋转手势使能
  Future<void> setTiltGesturesEnabled(bool enable);

  /// 所有手势使能
  Future<void> setAllGesturesEnabled(bool enable);

  /// 设置缩放大小
  ///
  /// 地图的缩放级别一共分为 17 级，从 3 到 19. 数字越大，展示的图面信息越精细
  Future<void> setZoomLevel(double level, {bool animated = true});

  /// 获取当前缩放大小
  Future<double?> getZoomLevel();

  /// 设置缩放是否以中心点为锚点
  Future<void> setZoomByCenter(bool byCenter);

  /// 放大一个等级
  Future<void> zoomIn({bool animated = true});

  /// 放大一个等级
  Future<void> zoomOut({bool animated = true});

  /// 设置地图中心点
  ///
  /// [lat]纬度, [lng]经度, [zoomLevel]缩放等级, [bearing]地图选择角度, [tilt]倾斜角
  Future<void> setCenterCoordinate(
    LatLng coordinate, {
    double? zoomLevel,
    double? bearing,
    double? tilt,
    bool animated = true,
  });

  /// 获取地图中心点
  Future<LatLng?> getCenterCoordinate();

  /// 添加marker
  ///
  /// 在纬度[lat], 经度[lng]的位置添加marker, 并设置标题[title]和副标题[snippet], [iconUri]
  /// 可以是图片url, asset路径或者文件路径.
  /// 其中图片参数[imageConfig]如果不知道怎么创建, 那么就直接调用flutter sdk内提供的[createLocalImageConfiguration]方法创建
  Future<IMarker> addMarker(MarkerOption option);

  /// 批量添加marker
  ///
  /// 根据[options]批量创建Marker
  Future<List<IMarker>> addMarkers(List<MarkerOption> options);

  /// 把marker列表从地图上移除
  Future<void> clearMarkers(List<IMarker> markers);

  /// 清除地图上所有覆盖物
  ///
  /// 根据[keepMyLocation]区分是否保留我的位置的marker
  Future<void> clear({bool keepMyLocation = true});

  /// 屏幕坐标转经纬度坐标
  Future<LatLng?> fromScreenLocation(Point point);

  /// 经纬度坐标转屏幕坐标
  Future<Point?> toScreenLocation(LatLng coordinate);

  /// 添加折线
  ///
  /// 可配置参数详见[PolylineOption]
  Future<IPolyline> addPolyline(PolylineOption option);

  /// 添加多边形
  ///
  /// 在点[points]的位置添加线, 可以设置宽度[width]和颜色[strokeColor]
  Future<IPolygon> addPolygon(PolygonOption option);

  /// 添加圆
  ///
  /// 在点[points]的位置添加线, 可以设置宽度[width]和颜色[strokeColor]
  Future<ICircle> addCircle(CircleOption option);

  /// 设置marker点击监听事件
  Future<void> setMarkerClickedListener(OnMarkerClicked onMarkerClicked);

  /// 设置marker拖动监听事件
  Future<void> setMarkerDragListener({
    OnMarkerDrag? onMarkerDragStart,
    OnMarkerDrag? onMarkerDragging,
    OnMarkerDrag? onMarkerDragEnd,
  });

  /// 设置地图点击监听事件
  Future<void> setMapClickedListener(OnMapClicked onMapClick);

  /// 设置地图长按监听事件
  Future<void> setMapLongPressedListener(OnMapClicked onMapLongPress);

  /// 设置地图移动监听事件
  Future<void> setMapMoveListener({
    OnMapMove? onMapMoveStart,
    OnMapMove? onMapMoving,
    OnMapMove? onMapMoveEnd,
  });

  /// 截图
  Future<Uint8List?> screenShot();

  /// 限制地图的显示范围
  ///
  /// [southWest]西南角, [northEast]东北角
  Future<void> setMapRegionLimits(LatLng southWest, LatLng northEast);

  /// Marker弹窗点击事件监听
  Future<void> setInfoWindowClickListener(OnMarkerClicked onInfoWindowClicked);

  /// 添加图片覆盖物
  Future<IGroundOverlay> addGroundOverlay(GroundOverlayOption option);

  /// 添加热力图
  Future<IHeatmapOverlay> addHeatmapTileOverlay(HeatmapTileOption option);

  /// 将指定的经纬度列表(包括但不限于marker, polyline, polygon等)调整至同一屏幕中显示
  ///
  /// [bounds]边界点形成的边界, [padding]地图内边距
  Future<void> zoomToSpan(
    List<LatLng> bounds, {
    EdgeInsets padding = const EdgeInsets.all(50),
    bool animated = true,
  });

  /// 自定义地图
  ///
  /// 三个参数对应自定义地图压缩包内的三个文件
  Future<void> setCustomMapStyle({
    String styleDataPath,
    String styleExtraPath,
    String texturePath,
  });

  /// 添加平滑移动marker
  ///
  /// 根据[options]批量创建Marker
  Future<ISmoothMoveMarker> addSmoothMoveMarker(SmoothMoveMarkerOption option);

  /// 添加海量点
  Future<IMultiPointOverlay> addMultiPointOverlay(MultiPointOption option);

  /// 设置地图朝向
  ///
  /// [bearing] 朝向角度, 单位为度(°), 范围为[0°,360°]
  Future<void> setBearing(double bearing, {bool animated = true});

  /// 设置地图倾斜度
  Future<void> setTilt(double tilt, {bool animated = true});

  /// 显示/隐藏3D楼块效果
  Future<void> showBuildings(bool show);

  /// 显示/隐藏地图上的文字标注
  Future<void> showMapText(bool show);

  /// 一次性设置地图视角
  Future<void> setCameraPosition({
    required LatLng coordinate,
    double? zoom,
    double? tilt,
    double? bearing,
    bool animated = true,
    Duration duration = const Duration(milliseconds: 500),
  });

  /// 设置最大缩放等级
  Future<void> setMaxZoomLevel(double zoomLevel);

  /// 设置最小缩放等级
  Future<void> setMinZoomLevel(double zoomLevel);

  /// 设置地图锚点
  Future<void> setMapAnchor(double anchorU, double anchorV);

  /// 根据起点[from]和终点[to]坐标, 搜索出路径并将驾车路线规划结果[driveRouteResult]添加到地图上, 可以配置交通拥堵情况[trafficOption],
  /// 路线的宽度[lineWidth], 自定纹理[customTexture].
  Future<void> addDriveRoute({
    required LatLng from,
    required LatLng to,
    List<LatLng>? passbyPointList,
    TrafficOption? trafficOption,
    double lineWidth = 10,
    ImageProvider? customTexture,
  });

  /// 添加地区轮廓
  ///
  /// 地区名称[districtName], 轮廓宽度[width], 轮廓颜色[strokeColor], 填充颜色[fillColor]
  ///
  /// 由于一个省份可能包含多个区域, 比如浙江包含很多岛屿, 如果把岛屿也画进去, 那么会非常消耗性能.
  /// 业务上而言, 我认为这些岛屿是否画进去基本上不影响使用, 所以增加了[onlyMainDistrict]参数
  /// 来控制是否只显示主要部分的边界, 如果你对地区完整度的需求非常高, 那么就把[onlyMainDistrict]
  /// 设置为false, 随之而来像浙江这种地区的边界绘制起来就会非常慢.
  /// 我的测试结果是MIX 3, release模式下需要5-6秒才能绘制完成.
  ///
  /// 采样率[sampleRate]可以控制经纬度列表的密度, 如果地区边界的经纬度列表长度非常长, 造成了卡顿,
  /// 那么可以把采样率调低一点, 这样画出来的区域可能没有采样率为1时那么精确, 但是减小了经纬度列表长度,
  /// 可以提升绘制速度.
  Future<List<IPolygon>> addDistrictOutline(
    String districtName, {
    double width = 5,
    Color strokeColor = Colors.green,
    Color fillColor = Colors.transparent,
    bool onlyMainDistrict = true,
    double sampleRate = 1.0,
  });

  /// 添加回放轨迹
  ///
  /// [coordinateList] 路径经纬度列表
  /// [width] 路径宽度
  /// [strokeColor] 路径颜色
  /// [iconProvider] 移动marker的图标
  /// [duration] 移动时长
  Future<IPlaybackTrace> addPlaybackTrace(
    List<LatLng> coordinateList, {
    double width = 5,
    Color strokeColor = Colors.green,
    required ImageProvider iconProvider,
    required Duration duration,
  });

  /// 给地图添加padding
  Future<void> setPadding(EdgeInsets padding);

  /// 设置的地图刷新帧率
  Future<void> setFps(int fps);
}
