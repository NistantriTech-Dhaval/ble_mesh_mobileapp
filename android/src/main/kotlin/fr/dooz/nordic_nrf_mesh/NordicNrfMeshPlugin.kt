package fr.dooz.nordic_nrf_mesh

import androidx.annotation.NonNull
import com.polidea.rxandroidble2.exceptions.BleException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.reactivex.exceptions.UndeliverableException
import io.reactivex.plugins.RxJavaPlugins

class NordicNrfMeshPlugin: FlutterPlugin, MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private var meshManagerApi: DoozMeshManagerApi? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // RxJava global error handling
        RxJavaPlugins.setErrorHandler { throwable ->
            if (throwable is UndeliverableException && throwable.cause is BleException) {
                // ignore BleExceptions
            } else {
                throw throwable
            }
        }

        // Initialize MethodChannel
        val messenger: BinaryMessenger = flutterPluginBinding.binaryMessenger
        methodChannel = MethodChannel(messenger, "fr.dooz.nordic_nrf_mesh/methods")
        methodChannel.setMethodCallHandler(this)

        // Initialize MeshManagerApi
        meshManagerApi = DoozMeshManagerApi(flutterPluginBinding.applicationContext, messenger)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        // TODO: cleanup meshManagerApi if necessary
    }

    // **Remove old V1 `registerWith` completely** — not needed in V2 embedding
}
