import 'dart:typed_data';

import 'package:amap_map_fluttify/src/android/android.export.g.dart';
import 'package:amap_map_fluttify/src/ios/ios.export.g.dart';

extension com_amap_api_maps_model_UrlTileProvider_X
    on com_amap_api_maps_model_UrlTileProvider {
  static Future<com_amap_api_maps_model_UrlTileProvider> create(
    int width,
    int height,
    String urlTemplate,
  ) async {
    final result = await kAmapMapFluttifyChannel.invokeMethod(
      'com.amap.api.maps.model.UrlTileProviderX::create',
      {
        'width': width,
        'height': height,
        'urlTemplate': urlTemplate,
      },
    );
    return (await AmapMapFluttifyAndroidAs<
        com_amap_api_maps_model_UrlTileProvider>(result))!;
  }
}

extension RideTypeX on RideType {
  String inString() {
    switch (this) {
      case RideType.elebike:
        return 'elebike';
      case RideType.bike:
        return 'bike';
      default:
        return 'bike';
    }
  }
}

// ignore: camel_case_types
class com_amap_api_maps_model_GradientX extends java_lang_Object {
  //region constants
  static Future<com_amap_api_maps_model_Gradient> create(
    Int32List var1,
    Float64List var2,
  ) async {
    final __result__ = await kAmapMapFluttifyChannel.invokeMethod(
      'ObjectFactory::createcom_amap_api_maps_model_Gradient__intArray__floatArrayX',
      {"var1": var1, "var2": var2},
    );
    return AmapMapFluttifyAndroidAs(__result__);
  }
}

extension MAPointAnnotationX on MAPointAnnotation {
  Future<void> setIcon(UIImage icon) async {
    await addProperty__(1, icon);
  }

  Future<void> setDraggable(bool draggable) async {
    await addJsonableProperty__(2, draggable);
  }

  Future<void> setRotateAngle(double rotateAngle) async {
    await addJsonableProperty__(3, rotateAngle);
  }

  Future<void> setInfoWindowEnabled(bool enable) async {
    await addJsonableProperty__(4, enable);
  }

  Future<void> setAnchor(double anchorU, double anchorV) async {
    await addJsonableProperty__(5, anchorU);
    await addJsonableProperty__(6, anchorV);
  }

  Future<void> setObject(String object) async {
    await addJsonableProperty__(7, object);
  }

  Future<void> setVisible(bool visible) async {
    await addJsonableProperty__(10, visible);
  }

  Future<void> setIcons(List<UIImage> icons) async {
    await addListProperty__(11, icons);
  }

  Future<void> setFps(int fps) async {
    await addJsonableProperty__(12, fps);
  }

  Future<void> setOpacity(double opacity) async {
    await addJsonableProperty__(13, opacity);
  }
}

extension MAPointAnnotationListX on List<MAPointAnnotation> {
  Future<void> setIcon(List<UIImage> icon) async {
    await addProperty_batch(1, icon);
  }

  Future<void> setDraggable(List<bool> draggable) async {
    await addJsonableProperty_batch(2, draggable);
  }

  Future<void> setRotateAngle(List<double> rotateAngle) async {
    await addJsonableProperty_batch(3, rotateAngle);
  }

  Future<void> setInfoWindowEnabled(List<bool> enable) async {
    await addJsonableProperty_batch(4, enable);
  }

  Future<void> setAnchor(List<double> anchorU, List<double> anchorV) async {
    await addJsonableProperty_batch(5, anchorU);
    await addJsonableProperty_batch(6, anchorV);
  }

  Future<void> setObject(List<String> object) async {
    await addJsonableProperty_batch(7, object);
  }

  Future<void> setVisible(List<bool> visible) async {
    await addJsonableProperty_batch(10, visible);
  }

  Future<void> setFps(List<int> fps) async {
    await addJsonableProperty_batch(12, fps);
  }
}

extension LatLngX on LatLng {
  Future<com_amap_api_maps_model_LatLng> toAndroidModel() async {
    return com_amap_api_maps_model_LatLng.create__double__double(
        latitude, longitude);
  }

  Future<CLLocationCoordinate2D> toIOSModel() async {
    return CLLocationCoordinate2D.create(latitude, longitude);
  }
}

extension MarkerAnimationX on MarkerAnimation {
  Future<com_amap_api_maps_model_animation_Animation> toAndroidModel() async {
    com_amap_api_maps_model_animation_Animation? result;
    if (this is ScaleMarkerAnimation) {
      result = await com_amap_api_maps_model_animation_ScaleAnimation
          .create__float__float__float__float(
        fromValue ?? 0,
        toValue ?? 0,
        fromValue ?? 0,
        toValue ?? 0,
      );
    } else if (this is AlphaMarkerAnimation) {
      result = await com_amap_api_maps_model_animation_AlphaAnimation
          .create__float__float(fromValue ?? 0, toValue ?? 0);
    } else if (this is RotateMarkerAnimation) {
      result = await com_amap_api_maps_model_animation_RotateAnimation
          .create__float__float(fromValue ?? 0, toValue ?? 0);
    } else if (this is TranslateMarkerAnimation) {
      final target = (this as TranslateMarkerAnimation).coordinate;
      result = await com_amap_api_maps_model_animation_TranslateAnimation
          .create__com_amap_api_maps_model_LatLng(
              await target.toAndroidModel());
    } else if (this is MarkerAnimationSet) {
      final _this = this as MarkerAnimationSet;
      result = await com_amap_api_maps_model_animation_AnimationSet
          .create__boolean(true);
      for (final ani in _this.animationSet!) {
        await (result as com_amap_api_maps_model_animation_AnimationSet)
            .addAnimation(await ani.toAndroidModel());
      }
      return result;
    }
    // 重复执行的次数 比如1表示执行一次动画后, 再执行一次, 这里和ios端统一, 表示总共执行
    // 几次动画 参考 https://a.amap.com/lbs/static/unzip/Android_Map_Doc/index.html
    await result?.setRepeatCount(repeatCount - 1);
    await result?.setRepeatMode(
      repeatMode == RepeatMode.Restart
          ? com_amap_api_maps_model_animation_Animation.RESTART
          : com_amap_api_maps_model_animation_Animation.REVERSE,
    );
    await result?.setDuration(duration.inMilliseconds);

    return result!;
  }
}
