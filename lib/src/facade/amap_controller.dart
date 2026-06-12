// ignore_for_file: non_constant_identifier_names
part of 'amap_view.widget.dart';

/// 海量点点击回调签名
typedef OnMultiPointClicked = Future<void> Function(
  String id,
  String title,
  String snippet,
  String object,
);

/// 地图控制类
class AmapController with WidgetsBindingObserver, IMapController {
  /// Android构造器
  AmapController.android(
    com_amap_api_maps_TextureMapView _androidController,
    _AmapViewState _state,
  ) {
    WidgetsBinding.instance.addObserver(this);
    androidController = _androidController;
    state = _state;
  }

  /// iOS构造器
  AmapController.ios(MAMapView _iosController, _AmapViewState _state) {
    WidgetsBinding.instance.addObserver(this);
    iosController = _iosController;
    state = _state;
  }

  com_amap_api_maps_TextureMapView? androidController;
  MAMapView? iosController;

  _AmapViewState? state;

  final imageConfiguration =
      ImageConfiguration(devicePixelRatio: ui.window.devicePixelRatio);

  // iOS端的回调处理类
  MAMapViewDelegate? _iosMapDelegate;

  //
  // // Android端的回调处理类
  // final androidMapDelegate = _AndroidMapDelegate();

  // 定位间隔订阅事件
  StreamSubscription? _locateSubscription;

