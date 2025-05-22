import 'package:amap_core_fluttify/amap_core_fluttify.dart';
import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:amap_map_fluttify/src/android/com/amap/api/maps/model/LatLng.g.dart';
import 'package:core_location_fluttify/core_location_fluttify.dart';
import 'package:flutter/material.dart';
import 'package:uni_map_platform_interface/uni_map_platform_interface.dart';

import '../android/android.export.g.dart';
import '../ios/ios.export.g.dart';
import 'extensions.dart';
import 'list.x.dart';

/// 地图标记
class Marker implements IMarker {
  Marker.android(this.androidModel);

  Marker.ios(this.iosModel, this.iosController);

  com_amap_api_maps_model_Marker? androidModel;

  MAPointAnnotation? iosModel;
  MAMapView? iosController;

  /// 获取标题
  @override
  Future<String> get title async {
    return platform(
      android: (_) async => await androidModel!.getTitle() ?? '',
      ios: (_) async => await iosModel!.get_title() ?? '',
    );
  }

  /// 获取副标题
  @override
  Future<String> get snippet {
    return platform(
      android: (_) async => await androidModel!.getSnippet() ?? '',
      ios: (_) async => await iosModel!.get_subtitle() ?? '',
    );
  }

  /// 获取定位信息
  @override
  Future<LatLng> get coordinate {
    return platform(
      android: (_) async {
        final _location = await androidModel!.getPosition();
        return LatLng(
          await _location!.get_latitude() ?? 0,
          await _location.get_longitude() ?? 0,
        );
      },
      ios: (_) async {
        final location = await iosModel!.get_coordinate();
        return LatLng(
          await location!.latitude ?? 0,
          await location.longitude ?? 0,
        );
      },
    );
  }

  /// 获取自定义信息
  @override
  Future<String> get object {
    return platform(
      android: (_) {
        return androidModel!.getObject().then((object) => object as String);
      },
      ios: (_) {
        return iosModel!
            .getJsonableProperty__(7)
            .then((object) => object as String);
      },
    );
  }

  /// 删除marker
  @override
  Future<void> remove() async {
    return platform(
      android: (_) => androidModel!.remove(),
      ios: (_) => iosController!.removeAnnotation(iosModel!),
    );
  }

  /// 设置坐标
  @override
  Future<void> setCoordinate(LatLng coordinate) async {
    return platform(
      android: (_) async => androidModel!.setPosition(
        await com_amap_api_maps_model_LatLng.create__double__double(
          coordinate.latitude,
          coordinate.longitude,
        ),
      ),
      ios: (_) async {
        final annotationView =
            await iosController!.viewForAnnotation(iosModel!);
        if (annotationView != null) {
          final _coordinate = await CLLocationCoordinate2D.create(
            coordinate.latitude,
            coordinate.longitude,
          );
          await iosModel!.set_coordinate(_coordinate);
          await annotationView.set_annotation(iosModel!);
        } else {
          debugPrint('当前_annotationView为null, 无法设置经纬度!');
        }
      },
    );
  }

  /// 设置可见性
  @override
  Future<void> setVisible(bool visible) async {
    return platform(
      android: (_) => androidModel!.setVisible(visible),
      ios: (_) async {
        await iosModel!.setVisible(visible);

        final annotationView =
            await iosController!.viewForAnnotation(iosModel!);
        await annotationView?.setHidden(!visible);
      },
    );
  }

  /// 显示弹窗
  @override
  Future<void> showInfoWindow() async {
    return platform(
      android: (_) => androidModel!.showInfoWindow(),
      ios: (_) => iosController!.selectAnnotation_animated(iosModel!, true),
    );
  }

  /// 关闭弹窗
  @override
  Future<void> hideInfoWindow() async {
    return platform(
      android: (_) => androidModel!.hideInfoWindow(),
      ios: (_) => iosController!.deselectAnnotation_animated(iosModel!, true),
    );
  }

