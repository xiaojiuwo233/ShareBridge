package com.xjw.sharebridge

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.res.Resources
import android.os.Build
import android.app.WallpaperManager
import android.util.Log
import android.content.Context
import android.content.res.Configuration
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.xjw.sharebridge/theme"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSystemColor") {
                // 获取是否为深色模式
                val isDarkMode = call.argument<Boolean>("isDarkMode") ?: false
                val colorHex = getSystemAccentColor(isDarkMode)
                result.success(colorHex)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getSystemAccentColor(isDarkMode: Boolean): String {
        return try {
            // 设置当前上下文为深色或浅色模式
            val currentNightMode = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
            val isSystemInDarkMode = currentNightMode == Configuration.UI_MODE_NIGHT_YES
            
            // 如果要求的深色模式与系统当前模式不一致，需要创建一个临时的上下文
            val contextToUse = if (isDarkMode != isSystemInDarkMode) {
                val newConfig = Configuration(resources.configuration)
                newConfig.uiMode = newConfig.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv() or
                        if (isDarkMode) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO
                createConfigurationContext(newConfig)
            } else {
                this
            }
            
            Log.d("MaterialYou", "Getting color for ${if (isDarkMode) "dark" else "light"} mode")
            
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
                            val dynamicColor = contextToUse.resources.getColor(colorResId, contextToUse.theme)
                            Log.d("MaterialYou", "System accent color detected for ${if (isDarkMode) "dark" else "light"} mode: ${colorToHex(dynamicColor)}")
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
                    val accentId = contextToUse.resources.getIdentifier("accent_device_default", "color", "android")
                    if (accentId != 0) {
                        val accentColor = contextToUse.resources.getColor(accentId, contextToUse.theme)
                        Log.d("MaterialYou", "Using accent_device_default for ${if (isDarkMode) "dark" else "light"} mode: ${colorToHex(accentColor)}")
                        return colorToHex(accentColor)
                    }
                } catch (e2: Exception) {
                    Log.e("MaterialYou", "Failed to get accent_device_default: ${e2.message}")
                }
                
                // 最后尝试应用主题的colorPrimary
                val typedValue = android.util.TypedValue()
                contextToUse.theme.resolveAttribute(android.R.attr.colorPrimary, typedValue, true)
                val colorPrimary = typedValue.data
                Log.d("MaterialYou", "Using theme colorPrimary for ${if (isDarkMode) "dark" else "light"} mode: ${colorToHex(colorPrimary)}")
                return colorToHex(colorPrimary)
            } else {
                // 尝试从壁纸获取主色调 (Android 10+)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    try {
                        val wallpaperManager = WallpaperManager.getInstance(this)
                        val color = wallpaperManager.getWallpaperColors(WallpaperManager.FLAG_SYSTEM)?.primaryColor?.toArgb()
                        if (color != null) {
                            Log.d("MaterialYou", "Using wallpaper color for ${if (isDarkMode) "dark" else "light"} mode: ${colorToHex(color)}")
                            return colorToHex(color)
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error getting wallpaper color: ${e.message}")
                    }
                }
                
                // 尝试获取主题的colorAccent或colorPrimary，根据是否暗模式选择
                try {
                    val typedValue = android.util.TypedValue()
                    val attrToUse = if (isDarkMode) {
                        // 在深色模式下优先尝试获取深色主题特定的颜色
                        if (contextToUse.theme.resolveAttribute(android.R.attr.colorPrimaryDark, typedValue, true)) {
                            typedValue.data
                        } else if (contextToUse.theme.resolveAttribute(android.R.attr.colorAccent, typedValue, true)) {
                            typedValue.data
                        } else {
                            contextToUse.theme.resolveAttribute(android.R.attr.colorPrimary, typedValue, true)
                            typedValue.data
                        }
                    } else {
                        // 浅色模式下获取标准的强调色
                        contextToUse.theme.resolveAttribute(android.R.attr.colorAccent, typedValue, true)
                        typedValue.data
                    }
                    Log.d("MaterialYou", "Using theme color for ${if (isDarkMode) "dark" else "light"} mode: ${colorToHex(attrToUse)}")
                    return colorToHex(attrToUse)
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error getting theme colors: ${e.message}")
                }
                
                // 如果所有尝试都失败，使用默认色
                Log.d("MaterialYou", "Using default color for ${if (isDarkMode) "dark" else "light"} mode: #2196F3")
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
