package com.example.concurso_admin

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var lastAuthCallback: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.data?.let { uri ->
            lastAuthCallback = uri.toString()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.channel/onedrive_auth").setMethodCallHandler { call, result ->
            when (call.method) {
                "launchAuth" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        intent.addCategory(Intent.CATEGORY_BROWSABLE)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "getAuthCallback" -> {
                    result.success(lastAuthCallback)
                }
                "clearAuthCallback" -> {
                    lastAuthCallback = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.data?.let { uri ->
            lastAuthCallback = uri.toString()
        }
    }
}
