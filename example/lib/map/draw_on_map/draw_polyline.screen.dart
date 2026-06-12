import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:amap_map_fluttify_example/utils/next_latlng.dart';
import 'package:decorated_flutter/decorated_flutter.dart';
import 'package:demo_widgets/demo_widgets.dart';
import 'package:flutter/material.dart';

final _networkIcon = NetworkImage(
    'https://w3.hoopchina.com.cn/30/a7/6a/30a76aea75aef69e4ea0e7d3dee552c7001.jpg');
final _assetsIcon1 = AssetImage('images/test_icon.png');
final _assetsIcon2 = AssetImage('images/arrow.png');

class DrawPolylineScreen extends StatefulWidget {
  DrawPolylineScreen();

  factory DrawPolylineScreen.forDesignTime() => DrawPolylineScreen();

  @override
  _DrawPolylineScreenState createState() => _DrawPolylineScreenState();
}

class _DrawPolylineScreenState extends State<DrawPolylineScreen>
    with NextLatLng {
  AmapController _controller;
  IPolyline _currentPolyline;
  IPlaybackTrace _playbackTrace;
  List<LatLng> _pointList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('绘制线')),
      body: DecoratedColumn(
        children: <Widget>[
          Flexible(
            flex: 1,
            child: Stack(
              children: <Widget>[
                AmapView(
                  tilt: 90,
                  zoomLevel: 7,
                  onMapCreated: (controller) async {
                    _controller = controller;
                  },
                ),
                Container(
                  height: 100,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          Flexible(
            child: DecoratedColumn(
              scrollable: true,
              divider: Divider(height: 1),
              children: <Widget>[
                ListTile(
                  title: Center(child: Text('添加线')),
                  onTap: () async {
                    _pointList = getNextBatchLatLng(3);

                    await _controller.addPolyline(PolylineOption(
                      coordinateList: [
                        LatLng(39.999391, 116.135972),
                        LatLng(39.898323, 116.057694),
                        LatLng(39.900430, 116.265061),
                        LatLng(39.955192, 116.140092),
                      ],
                      strokeColor: Colors.red,
                      width: 10,
                    ));
                  },
                ),
                ListTile(
                  title: Center(child: Text('平滑处理')),
                  onTap: () async {
                    if (_currentPolyline == null) {
                      toast('请先添加对比折线');
                      return;
                    }
                    final smooth =
                        await AmapService.instance.pathSmooth(_pointList);
                    await _controller?.addPolyline(PolylineOption(
                      coordinateList: smooth,
                      width: 10,
                      strokeColor: Colors.green,
                    ));
                  },
                ),
                ListTile(
                  title: Center(child: Text('将地图缩放至可以显示所有Marker')),
                  onTap: () async {
                    await _controller?.zoomToSpan(
                      _pointList,
                      padding: EdgeInsets.only(top: 100),
                    );
                  },
                ),
                ListTile(
                  title: Center(child: Text('添加线(自定义纹理)')),
                  onTap: () async {
                    await _currentPolyline?.remove();
                    _currentPolyline =
                        await _controller?.addPolyline(PolylineOption(
                      coordinateList: [
                        getNextLatLng(),
                        getNextLatLng(),
                        getNextLatLng(),
                        getNextLatLng(),
                      ],
                      width: 10,
                      textureProvider: _assetsIcon2,
                    ));
                  },
                ),
                ListTile(
                  title: Center(child: Text('删除折线')),
                  onTap: () => _currentPolyline?.remove(),
                ),
                ListTile(
                  title: Center(child: Text('绘制北京行政区域边界')),
                  onTap: () => _controller.addDistrictOutline('北京'),
                ),
                ListTile(
                  title: Center(child: Text('添加回放轨迹')),
                  onTap: () async {
                    final result = await AmapSearch.instance.searchDriveRoute(
                      from: LatLng(39.958245, 116.330929),
                      to: LatLng(39.915599, 116.42912),
                    );
                    final pathList = await result.drivePathList;
                    final stepList = [
                      for (final path in pathList) ...await path.driveStepList
                    ];
                    final coordinateList = [
                      for (final step in stepList) ...await step.polyline
                    ];
                    _playbackTrace = await _controller.addPlaybackTrace(
                      coordinateList,
                      iconProvider: _assetsIcon1,
                      duration: Duration(seconds: 10),
                    );
                  },
                ),
                ListTile(
                  title: Center(child: Text('删除回放轨迹')),
                  onTap: () async {
                    _playbackTrace?.remove();
                  },
                ),
                ListTile(
                  title: Center(child: Text('给折线添加点')),
                  onTap: () async {
                    _pointList = [..._pointList, getNextLatLng()];
                    await _currentPolyline?.setCoordinateList(_pointList);
                  },
                ),
                DiscreteSetting(
                  head: '选择始末端样式',
                  options: [
                    '普通头',
                    '扩展头',
                    '箭头',
                    '圆形头',
                  ],
                  onSelected: (value) async {
                    LineCapType type;
                    switch (value) {
                      case '普通头':
                        type = LineCapType.Butt;
                        break;
                      case '扩展头':
                        type = LineCapType.Square;
                        break;
                      case '箭头':
                        type = LineCapType.Arrow;
                        break;
                      case '圆形头':
                        type = LineCapType.Round;
                        break;
                    }
                    await _currentPolyline?.remove();
                    _currentPolyline =
                        await _controller?.addPolyline(PolylineOption(
                      coordinateList: [
                        getNextLatLng(),
                        getNextLatLng(),
                        getNextLatLng(),
                        getNextLatLng(),
                      ],
                      width: 10,
                      strokeColor: Colors.green,
                      lineCapType: type,
                    ));
                  },
                ),
                DiscreteSetting(
                  head: '选择连接点样式',
                  options: [
                    '斜面连接点',
                    '斜接连接点',
                    '圆角连接点',
                  ],
                  onSelected: (value) async {
                    LineJoinType type;
                    switch (value) {
                      case '斜面连接点':
                        type = LineJoinType.Bevel;
                        break;
                      case '斜接连接点':
                        type = LineJoinType.Miter;
                        break;
                      case '圆角连接点':
                        type = LineJoinType.Round;
                        break;
                    }
                    await _currentPolyline?.remove();
                    _currentPolyline =
                        await _controller?.addPolyline(PolylineOption(
                      coordinateList: [
                        LatLng(39.999391, 116.135972),
                        LatLng(39.898323, 116.057694),
                        LatLng(39.900430, 116.265061),
                        LatLng(39.955192, 116.140092),
                      ],
                      width: 10,
                      strokeColor: Colors.green,
                      lineJoinType: type,
                    ));
                  },
                ),
                DiscreteSetting(
                  head: '选择始折线样式',
                  options: [
                    '普通折线',
                    '方块虚线',
                    '圆形虚线',
                  ],
                  onSelected: (value) async {
                    DashType type;
                    switch (value) {
                      case '普通折线':
                        type = null;
                        break;
                      case '方块虚线':
                        type = DashType.Square;
                        break;
                      case '圆形虚线':
                        type = DashType.Circle;
                        break;
                    }
                    await _currentPolyline?.remove();
                    _currentPolyline =
                        await _controller?.addPolyline(PolylineOption(
                      coordinateList: [
                        getNextLatLng(),
                        getNextLatLng(),
                        getNextLatLng(),
                        getNextLatLng(),
                      ],
                      width: 10,
                      strokeColor: Colors.green,
                      dashType: type,
                    ));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
