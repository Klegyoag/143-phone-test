package com.x10think.onefourthree

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity is required by local_auth on some Android versions.
class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screenshots, screen recording and insecure recent-app previews on Android.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
