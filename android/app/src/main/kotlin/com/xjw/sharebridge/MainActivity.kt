package com.xjw.sharebridge

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.res.Resources
import android.os.Build
import android.app.WallpaperManager
import android.util.Log
import android.content.Context
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.xjw.sharebridge/theme"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSystemColor") {
                val colorHex = getSystemAccentColor()
                result.success(colorHex)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getSystemAccentColor(): String {
        return try {
            // 尝试获取系统主题色
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                try {
                    // 尝试先使用动态颜色，Android 12+ (API 31+)
                    val dynamicColors = listOf(
                        android.R.color.system_accent1_500,
                        android.R.color.system_accent2_500,
                        android.R.color.system_accent3_500
                    )
                    
                    // 遍历尝试获取可用的动态颜色
                    for (colorResId in dynamicColors) {
                        try {
                            val dynamicColor = resources.getColor(colorResId, theme)
                            Log.d("MaterialYou", "System accent color detected: ${colorToHex(dynamicColor)}")
                            return colorToHex(dynamicColor)
                        } catch (e: Exception) {
                            continue // 尝试下一个颜色
                        }
                    }
                    
                    // 如果上面的方法都失败，尝试使用colorPrimary
                    Log.e("MaterialYou", "Failed to get system_accent colors, trying alternatives")
                } catch (e: Exception) {
                    Log.e("MaterialYou", "Failed to get system accents: ${e.message}")
                }
                
                // 尝试其他资源ID
                try {
                    val accentId = resources.getIdentifier("accent_device_default", "color", "android")
                    if (accentId != 0) {
                        val accentColor = resources.getColor(accentId, theme)
                        Log.d("MaterialYou", "Using accent_device_default: ${colorToHex(accentColor)}")
                        return colorToHex(accentColor)
                    }
                } catch (e2: Exception) {
                    Log.e("MaterialYou", "Failed to get accent_device_default: ${e2.message}")
                }
                
                // 最后尝试应用主题的colorPrimary
                val typedValue = android.util.TypedValue()
                theme.resolveAttribute(android.R.attr.colorPrimary, typedValue, true)
                val colorPrimary = typedValue.data
                Log.d("MaterialYou", "Using theme colorPrimary: ${colorToHex(colorPrimary)}")
                return colorToHex(colorPrimary)
            } else {
                // 尝试从壁纸获取主色调 (Android 8.1+)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                    try {
                        val wallpaperManager = WallpaperManager.getInstance(this)
                        val color = wallpaperManager.getWallpaperColors(WallpaperManager.FLAG_SYSTEM)?.primaryColor?.toArgb()
                        if (color != null) {
                            Log.d("MaterialYou", "Using wallpaper color: ${colorToHex(color)}")
                            return colorToHex(color)
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error getting wallpaper color: ${e.message}")
                    }
                }
                
                // 尝试获取主题的colorAccent
                try {
                    val typedValue = android.util.TypedValue()
                    theme.resolveAttribute(android.R.attr.colorAccent, typedValue, true)
                    val accentColor = typedValue.data
                    Log.d("MaterialYou", "Using theme colorAccent: ${colorToHex(accentColor)}")
                    return colorToHex(accentColor)
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error getting colorAccent: ${e.message}")
                }
                
                // 如果所有尝试都失败，使用默认色
                Log.d("MaterialYou", "Using default color: #2196F3")
                "#2196F3" // 默认Material蓝色
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error retrieving system theme color: ${e.message}")
            "#2196F3" // 默认Material蓝色
        }
    }
    
    private fun colorToHex(color: Int): String {
        return String.format("#%06X", 0xFFFFFF and color)
    }
}