  /// 获取当前位置
  ///
  /// 由于定位需要时间, 如果进入地图后马上获取位置信息, 获取到的会是null, [getLocation]会默认
  /// 以[interval]500毫秒为间隔循环获取定位信息, 直到获取到的定位不为空. 你可以设置超时时间[timeout], 防止
  /// 一直获取不到定位的情况(比如没有设置[showMyLocation]为true, 或者没有同意权限申请).
  @override
  Future<LatLng?> getLocation() async {
    Duration interval = const Duration(milliseconds: 500);
    Duration timeout = const Duration(seconds: 10);
    // 总尝试次数
    final attempts = timeout.inMilliseconds ~/ interval.inMilliseconds;
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        for (var i = 0; i < attempts; i++) {
          final location = await map!.getMyLocation();
          pool.add(location);

          final latitude = await location?.latitude;
          final longitude = await location?.longitude;
          if (latitude != null &&
              latitude != 0 &&
              longitude != null &&
              longitude != 0) {
            return LatLng(latitude, longitude);
          }
          await Future.delayed(interval);
        }
        return null;
      },
      ios: (pool) async {
        for (var i = 0; i < attempts; i++) {
          final location = await iosController!.get_userLocation();
          if (location == null) {
            throw '定位数据为null, 请检查是否已调用showMyLocation';
          }
          final coord = await location.get_coordinate();

          final latitude = await coord?.latitude;
          final longitude = await coord?.longitude;
          if (latitude != null &&
              latitude != 0 &&
              longitude != null &&
              longitude != 0) {
            pool.add(coord);
            return LatLng(latitude, longitude);
          }
          await Future.delayed(interval);
        }
        return null;
      },
    );
  }

  /// 显示我的位置
  ///
  /// 可配置的参数详见[MyLocationOption]
  @override
  Future<void> showMyLocation(MyLocationOption option) async {
    if (state?.mounted != true) return;

    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final locationStyle =
            await com_amap_api_maps_model_MyLocationStyle.create__();
        await locationStyle.showMyLocation(option.show);
        await map!.setMyLocationEnabled(option.show);

        if (option.show) {
          switch (option.myLocationType) {
            case MyLocationType.Show:
              await locationStyle.myLocationType(
                com_amap_api_maps_model_MyLocationStyle.LOCATION_TYPE_SHOW,
              );
              break;
            case MyLocationType.Locate:
              await locationStyle.myLocationType(
                com_amap_api_maps_model_MyLocationStyle.LOCATION_TYPE_LOCATE,
              );
              break;
            case MyLocationType.Follow:
              await locationStyle.myLocationType(
                com_amap_api_maps_model_MyLocationStyle.LOCATION_TYPE_FOLLOW,
              );
              break;
            case MyLocationType.FollowNoCenter:
              await locationStyle.myLocationType(
                com_amap_api_maps_model_MyLocationStyle
                    .LOCATION_TYPE_FOLLOW_NO_CENTER,
              );
              break;
            case MyLocationType.Rotate:
              await locationStyle.myLocationType(
                com_amap_api_maps_model_MyLocationStyle
                    .LOCATION_TYPE_MAP_ROTATE,
              );
              break;
          }
          // 定位间隔
          await locationStyle.interval(option.interval.inMilliseconds);

          // 定位图标
          if (option.iconProvider != null) {
            final imageData =
                await option.iconProvider!.toImageData(imageConfiguration);
            final bitmap = await android_graphics_Bitmap.create(imageData);
            final bitmapDescriptor =
                await com_amap_api_maps_model_BitmapDescriptorFactory
                    .fromBitmap(bitmap);
            await locationStyle.myLocationIcon(bitmapDescriptor!);
          }
          /* else {
            final imageData = await AssetImage('images/location_pointer.png',
                    package: 'amap_map_fluttify')
                .toImageData(imageConfiguration);
            final bitmap = await android_graphics_Bitmap.create(imageData);
            final bitmapDescriptor =
                await com_amap_api_maps_model_BitmapDescriptorFactory
                    .fromBitmap(bitmap);
            await locationStyle.myLocationIcon(bitmapDescriptor);
          }*/
          // 边框颜色
          await locationStyle
              .strokeColor(Int32List.fromList([option.strokeColor.value])[0]);
          // 填充颜色
          await locationStyle
              .radiusFillColor(Int32List.fromList([option.fillColor.value])[0]);
          // 边框宽度
          await locationStyle.strokeWidth(option.strokeWidth);
          // 锚点
          if (option.anchorU != null && option.anchorV != null) {
            await locationStyle.anchor(option.anchorU!, option.anchorV!);
          }

          // 设置样式
          await map.setMyLocationStyle(locationStyle);
        }

        pool.add(locationStyle);
      },
      ios: (pool) async {
        await iosController!.set_showsUserLocation(option.show);

        if (option.show) {
          if (option.interval != Duration.zero) {
            await _locateSubscription?.cancel();
            _locateSubscription =
                Stream.periodic(option.interval, (_) => _).listen((_) {
              if (option.myLocationType == MyLocationType.Follow) {
                iosController!.setUserTrackingMode_animated(
                  MAUserTrackingMode.MAUserTrackingModeFollow,
                  true,
                );
              } else if (option.myLocationType ==
                  MyLocationType.FollowNoCenter) {
                iosController!.setUserTrackingMode_animated(
                  MAUserTrackingMode.MAUserTrackingModeNone,
                  true,
                );
              }
            });
          }

          switch (option.myLocationType) {
            case MyLocationType.Show:
              await iosController!.setUserTrackingMode_animated(
                MAUserTrackingMode.MAUserTrackingModeNone,
                true,
              );
              break;
            // ios端没有只定位一次的选项, 所以这里要模拟一下这个效果
            // 1. 先设置不跟踪位置, 防止定位marker来回跳
            // 2. 获取当前用户位置
            // 3. 把当前地图中心点设置为用户位置
            case MyLocationType.Locate:
              await iosController!.setUserTrackingMode_animated(
                MAUserTrackingMode.MAUserTrackingModeNone,
                true,
              );
              final myLocation = await iosController!.get_userLocation();
              await iosController!.setCenterCoordinate_animated(
                (await myLocation!.get_coordinate())!,
                false,
              );
              break;
            case MyLocationType.Follow:
              await iosController!.setUserTrackingMode_animated(
                MAUserTrackingMode.MAUserTrackingModeFollow,
                true,
              );
              break;
            case MyLocationType.FollowNoCenter:
              await iosController!.setUserTrackingMode_animated(
                MAUserTrackingMode.MAUserTrackingModeNone,
                true,
              );
              break;
            case MyLocationType.Rotate:
              await iosController!.setUserTrackingMode_animated(
                MAUserTrackingMode.MAUserTrackingModeFollowWithHeading,
                true,
              );
              break;
          }

          final style = await MAUserLocationRepresentation.create__();

          // 定位图标
          if (option.iconProvider != null) {
            final imageData =
                await option.iconProvider!.toImageData(imageConfiguration);
            final bitmap = await UIImage.create(imageData);
            await style.set_image(bitmap);
          }
          /* else {
            final imageData = await AssetImage('images/location_pointer.png',
                    package: 'amap_map_fluttify')
                .toImageData(imageConfiguration);
            final bitmap = await UIImage.create(imageData);
            await style.set_image(bitmap);
          }*/
          // 边框颜色
          {
            final color = await UIColor.create(option.strokeColor);
            await style.set_strokeColor(color);
          }
          // 填充颜色
          {
            final color = await UIColor.create(option.fillColor);
            await style.set_fillColor(color);
          }
          // 边框宽度
          await style.set_lineWidth(option.strokeWidth);
          // 锚点
          if (option.anchorU != null && option.anchorV != null) {
            // 目前无作用
            await style.addJsonableProperty__(1, option.anchorU!);
            await style.addJsonableProperty__(2, option.anchorV!);
          }

          await iosController!.updateUserLocationRepresentation(style);
        } else {
          await _locateSubscription?.cancel();
        }
      },
    );
  }

  /// 设置我的位置图标旋转角度
  @override
  Future<void> setMyLocationRotateAngle(double angle) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        await map!.setMyLocationRotateAngle(360 - angle);
      },
      ios: (pool) async {
        final location = await iosController!.get_userLocation();
        final view = await iosController!.viewForAnnotation(location!);
        // 当前定位图标不在屏幕内时为null
        await view?.rotate(angle);
      },
    );
  }

  /// 是否显示室内地图
  @override
  Future<void> showIndoorMap(bool show) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        await map!.showIndoorMap(show);
      },
      ios: (pool) async {
        await iosController!.set_showsIndoorMap(show);
      },
    );
  }

  /// 选择显示图层
  @override
  Future<void> setMapType(MapType mapType) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        switch (mapType) {
          case MapType.Standard:
            await map!.setMapType(1);
            break;
          case MapType.Satellite:
            await map!.setMapType(2);
            break;
          case MapType.Night:
            await map!.setMapType(3);
            break;
          case MapType.Navi:
            await map!.setMapType(4);
            break;
          case MapType.Bus:
            await map!.setMapType(5);
            break;
        }
      },
      ios: (pool) async {
        switch (mapType) {
          case MapType.Standard:
            await iosController!.set_mapType(MAMapType.MAMapTypeStandard);
            break;
          case MapType.Satellite:
            await iosController!.set_mapType(MAMapType.MAMapTypeSatellite);
            break;
          case MapType.Night:
            await iosController!.set_mapType(MAMapType.MAMapTypeStandardNight);
            break;
          case MapType.Navi:
            await iosController!.set_mapType(MAMapType.MAMapTypeNavi);
            break;
          case MapType.Bus:
            await iosController!.set_mapType(MAMapType.MAMapTypeBus);
            break;
        }
      },
    );
  }

  /// 选择地图语言
  Future<void> setMapLanguage(Language language) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        switch (language) {
          case Language.Chinese:
            await map!.setMapLanguage(com_amap_api_maps_AMap.CHINESE);
            break;
          case Language.English:
            await map!.setMapLanguage(com_amap_api_maps_AMap.ENGLISH);
            break;
        }
      },
      ios: (pool) async {
        switch (language) {
          case Language.Chinese:
            await iosController!
                .performSelectorWithObject__('setMapLanguage:', 0);
            break;
          case Language.English:
            await iosController!
                .performSelectorWithObject__('setMapLanguage:', 1);
            break;
        }
      },
    );
  }

  /// 显示路况信息
  @override
  Future<void> showTraffic(bool enable) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        await map!.setTrafficEnabled(enable);
      },
      ios: (pool) async {
        await iosController!.set_showTraffic(enable);
      },
    );
  }

  /// 显示缩放控件
  @override
  Future<void> showZoomControl(bool enable) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final uiSetting = await map!.getUiSettings();
        await uiSetting!.setZoomControlsEnabled(enable);

        pool.add(uiSetting);
      },
      ios: (pool) async {
        debugPrint('ios端不支持显示缩放控件');
      },
    );
  }

  /// 显示指南针
  @override
  Future<void> showCompass(bool enable) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final uiSetting = await map!.getUiSettings();
        await uiSetting!.setCompassEnabled(enable);

        pool.add(uiSetting);
      },
      ios: (pool) async {
        await iosController!.set_showsCompass(enable);
      },
    );
  }

  /// 显示定位按钮
  @override
  Future<void> showLocateControl(bool enable) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final uiSetting = await map!.getUiSettings();
        await uiSetting!.setMyLocationButtonEnabled(enable);

        pool.add(uiSetting);
      },
      ios: (pool) async {
        debugPrint('ios端不支持显示定位按钮');
      },
    );
  }

  /// 显示比例尺控件
  @override
  Future<void> showScaleControl(bool enable) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final uiSetting = await map!.getUiSettings();
        await uiSetting!.setScaleControlsEnabled(enable);

        pool.add(uiSetting);
      },
      ios: (pool) async {
        await iosController!.set_showsScale(enable);
      },
    );
  }

  /// 缩放手势使能
  @override
  Future<void> setZoomGesturesEnabled(bool enable) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final uiSetting = await map!.getUiSettings();
        await uiSetting!.setZoomGesturesEnabled(enable);

        pool.add(uiSetting);
      },
      ios: (pool) async {
        await iosController!.set_zoomEnabled(enable);
      },
    );
  }

  /// 滑动手势使能
  @override
  Future<void> setScrollGesturesEnabled(bool enable) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final uiSetting = await map!.getUiSettings();
        await uiSetting!.setScrollGesturesEnabled(enable);

        pool.add(uiSetting);
      },
      ios: (pool) async {
        await iosController!.set_scrollEnabled(enable);
      },
    );
  }

  /// 旋转手势使能
  @override
  Future<void> setRotateGesturesEnabled(bool enable) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final uiSetting = await map!.getUiSettings();
        await uiSetting!.setRotateGesturesEnabled(enable);

        pool.add(uiSetting);
      },
      ios: (pool) async {
        await iosController!.set_rotateEnabled(enable);
      },
    );
  }

  /// 旋转手势使能
  @override
  Future<void> setTiltGesturesEnabled(bool enable) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final uiSetting = await map!.getUiSettings();
        await uiSetting!.setTiltGesturesEnabled(enable);

        pool.add(uiSetting);
      },
      ios: (pool) async {
        await iosController!.set_rotateCameraEnabled(enable);
      },
    );
  }

  /// 所有手势使能
  @override
  Future<void> setAllGesturesEnabled(bool enable) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final uiSetting = await map!.getUiSettings();
        await uiSetting!.setAllGesturesEnabled(enable);

        pool.add(uiSetting);
      },
      ios: (pool) async {
        await iosController!.set_zoomEnabled(enable);
        await iosController!.set_scrollEnabled(enable);
        await iosController!.set_rotateEnabled(enable);
        await iosController!.set_rotateCameraEnabled(enable);
      },
    );
  }

  /// 设置缩放大小
  ///
  /// 地图的缩放级别一共分为 17 级，从 3 到 19. 数字越大，展示的图面信息越精细
  @override
  Future<void> setZoomLevel(double level, {bool animated = true}) async {
    assert(level >= 3 && level <= 19, '缩放范围为3-19');
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final cameraUpdate =
            await com_amap_api_maps_CameraUpdateFactory.zoomTo(level);
        if (animated) {
          await map!
              .animateCamera__com_amap_api_maps_CameraUpdate(cameraUpdate!);
        } else {
          await map!.moveCamera(cameraUpdate!);
        }

        pool.add(cameraUpdate);
      },
      ios: (pool) async {
        await iosController!.setZoomLevel_animated(level, animated);
      },
    );
  }

  /// 获取当前缩放大小
  @override
  Future<double> getZoomLevel() async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final camera = await map!.getCameraPosition();

        pool.add(camera);
        return await camera!.get_zoom() ?? 10;
      },
      ios: (pool) async {
        return await iosController!.get_zoomLevel() ?? 10;
      },
    );
  }

  /// 设置缩放是否以中心点为锚点
  @override
  Future<void> setZoomByCenter(bool byCenter) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final uiSetting = await map!.getUiSettings();
        await uiSetting!.setZoomInByScreenCenter(byCenter);
        await uiSetting.setGestureScaleByMapCenter(byCenter);

        pool.add(uiSetting);
      },
      ios: (pool) async {
        await iosController!.set_zoomingInPivotsAroundAnchorPoint(!byCenter);
      },
    );
  }

  /// 放大一个等级
  @override
  Future<void> zoomIn({bool animated = true}) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final cameraUpdate =
            await com_amap_api_maps_CameraUpdateFactory.zoomIn();
        if (animated) {
          await map!
              .animateCamera__com_amap_api_maps_CameraUpdate(cameraUpdate!);
        } else {
          await map!.moveCamera(cameraUpdate!);
        }

        pool.add(cameraUpdate);
      },
      ios: (pool) async {
        final currentLevel = await iosController!.get_zoomLevel() ?? 10;
        await iosController!.setZoomLevel_animated(currentLevel + 1, animated);
      },
    );
  }

  /// 放大一个等级
  @override
  Future<void> zoomOut({bool animated = true}) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final cameraUpdate =
            await com_amap_api_maps_CameraUpdateFactory.zoomOut();
        if (animated) {
          await map!
              .animateCamera__com_amap_api_maps_CameraUpdate(cameraUpdate!);
        } else {
          await map!.moveCamera(cameraUpdate!);
        }

        pool.add(cameraUpdate);
      },
      ios: (pool) async {
        final currentLevel = await iosController!.get_zoomLevel() ?? 10;
        await iosController!.setZoomLevel_animated(currentLevel - 1, animated);
      },
    );
  }

  /// 设置地图中心点
  ///
  /// [lat]纬度, [lng]经度, [zoomLevel]缩放等级, [bearing]地图选择角度, [tilt]倾斜角
  @override
  Future<void> setCenterCoordinate(
    LatLng coordinate, {
    double? zoomLevel,
    double? bearing,
    double? tilt,
    bool animated = true,
  }) async {
    assert(
      zoomLevel == null || (zoomLevel >= 3 && zoomLevel <= 19),
      '缩放范围为3-19',
    );
    final lat = coordinate.latitude;
    final lng = coordinate.longitude;
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final latLng = await com_amap_api_maps_model_LatLng
            .create__double__double(lat, lng);

        final camera = await map!.getCameraPosition();
        final finalZoomLevel = zoomLevel ?? (await camera!.get_zoom())!;
        final finalBearing = bearing ?? (await camera!.get_bearing())!;
        final finalTilt = tilt ?? (await camera!.get_tilt())!;
        final cameraPosition = await com_amap_api_maps_model_CameraPosition
            .create__com_amap_api_maps_model_LatLng__float__float__float(
                latLng, finalZoomLevel, finalTilt, finalBearing);

        final cameraUpdate = await com_amap_api_maps_CameraUpdateFactory
            .newCameraPosition(cameraPosition);

        if (animated) {
          await map
              .animateCamera__com_amap_api_maps_CameraUpdate(cameraUpdate!);
        } else {
          await map.moveCamera(cameraUpdate!);
        }

        pool
          ..add(latLng)
          ..add(cameraUpdate);
      },
      ios: (pool) async {
        final latLng = await CLLocationCoordinate2D.create(lat, lng);
        if (zoomLevel != null) {
          await iosController!.setZoomLevel_animated(zoomLevel, animated);
        }
        if (bearing != null) {
          await iosController!.set_rotationDegree(bearing);
        }
        if (tilt != null) {
          await iosController!.set_cameraDegree(tilt);
        }
        await iosController!.setCenterCoordinate_animated(latLng, animated);

        pool.add(latLng);
      },
    );
  }

  /// 获取地图中心点
  @override
  Future<LatLng> getCenterCoordinate() {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final position = await map!.getCameraPosition();
        final target = await position!.get_target();

        // target不能马上释放, 因为跟返回对象有联系
        pool.add(position);

        return LatLng(
          await target!.get_latitude() ?? 0,
          await target.get_longitude() ?? 0,
        );
      },
      ios: (pool) async {
        final target = await iosController!.get_centerCoordinate();
        // target不能马上释放, 因为跟返回对象有联系
        return LatLng(await target!.latitude ?? 0, await target.longitude ?? 0);
      },
    );
  }

  /// 添加marker
  ///
  /// 在纬度[lat], 经度[lng]的位置添加marker, 并设置标题[title]和副标题[snippet], [iconUri]
  /// 可以是图片url, asset路径或者文件路径.
  /// 其中图片参数[imageConfig]如果不知道怎么创建, 那么就直接调用flutter sdk内提供的[createLocalImageConfiguration]方法创建
  @override
  Future<IMarker> addMarker(MarkerOption option) {
    if (state?.mounted != true) throw StateError('state is not mounted');

    final latitude = option.coordinate.latitude;
    final longitude = option.coordinate.longitude;
    return platform(
      android: (pool) async {
        // 获取地图
        final map = await androidController!.getMap();

        // marker经纬度
        final latLng = await com_amap_api_maps_model_LatLng
            .create__double__double(latitude, longitude);

        // marker配置
        final markerOption =
            await com_amap_api_maps_model_MarkerOptions.create__();

        // 设置marker经纬度
        await markerOption.position(latLng);
        // 设置marker标题
        await markerOption.title(option.title);
        // 设置marker副标题
        await markerOption.snippet(option.snippet);
        // 设置marker图标
        // 帧动画
        if (option.iconsProvider != null && option.iconsProvider!.isNotEmpty) {
          List<Uint8List> iconData = [];
          for (final item in option.iconsProvider!) {
            final data = await item.toImageData(imageConfiguration);
            iconData.add(data);
          }

          final bitmap = await android_graphics_Bitmap.create_batch(iconData);
          final icon =
              await com_amap_api_maps_model_BitmapDescriptorFactory_Batch
                  .fromBitmap_batch(bitmap!);
          await markerOption.icons(icon
              .whereType<com_amap_api_maps_model_BitmapDescriptor>()
              .toList());
          await markerOption.period(240 ~/ (option.animationFps ?? 30));

          pool
            ..addAll(bitmap)
            ..addAll(icon);
        }
        // 普通图片
        else if (option.iconProvider != null) {
          Uint8List iconData =
              await option.iconProvider!.toImageData(imageConfiguration);

          final bitmap = await android_graphics_Bitmap.create(iconData);
          final icon = await com_amap_api_maps_model_BitmapDescriptorFactory
              .fromBitmap(bitmap);
          await markerOption.icon(icon!);

          pool
            ..add(bitmap)
            ..add(icon);
        }
        // widget as marker
        else if (option.widget != null) {
          final iconData = (await state!.widgetToImageData([option.widget!]))!;

          final bitmap = await android_graphics_Bitmap.create(iconData[0]);
          final icon = await com_amap_api_maps_model_BitmapDescriptorFactory
              .fromBitmap(bitmap);
          await markerOption.icon(icon!);

          pool
            ..add(bitmap)
            ..add(icon);
        }
        // 是否可拖拽
        await markerOption.draggable(option.draggable);
        // 旋转角度
        await markerOption.rotateAngle(option.rotateAngle);
        // 锚点 默认在中间底部是最合理的
        await markerOption.anchor(option.anchorU, option.anchorV);
        // 是否可见
        await markerOption.visible(option.visible);
        // 透明度
        if (option.opacity != null) await markerOption.alpha(option.opacity!);

        final marker = await map!.addMarker(markerOption);
        // 是否允许弹窗
        await marker!.setInfoWindowEnable(option.infoWindowEnabled);

        // 自定义数据
        if (option.object != null) {
          await marker.setObject(option.object!);
        }

        // marker不释放, 还有用
        pool
          ..add(latLng)
          ..add(markerOption);

        return Marker.android(marker);
      },
      ios: (pool) async {
        _iosMapDelegate ??= await MAMapViewDelegate.anonymous__();
        await iosController!.set_delegate(_iosMapDelegate!);

        // 创建marker
        final annotation = await MAPointAnnotation.create__();

        final coordinate =
            await CLLocationCoordinate2D.create(latitude, longitude);

        // 设置经纬度
        await annotation.set_coordinate(coordinate);

        // 设置标题
        await annotation.set_title(option.title);
        // 设置副标题
        await annotation.set_subtitle(option.snippet);
        // 设置图片
        // 帧动画
        if (option.iconsProvider != null && option.iconsProvider!.isNotEmpty) {
          List<Uint8List> iconData = [];
          for (final item in option.iconsProvider!) {
            final data = await item.toImageData(imageConfiguration);
            iconData.add(data);
          }

          final icons = await UIImage.create_batch(iconData);

          await annotation.setIcons(icons);
          await annotation.setFps(
            (1 / (option.animationFps ?? 30) * icons.length).toInt(),
          );

          pool.addAll(icons);
        }
        // 普通图片
        else if (option.iconProvider != null) {
          Uint8List iconData =
              await option.iconProvider!.toImageData(imageConfiguration);

          final icon = await UIImage.create(iconData);

          // 由于ios端的icon参数在回调中设置, 需要添加属性来实现
          await annotation.setIcon(icon);

          pool.add(icon);
        }
        // widget as marker
        else if (option.widget != null) {
          List<Uint8List> iconData =
              (await state!.widgetToImageData([option.widget!]))!;

          final icon = await UIImage.create(iconData[0]);

          // 由于ios端的icon参数在回调中设置, 需要添加属性来实现
          await annotation.setIcon(icon);

          pool.add(icon);
        }
        // 是否可拖拽
        await annotation.setDraggable(option.draggable);
        // 旋转角度
        await annotation.setRotateAngle(option.rotateAngle);
        // 是否允许弹窗
        await annotation.setInfoWindowEnabled(option.infoWindowEnabled);
        // 锚点
        await annotation.setAnchor(option.anchorU, option.anchorV);
        // 自定义数据
        if (option.object != null) {
          await annotation.setObject(option.object!);
        }
        // 是否可见
        await annotation.setVisible(option.visible);
        // 透明度
        if (option.opacity != null) {
          await annotation.setOpacity(option.opacity!);
        }

        // 添加marker
        await iosController!.addAnnotation(annotation);

        pool.add(coordinate);

        return Marker.ios(annotation, iosController);
      },
    );
  }

  /// 批量添加marker
  ///
  /// 根据[options]批量创建Marker
  @override
  Future<List<IMarker>> addMarkers(List<MarkerOption> options) async {
    if (state?.mounted != true) return [];

    if (options.isEmpty) return Future.value([]);

    final latBatch = options.map((it) => it.coordinate.latitude).toList();
    final lngBatch = options.map((it) => it.coordinate.longitude).toList();
    final titleBatch = options.map((it) => it.title).toList();
    final snippetBatch = options.map((it) => it.snippet).toList();
    final draggableBatch = options.map((it) => it.draggable).toList();
    final rotateAngleBatch = options.map((it) => it.rotateAngle).toList();
    final anchorUBatch = options.map((it) => it.anchorU).toList();
    final anchorVBatch = options.map((it) => it.anchorV).toList();
    final visibleBatch = options.map((it) => it.visible).toList();
    final infoWindowEnabledBatch =
        options.map((it) => it.infoWindowEnabled).toList();
    final objectBatch = options.map((it) => it.object ?? '').toList();
    final iconDataBatch = <Uint8List>[
      ...await Future.wait([
        for (final option in options)
          if (option.iconProvider != null)
            option.iconProvider!.toImageData(imageConfiguration)
      ]),
      ...?await state!.widgetToImageData(options
          .where((element) => element.widget != null)
          .map((e) => e.widget!)
          .toList()),
    ];

    return platform(
      android: (pool) async {
        // 获取地图
        final map = await androidController!.getMap();
        final latLngBatch = await com_amap_api_maps_model_LatLng
            .create_batch__double__double(latBatch, lngBatch);
        // marker配置
        final markerOptionBatch = await com_amap_api_maps_model_MarkerOptions
            .create_batch__(options.length);
        // 添加经纬度
        await markerOptionBatch.position_batch(latLngBatch);
        // 添加标题
        await markerOptionBatch.title_batch(titleBatch);
        // 添加副标题
        await markerOptionBatch.snippet_batch(snippetBatch);
        // 是否可拖动
        await markerOptionBatch.draggable_batch(draggableBatch);
        // 旋转角度
        await markerOptionBatch.rotateAngle_batch(rotateAngleBatch);
        // 锚点
        await markerOptionBatch.anchor_batch(anchorUBatch, anchorVBatch);
        // 是否可见
        await markerOptionBatch.visible_batch(visibleBatch);
        // 图片
        if (iconDataBatch.isNotEmpty) {
          final bitmapBatch =
              await android_graphics_Bitmap.create_batch(iconDataBatch);
          final iconBatch =
              await com_amap_api_maps_model_BitmapDescriptorFactory_Batch
                  .fromBitmap_batch(bitmapBatch!);
          await markerOptionBatch.icon_batch(iconBatch
              .whereType<com_amap_api_maps_model_BitmapDescriptor>()
              .toList());
          pool
            ..addAll(bitmapBatch)
            ..addAll(iconBatch);
        }

        // 添加marker
        final markers = await map!.addMarkers(markerOptionBatch, false);

        // 弹窗使能
        await markers!.setInfoWindowEnable_batch(infoWindowEnabledBatch);
        // 自定义数据
        await markers.setObject_batch(objectBatch.whereType<Object>().toList());

        // marker不释放, 还有用
        pool
          ..addAll(latLngBatch)
          ..addAll(markerOptionBatch);
        return markers.map((it) => Marker.android(it)).toList();
      },
      ios: (pool) async {
        _iosMapDelegate ??= await MAMapViewDelegate.anonymous__();
        await iosController!.set_delegate(_iosMapDelegate!);

        // 创建marker
        final annotationBatch =
            await MAPointAnnotation.create_batch__(options.length);

        // 经纬度列表
        final coordinateBatch =
            await CLLocationCoordinate2D.create_batch(latBatch, lngBatch);
        // 设置经纬度
        await annotationBatch.set_coordinate_batch(coordinateBatch);
        // 设置标题
        await annotationBatch.set_title_batch(titleBatch);
        // 设置副标题
        await annotationBatch.set_subtitle_batch(snippetBatch);
        // 设置图片
        if (iconDataBatch.isNotEmpty) {
          final iconBatch = await UIImage.create_batch(iconDataBatch);
          await annotationBatch.setIcon(iconBatch);
          pool.addAll(iconBatch);
        }
        // 是否可拖拽
        await annotationBatch.setDraggable(draggableBatch);
        // 旋转角度
        await annotationBatch.setRotateAngle(rotateAngleBatch);
        // 是否允许弹窗
        await annotationBatch.setInfoWindowEnabled(infoWindowEnabledBatch);
        // 锚点
        await annotationBatch.setAnchor(anchorUBatch, anchorVBatch);
        // 自定义数据
        await annotationBatch.setObject(objectBatch);
        // 是否可见
        await annotationBatch.setVisible(visibleBatch);

        // 添加marker
        await iosController!.addAnnotations(annotationBatch);

        pool.addAll(coordinateBatch);
        return [
          for (int i = 0; i < options.length; i++)
            Marker.ios(annotationBatch[i], iosController)
        ];
      },
    );
  }

  /// 把marker列表从地图上移除
  @override
  Future<void> clearMarkers(List<IMarker> markers) async {
    await platform(
      android: (pool) async {
        final markerBatch =
            markers.cast<Marker>().map((it) => it.androidModel).toList();
        await markerBatch.remove_batch();
      },
      ios: (pool) async {
        final markerBatch =
            markers.cast<Marker>().map((it) => it.iosModel).toList();
        await iosController!.removeAnnotations(markerBatch);
      },
    );
  }

  /// 清除地图上所有覆盖物
  ///
  /// 根据[keepMyLocation]区分是否保留我的位置的marker
  @override
  Future<void> clear({bool keepMyLocation = true}) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        await map!.clear__bool(keepMyLocation);
      },
      ios: (pool) async {
        final markers = await iosController!.get_annotations();
        final overlays = await iosController!.get_overlays();
        await iosController!.removeAnnotations(markers!);
        await iosController!.removeOverlays(overlays!);

        pool
          ..addAll(markers.cast<Ref>())
          ..addAll(overlays.cast<Ref>());
      },
    );
  }

  /// 屏幕坐标转经纬度坐标
  @override
  Future<LatLng> fromScreenLocation(Point point) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final projection = await map!.getProjection();

        final androidPoint = await android_graphics_Point.create(
            point.x.toInt(), point.y.toInt());

        final latLng = await projection!.fromScreenLocation(androidPoint);

        pool
          ..add(projection)
          ..add(androidPoint)
          ..add(latLng);
        return LatLng(
          await latLng!.get_latitude() ?? 0,
          await latLng.get_longitude() ?? 0,
        );
      },
      ios: (pool) async {
        final cgPoint =
            await CGPoint.create(point.x.toDouble(), point.y.toDouble());
        final coord2d = await iosController!
            .convertPoint_toCoordinateFromView(cgPoint, iosController!);

        pool
          ..add(cgPoint)
          ..add(coord2d);
        return LatLng(
          await coord2d!.latitude ?? 0,
          await coord2d.longitude ?? 0,
        );
      },
    );
  }

  /// 经纬度坐标转屏幕坐标
  @override
  Future<Point> toScreenLocation(LatLng coordinate) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        final projection = await map!.getProjection();

        final latLng = await com_amap_api_maps_model_LatLng
            .create__double__double(coordinate.latitude, coordinate.longitude);

        final point = await projection!.toScreenLocation(latLng);

        pool
          ..add(projection)
          ..add(latLng)
          ..add(point);
        return Point((await point!.x)!.toDouble(), (await point.y)!.toDouble());
      },
      ios: (pool) async {
        final latLng = await CLLocationCoordinate2D.create(
            coordinate.latitude, coordinate.longitude);
        final point = await iosController!
            .convertCoordinate_toPointToView(latLng, iosController!);

        pool
          ..add(latLng)
          ..add(point);
        return Point((await point!.x)!.toDouble(), (await point.y)!.toDouble());
      },
    );
  }

  /// 添加折线
  ///
  /// 可配置参数详见[PolylineOption]
  @override
  Future<IPolyline> addPolyline(PolylineOption option) async {
    if (state?.mounted != true) throw StateError('widget no longer mounted');

    final latitudeBatch = option.coordinateList.map((e) => e.latitude).toList();
    final longitudeBatch =
        option.coordinateList.map((e) => e.longitude).toList();
    final textureData =
        await option.textureProvider?.toImageData(imageConfiguration);
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        // 构造折线点
        List<com_amap_api_maps_model_LatLng> latLngList =
            await com_amap_api_maps_model_LatLng.create_batch__double__double(
          latitudeBatch,
          longitudeBatch,
        );

        // 构造折线参数
        final polylineOptions =
            await com_amap_api_maps_model_PolylineOptions.create__();

        // 添加经纬度列表
        await polylineOptions.addAll(latLngList);
        await polylineOptions.width(option.width);
        // 颜色
        await polylineOptions
            .color(Int32List.fromList([option.strokeColor.value])[0]);
        // 自定义贴图
        if (textureData != null) {
          final bitmap = await android_graphics_Bitmap.create(textureData);
          final texture = await com_amap_api_maps_model_BitmapDescriptorFactory
              .fromBitmap(bitmap);
          await polylineOptions.setCustomTexture(texture!);
          await polylineOptions.setUseTexture(true);

          pool
            ..add(bitmap)
            ..add(texture);
        }
        // 线段始末端样式, 由于两端的枚举顺序是一样的, 所以这里直接从索引获取枚举
        if (option.lineCapType != null) {
          await polylineOptions.lineCapType(
            com_amap_api_maps_model_PolylineOptions_LineCapType
                .values[option.lineCapType!.index],
          );
        }
        // 线段连接处样式, 由于两端的枚举顺序是一样的, 所以这里直接从索引获取枚举
        if (option.lineJoinType != null) {
          await polylineOptions.lineJoinType(
              com_amap_api_maps_model_PolylineOptions_LineJoinType
                  .values[option.lineJoinType!.index]);
        }
        // 是否虚线
        if (option.dashType != null) {
          await polylineOptions.setDottedLine(true);
          switch (option.dashType!) {
            case DashType.Square:
              await polylineOptions.setDottedLineType(
                  com_amap_api_maps_model_PolylineOptions
                      .DOTTEDLINE_TYPE_SQUARE);
              break;
            case DashType.Circle:
              await polylineOptions.setDottedLineType(
                  com_amap_api_maps_model_PolylineOptions
                      .DOTTEDLINE_TYPE_CIRCLE);
              break;
          }
        }
        // 设置参数
        final polyline = await map!.addPolyline(polylineOptions);

        pool
          ..add(polylineOptions)
          ..addAll(latLngList);

        return Polyline.android(polyline);
      },
      ios: (pool) async {
        _iosMapDelegate ??= await MAMapViewDelegate.anonymous__();
        await iosController!.set_delegate(_iosMapDelegate!);

        // 构造折线点
        List<CLLocationCoordinate2D> latLngList =
            await CLLocationCoordinate2D.create_batch(
                latitudeBatch, longitudeBatch);

        // 构造折线参数
        final polyline = await MAPolyline.polylineWithCoordinates_count(
            latLngList, latLngList.length);

        // 宽度和颜色需要设置到STACK里去
        final pixelRatio = MediaQuery.of(state!.context).devicePixelRatio;
        await polyline!.addJsonableProperty__(1, option.width / pixelRatio);
        // 颜色
        await polyline.addJsonableProperty__(2, option.strokeColor.value);
        // 设置图片
        if (textureData != null) {
          final texture = await UIImage.create(textureData);

          await polyline.addProperty__(3, texture);

          pool.add(texture);
        }
        // 线段始末端样式, 由于两端的枚举顺序是一样的, 所以这里直接从索引获取枚举
        if (option.lineCapType != null) {
          await polyline.addJsonableProperty__(4, option.lineCapType!.index);
        }
        // 线段连接处样式, 由于两端的枚举顺序是一样的, 所以这里直接从索引获取枚举
        if (option.lineJoinType != null) {
          await polyline.addJsonableProperty__(5, option.lineJoinType!.index);
        }
        // 是否虚线
        if (option.dashType != null) {
          await polyline.addJsonableProperty__(6, option.dashType!.index + 1);
        }

        // 设置参数
        await iosController!.addOverlay(polyline);

        pool.addAll(latLngList);

        return Polyline.ios(polyline, iosController);
      },
    );
  }

  /// 添加多边形
  ///
  /// 在点[points]的位置添加线, 可以设置宽度[width]和颜色[strokeColor]
  @override
  Future<IPolygon> addPolygon(PolygonOption option) {
    final latitudeBatch = option.coordinateList.map((e) => e.latitude).toList();
    final longitudeBatch =
        option.coordinateList.map((e) => e.longitude).toList();
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        // 构造折线点
        List<com_amap_api_maps_model_LatLng> latLngList =
            await com_amap_api_maps_model_LatLng.create_batch__double__double(
          latitudeBatch,
          longitudeBatch,
        );

        // 构造参数
        final polygonOptions =
            await com_amap_api_maps_model_PolygonOptions.create__();

        // 添加参数
        await polygonOptions.addAll(latLngList);
        // 宽度
        await polygonOptions.strokeWidth(option.width);
        // 边框颜色
        await polygonOptions
            .strokeColor(Int32List.fromList([option.strokeColor.value])[0]);
        // 填充颜色
        await polygonOptions
            .fillColor(Int32List.fromList([option.fillColor.value])[0]);
        if (option.zIndex != null) {
          await polygonOptions.zIndex(option.zIndex!);
        }

        // 设置参数
        final polygon = await map!.addPolygon(polygonOptions);

        pool
          ..add(polygonOptions)
          ..addAll(latLngList);

        return Polygon.android(polygon);
      },
      ios: (pool) async {
        _iosMapDelegate ??= await MAMapViewDelegate.anonymous__();
        await iosController!.set_delegate(_iosMapDelegate!);

        // 构造折线点
        List<CLLocationCoordinate2D> latLngList =
            await CLLocationCoordinate2D.create_batch(
                latitudeBatch, longitudeBatch);

        // 构造折线参数
        final polygon = await MAPolygon.polygonWithCoordinates_count(
            latLngList, latLngList.length);

        final pixelRatio = MediaQuery.of(state!.context).devicePixelRatio;
        await polygon!.addJsonableProperty__(1, option.width / pixelRatio);
        await polygon.addJsonableProperty__(2, option.strokeColor.value);
        await polygon.addJsonableProperty__(3, option.fillColor.value);
        if (option.zIndex != null) {
          // TODO ios端未实现
          await polygon.addJsonableProperty__(4, option.zIndex!);
        }

        // 设置参数
        await iosController!.addOverlay(polygon);

        pool.addAll(latLngList);

        return Polygon.ios(polygon, iosController);
      },
    );
  }

  /// 添加圆
  ///
  /// 在点[points]的位置添加线, 可以设置宽度[width]和颜色[strokeColor]
  @override
  Future<ICircle> addCircle(CircleOption option) {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        // 构造点
        final latLng =
            await com_amap_api_maps_model_LatLng.create__double__double(
          option.center.latitude,
          option.center.longitude,
        );

        // 构造参数
        final circleOptions =
            await com_amap_api_maps_model_CircleOptions.create__();

        // 中心点
        await circleOptions.center(latLng);
        // 半径
        await circleOptions.radius(option.radius);
        // 宽度
        await circleOptions.strokeWidth(option.width);
        // 边框颜色
        await circleOptions
            .strokeColor(Int32List.fromList([option.strokeColor.value])[0]);
        // 填充颜色
        await circleOptions
            .fillColor(Int32List.fromList([option.fillColor.value])[0]);

        // 设置参数
        final circle = await map!.addCircle(circleOptions);

        pool
          ..add(circleOptions)
          ..add(latLng);

        return Circle.android(circle);
      },
      ios: (pool) async {
        _iosMapDelegate ??= await MAMapViewDelegate.anonymous__();
        await iosController!.set_delegate(_iosMapDelegate!);

        final latLng = await CLLocationCoordinate2D.create(
          option.center.latitude,
          option.center.longitude,
        );

        // 参数
        final circle = await MACircle.circleWithCenterCoordinate_radius(
          latLng,
          option.radius,
        );

        final pixelRatio = MediaQuery.of(state!.context).devicePixelRatio;
        await circle!.addJsonableProperty__(1, option.width / pixelRatio);
        await circle.addJsonableProperty__(2, option.strokeColor.value);
        await circle.addJsonableProperty__(3, option.fillColor.value);

        // 设置参数
        await iosController!.addOverlay(circle);

        return Circle.ios(circle, iosController);
      },
    );
  }

  /// 设置marker点击监听事件
  @override
  Future<void> setMarkerClickedListener(OnMarkerClicked onMarkerClicked) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final listener =
            await com_amap_api_maps_AMap_OnMarkerClickListener.anonymous__();
        await map!.setOnMarkerClickListener(
          listener
            ..onMarkerClick = (marker) async {
              onMarkerClicked(Marker.android(marker));
              return true;
            },
        );
      },
      ios: (pool) async {
        _iosMapDelegate ??= await MAMapViewDelegate.anonymous__();
        await iosController!.set_delegate(
          _iosMapDelegate!
            ..mapView_didAnnotationViewTapped = (_, view) async {
              onMarkerClicked(
                Marker.ios(
                  // 这里由于传入的类型是MAAnnotation, 而fluttify对于抽象类的实体子类的处理方式是找到sdk
                  // 内的第一个实体子类进行实例化, 这里如果放任不管取第一个实体子类的话是MAGroundOverlay
                  // 跟当前需要的MAPointAnnotation类是冲突的.
                  //
                  // 解决办法很简单, 把refId取出来放到目标实体类里就行了
                  MAPointAnnotation()
                    ..refId = (await view!.get_annotation())!.refId,
                  iosController,
                ),
              );
            },
        );
      },
    );
  }

  /// 设置marker拖动监听事件
  @override
  Future<void> setMarkerDragListener({
    OnMarkerDrag? onMarkerDragStart,
    OnMarkerDrag? onMarkerDragging,
    OnMarkerDrag? onMarkerDragEnd,
  }) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final listener =
            await com_amap_api_maps_AMap_OnMarkerDragListener.anonymous__();
        await map!.setOnMarkerDragListener(
          listener
            ..onMarkerDragStart = (marker) async {
              onMarkerDragStart?.call(Marker.android(marker));
            }
            ..onMarkerDrag = (marker) async {
              onMarkerDragging?.call(Marker.android(marker));
            }
            ..onMarkerDragEnd = (marker) async {
              onMarkerDragEnd?.call(Marker.android(marker));
            },
        );
      },
      ios: (pool) async {
        _iosMapDelegate ??= await MAMapViewDelegate.anonymous__();
        await iosController!.set_delegate(
          _iosMapDelegate!
            ..mapView_annotationView_didChangeDragState_fromOldState =
                (_, view, newState, oldState) async {
              final annotation = AmapMapFluttifyIOSAs<MAPointAnnotation>(
                  await view!.get_annotation());
              if (newState ==
                  MAAnnotationViewDragState.MAAnnotationViewDragStateStarting) {
                await onMarkerDragStart
                    ?.call(Marker.ios(annotation, iosController));
              }

              if (newState ==
                  MAAnnotationViewDragState.MAAnnotationViewDragStateDragging) {
                await onMarkerDragging
                    ?.call(Marker.ios(annotation, iosController));
              }

              if (newState ==
                  MAAnnotationViewDragState.MAAnnotationViewDragStateEnding) {
                await onMarkerDragEnd
                    ?.call(Marker.ios(annotation, iosController));
              }
            },
        );
      },
    );
  }

  /// 设置地图点击监听事件
  @override
  Future<void> setMapClickedListener(OnMapClicked onMapClick) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final listener =
            await com_amap_api_maps_AMap_OnMapClickListener.anonymous__();
        await map!.setOnMapClickListener(
          listener
            ..onMapClick = (latLng) async {
              onMapClick(
                LatLng(
                  await latLng!.get_latitude() ?? 0,
                  await latLng.get_longitude() ?? 0,
                ),
              );
            },
        );
      },
      ios: (pool) async {
        await iosController!.set_delegate(
          _iosMapDelegate!
            ..mapView_didSingleTappedAtCoordinate = (_, coordinate) async {
              await onMapClick(
                LatLng(
                  await coordinate!.latitude ?? 0,
                  await coordinate.longitude ?? 0,
                ),
              );
            },
        );
      },
    );
  }

  /// 设置地图长按监听事件
  @override
  Future<void> setMapLongPressedListener(OnMapClicked onMapLongPress) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final listener =
            await com_amap_api_maps_AMap_OnMapLongClickListener.anonymous__();
        await map!.setOnMapLongClickListener(
          listener
            ..onMapLongClick = (latLng) async {
              await onMapLongPress(
                LatLng(
                  await latLng!.get_latitude() ?? 0,
                  await latLng.get_longitude() ?? 0,
                ),
              );
            },
        );
      },
      ios: (pool) async {
        _iosMapDelegate ??= await MAMapViewDelegate.anonymous__();
        await iosController!.set_delegate(
          _iosMapDelegate!
            ..mapView_didLongPressedAtCoordinate = (mapView, coordinate) async {
              await onMapLongPress(
                LatLng(
                  await coordinate!.latitude ?? 0,
                  await coordinate.longitude ?? 0,
                ),
              );
            },
        );
      },
    );
  }

  /// 设置地图移动监听事件
  @override
  Future<void> setMapMoveListener({
    OnMapMove? onMapMoveStart,
    OnMapMove? onMapMoving,
    OnMapMove? onMapMoveEnd,
  }) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        bool _moveStarted = false;
        final listener =
            await com_amap_api_maps_AMap_OnCameraChangeListener.anonymous__();
        await map!.setOnCameraChangeListener(
          listener
            ..onCameraChange = (position) async {
              final location = await position!.get_target();
              if (onMapMoving != null && _moveStarted) {
                await onMapMoving(MapMove(
                  coordinate: LatLng(
                    await location!.get_latitude() ?? 0,
                    await location.get_longitude() ?? 0,
                  ),
                  zoom: await position.get_zoom(),
                  tilt: await position.get_tilt(),
                  bearing: await position.get_bearing(),
                  isAbroad: await position.get_isAbroad(),
                ));
              } else if (onMapMoveStart != null && !_moveStarted) {
                await onMapMoveStart(MapMove(
                  coordinate: LatLng(
                    await location!.get_latitude() ?? 0,
                    await location.get_longitude() ?? 0,
                  ),
                  zoom: await position.get_zoom(),
                  bearing: await position.get_bearing(),
                  tilt: await position.get_tilt(),
                  isAbroad: await position.get_isAbroad(),
                ));
                // 由于ios端只有`开始`和`结束`的回调, 而android这边是只要改变就有回调, 这里回调过
                // 第一次之后就把标记记为已经触发, 在移动结束后再置回来
                _moveStarted = true;
              } else {
                // 防止没有设置_onMapMoveStart, 这里一律在回调后设置成已经开始移动
                _moveStarted = true;
              }
            }
            ..onCameraChangeFinish = (position) async {
              if (onMapMoveEnd != null) {
                final location = await position!.get_target();
                await onMapMoveEnd(MapMove(
                  coordinate: LatLng(
                    await location!.get_latitude() ?? 0,
                    await location.get_longitude() ?? 0,
                  ),
                  zoom: await position.get_zoom(),
                  bearing: await position.get_bearing(),
                  tilt: await position.get_tilt(),
                  isAbroad: await position.get_isAbroad(),
                ));
              }
              // 无论有没有设置过回调, 这里都给它置回来
              _moveStarted = false;
            },
        );
      },
      ios: (pool) async {
        _iosMapDelegate ??= await MAMapViewDelegate.anonymous__();
        await iosController!.set_delegate(
          _iosMapDelegate!
            ..mapView_regionWillChangeAnimated_wasUserAction =
                (mapView, animated, userAction) async {
              final location = await mapView!.get_centerCoordinate();
              await onMapMoveStart?.call(MapMove(
                coordinate: LatLng(
                  await location!.latitude ?? 0,
                  await location.longitude ?? 0,
                ),
                zoom: await mapView.get_zoomLevel(),
                tilt: await mapView.get_cameraDegree(),
                bearing: await mapView.get_rotationDegree(),
                isAbroad: await mapView.get_isAbroad(),
              ));
            }
            ..mapViewRegionChanged = (mapView) async {
              final location = await mapView!.get_centerCoordinate();
              await onMapMoving?.call(MapMove(
                coordinate: LatLng(
                  await location!.latitude ?? 0,
                  await location.longitude ?? 0,
                ),
                zoom: await mapView.get_zoomLevel(),
                tilt: await mapView.get_cameraDegree(),
                bearing: await mapView.get_rotationDegree(),
                isAbroad: await mapView.get_isAbroad(),
              ));
            }
            ..mapView_regionDidChangeAnimated_wasUserAction =
                (mapView, animated, userAction) async {
              final location = await mapView!.get_centerCoordinate();
              await onMapMoveEnd?.call(MapMove(
                coordinate: LatLng(
                  await location!.latitude ?? 0,
                  await location.longitude ?? 0,
                ),
                zoom: await mapView.get_zoomLevel(),
                tilt: await mapView.get_cameraDegree(),
                bearing: await mapView.get_rotationDegree(),
                isAbroad: await mapView.get_isAbroad(),
              ));
            },
        );
      },
    );
  }

  /// 请求后台定位 *仅iOS
  Future<void> requireAlwaysAuth() async {
    await platform(
      android: (pool) async {},
      ios: (pool) async {
        await iosController!.set_delegate(
          _iosMapDelegate!
            ..mapViewRequireLocationAuth = (CLLocationManager? manager) async {
              await manager?.requestAlwaysAuthorization();
            },
        );
      },
    );
  }

  /// 截图
  @override
  Future<Uint8List> screenShot() async {
    return platform(
      android: (pool) async {
        final completer = Completer<Uint8List>();

        final map = await androidController!.getMap();

        final listener =
            await com_amap_api_maps_AMap_OnMapScreenShotListener.anonymous__();
        await map!.getMapScreenShot(
          listener
            ..onMapScreenShot__android_graphics_Bitmap = (bitmap) async {
              completer.complete((await bitmap!.data)!);
            },
        );

        return completer.future;
      },
      ios: (pool) async {
        final completer = Completer<Uint8List>();

        final rect = await iosController!.frame;
        await iosController!.takeSnapshotInRect_withCompletionBlock(
          rect,
          (image, state) async {
            completer.complete((await image!.data)!);
            pool.add(image);
          },
        );

        pool.add(rect);
        return completer.future;
      },
    );
  }

  /// 限制地图的显示范围
  ///
  /// [southWest]西南角, [northEast]东北角
  @override
  Future<void> setMapRegionLimits(LatLng southWest, LatLng northEast) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final southWestPoint = await com_amap_api_maps_model_LatLng
            .create__double__double(southWest.latitude, southWest.longitude);
        final northEastPoint = await com_amap_api_maps_model_LatLng
            .create__double__double(northEast.latitude, northEast.longitude);

        final latLngBounds = await com_amap_api_maps_model_LatLngBounds
            .create__com_amap_api_maps_model_LatLng__com_amap_api_maps_model_LatLng(
                southWestPoint, northEastPoint);

        await map!.setMapStatusLimits(latLngBounds);

        pool
          ..add(southWestPoint)
          ..add(northEastPoint)
          ..add(latLngBounds);
      },
      ios: (pool) async {
        final center = await CLLocationCoordinate2D.create(
          (southWest.latitude + northEast.latitude) / 2,
          (southWest.longitude + northEast.longitude) / 2,
        );
        final span = await MACoordinateSpanMake(
          northEast.latitude - southWest.latitude,
          northEast.longitude - southWest.longitude,
        );
        final region = await MACoordinateRegionMake(center, span!);
        await iosController!.set_limitRegion(region!);

        pool
          ..add(center)
          ..add(span)
          ..add(region);
      },
    );
  }

  /// Marker弹窗点击事件监听
  @override
  Future<void> setInfoWindowClickListener(
    OnMarkerClicked onInfoWindowClicked,
  ) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final listener = await com_amap_api_maps_AMap_OnInfoWindowClickListener
            .anonymous__();
        await map!.setOnInfoWindowClickListener(
          listener
            ..onInfoWindowClick = (marker) async {
              onInfoWindowClicked(Marker.android(marker));
            },
        );
      },
      ios: (pool) async {
        _iosMapDelegate ??= await MAMapViewDelegate.anonymous__();
        await iosController!.set_delegate(
          _iosMapDelegate!
            ..mapView_didAnnotationViewCalloutTapped = (_, view) async {
              await onInfoWindowClicked(
                Marker.ios(
                  MAPointAnnotation()
                    ..refId = (await view!.get_annotation())!.refId,
                  iosController,
                ),
              );
            },
        );
      },
    );
  }

  /// 添加瓦片图
  @override
  Future<IUrlTileOverlay> addUrlTileOverlay(UrlTileOption option) async {
    final width = option.width;
    final height = option.height;
    final urlTemplate = option.urlTemplate;
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final options =
            await com_amap_api_maps_model_TileOverlayOptions.create__();
        final provider = await com_amap_api_maps_model_UrlTileProvider_X.create(
            width, height, urlTemplate);
        await options.tileProvider(provider);
        await options.diskCacheEnabled(true);
        await options.diskCacheSize(100000);
        await options.memoryCacheEnabled(true);
        await options.memCacheSize(100000);
        await options.zIndex(-9999);

        // 进行添加
        final tile = await map!.addTileOverlay(options);
        pool
          ..add(options)
          ..add(provider);

        return UrlTileOverlay.android(tile);
      },
      ios: (pool) async {
        await iosController!.set_delegate(_iosMapDelegate!);

        final overlay = await MATileOverlay.create__();
        await overlay.initWithURLTemplate(urlTemplate);
        await overlay.set_tileSize(
          await CGSize.create(width.toDouble(), height.toDouble()),
        );

        // 添加热力图
        await iosController!.addOverlay(overlay);

        pool.add(overlay);

        return UrlTileOverlay.ios(overlay, iosController);
      },
    );
  }

  /// 自定义弹窗
  Future<void> showCustomInfoWindow(Marker marker, Widget widget) async {
    final imageData = (await state!.widgetToImageData([widget]))?.first;
    if (imageData == null) return;

    // 准备弹窗需要的数据
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        await kAmapMapFluttifyChannel.invokeMethod(
          'com.amap.api.maps.AMap::setInfoWindowAdapterX',
          {'__this__': map},
        );
        final bitmap = await android_graphics_Bitmap.create(imageData);
        await pushStack('infoWindow', bitmap);

        pool.add(bitmap);
      },
      ios: (pool) async {
        // 创建弹窗view
        final bitmap = await UIImage.create(imageData);
        final imageView = await UIImageView.create(bitmap);

        final frame = await imageView.frame;
        final width = await frame.width;
        final height = await frame.height;

        // 去掉默认的弹窗
        final annotationView =
            await iosController!.viewForAnnotation(marker.iosModel!);
        await annotationView?.set_canShowCallout(false);
        // 由于默认偏移量是0, 这里根据弹窗view设置一下偏移量
        await annotationView?.set_calloutOffset(
          await CGPoint.create(-width! / 2, -height!),
        );

        // 创建自定义弹窗
        final calloutView = await MACustomCalloutView.create__();
        await calloutView.initWithCustomView(imageView);

        // 设置自定义弹窗
        await annotationView?.set_customCalloutView(calloutView);

        pool
          ..add(bitmap)
          ..add(imageView)
          ..add(calloutView);
      },
    );

    // 显示弹窗
    await marker.showInfoWindow();
  }

  /// 添加图片覆盖物
  @override
  Future<IGroundOverlay> addGroundOverlay(GroundOverlayOption option) async {
    final imageData = await option.imageProvider
        .toImageData(createLocalImageConfiguration(state!.context));
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final groundOverlayOption =
            await com_amap_api_maps_model_GroundOverlayOptions.create__();

        // 创建图片边界
        final southWestPoint =
            await com_amap_api_maps_model_LatLng.create__double__double(
                option.southWest.latitude, option.southWest.longitude);
        final northEastPoint =
            await com_amap_api_maps_model_LatLng.create__double__double(
                option.northEast.latitude, option.northEast.longitude);

        final bounds = await com_amap_api_maps_model_LatLngBounds
            .create__com_amap_api_maps_model_LatLng__com_amap_api_maps_model_LatLng(
                southWestPoint, northEastPoint);
        await groundOverlayOption.positionFromBounds(bounds);

        // 创建图片
        final bitmap = await android_graphics_Bitmap.create(imageData);
        final descriptor = await com_amap_api_maps_model_BitmapDescriptorFactory
            .fromBitmap(bitmap);
        await groundOverlayOption.image(descriptor!);

        // 进行添加
        final groundOverlay = await map!.addGroundOverlay(groundOverlayOption);

        await bitmap.recycle();
        pool
          ..add(groundOverlayOption)
          ..add(southWestPoint)
          ..add(descriptor)
          ..add(northEastPoint);

        return GroundOverlay.android(groundOverlay);
      },
      ios: (pool) async {
        await iosController!.set_delegate(_iosMapDelegate!);

        final southWestPoint = await CLLocationCoordinate2D.create(
          option.southWest.latitude,
          option.southWest.longitude,
        );
        final northEastPoint = await CLLocationCoordinate2D.create(
          option.northEast.latitude,
          option.northEast.longitude,
        );
        final bounds =
            await MACoordinateBoundsMake(northEastPoint, southWestPoint);

        final bitmap = await UIImage.create(imageData);
        final overlay =
            await MAGroundOverlay.groundOverlayWithBounds_icon(bounds!, bitmap);

        // 添加热力图
        await iosController!.addOverlay(overlay!);

        pool
          ..add(southWestPoint)
          ..add(northEastPoint)
          ..add(bounds)
          ..add(bitmap);

        return GroundOverlay.ios(overlay, iosController);
      },
    );
  }

  /// 添加热力图
  @override
  Future<IHeatmapOverlay> addHeatmapTileOverlay(
    HeatmapTileOption option,
  ) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        // 创建热力图Provider
        final builder =
            await com_amap_api_maps_model_HeatmapTileProvider_Builder
                .create__();
        List<com_amap_api_maps_model_LatLng> latLngList = [];
        for (final latLng in option.coordinateList) {
          latLngList.add(await com_amap_api_maps_model_LatLng
              .create__double__double(latLng.latitude, latLng.longitude));
        }
        await builder.data(latLngList);
        if (option.gradient != null) {
          await builder.gradient(
            await com_amap_api_maps_model_GradientX.create(
              Int32List.fromList(
                  option.gradient!.colors.map((e) => e.value).toList()),
              Float64List.fromList(option.gradient!.stops!),
            ),
          );
          // if (option.gradient.radius != null) {
          //   await builder.radius(option.gradient.radius?.toInt());
          // }
        }

        // 创建Tile Overlay选项
        final tileOverlayOption =
            await com_amap_api_maps_model_TileOverlayOptions.create__();
        await tileOverlayOption.tileProvider((await builder.build())!);

        // 添加热力图
        final heatmap = await map!.addTileOverlay(tileOverlayOption);

        pool
          ..add(builder)
          ..addAll(latLngList)
          ..add(tileOverlayOption);

        return HeatmapOverlay.android(heatmap);
      },
      ios: (pool) async {
        await iosController!.set_delegate(_iosMapDelegate!);

        // 创建热力图选项
        final overlay = await MAHeatMapTileOverlay.create__();

        // 构造热力图结点
        List<MAHeatMapNode> nodeList = [];
        for (final latLng in option.coordinateList) {
          final node = await MAHeatMapNode.create__();
          final coordinate = await CLLocationCoordinate2D.create(
            latLng.latitude,
            latLng.longitude,
          );
          pool
            ..add(node)
            ..add(coordinate);

          // 坐标点
          await node.set_coordinate(coordinate);
          // 权重值 暂时全部都为1
          await node.set_intensity(1);
          // 权重值 暂时全部都为1
          nodeList.add(node);
        }
        // 添加结点数据
        await overlay.set_data(nodeList);
        if (option.gradient != null) {
          final gradient = await MAHeatMapGradient.create__(init: false);
          await gradient.initWithColor_andWithStartPoints(
            <UIColor>[
              for (final color in option.gradient!.colors)
                await UIColor.create(color)
            ],
            option.gradient!.stops!,
          );
          await overlay.set_gradient(gradient);

          // if (option.gradient.radius != null) {
          //   await overlay.set_radius(option.gradient.radius.toInt());
          // }
        }

        // 添加热力图
        await iosController!.addOverlay(overlay);

        pool.addAll(nodeList);

        return HeatmapOverlay.ios(overlay, iosController);
      },
    );
  }

  /// 将指定的经纬度列表(包括但不限于marker, polyline, polygon等)调整至同一屏幕中显示
  ///
  /// [bounds]边界点形成的边界, [padding]地图内边距
  @override
  Future<void> zoomToSpan(
    List<LatLng> bounds, {
    EdgeInsets padding = const EdgeInsets.all(50),
    bool animated = true,
  }) async {
    final double minLat = await Stream.fromIterable(bounds)
        .reduce((pre, cur) => pre.latitude < cur.latitude ? pre : cur)
        .then((bottom) => bottom.latitude);
    final double minLng = await Stream.fromIterable(bounds)
        .reduce((pre, cur) => pre.longitude < cur.longitude ? pre : cur)
        .then((left) => left.longitude);
    final double maxLat = await Stream.fromIterable(bounds)
        .reduce((pre, cur) => pre.latitude > cur.latitude ? pre : cur)
        .then((top) => top.latitude);
    final double maxLng = await Stream.fromIterable(bounds)
        .reduce((pre, cur) => pre.longitude > cur.longitude ? pre : cur)
        .then((right) => right.longitude);

    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        // 西南角
        final southWest = await com_amap_api_maps_model_LatLng
            .create__double__double(minLat, minLng);
        // 东北角
        final northEast = await com_amap_api_maps_model_LatLng
            .create__double__double(maxLat, maxLng);

        // 可视区域矩形
        final rect = await com_amap_api_maps_model_LatLngBounds
            .create__com_amap_api_maps_model_LatLng__com_amap_api_maps_model_LatLng(
                southWest, northEast);

        // 更新对象 android端由于单位是像素, 所以这里要乘以当前设备的像素密度
        final cameraUpdate =
            await com_amap_api_maps_CameraUpdateFactory.newLatLngBoundsRect(
          rect,
          (padding.left.toInt() * ui.window.devicePixelRatio).toInt(),
          (padding.right.toInt() * ui.window.devicePixelRatio).toInt(),
          (padding.top.toInt() * ui.window.devicePixelRatio).toInt(),
          (padding.bottom.toInt() * ui.window.devicePixelRatio).toInt(),
        );

        if (animated) {
          await map!
              .animateCamera__com_amap_api_maps_CameraUpdate(cameraUpdate!);
        } else {
          await map!.moveCamera(cameraUpdate!);
        }

        pool
          ..add(southWest)
          ..add(northEast)
          ..add(rect)
          ..add(cameraUpdate);
      },
      ios: (pool) async {
        // 由于屏幕坐标的(0, 0)左上角, 所以需要西北角和东南角
        // 西北角
        final northWest = await CLLocationCoordinate2D.create(maxLat, minLng);
        // 东南角
        final southEast = await CLLocationCoordinate2D.create(minLat, maxLng);

        // 西北角屏幕坐标
        final northWestPoint = await MAMapPointForCoordinate(northWest);
        // 东南角屏幕坐标
        final southEastPoint = await MAMapPointForCoordinate(southEast);

        // 矩形原点x
        final x = await northWestPoint!.get_x();
        // 矩形原点y
        final y = await northWestPoint.get_y();
        // 矩形宽度
        final width =
            ((await southEastPoint!.get_x())! - (await northWestPoint.get_x())!)
                .abs();
        // 矩形高度
        final height =
            ((await southEastPoint.get_y())! - (await northWestPoint.get_y())!)
                .abs();

        // 矩形
        final rect = await MAMapRectMake(x!, y!, width, height);

        await iosController?.setVisibleMapRect_edgePadding_animated(
          rect!,
          await UIEdgeInsets.create(
            padding.top,
            padding.left,
            padding.bottom,
            padding.right,
          ),
          animated,
        );

        pool
          ..add(northWest)
          ..add(southEast)
          ..add(northWestPoint)
          ..add(southEastPoint)
          ..add(rect);
      },
    );
  }

  // TODO 添加文字

  /// 自定义地图
  ///
  /// 三个参数对应自定义地图压缩包内的三个文件
  @override
  Future<void> setCustomMapStyle({
    String? styleDataPath,
    String? styleExtraPath,
    String? texturePath,
  }) async {
    Uint8List? styleData;
    if (styleDataPath != null) {
      styleData = await rootBundle
          .load(styleDataPath)
          .then((byteData) => byteData.buffer.asUint8List());
    }
    Uint8List? styleExtra;
    if (styleExtraPath != null) {
      styleExtra = await rootBundle
          .load(styleExtraPath)
          .then((byteData) => byteData.buffer.asUint8List());
    }
    Uint8List? texture;
    if (texturePath != null) {
      texture = await rootBundle
          .load(texturePath)
          .then((byteData) => byteData.buffer.asUint8List());
    }
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        // 构造选项
        final option =
            await com_amap_api_maps_model_CustomMapStyleOptions.create__();
        await option.setEnable(true);
        if (styleData != null) await option.setStyleData(styleData);
        if (styleExtra != null) await option.setStyleExtraData(styleExtra);
        if (texture != null) await option.setStyleTextureData(texture);

        await map!.setCustomMapStyle(option);

        pool.add(option);
      },
      ios: (pool) async {
        // 构造选项
        final option = await MAMapCustomStyleOptions.create__();

        if (styleData != null) {
          final styleDataNSData = await NSData.createWithUint8List(styleData);
          await option.set_styleData(styleDataNSData);
          pool.add(styleDataNSData);
        }
        if (styleExtra != null) {
          final styleExtraNSData = await NSData.createWithUint8List(styleExtra);
          await option.set_styleExtraData(styleExtraNSData);
          pool.add(styleExtraNSData);
        }
        if (texture != null) {
          final textureNSData = await NSData.createWithUint8List(texture);
          await option.set_styleTextureData(textureNSData);
          pool.add(textureNSData);
        }

        await iosController!.setCustomMapStyleOptions(option);
        await iosController!.set_customMapStyleEnabled(true);

        pool.add(option);
      },
    );
  }

  /// 设置海量点点击监听事件
  Future<void> setMultiPointClickedListener(
    OnMultiPointClicked onMultiPointClicked,
  ) async {
    await platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final listener = await com_amap_api_maps_AMap_OnMultiPointClickListener
            .anonymous__();
        await map!.setOnMultiPointClickListener(
          listener
            ..onPointClick = (point) async {
              final id = await point!.getCustomerId();
              final title = await point.getTitle();
              final snippet = await point.getSnippet();
              final object = await point.getObject();
              await onMultiPointClicked(
                id!,
                title!,
                snippet!,
                object as String,
              );
              return true;
            },
        );
      },
      ios: (pool) async {
        final delegate =
            await MAMultiPointOverlayRendererDelegate.anonymous__();
        delegate.multiPointOverlayRenderer_didItemTapped = (_, item) async {
          final id = await item!.get_customID();
          final title = await item.get_title();
          final snippet = await item.get_subtitle();
          final object = await item.getJsonableProperty__(1);
          await onMultiPointClicked(id!, title!, snippet!, object);
        };
        // TODO 不知道委托该设置在哪里
        // await iosController.set_delegate(delegate);
      },
    );
  }

  /// 添加平滑移动marker
  ///
  /// 根据[options]批量创建Marker
  @override
  Future<ISmoothMoveMarker> addSmoothMoveMarker(
    SmoothMoveMarkerOption option,
  ) async {
    final latitudeBatch = option.path.map((e) => e.latitude).toList();
    final longitudeBatch = option.path.map((e) => e.longitude).toList();
    final iconData = await option.iconProvider
        .toImageData(createLocalImageConfiguration(state!.context));
    return platform(
      android: (pool) async {
        // 获取地图
        final map = await androidController!.getMap();

        // 创建平滑移动marker对象
        final marker = await com_amap_api_maps_utils_overlay_SmoothMoveMarker
            .create__com_amap_api_maps_AMap(map!);

        // 创建marker的图标
        final bitmap = await android_graphics_Bitmap.create(iconData);
        final bitmapDescriptor =
            await com_amap_api_maps_model_BitmapDescriptorFactory
                .fromBitmap(bitmap);

        // 设置图标
        await marker.setDescriptor(bitmapDescriptor!);

        // 动画途经点
        final points = await com_amap_api_maps_model_LatLng
            .create_batch__double__double(latitudeBatch, longitudeBatch);

        // 设置途经点
        await marker.setPoints(points);
        // 设置动画时长
        await marker.setTotalDuration(option.duration.inSeconds);
        // 执行动画
        await marker.startSmoothMove();

        pool
          ..add(bitmap)
          ..add(bitmapDescriptor)
          ..addAll(points);
        return SmoothMoveMarker.android(marker);
      },
      ios: (pool) async {
        // await iosController.set_delegate(
        //   _iosMapDelegate..iosController = iosController,
        // );

        // 创建annotation
        final annotation = await MAAnimatedAnnotation.create__();

        // 动画途经点
        final points = await CLLocationCoordinate2D.create_batch(
            latitudeBatch, longitudeBatch);

        // 设置图片
        // 普通图片
        final icon = await UIImage.create(iconData);
        await annotation.setIcon(icon);

        // 设置起始点
        await annotation.set_coordinate(points[0]);

        // 添加动画
        final animation = await annotation
            .addMoveAnimationWithKeyCoordinates_count_withDuration_withName_completeCallback(
          points,
          points.length,
          option.duration.inSeconds.toDouble(),
          'name',
          (finished) {},
        );

        await iosController!.addAnnotation(annotation);

        pool
          ..addAll(points)
          ..add(icon);
        return SmoothMoveMarker.ios(iosController, animation, annotation);
      },
    );
  }

  /// 添加海量点
  @override
  Future<IMultiPointOverlay> addMultiPointOverlay(
    MultiPointOption option,
  ) async {
    assert(option.pointList.isNotEmpty);

    final latitudeBatch =
        option.pointList.map((it) => it.coordinate.latitude).toList();
    final longitudeBatch =
        option.pointList.map((it) => it.coordinate.longitude).toList();
    final idBatch = option.pointList.map((it) => it.id).toList();
    final titleBatch = option.pointList.map((it) => it.title).toList();
    final snippetBatch = option.pointList.map((it) => it.snippet).toList();
    final objectBatch = option.pointList.map((it) => it.object).toList();
    Uint8List? iconData;
    if (option.iconProvider != null) {
      iconData = await option.iconProvider!
          .toImageData(createLocalImageConfiguration(state!.context));
    }

    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final overlayOptions =
            await com_amap_api_maps_model_MultiPointOverlayOptions.create__();

        final latLngBatch = await com_amap_api_maps_model_LatLng
            .create_batch__double__double(latitudeBatch, longitudeBatch);

        // 设置marker图标
        // 普通图片
        if (iconData != null) {
          final bitmap = await android_graphics_Bitmap.create(iconData);
          final icon = await com_amap_api_maps_model_BitmapDescriptorFactory
              .fromBitmap(bitmap);
          await overlayOptions.icon(icon!);

          pool
            ..add(bitmap)
            ..add(icon);
        }

        final multiPointOverlay =
            await map!.addMultiPointOverlay(overlayOptions);

        final multiPointList = await com_amap_api_maps_model_MultiPointItem
            .create_batch__com_amap_api_maps_model_LatLng(latLngBatch);
        await multiPointList.setCustomerId_batch(idBatch.whereNotNull());
        await multiPointList.setTitle_batch(titleBatch.whereNotNull());
        await multiPointList.setSnippet_batch(snippetBatch.whereNotNull());
        await multiPointList.setObject_batch(objectBatch.whereNotNull());

        await multiPointOverlay!.setItems(multiPointList);

        pool.addAll(latLngBatch);
        return MultiPointOverlay.android(multiPointOverlay);
      },
      ios: (pool) async {
        await iosController!.set_delegate(_iosMapDelegate!);

        final overlay = await MAMultiPointOverlay.create__();

        final length = option.pointList.length;
        final pointItemList = await MAMultiPointItem.create_batch__(length);

        final latLngBatch = await CLLocationCoordinate2D.create_batch(
            latitudeBatch, longitudeBatch);

        // 设置marker图标
        // 普通图片
        final bitmap = await UIImage.create(iconData!);
        await overlay.addProperty__(1, bitmap);
        pool.add(bitmap);
        await pointItemList.set_coordinate_batch(latLngBatch);
        await pointItemList.set_customID_batch(idBatch.whereNotNull());
        await pointItemList.set_title_batch(titleBatch.whereNotNull());
        await pointItemList.set_subtitle_batch(snippetBatch.whereNotNull());
        await pointItemList.addJsonableProperty_batch(
            1, objectBatch.whereNotNull());

        await overlay.initWithMultiPointItems(pointItemList);

        await iosController!.addOverlay(overlay);

        pool
          ..addAll(pointItemList)
          ..addAll(latLngBatch);
        return MultiPointOverlay.ios(overlay, iosController);
      },
    );
  }

  /// 设置地图朝向
  ///
  /// [bearing] 朝向角度, 单位为度(°), 范围为[0°,360°]
  @override
  Future<void> setBearing(double bearing, {bool animated = true}) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final update =
            await com_amap_api_maps_CameraUpdateFactory.changeBearing(bearing);
        if (animated) {
          await map!.animateCamera__com_amap_api_maps_CameraUpdate(update!);
        } else {
          await map!.moveCamera(update!);
        }

        pool.add(update);
      },
      ios: (pool) async {
        if (bearing < 0) bearing = 360 + (bearing % 360);

        final currentRotation = await iosController!.get_rotationDegree();
        if ((bearing - currentRotation!).abs() > 180) {
          await iosController!.setRotationDegree_animated_duration(
            360 - bearing,
            animated,
            0.3,
          );
        } else {
          await iosController!.setRotationDegree_animated_duration(
            bearing,
            animated,
            0.3,
          );
        }
      },
    );
  }

  /// 设置地图倾斜度
  @override
  Future<void> setTilt(double tilt, {bool animated = true}) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final update =
            await com_amap_api_maps_CameraUpdateFactory.changeTilt(tilt);
        if (animated) {
          await map!.animateCamera__com_amap_api_maps_CameraUpdate(update!);
        } else {
          await map!.moveCamera(update!);
        }

        pool.add(update);
      },
      ios: (pool) async {
        await iosController!.setCameraDegree_animated_duration(
          tilt,
          animated,
          0.3,
        );
      },
    );
  }

  /// 显示/隐藏3D楼块效果
  @override
  Future<void> showBuildings(bool show) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        await map!.showBuildings(show);
      },
      ios: (pool) async {
        await iosController!.set_showsBuildings(show);
      },
    );
  }

  /// 显示/隐藏地图上的文字标注
  @override
  Future<void> showMapText(bool show) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        await map!.showMapText(show);
      },
      ios: (pool) async {
        await iosController!.set_showsLabels(show);
      },
    );
  }

  /// 一次性设置地图视角
  @override
  Future<void> setCameraPosition({
    required LatLng coordinate,
    double? zoom,
    double? tilt,
    double? bearing,
    bool animated = true,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        final builder = await com_amap_api_maps_model_CameraPosition.builder();
        final latLng =
            await com_amap_api_maps_model_LatLng.create__double__double(
          coordinate.latitude,
          coordinate.longitude,
        );
        await builder!.target(latLng);
        if (zoom != null) {
          await builder.zoom(zoom);
        }
        if (tilt != null) {
          await builder.tilt(tilt);
        }
        if (bearing != null) {
          await builder.bearing(bearing!);
        }

        final update = await com_amap_api_maps_CameraUpdateFactory
            .newCameraPosition((await builder.build())!);
        if (animated) {
          await map!
              .animateCamera__com_amap_api_maps_CameraUpdate__int__com_amap_api_maps_AMap_CancelableCallback(
            update!,
            duration.inMilliseconds,
            await com_amap_api_maps_AMap_CancelableCallback.anonymous__(),
          );
        } else {
          await map!.moveCamera(update!);
        }

        pool.add(update);
      },
      ios: (pool) async {
        final status = await MAMapStatus.create__();
        final latLng = await CLLocationCoordinate2D.create(
            coordinate.latitude, coordinate.longitude);
        await status.set_centerCoordinate(latLng);
        if (zoom != null) {
          await status.set_zoomLevel(zoom);
        }
        if (tilt != null) {
          await status.set_cameraDegree(tilt);
        }
        if (bearing != null) {
          bearing = (bearing!.remainder(360) + 360).remainder(360);
          final currentRotation = await iosController!.get_rotationDegree();
          if ((currentRotation! - bearing!).abs() > 180) {
            double fixed = bearing!;
            if (bearing! > 180) {
              fixed = (bearing! - 360);
            } else {
              fixed = (360 + bearing!);
            }
            // debugPrint(
            //     'currentRotation: $currentRotation, bearing: $bearing, 修正后bearing: $fixed');
            await status.set_rotationDegree(fixed);
          } else {
            await status.set_rotationDegree(bearing!);
            // debugPrint('currentRotation: $currentRotation, bearing: $bearing');
          }
        }
        await iosController!.setMapStatus_animated_duration(
          status,
          animated,
          duration.inMilliseconds / 1000,
        );
      },
    );
  }

  /// 根据起点[from]和终点[to]坐标, 搜索出路径并将驾车路线规划结果[driveRouteResult]添加到地图上, 可以配置交通拥堵情况[trafficOption],
  /// 路线的宽度[lineWidth], 自定纹理[customTexture].
  @override
  Future<void> addDriveRoute({
    required LatLng from,
    required LatLng to,
    List<LatLng>? passbyPointList,
    TrafficOption? trafficOption,
    double lineWidth = 10,
    ImageProvider? customTexture,
  }) async {
    // 搜索路径
    final route = await AmapSearch.instance.searchDriveRoute(
      from: from,
      to: to,
      passedByPoints: passbyPointList ?? [],
    );

    // 添加路径
    for (final path in await route.drivePathList) {
      for (final step in await path.driveStepList) {
        if (trafficOption?.show == true) {
          for (final tmc in await step.tmsList) {
            final status = await tmc.status;
            Color statusColor = Colors.green;
            switch (status) {
              case '缓行':
                statusColor = Colors.yellow;
                break;
              case '拥堵':
                statusColor = Colors.red;
                break;
              case '未知':
                statusColor = Colors.blue;
                break;
              default:
                break;
            }
            await addPolyline(PolylineOption(
              coordinateList: await tmc.polyline,
              strokeColor: statusColor,
              width: lineWidth,
              textureProvider: customTexture,
            ));
          }
        } else {
          await addPolyline(PolylineOption(
            coordinateList: await step.polyline,
            width: lineWidth,
            textureProvider: customTexture,
          ));
        }
      }
    }
  }

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
  @override
  Future<List<IPolygon>> addDistrictOutline(
    String districtName, {
    double width = 5,
    Color strokeColor = Colors.green,
    Color fillColor = Colors.transparent,
    bool onlyMainDistrict = true,
    double sampleRate = 1.0,
  }) async {
    assert(districtName.isNotEmpty);
    assert(sampleRate > 0 && sampleRate <= 1);
    final district = await AmapSearch.instance
        .searchDistrict(districtName, showBoundary: true);

    final districtList = district.districtList;
    if (districtList!.isNotEmpty) {
      if (onlyMainDistrict) {
        final sampler = Random();
        List<LatLng> boundary = district.districtList![0].boundary!
            .reduce((pre, next) => pre.length > next.length ? pre : next)
          ..retainWhere((_) => sampler.nextDouble() <= sampleRate);
        return [
          await addPolygon(PolygonOption(
            coordinateList: boundary,
            width: width,
            strokeColor: strokeColor,
            fillColor: fillColor,
          ))
        ];
      } else {
        List<List<LatLng>> boundaryList = (district.districtList![0].boundary)!;
        return [
          for (final boundary in boundaryList)
            await addPolygon(PolygonOption(
              coordinateList: boundary,
              width: width,
              strokeColor: strokeColor,
              fillColor: fillColor,
            ))
        ];
      }
    } else {
      throw Exception('地区不存在');
    }
  }

  /// 添加回放轨迹
  ///
  /// [coordinateList] 路径经纬度列表
  /// [width] 路径宽度
  /// [strokeColor] 路径颜色
  /// [iconProvider] 移动marker的图标
  /// [duration] 移动时长
  @override
  Future<IPlaybackTrace> addPlaybackTrace(
    List<LatLng> coordinateList, {
    double width = 5,
    Color strokeColor = Colors.green,
    required ImageProvider iconProvider,
    required Duration duration,
  }) async {
    assert(coordinateList.isNotEmpty);
    // 画轨迹线
    final polyline = await addPolyline(PolylineOption(
      coordinateList: coordinateList,
      width: width,
      strokeColor: strokeColor,
    ));
    final marker = await addSmoothMoveMarker(SmoothMoveMarkerOption(
      path: coordinateList,
      duration: duration,
      iconProvider: iconProvider,
    ));

    return PlaybackTrace(marker, polyline);
  }

  /// 设置最大缩放等级
  @override
  Future<void> setMaxZoomLevel(double zoomLevel) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        await map!.setMaxZoomLevel(zoomLevel);
      },
      ios: (pool) async {
        await iosController!.set_maxZoomLevel(zoomLevel);
      },
    );
  }

  /// 设置最小缩放等级
  @override
  Future<void> setMinZoomLevel(double zoomLevel) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();

        await map!.setMinZoomLevel(zoomLevel);
      },
      ios: (pool) async {
        await iosController!.set_minZoomLevel(zoomLevel);
      },
    );
  }

  /// 设置地图锚点
  @override
  Future<void> setMapAnchor(double anchorU, double anchorV) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        await map!.setPointToCenter(anchorU.toInt(), anchorV.toInt());
      },
      ios: (pool) async {
        final anchor = await CGPoint.create(anchorU, anchorV);
        await iosController!.set_screenAnchor(anchor);
      },
    );
  }

  @override
  Future<void> setPadding(EdgeInsets padding) async {
    debugPrint('高德地图没有setPadding对应接口');
  }

  @override
  Future<void> setFps(int fps) async {
    return platform(
      android: (pool) async {
        final map = await androidController!.getMap();
        await map!.setRenderFps(fps);
      },
      ios: (pool) async {
        await iosController!.set_maxRenderFrame(fps);
      },
    );
  }

  @override
  Future<void> dispose() async {
    await _locateSubscription?.cancel();

    await androidController?.onPause();
    await androidController?.onDestroy();

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('didChangeAppLifecycleState: $state');
    // 因为这里的生命周期其实已经是App的生命周期了, 所以除了这里还需要在dispose里释放资源
    switch (state) {
      case AppLifecycleState.resumed:
        androidController?.onResume();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        androidController?.onPause();
        break;
      case AppLifecycleState.detached:
        androidController?.onDestroy();
        break;
    }
  }
}

extension ListX<T> on List<T?> {
  List<T> whereNotNull() => where((e) => e != null).cast<T>().toList();
}
