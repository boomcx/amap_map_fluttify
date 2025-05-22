# [文档](https://github.com/fluttify-project/amap_map_fluttify/wiki) [文档](https://github.com/fluttify-project/amap_map_fluttify/wiki) [文档](https://github.com/fluttify-project/amap_map_fluttify/wiki)

![Logo](https://github.com/fluttify-project/fluttify-core-example/blob/develop/other/Logo-Landscape.png?raw=true)

# 高德地图 地图组件 Flutter插件
[![pub package](https://img.shields.io/pub/v/amap_map_fluttify.svg)](https://pub.Flutter-io.cn/packages/amap_map_fluttify)

## 依赖
```yaml
dependencies:
  flutter:
    sdk: flutter
  amap_map_fluttify: ^x.x.x
```

## 配置
### Android
1. 注意在app/build.gradle的android块中配置签名信息, 并在buildTypes块中指定签名信息, 否则将无法匹配到你在高德后台配置的appkey, 例如:
```groovy
android {
    signingConfigs {
        release {
            keyAlias 'amap_map_test'
            keyPassword 'amap_map_test'
            storeFile file('../amap_map_test.jks')
            storePassword 'amap_map_test'
        }
    }

    buildTypes {
        debug {
            signingConfig signingConfigs.release
        }
        profile {
            signingConfig signingConfigs.release
        }
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### iOS
1. 定位需要声明权限, 在Info.plist中添加:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要定位权限</string>
```
2. 调用高德地图需要添加白名单:
```dart
<key>LSApplicationQueriesSchemes</key>
<array>
	<string>iosamap</string>
	<string>amapuri</string>
</array>
```

## 导入
```dart
import 'package:amap_map_fluttify/amap_map_fluttify.dart';
```

## 使用
参考[wiki](https://github.com/fluttify-project/amap_map_fluttify/wiki).

## LICENSE
> Copyright (C) 2022 yohom
> 
> This program is free software: you can redistribute it and/or modify
> it under the terms of the GNU General Public License as published by
> the Free Software Foundation, either version 3 of the License, or
> (at your option) any later version.
> 
> This program is distributed in the hope that it will be useful,
> but WITHOUT ANY WARRANTY; without even the implied warranty of
> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
> GNU General Public License for more details.
> 
> You should have received a copy of the GNU General Public License
> along with this program.  If not, see <https://www.gnu.org/licenses/>.