package com.cyber_assasin.file_fortress

import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
	private val channel = "file_fortress/file_ops"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"deleteUri" -> {
						val uriString = call.argument<String>("uri")
						if (uriString.isNullOrBlank()) {
							result.success(false)
							return@setMethodCallHandler
						}

						val deleted = try {
							val uri = Uri.parse(uriString)
							if (DocumentsContract.isDocumentUri(this, uri)) {
								DocumentsContract.deleteDocument(contentResolver, uri)
							} else {
								contentResolver.delete(uri, null, null) > 0
							}
						} catch (e: Exception) {
							false
						}
						result.success(deleted)
					}
					else -> result.notImplemented()
				}
			}
	}
}
