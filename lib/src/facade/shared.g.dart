import 'package:flutter/services.dart';
import 'package:foundation_fluttify/foundation_fluttify.dart';
import 'package:amap_map_fluttify/src/ios/ios.export.g.dart';
import 'package:amap_map_fluttify/src/android/android.export.g.dart';

const kAmapMapFluttifyMessageCodec = FluttifyMessageCodec(tag: 'amap_map_fluttify'/*, androidCaster: AmapMapFluttifyAndroidAs, iosCaster: AmapMapFluttifyIOSAs*/);
const kAmapMapFluttifyMethodCodec = StandardMethodCodec(kAmapMapFluttifyMessageCodec);
const kAmapMapFluttifyChannel = MethodChannel('me.yohom/amap_map_fluttify', kAmapMapFluttifyMethodCodec);
const kAmapMapFluttifyProjectName = 'amap_map_fluttify';

Future<void> releaseAmapMapFluttifyPool() async {
  final isCurrentPlugin = (Ref it) => it.tag__ == kAmapMapFluttifyProjectName;
  await gGlobalReleasePool.where(isCurrentPlugin).release_batch();
  gGlobalReleasePool.removeWhere(isCurrentPlugin);
}