  /// 设置图标
  @override
  Future<void> setIcon(
    ImageProvider iconProvider,
    ImageConfiguration configuration,
  ) async {
    final iconData = await iconProvider.toImageData(configuration);
    return platform(
      android: (pool) async {
        final bitmap = await android_graphics_Bitmap.create(iconData);
        final icon = await com_amap_api_maps_model_BitmapDescriptorFactory
            .fromBitmap(bitmap);
        await androidModel!.setIcon(icon!);
      },
      ios: (pool) async {
        final icon = await UIImage.create(iconData);

        // 这里和annotationView?.set_image看上去是做同一件事情, 但其实是针对两种不同情况
        // 如果marker是屏幕内, 那会直接走annotationView?.set_image;
        // 如果不在屏幕内, 那么annotationView?.set_image不会被执行, 如果此marker后来
        // 进入到屏幕内后, 此时需要同步annotation的数据, 如果不给annotation设置值, 那么
        // 渲染的时候还是上次的图片
        await iosModel!.setIcon(icon);
        final annotationView =
            await iosController!.viewForAnnotation(iosModel!);
        await annotationView?.set_image(
          icon,
        );
      },
    );
  }

  /// 设置动画
  @override
  Future<void> startAnimation(MarkerAnimation animation) async {
    return platform(
      android: (pool) async {
        final _animation = await animation.toAndroidModel();
        await androidModel!.setAnimation(_animation);
        await androidModel!.startAnimation();

        pool.add(_animation);
      },
      ios: (pool) async {
        final annotationView =
            await iosController!.viewForAnnotation(iosModel!);
        final imageView = await annotationView!.get_imageView();

        if (animation is ScaleMarkerAnimation) {
          await imageView?.scaleWithDuration(
            fromValue: animation.fromValue!,
            toValue: animation.toValue!,
            duration: animation.duration,
            repeatCount: animation.repeatCount,
            repeatMode: animation.repeatMode.index,
          );
        } else if (animation is AlphaMarkerAnimation) {
          await imageView?.alphaWithDuration(
            fromValue: animation.fromValue!,
            toValue: animation.toValue!,
            duration: animation.duration,
            repeatCount: animation.repeatCount,
            repeatMode: animation.repeatMode.index,
          );
        } else if (animation is RotateMarkerAnimation) {
          await imageView?.rotateWithDuration(
            fromValue: animation.fromValue!,
            toValue: animation.toValue!,
            duration: animation.duration,
            repeatCount: animation.repeatCount,
            repeatMode: animation.repeatMode.index,
          );
        } else if (animation is TranslateMarkerAnimation) {
          // FIXME 地图移动后, 移动终点仍然在最开始设置的终点, 应该以经纬度作为标准而不是屏幕坐标
          await imageView?.translateWithDuration(
            toValue: (await iosController!.convertCoordinate_toPointToView(
              await animation.coordinate.toIOSModel(),
              iosController!,
            ))!,
            duration: animation.duration,
            repeatCount: animation.repeatCount,
            repeatMode: animation.repeatMode.index,
          );
          // TODO 修复 原先在delegate中的regionController目前被去掉了
          // regionController.stream.listen((event) async {
          //   debugPrint('地图移动');
          //   await imageView?.translateWithDuration(
          //     toValue: await iosController.convertCoordinate_toPointToView(
          //       await animation.coordinate.toIOSModel(),
          //       iosController,
          //     ),
          //     duration: animation.duration,
          //     repeatCount: animation.repeatCount,
          //     repeatMode: animation.repeatMode.index,
          //   );
          // });
        } else if (animation is MarkerAnimationSet) {
          await imageView?.groupWithDuration(
            fromValue:
                animation.animationSet!.map((e) => e.fromValue!).toList(),
            toValue: animation.animationSet!.map((e) => e.toValue!).toList(),
            keyPath: [
              for (final item in animation.animationSet!)
                if (item is ScaleMarkerAnimation)
                  'transform.scale'
                else if (item is AlphaMarkerAnimation)
                  'opacity'
                else if (item is TranslateMarkerAnimation)
                  'position'
                else if (item is RotateMarkerAnimation)
                  'transform.rotation',
            ],
            duration: animation.duration,
            repeatCount: animation.repeatCount,
            repeatMode: animation.repeatMode.index,
          );
        }
      },
    );
  }

