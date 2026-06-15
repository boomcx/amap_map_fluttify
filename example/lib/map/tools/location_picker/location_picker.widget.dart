import 'dart:async';

import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_easyrefresh/material_footer.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'models.dart';

const _iconSize = 50.0;
const _package = 'amap_all_fluttify';
const _indicator = 'images/test_icon.png';
double _fabHeight = 16.0;

typedef RequestPermission = Future<bool> Function();
typedef PoiItemBuilder = Widget Function(Poi poi, bool selected);

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.requestPermission,
    required this.poiItemBuilder,
    this.zoomLevel = 16.0,
    this.zoomGesturesEnabled = false,
    this.showZoomControl = false,
    this.centerIndicator,
    this.enableLoadMore = true,
    this.onItemSelected,
  }) : assert(zoomLevel >= 3 && zoomLevel <= 19);

  final RequestPermission requestPermission;

  final PoiItemBuilder poiItemBuilder;

  final double zoomLevel;

  final bool zoomGesturesEnabled;

  final bool showZoomControl;

  final Widget? centerIndicator;

  final bool enableLoadMore;

  final ValueChanged<PoiInfo>? onItemSelected;

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker>
    with SingleTickerProviderStateMixin, _BLoCMixin, _AnimationMixin {
  // 地图控制器
  late AmapController _controller;
  final PanelController _panelController = PanelController();

  bool _moveByUser = true;

  List<PoiInfo> _poiInfoList = [];

  LatLng? _currentCenterCoordinate;

  // 页数
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final minPanelHeight = MediaQuery.of(context).size.height * 0.4;
    final maxPanelHeight = MediaQuery.of(context).size.height * 0.7;
    return SlidingUpPanel(
      controller: _panelController,
      parallaxEnabled: true,
      parallaxOffset: 0.5,
      minHeight: minPanelHeight,
      maxHeight: maxPanelHeight,
      borderRadius: BorderRadius.circular(8),
      onPanelSlide: (double pos) => setState(() {
        _fabHeight = pos * (maxPanelHeight - minPanelHeight) * .5 + 16;
      }),
      body: Column(
        children: <Widget>[
          Flexible(
            child: Stack(
              children: <Widget>[
                AmapView(
                  zoomLevel: widget.zoomLevel,
                  zoomGesturesEnabled: widget.zoomGesturesEnabled,
                  showZoomControl: widget.showZoomControl,
                  onMapMoveEnd: (move) async {
                    if (_moveByUser) {
                      _jumpController.forward().then(
                        (it) => _jumpController.reverse(),
                      );
                      _search(move.coordinate!);
                    }
                    _moveByUser = true;
                    _currentCenterCoordinate = move.coordinate;
                  },
                  onMapCreated: (controller) async {
                    _controller = controller;
                    if (await widget.requestPermission()) {
                      await _showMyLocation();
                      _search((await _controller.getLocation())!);
                    } else {
                      debugPrint('权限请求被拒绝!');
                    }
                  },
                ),
                // 中心指示器
                Center(
                  child: AnimatedBuilder(
                    animation: _tween,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          _tween.value.dx,
                          _tween.value.dy - _iconSize / 2,
                        ),
                        child: child,
                      );
                    },
                    child:
                        widget.centerIndicator ??
                        Image.asset(
                          _indicator,
                          height: _iconSize,
                          package: _package,
                        ),
                  ),
                ),
                // 定位按钮
                Positioned(
                  right: 16.0,
                  bottom: _fabHeight,
                  child: FloatingActionButton(
                    child: StreamBuilder<bool>(
                      stream: _onMyLocation.stream,
                      initialData: true,
                      builder: (context, snapshot) {
                        return Icon(
                          Icons.gps_fixed,
                          color: snapshot.data ?? false
                              ? Theme.of(context).primaryColor
                              : Colors.black54,
                        );
                      },
                    ),
                    onPressed: _showMyLocation,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // 用来抵消panel的最小高度
          SizedBox(height: minPanelHeight),
        ],
      ),
      panelBuilder: (scrollController) {
        return StreamBuilder<List<PoiInfo>>(
          stream: _poiStream.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data!;
              return EasyRefresh(
                footer: MaterialFooter(),
                onLoad: widget.enableLoadMore ? _handleLoadMore : null,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  controller: scrollController,
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final poi = data[index].poi;
                    final selected = data[index].selected;
                    return GestureDetector(
                      onTap: () {
                        for (int i = 0; i < data.length; i++) {
                          data[i].selected = i == index;
                        }
                        _onMyLocation.add(index == 0);
                        _poiStream.add(data);
                        _setCenterCoordinate(poi.latLng!);
                        widget.onItemSelected?.call(data[index]);
                      },
                      child: widget.poiItemBuilder(poi, selected),
                    );
                  },
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        );
      },
    );
  }

  Future<void> _search(LatLng location) async {
    final poiList = await AmapSearch.instance.searchAround(location);
    _poiInfoList = poiList.map((poi) => PoiInfo(poi)).toList();
    // 默认勾选第一项
    if (_poiInfoList.isNotEmpty) _poiInfoList[0].selected = true;
    _poiStream.add(_poiInfoList);

    // 重置页数
    _page = 1;
  }

  Future<void> _showMyLocation() async {
    _onMyLocation.add(true);
    await _controller?.showMyLocation(
      MyLocationOption(
        strokeColor: Colors.transparent,
        fillColor: Colors.transparent,
      ),
    );
  }

  Future<void> _setCenterCoordinate(LatLng coordinate) async {
    await _controller.setCenterCoordinate(coordinate);
    _moveByUser = false;
  }

  Future<void> _handleLoadMore() async {
    final poiList = await AmapSearch.instance.searchAround(
      _currentCenterCoordinate!,
      page: ++_page,
    );
    _poiInfoList.addAll(poiList.map((poi) => PoiInfo(poi)).toList());
    _poiStream.add(_poiInfoList);
  }
}

mixin _BLoCMixin on State<LocationPicker> {
  // poi流
  final _poiStream = StreamController<List<PoiInfo>>();

  // 是否在我的位置
  final _onMyLocation = StreamController<bool>();

  @override
  void dispose() {
    _poiStream.close();
    _onMyLocation.close();
    super.dispose();
  }
}

mixin _AnimationMixin on SingleTickerProviderStateMixin<LocationPicker> {
  // 动画相关
  late AnimationController _jumpController;
  late Animation<Offset> _tween;

  @override
  void initState() {
    super.initState();
    _jumpController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _tween = Tween(begin: Offset(0, 0), end: Offset(0, -15)).animate(
      CurvedAnimation(parent: _jumpController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _jumpController?.dispose();
    super.dispose();
  }
}
