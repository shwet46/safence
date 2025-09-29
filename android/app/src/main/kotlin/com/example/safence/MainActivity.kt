package com.example.safence

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.provider.Telephony
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterFragmentActivity() {
	private val smsChannel = "safence/sms_stream"
	private var smsReceiver: BroadcastReceiver? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, smsChannel)
			.setStreamHandler(object : EventChannel.StreamHandler {
				override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
					registerSmsReceiver(events)
				}

				override fun onCancel(arguments: Any?) {
					unregisterSmsReceiver()
				}
			})
	}

	private fun registerSmsReceiver(events: EventChannel.EventSink?) {
		if (smsReceiver != null) return
		smsReceiver = object : BroadcastReceiver() {
			override fun onReceive(context: Context?, intent: Intent?) {
				if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
					val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
					for (msg in messages) {
						val map = hashMapOf(
							"address" to (msg.originatingAddress ?: "Unknown"),
							"body" to (msg.messageBody ?: ""),
							"timestamp" to msg.timestampMillis
						)
						events?.success(map)
					}
				}
			}
		}
		val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
		registerReceiver(smsReceiver, filter)
	}

	private fun unregisterSmsReceiver() {
		smsReceiver?.let { unregisterReceiver(it) }
		smsReceiver = null
	}

	override fun onDestroy() {
		unregisterSmsReceiver()
		super.onDestroy()
	}
}
