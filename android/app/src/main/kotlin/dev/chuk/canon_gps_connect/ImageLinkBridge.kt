package dev.chuk.canon_gps_connect

import android.util.Log
import jp.co.canon.android.imagelink.ImageLinkService
import java.util.concurrent.CountDownLatch
import java.util.concurrent.atomic.AtomicInteger

/**
 * Drives Canon's native IMLink (PTP/IP) session to geotag photos already on the
 * camera/SD card — the Layer-3 transport reverse-engineered from
 * com.canon.eos.U2 + IML*GpsTag*Command.
 *
 * Flow (must already be joined to the camera's WiFi SoftAP):
 *   init()  -> nativeInit + nativeCreate (mDNS discovers the camera on WiFi)
 *   requestObjectList(from,to) -> opcode 31 -> list of (objectId, captureTimeIso)
 *   attachGps(objectId, nmea)  -> opcode 33 -> camera writes GPS EXIF on device
 *   destroy()
 *
 * The NMEA string is sent verbatim as GPSInformation.mGps; the camera parses it.
 */
class ImageLinkBridge {
    companion object {
        private const val TAG = "ImageLinkBridge"
        const val OP_REQUEST_GPS_OBJECT_LIST = 31
        const val OP_ATTACH_GPS_INFO = 33
    }

    private var iml: ImageLinkService? = null

    data class CapturedObject(val objectId: Long, val timeIso: String)

    /** Minimal RequestListener — we only consume; camera-push paths return safe defaults. */
    private val requestListener = object : ImageLinkService.RequestListener {
        override fun getObjectReceiveCapability(): Any? = null
        override fun notifyDeviceAppeared(p: ImageLinkService.PeerDeviceInformation?) {
            Log.i(TAG, "device appeared: ${p?.getIPAdress()}")
        }
        override fun notifyDeviceDisappeared(ip: String?) {}
        override fun notifyRecvConnectRequest(s: String?) {}
        override fun notifyRecvExtActReq(i: ImageLinkService.ExtensionalActionIn?): Any? = null
        override fun notifyRespResPacketEnd() {}
        override fun notifyRespResPacketStart() {}
        override fun setMovieExtProperty(r: ImageLinkService.RequestMovieExtProperty?): Any? = null
        override fun setObjectData(d: ImageLinkService.SendObjectData?): Any? = null
        override fun setSendObjectInformation(i: ImageLinkService.SendObjectInformation?): Any? = null
        override fun setUsecaseStatus(u: ImageLinkService.UsecaseInformation?): Any? = null
    }

    /**
     * Start the IMLink session. deviceInfo identifies this phone to the camera.
     * Returns 0 on success (native EDS_ERR_OK).
     *
     * NOTE: the exact MyDeviceInformation values + ExtensionalAction set are
     * device-verified (capture via btsnoop / EDSDK logs). Sensible defaults below.
     */
    fun init(modelName: String, friendlyName: String, targetId: String, vendorExtVer: String): Int {
        if (iml == null) iml = ImageLinkService()
        val dev = ImageLinkService.MyDeviceInformation().apply {
            setModelName(modelName)
            setFriendlyName(friendlyName)
            setTargetID(targetId)
            setVendorExtVersion(vendorExtVer)
        }
        val appParam = ImageLinkService.ApplicationParameter().apply {
            setDeviceInformation(dev)
        }
        val extList = ImageLinkService.ExtensionalActionList().apply {
            setExtensionalActionVersion(ImageLinkService.Version(1L, 0L))
            setExtensionalActionList(ArrayList()) // a() calls getExtensionalActionList().toArray()
            setActionCount(0)
        }
        return iml!!.a(requestListener, appParam, extList)
    }

    fun serviceInfo(): ImageLinkService.ServiceInfo? {
        val info = ImageLinkService.ServiceInfo()
        val rc = iml?.c(info) ?: -1
        return if (rc == 0) info else null
    }

    /** opcode 31 — paged request of captured objects + their UTC capture times. */
    fun requestObjectList(fromIso: String, toIso: String): List<CapturedObject> {
        val service = iml ?: return emptyList()
        val out = ArrayList<CapturedObject>()
        var total = Int.MAX_VALUE
        var index = 0
        while (index < total) {
            val req = ImageLinkService.RequestTimeList(fromIso, toIso, 0L, 0L).apply {
                setIndex((index + 1).toLong())
            }
            val latch = CountDownLatch(1)
            val rc = AtomicInteger(0)
            val listener = ImageLinkService.ResponseListener { code, obj ->
                if (code == 0 && obj is ImageLinkService.CaptureTimeList) {
                    total = obj.totalNumber.toInt()
                    val list = obj.captureTimeList
                    if (list != null) {
                        for (ct in list) out.add(CapturedObject(ct.objectId, ct.time))
                        index += list.size
                    }
                } else {
                    rc.set(if (code == 0) 0 else code)
                    total = 0 // stop
                }
                latch.countDown()
                0
            }
            val sendRc = service.d(OP_REQUEST_GPS_OBJECT_LIST, req, listener)
            if (sendRc != 0) break
            latch.await()
            if (out.isEmpty() && total == 0) break
            if (index == 0) break // no progress guard
        }
        return out
    }

    /** opcode 33 — attach GPS EXIF (NMEA string) to one object on the camera. */
    fun attachGps(objectId: Long, nmea: String): Int {
        val service = iml ?: return -1
        val info = arrayOf(ImageLinkService.GPSInformation(objectId, nmea))
        val latch = CountDownLatch(1)
        val result = AtomicInteger(0)
        val listener = ImageLinkService.ResponseListener { code, _ ->
            result.set(code)
            latch.countDown()
            0
        }
        val rc = service.d(OP_ATTACH_GPS_INFO, info, listener)
        if (rc != 0) return rc
        latch.await()
        return result.get()
    }

    fun destroy() {
        iml?.b(ImageLinkService.DestroyEndListener { })
        iml = null
    }
}