  /// 设置角度
  @override
  Future<void> setAngle(double angle) async {
    return platform(
      android: (pool) async {
        await androidModel!.setRotateAngle(angle);
      },
      ios: (pool) async {
        final annotationView =
            await iosController!.viewForAnnotation(iosModel!);
        final imageView = await annotationView!.get_imageView();
        await imageView!.rotate(angle);
      },
    );
  }

  /// 设置标题
  @override
  Future<void> setTitle(String title) async {
    return platform(
      android: (pool) async {
        await androidModel!.setTitle(title);
      },
      ios: (pool) async {
        await iosModel!.set_title(title);
      },
    );
  }

  /// 设置副标题
  @override
  Future<void> setSnippet(String snippet) async {
    return platform(
      android: (pool) async {
        await androidModel!.setSnippet(snippet);
      },
      ios: (pool) async {
        await iosModel!.set_subtitle(snippet);
      },
    );
  }
}

/// 平滑移动点
class SmoothMoveMarker implements ISmoothMoveMarker {
  SmoothMoveMarker.android(this.androidModel);

  SmoothMoveMarker.ios(this.iosController, this.iosAnimation, this.annotation);

  com_amap_api_maps_utils_overlay_SmoothMoveMarker? androidModel;

  MAMapView? iosController;
  MAAnnotationMoveAnimation? iosAnimation;
  MAAnimatedAnnotation? annotation;

  @override
  Future<void> remove() async {
    return platform(
      android: (pool) => androidModel!.removeMarker(),
      ios: (pool) => iosController!.removeAnnotation(annotation!),
    );
  }

  @override
  Future<void> stop() async {
    return platform(
      android: (pool) => androidModel!.stopMove(),
      ios: (pool) => iosAnimation!.cancel(),
    );
  }
}

/// 折线
class Polyline implements IPolyline {
  Polyline.android(this.androidModel);

  Polyline.ios(this.iosModel, this.iosController);

  com_amap_api_maps_model_Polyline? androidModel;
  MAPolyline? iosModel;
  MAMapView? iosController;

  @override
  Future<void> remove() {
    return platform(
      android: (_) => androidModel!.remove(),
      ios: (_) => iosController!.removeOverlay(iosModel!),
    );
  }

  /// 重新设置折线点列表
  ///
  /// 可用于轨迹记录
  @override
  Future<void> setCoordinateList(List<LatLng> coordinateList) {
    return platform(
      android: (pool) async {
        final androidCoordinateList = await coordinateList.toAndroidList();
        await androidModel!.setPoints(androidCoordinateList);

        pool.addAll(androidCoordinateList);
      },
      ios: (pool) async {
        final iosCoordinateList = await coordinateList.toIOSList();
        await iosModel!.setPolylineWithCoordinates_count(
          iosCoordinateList,
          iosCoordinateList.length,
        );

        pool.addAll(iosCoordinateList);
      },
    );
  }
}

/// 多边形
class Polygon implements IPolygon {
  Polygon.android(this.androidModel);

  Polygon.ios(this.iosModel, this.iosController);

  com_amap_api_maps_model_Polygon? androidModel;
  MAPolygon? iosModel;
  MAMapView? iosController;

  @override
  Future<void> remove() {
    return platform(
      android: (_) => androidModel!.remove(),
      ios: (_) => iosController!.removeOverlay(iosModel!),
    );
  }

