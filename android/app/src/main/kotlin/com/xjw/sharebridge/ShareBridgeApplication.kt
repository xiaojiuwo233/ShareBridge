package com.xjw.sharebridge

import androidx.multidex.MultiDexApplication
import io.flutter.app.FlutterApplication

// 自定义Application类，支持MultiDex
class ShareBridgeApplication : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        // 可以在这里添加应用初始化代码
    }
} 