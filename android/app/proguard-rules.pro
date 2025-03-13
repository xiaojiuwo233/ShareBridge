# Flutter相关规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase相关规则
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# 保持Parcelable类不被混淆
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# 保持Serializable类不被混淆
-keepnames class * implements java.io.Serializable

# 保持R文件的静态字段不被混淆
-keepclassmembers class **.R$* {
    public static <fields>;
}

# 第三方库规则
# 分享插件
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class com.kasem.receive_sharing_intent.** { *; }

# 图片处理
-keep class vn.hunghd.flutter.plugins.imagecropper.** { *; }
-keep class com.fluttercandies.image_editor.** { *; }

# 设备信息
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# SQLite
-keep class com.tekartik.sqflite.** { *; }

# 本地存储
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# 解决Play Core库缺失问题
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }

# 解决其他可能的问题
-keep class androidx.lifecycle.** { *; }
-keep class androidx.fragment.app.** { *; } 