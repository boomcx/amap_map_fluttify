import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:amap_map_fluttify_example/utils/next_latlng.dart';
import 'package:decorated_flutter/decorated_flutter.dart';
import 'package:flutter/material.dart';

class DrawPolygonScreen extends StatefulWidget {
  DrawPolygonScreen();

  factory DrawPolygonScreen.forDesignTime() => DrawPolygonScreen();

  @override
  _DrawPolygonScreenState createState() => _DrawPolygonScreenState();
}

class _DrawPolygonScreenState extends State<DrawPolygonScreen> with NextLatLng {
  AmapController _controller;
  List<IPolygon> _polygonList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('绘制多边形')),
      body: DecoratedColumn(
        children: <Widget>[
          Flexible(
            flex: 1,
            child: AmapView(
              zoomLevel: 10,
              onMapCreated: (controller) async {
                _controller = controller;
              },
            ),
          ),
          Flexible(
            child: DecoratedColumn(
              divider: Divider(height: 1),
              children: <Widget>[
                ListTile(
                  title: Center(child: Text('添加多边形')),
                  onTap: () async {
                    final polygon = await _controller?.addPolygon(PolygonOption(
                      coordinateList: [
                        LatLng(39.999391, 116.135972),
                        LatLng(39.898323, 116.057694),
                        LatLng(39.900430, 116.265061),
                        LatLng(39.955192, 116.140092),
                      ],
                      width: 10,
                      strokeColor: Colors.green,
                    ));
                    _polygonList.add(polygon);
                  },
                ),
                ListTile(
                  title: Center(child: Text('添加虚线折线')),
                  onTap: () async {
                    final polyline =
                        await _controller?.addPolyline(PolylineOption(
                      coordinateList: [
                        LatLng(39.999391, 116.135972),
                        LatLng(39.898323, 116.057694),
                        LatLng(39.900430, 116.265061),
                        LatLng(39.955192, 116.140092),
                        LatLng(39.999391, 116.135972),
                      ],
                      width: 10,
                      dashType: DashType.Square,
                    ));
                  },
                ),
                ListTile(
                  title: Center(child: Text('添加虚线填充多边形')),
                  onTap: () async {
                    await _controller?.addPolyline(PolylineOption(
                      coordinateList: [
                        LatLng(39.999391, 116.135972),
                        LatLng(39.898323, 116.057694),
                        LatLng(39.900430, 116.265061),
                        LatLng(39.955192, 116.140092),
                        LatLng(39.999391, 116.135972),
                      ],
                      width: 10,
                      strokeColor: Colors.blue,
                      dashType: DashType.Square,
                    ));
                    final polygon = await _controller?.addPolygon(PolygonOption(
                      coordinateList: [
                        LatLng(39.999391, 116.135972),
                        LatLng(39.898323, 116.057694),
                        LatLng(39.900430, 116.265061),
                        LatLng(39.955192, 116.140092),
                      ],
                      fillColor: Colors.blue.withOpacity(0.3),
                      strokeColor: Colors.transparent,
                    ));
                    _polygonList.add(polygon);
                  },
                ),
                ListTile(
                  title: Center(child: Text('删除多边形')),
                  onTap: () async {
                    if (_polygonList.isNotEmpty) {
                      await _polygonList.first.remove();
                      _polygonList.removeAt(0);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
