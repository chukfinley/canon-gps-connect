package dev.chuk.canon_gps_connect

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "canon_gps_connect/imagelink"
    private val bridge = ImageLinkBridge()
    private val io = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                // Native IMLink calls block on socket I/O — run off the platform thread.
                io.execute {
                    try {
                        val res: Any? = when (call.method) {
                            "init" -> bridge.init(
                                call.argument<String>("modelName") ?: "CanonGpsConnect",
                                call.argument<String>("friendlyName") ?: "Canon GPS Connect",
                                call.argument<String>("targetId") ?: "00000000-0000-0000-0000-000000000000",
                                call.argument<String>("vendorExtVer") ?: "1.0",
                            )
                            "serviceInfo" -> bridge.serviceInfo()?.portNum ?: -1
                            "requestObjectList" -> bridge.requestObjectList(
                                call.argument<String>("from")!!,
                                call.argument<String>("to")!!,
                            ).map { mapOf("objectId" to it.objectId, "timeIso" to it.timeIso) }
                            "attachGps" -> bridge.attachGps(
                                (call.argument<Number>("objectId")!!).toLong(),
                                call.argument<String>("nmea")!!,
                            )
                            "destroy" -> { bridge.destroy(); 0 }
                            else -> { runOnUiThread { result.notImplemented() }; return@execute }
                        }
                        runOnUiThread { result.success(res) }
                    } catch (e: Throwable) {
                        runOnUiThread { result.error("IMLINK", e.message, null) }
                    }
                }
            }
    }
}
