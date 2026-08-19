package com.kisimba.kisimba_pos

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val channelName = "com.kisimba.pos/bixolon"
    private val serialUuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val bluetoothPermissionRequest = 8412
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "requestPermission" -> requestBluetoothPermission(result)
                    "pairedPrinters" -> result.success(pairedPrinters())
                    "printReceipt" -> {
                        val address = call.argument<String>("address") ?: error("Adresse Bluetooth manquante")
                        val receipt = call.argument<String>("receipt") ?: error("Ticket manquant")
                        printReceipt(address, receipt)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: SecurityException) {
                result.error("permission_denied", "Autorisez l’accès Bluetooth.", null)
            } catch (error: Exception) {
                result.error("print_failed", error.message ?: "Impression impossible", null)
            }
        }
    }

    private fun requestBluetoothPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }
        if (permissionResult != null) {
            result.error("permission_pending", "Une demande Bluetooth est déjà ouverte.", null)
            return
        }
        permissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN),
            bluetoothPermissionRequest,
        )
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == bluetoothPermissionRequest) {
            val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            permissionResult?.success(granted)
            permissionResult = null
        }
    }

    @SuppressLint("MissingPermission")
    private fun pairedPrinters(): List<Map<String, String>> {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return emptyList()
        if (!adapter.isEnabled) return emptyList()
        return adapter.bondedDevices
            .filter { (it.name ?: "").contains("BIXOLON", ignoreCase = true) }
            .map { mapOf("name" to (it.name ?: "BIXOLON"), "address" to it.address) }
    }

    @SuppressLint("MissingPermission")
    private fun printReceipt(address: String, receipt: String) {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: error("Bluetooth indisponible")
        val device = adapter.getRemoteDevice(address)
        adapter.cancelDiscovery()
        device.createRfcommSocketToServiceRecord(serialUuid).use { socket ->
            socket.connect()
            socket.outputStream.use { output ->
                output.write(byteArrayOf(0x1B, 0x40)) // ESC @: initialize
                output.write(receipt.toByteArray(Charsets.UTF_8))
                output.write(byteArrayOf(0x0A, 0x0A, 0x0A))
                output.write(byteArrayOf(0x1D, 0x56, 0x00)) // GS V: cut when supported
                output.flush()
            }
        }
    }
}
