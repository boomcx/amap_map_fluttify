//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<amap_core_fluttify/AmapCoreFluttifyPlugin.h>)
#import <amap_core_fluttify/AmapCoreFluttifyPlugin.h>
#else
@import amap_core_fluttify;
#endif

#if __has_include(<amap_location_fluttify/AmapLocationFluttifyPlugin.h>)
#import <amap_location_fluttify/AmapLocationFluttifyPlugin.h>
#else
@import amap_location_fluttify;
#endif

#if __has_include(<amap_map_fluttify/AmapMapFluttifyPlugin.h>)
#import <amap_map_fluttify/AmapMapFluttifyPlugin.h>
#else
@import amap_map_fluttify;
#endif

#if __has_include(<amap_search_fluttify/AmapSearchFluttifyPlugin.h>)
#import <amap_search_fluttify/AmapSearchFluttifyPlugin.h>
#else
@import amap_search_fluttify;
#endif

#if __has_include(<core_location_fluttify/CoreLocationFluttifyPlugin.h>)
#import <core_location_fluttify/CoreLocationFluttifyPlugin.h>
#else
@import core_location_fluttify;
#endif

#if __has_include(<foundation_fluttify/FoundationFluttifyPlugin.h>)
#import <foundation_fluttify/FoundationFluttifyPlugin.h>
#else
@import foundation_fluttify;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<url_launcher_ios/URLLauncherPlugin.h>)
#import <url_launcher_ios/URLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [AmapCoreFluttifyPlugin registerWithRegistrar:[registry registrarForPlugin:@"AmapCoreFluttifyPlugin"]];
  [AmapLocationFluttifyPlugin registerWithRegistrar:[registry registrarForPlugin:@"AmapLocationFluttifyPlugin"]];
  [AmapMapFluttifyPlugin registerWithRegistrar:[registry registrarForPlugin:@"AmapMapFluttifyPlugin"]];
  [AmapSearchFluttifyPlugin registerWithRegistrar:[registry registrarForPlugin:@"AmapSearchFluttifyPlugin"]];
  [CoreLocationFluttifyPlugin registerWithRegistrar:[registry registrarForPlugin:@"CoreLocationFluttifyPlugin"]];
  [FoundationFluttifyPlugin registerWithRegistrar:[registry registrarForPlugin:@"FoundationFluttifyPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [URLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"URLLauncherPlugin"]];
}

@end
