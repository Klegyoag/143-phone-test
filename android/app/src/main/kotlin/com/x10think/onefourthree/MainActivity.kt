package com.x10think.onefourthree

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity is required by local_auth on some Android versions.
class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Keep production couple data out of screenshots and recent-app previews.
        // Debug/profile builds deliberately remain capturable for device QA.
        val isQABuild = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        if (!isQABuild) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
