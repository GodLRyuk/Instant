# ==============================================================================
# FINAL OPTIMIZED PROGUARD/R8 RULES
# ==============================================================================

# Suppress "Unresolved class name" warnings in the IDE inspection
# These classes are often provided by plugins and not directly in the app classpath.
-dontnote com.google.gson.**
-dontnote net.sqlcipher.**
-dontnote org.sqlite.**
-dontnote me.carda.**
-dontnote javax.annotation.**

# 1. Flutter Core & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 2. Awesome Notifications (me.carda.**)
-keep class me.carda.** { *; }
-dontwarn me.carda.**

# 3. Gson / JSON Serialization
-keepattributes Signature, *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.stream.** { *; }
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# Retain generic signatures for TypeToken (R8 3.0+)
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Prevent R8 from stripping fields used by Gson
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# 4. SQLCipher & SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }
-keep,includedescriptorclasses class net.sqlcipher.** { *; }
-keep,includedescriptorclasses interface net.sqlcipher.** { *; }

# 5. General Cleanup & Library Warnings
-dontwarn com.google.**
-dontwarn javax.annotation.**
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy
