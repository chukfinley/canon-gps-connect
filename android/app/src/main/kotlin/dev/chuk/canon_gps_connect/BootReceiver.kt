package dev.chuk.canon_gps_connect

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * On reboot the OS clears foreground services. flutter_foreground_task restarts
 * its own service when configured with autoRunOnBoot; this receiver is the
 * manifest hook for BOOT_COMPLETED. Kept minimal — the Dart side re-arms GPS/BLE
 * on next launch, and FlutterForegroundTask.setOnLockScreenVisibility handles
 * persistence. Extend here if you need cold-boot auto-start without opening UI.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // no-op placeholder; foreground task plugin handles restart when enabled
        }
    }
}
