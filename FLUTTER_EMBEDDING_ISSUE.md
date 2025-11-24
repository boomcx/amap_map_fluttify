# Flutter Embedding 依赖问题

## 问题描述

当使用 Git 依赖方式引用本地化的 fluttify 插件时，Android 构建会失败，错误信息：

```
Could not find io.flutter:flutter_embedding_debug:1.0.0-a18df97ca57a249df5d8d68cd0820600223ce262.
Required by: project :foundation_fluttify
```

## 问题分析

1. **根本原因**: Git 依赖的 Flutter 插件在构建时，Gradle 无法正确解析 Flutter SDK 提供的本地 Maven 依赖
2. **影响范围**: 所有通过 Git path 引用的 fluttify 插件（foundation_fluttify、core_location_fluttify 等）
3. **Flutter 版本**: Flutter 3.24.5, Dart 3.5.4

## 已尝试的解决方案

1. ✗ 在插件 build.gradle 中添加 Flutter Maven 仓库配置
2. ✗ 创建 settings.gradle 配置 Flutter SDK 路径
3. ✗ 显式添加 flutter_embedding_release 依赖
4. ✗ 应用 dev.flutter.flutter-plugin 插件

## 建议的解决方案

### 方案 1: 使用本地路径依赖（推荐用于开发）

在 `pubspec.yaml` 中使用本地路径而不是 Git 依赖：

```yaml
dependencies:
  foundation_fluttify:
    path: dependencies/foundation_fluttify
  # 其他依赖同理...
```

**优点**: 
- 构建正常工作
- 开发调试方便

**缺点**: 
- 无法发布到 pub.dev
- 其他项目无法直接引用

### 方案 2: 发布到私有 pub 服务器

如果团队有私有 pub 服务器，可以将升级后的插件发布到私服：

```yaml
dependencies:
  foundation_fluttify:
    hosted:
      name: foundation_fluttify
      url: https://your-private-pub-server.com
    version: ^0.13.0+1
```

### 方案 3: 使用 Melos 管理 Monorepo

使用 [Melos](https://github.com/invertase/melos) 工具来管理多包项目：

```bash
# 安装 Melos
dart pub global activate melos

# 初始化配置
melos bootstrap
```

### 方案 4: 等待上游修复

这可能是 Flutter Gradle 插件对 Git 依赖支持的一个 bug。可以考虑：
- 在 Flutter GitHub repo 提 issue
- 关注相关问题的更新

## 当前项目状态

✅ **已完成**:
- 所有插件升级到 Flutter 3.24.5
- SDK 约束更新到 Dart 3.5.0+
- Android/iOS 配置现代化
- 依赖引用改为 Git 方式
- 所有更改已提交到 Git

⚠️ **存在问题**:
- Android 构建失败（flutter_embedding_debug 依赖问题）
- iOS 构建未测试

## 临时解决方案（用于继续开发）

如果需要立即使用，建议：

1. **回退到本地路径依赖**:
   ```bash
   # 修改 pubspec.yaml 使用 path 而不是 git
   # 然后运行
   flutter pub get
   flutter build apk --debug
   ```

2. **或者使用主项目**:
   直接在主项目中开发，不依赖 dependencies 目录的插件

## 技术参考

- [Flutter 插件开发文档](https://docs.flutter.dev/packages-and-plugins/developing-packages)
- [Gradle 依赖管理](https://docs.gradle.org/current/userguide/dependency_management.html)
- [Flutter Git 依赖](https://dart.dev/tools/pub/dependencies#git-packages)