  @override
  Future<bool> contains(LatLng target) {
    return platform(
      android: (_) async {
        final latLng = await com_amap_api_maps_model_LatLng
            .create__double__double(target.latitude, target.longitude);
        return await androidModel!.contains(latLng) == true;
      },
      ios: (_) async {
        final latLng = await CLLocationCoordinate2D.create(
            target.latitude, target.longitude);
        final point = await MAMapPointForCoordinate(latLng);
        final bounds = await iosModel!.get_points();
        return (await MAPolygonContainsPoint(point!, bounds!, bounds.length))!;
      },
    );
  }
}

/// 圆形
class Circle implements ICircle {
  Circle.android(this.androidModel);

  Circle.ios(this.iosModel, this.iosController);

  com_amap_api_maps_model_Circle? androidModel;
  MACircle? iosModel;
  MAMapView? iosController;

  @override
  Future<void> remove() {
    return platform(
      android: (_) => androidModel!.remove(),
      ios: (_) => iosController!.removeOverlay(iosModel!),
    );
  }

  @override
  Future<void> setCoordinate(LatLng coordinate) {
    // TODO: implement setCoordinate
    throw UnimplementedError();
  }

  @override
  Future<void> setRadius(double radius) {
    // TODO: implement setRadius
    throw UnimplementedError();
  }
}

/// 热力图
class HeatmapOverlay implements IHeatmapOverlay {
  HeatmapOverlay.android(this.androidModel);

  HeatmapOverlay.ios(this.iosModel, this.iosController);

  com_amap_api_maps_model_TileOverlay? androidModel;
  MAHeatMapTileOverlay? iosModel;
  MAMapView? iosController;

  @override
  Future<void> remove() {
    return platform(
      android: (_) => androidModel!.remove(),
      ios: (_) => iosController!.removeOverlay(iosModel!),
    );
  }
}

/// 瓦片图
class UrlTileOverlay implements IUrlTileOverlay {
  UrlTileOverlay.android(this.androidModel);

  UrlTileOverlay.ios(this.iosModel, this.iosController);

  com_amap_api_maps_model_TileOverlay? androidModel;
  MATileOverlay? iosModel;
  MAMapView? iosController;

  @override
  Future<void> remove() {
    return platform(
      android: (_) => androidModel!.remove(),
      ios: (_) => iosController!.removeOverlay(iosModel!),
    );
  }
}

/// 图片覆盖物
class GroundOverlay implements IGroundOverlay {
  GroundOverlay.android(this.androidModel);

  GroundOverlay.ios(this.iosModel, this.iosController);

  com_amap_api_maps_model_GroundOverlay? androidModel;
  MAGroundOverlay? iosModel;
  MAMapView? iosController;

  @override
  Future<void> remove() {
    return platform(
      android: (_) => androidModel!.remove(),
      ios: (_) => iosController!.removeOverlay(iosModel!),
    );
  }
}

/// 海量点
class MultiPointOverlay implements IMultiPointOverlay {
  MultiPointOverlay.android(this.androidModel)
      : iosModel = null,
        iosController = null;

  MultiPointOverlay.ios(this.iosModel, this.iosController)
      : androidModel = null;

  final com_amap_api_maps_model_MultiPointOverlay? androidModel;

  final MAMultiPointOverlay? iosModel;
  final MAMapView? iosController;

  @override
  Future<void> remove() {
    return platform(
      android: (_) => androidModel!.remove(),
      ios: (_) => iosController!.removeOverlay(iosModel!),
    );
  }
}

/// 回放轨迹
class PlaybackTrace implements IPlaybackTrace {
  PlaybackTrace(this.marker, this.polyline);

  final ISmoothMoveMarker marker;
  final IPolyline polyline;

  @override
  Future<void> remove() async {
    await marker.remove();
    await polyline.remove();
  }

  @override
  Future<void> stop() async {
    await marker.stop();
  }
}
