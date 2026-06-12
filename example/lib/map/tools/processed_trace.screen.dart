import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:decorated_flutter/decorated_flutter.dart';
import 'package:flutter/material.dart';

class ProcessedTraceScreen extends StatefulWidget {
  @override
  ProcessedTraceStateScreen createState() => ProcessedTraceStateScreen();
}

class ProcessedTraceStateScreen extends State<ProcessedTraceScreen> {
  List<LatLng> _result = [];

  AmapController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('轨迹纠偏'),
      ),
      body: DecoratedColumn(
        padding: EdgeInsets.all(kSpace16),
        children: <Widget>[
          Flexible(
            child: AmapView(
              onMapCreated: (controller) async {
                _controller = controller;
                await controller.setMapClickedListener((latLng) async {
                  _result.add(latLng);
                  await controller.addMarker(MarkerOption(coordinate: latLng));
                });
              },
            ),
          ),
          RaisedButton(
            onPressed: () async {
              await AmapService.instance.queryProcessedTrace(
                1,
                [
                  for (final item in _result)
                    TraceLocation(
                      latitude: item.latitude,
                      longitude: item.longitude,
                      speed: 32,
                      bearing: 0,
                      time: 60000,
                    ),
                ],
                onTraceFinished: (List<LatLng> traceList, int distance) async {
                  await _controller
                      .addPolyline(PolylineOption(coordinateList: traceList));
                },
              );
            },
            child: Text('开始纠偏'),
          ),
        ],
      ),
    );
  }
}
