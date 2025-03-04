# ShareBridge

一个强大的Android分享中转工具，可以接收来自任何应用的分享内容，处理后再通过系统分享菜单进行二次分享。

# 初期开发中，功能暂不可用

## 特性

- **分享接收与处理**：接收来自任何应用的分享内容（文本、图片、文件）
- **预览与编辑**：在弹窗或全屏界面中预览分享内容，支持编辑功能
- **二次分享**：处理后通过系统分享菜单进行再次分享
- **历史管理**：时间线形式展示分享历史及详细信息
- **Material You设计**：采用Material Design 3主题设计

## 系统要求

- Android 9.0（API级别28）或更高版本
- Flutter 3.x
- Dart SDK 3.x

## 安装方式

1. 从Github Releases下载
2. 或从源代码构建：
   ```bash
   git clone https://github.com/xiaojiuwo233/sharebridge.git
   cd sharebridge
   flutter pub get
   flutter build apk --release
   ```

## 使用方法

1. 在任意应用中，点击分享按钮
2. 从分享菜单中选择ShareBridge
3. 根据需要预览和编辑内容
4. 点击"分享"通过系统分享菜单进行二次分享

## 参与贡献

欢迎提交Pull Request参与项目贡献！

## 特别感谢

- [Flutter](https://flutter.dev)
- [Material You](https://m3.material.io)
- [Claude](https://www.claude.ai)

## 许可证

本项目采用GNU Affero通用公共许可证v3.0（AGPLv3）- 详见[LICENSE](./LICENSE)文件 