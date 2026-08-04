# Cleaned and Organized Proguard Rules

# Flutter Specific Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Awesome Notifications (me.carda.**)
# Keeping these classes is required for serialization of notifications
-keep class me.carda.** { *; }
-dontwarn me.carda.**

# Gson Specific Rules
-keepattributes Signature, *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.stream.** { *; }

# Retain generic signatures of TypeToken and its subclasses
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Prevent R8 from nullifying Data object members annotated with SerializedName
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# SQLCipher / SQLite Rules
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }
-keep,includedescriptorclasses class net.sqlcipher.** { *; }
-keep,includedescriptorclasses interface net.sqlcipher.** { *; }

# General Cleanup
-dontwarn com.google.**
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy
-dontwarn javax.annotation.**
