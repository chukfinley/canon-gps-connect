package jp.co.canon.android.imagelink;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/* loaded from: classes.dex */
public class ImageLinkService {
    public static int a;

    /* loaded from: classes.dex */
    public static class ActionFailReason {
        private long mActionStatus;
        private String mReason;

        public ActionFailReason() {
        }

        public long getActionStatus() {
            return this.mActionStatus;
        }

        public String getReason() {
            return this.mReason;
        }

        public void setActionStatus(long j2) {
            this.mActionStatus = j2;
        }

        public void setReason(String str) {
            this.mReason = str;
        }

        public ActionFailReason(long j2, String str) {
            this.mActionStatus = j2;
            this.mReason = str;
        }
    }

    /* loaded from: classes.dex */
    public static class ApplicationParameter {
        MyDeviceInformation mDeviceInfo;

        public ApplicationParameter() {
        }

        public MyDeviceInformation getDeviceInformation() {
            return this.mDeviceInfo;
        }

        public void setDeviceInformation(MyDeviceInformation myDeviceInformation) {
            this.mDeviceInfo = myDeviceInformation;
        }

        public ApplicationParameter(String str, String str2, String str3, String str4) {
            this.mDeviceInfo = new MyDeviceInformation(str, str2, str3, str4);
        }
    }

    /* loaded from: classes.dex */
    public static class CaptureTime {
        private long mObjectId;
        private String mTime;

        public CaptureTime() {
        }

        public long getObjectId() {
            return this.mObjectId;
        }

        public String getTime() {
            return this.mTime;
        }

        public void setObjectId(long j2) {
            this.mObjectId = j2;
        }

        public void setTime(String str) {
            this.mTime = str;
        }

        public CaptureTime(long j2, String str) {
            this.mObjectId = j2;
            this.mTime = str;
        }
    }

    /* loaded from: classes.dex */
    public static class CaptureTimeList {
        private List<CaptureTime> mCaptureTimeList;
        private long mListNumber;
        private long mTotalNumber;

        public CaptureTimeList() {
        }

        public List<CaptureTime> getCaptureTimeList() {
            return this.mCaptureTimeList;
        }

        public long getListNumber() {
            return this.mListNumber;
        }

        public long getTotalNumber() {
            return this.mTotalNumber;
        }

        public void setCaptureTimeList(List<CaptureTime> list) {
            this.mCaptureTimeList = list;
        }

        public void setListNumber(long j2) {
            this.mListNumber = j2;
        }

        public void setTotalNumber(long j2) {
            this.mTotalNumber = j2;
        }

        public CaptureTimeList(long j2, long j4, long[] jArr, String[] strArr) {
            this.mTotalNumber = j2;
            this.mListNumber = j4;
            CaptureTime[] captureTimeArr = new CaptureTime[j4 > 2147483647L ? Integer.MAX_VALUE : (int) j4];
            this.mCaptureTimeList = new ArrayList();
            for (int i5 = 0; i5 < j4; i5++) {
                CaptureTime captureTime = new CaptureTime(jArr[i5], strArr[i5]);
                captureTimeArr[i5] = captureTime;
                this.mCaptureTimeList.add(captureTime);
            }
        }
    }

    /* loaded from: classes.dex */
    public static class ConnDevInfo {
        private DevSrvInfo mDevSrvInfo;
        private String mHostName;
        private String mIpAddr;
        private String mModelName;
        private String mTargetId;
        private String mVenderName;

        public ConnDevInfo() {
        }

        public Object getDevSrvInfo() {
            return this.mDevSrvInfo;
        }

        public String getHostName() {
            return this.mHostName;
        }

        public String getIpAddr() {
            return this.mIpAddr;
        }

        public String getModelName() {
            return this.mModelName;
        }

        public String getTargetId() {
            return this.mTargetId;
        }

        public String getVenderName() {
            return this.mVenderName;
        }

        public void setDevSrvInfo(DevSrvInfo devSrvInfo) {
            this.mDevSrvInfo = devSrvInfo;
        }

        public void setHostName(String str) {
            this.mHostName = str;
        }

        public void setIpAddr(String str) {
            this.mIpAddr = str;
        }

        public void setModelName(String str) {
            this.mModelName = str;
        }

        public void setTargetId(String str) {
            this.mTargetId = str;
        }

        public void setVenderName(String str) {
            this.mVenderName = str;
        }

        public ConnDevInfo(DevSrvInfo devSrvInfo, String str, String str2, String str3, String str4, String str5) {
            setDevSrvInfo(devSrvInfo);
            setIpAddr(str);
            setTargetId(str2);
            setHostName(str3);
            setModelName(str4);
            setVenderName(str5);
        }
    }

    /* loaded from: classes.dex */
    public static class ConnectRequestParametor {
        private IPAddressParameters mAddress;
        private int mDiscoveryType;
        private String mHostName;
        private String mServiceName;

        public ConnectRequestParametor() {
        }

        public int getDiscoveryType() {
            return this.mDiscoveryType;
        }

        public String getHostName() {
            return this.mHostName;
        }

        public IPAddressParameters getIPAdress() {
            return this.mAddress;
        }

        public String getServiceName() {
            return this.mServiceName;
        }

        public void setDiscoveryType(int i5) {
            this.mDiscoveryType = i5;
        }

        public void setHostName(String str) {
            this.mHostName = str;
        }

        public void setIPAddres(IPAddressParameters iPAddressParameters) {
            this.mAddress = iPAddressParameters;
        }

        public void setServiceName(String str) {
            this.mServiceName = str;
        }

        public ConnectRequestParametor(String str, String str2, String str3, String str4, int i5) {
            this.mAddress = new IPAddressParameters(str, str2);
            this.mHostName = str3;
            this.mServiceName = str4;
            this.mDiscoveryType = i5;
        }
    }

    /* loaded from: classes.dex */
    public interface DestroyEndListener {
        void onDestroyEnd();
    }

    /* loaded from: classes.dex */
    public static class DevSrvInfo {
        private Version mExtActVer;
        private ServiceInfo mSrvInfo;
        private String mVendExtVer;

        public DevSrvInfo() {
        }

        public Object getExtActVer() {
            return this.mExtActVer;
        }

        public Object getSrvInfo() {
            return this.mSrvInfo;
        }

        public String getVendExtVer() {
            return this.mVendExtVer;
        }

        public void setExtActVer(Version version) {
            this.mExtActVer = version;
        }

        public void setSrvInfo(ServiceInfo serviceInfo) {
            this.mSrvInfo = serviceInfo;
        }

        public void setVendExtVer(String str) {
            this.mVendExtVer = str;
        }

        public DevSrvInfo(int i5, long j2, long j4, long j5, long j6, String str) {
            this.mSrvInfo = new ServiceInfo(i5, j2, j4);
            this.mExtActVer = new Version((int) j5, (int) j6);
            setVendExtVer(str);
        }

        public DevSrvInfo(ServiceInfo serviceInfo, Version version, String str) {
            setSrvInfo(serviceInfo);
            setExtActVer(version);
            setVendExtVer(str);
        }
    }

    /* loaded from: classes.dex */
    public static class ExtensionalAction {
        private int mCallBackType;
        private String mResourceName;

        public ExtensionalAction() {
        }

        public int getCallBackType() {
            return this.mCallBackType;
        }

        public String getResourceName() {
            return this.mResourceName;
        }

        public void setCallBackType(int i5) {
            this.mCallBackType = i5;
        }

        public void setResourceName(String str) {
            this.mResourceName = str;
        }

        public ExtensionalAction(String str, int i5) {
            this.mResourceName = str;
            this.mCallBackType = i5;
        }
    }

    /* loaded from: classes.dex */
    public static class ExtensionalActionArgument {
        private int mArgumentTotal;
        private ExtensionalActionNameValue[] mExtensionalActionNameValueList;

        public ExtensionalActionArgument() {
        }

        public int getArgumentTotal() {
            return this.mArgumentTotal;
        }

        public Object[] getExtensionalActionNameValueArray() {
            return this.mExtensionalActionNameValueList;
        }

        public ExtensionalActionNameValue[] getExtensionalActionNameValueList() {
            return this.mExtensionalActionNameValueList;
        }

        public void setArgumentTotal(int i5) {
            this.mArgumentTotal = i5;
        }

        public void setExtensionalActionNameValueList(ExtensionalActionNameValue[] extensionalActionNameValueArr) {
            this.mExtensionalActionNameValueList = extensionalActionNameValueArr;
        }

        public ExtensionalActionArgument(int i5, Object[] objArr) {
            this.mArgumentTotal = i5;
            if (objArr instanceof ExtensionalActionNameValue[]) {
                this.mExtensionalActionNameValueList = (ExtensionalActionNameValue[]) objArr;
            }
        }
    }

    /* loaded from: classes.dex */
    public static class ExtensionalActionIn {
        private ExtensionalActionArgument mArgument;
        private ExtensionalActionReferenceArgument mReferenceArgument;
        private int mRequestKind;
        private String mResourceName;

        public ExtensionalActionIn() {
        }

        public ExtensionalActionArgument getExtensionalActionArgument() {
            return this.mArgument;
        }

        public ExtensionalActionReferenceArgument getExtensionalActionReferenceArgument() {
            return this.mReferenceArgument;
        }

        public int getRequestKind() {
            return this.mRequestKind;
        }

        public String getResourceName() {
            return this.mResourceName;
        }

        public void setExtensionalActionArgument(ExtensionalActionArgument extensionalActionArgument) {
            this.mArgument = extensionalActionArgument;
        }

        public void setExtensionalActionReferenceArgument(ExtensionalActionReferenceArgument extensionalActionReferenceArgument) {
            this.mReferenceArgument = extensionalActionReferenceArgument;
        }

        public void setRequestKind(int i5) {
            this.mRequestKind = i5;
        }

        public void setResourceName(String str) {
            this.mResourceName = str;
        }

        public ExtensionalActionIn(String str, int i5, Object obj, Object obj2) {
            this.mResourceName = str;
            this.mRequestKind = i5;
            if (obj instanceof ExtensionalActionReferenceArgument) {
                this.mReferenceArgument = (ExtensionalActionReferenceArgument) obj;
            }
            if (obj2 instanceof ExtensionalActionArgument) {
                this.mArgument = (ExtensionalActionArgument) obj2;
            }
        }
    }

    /* loaded from: classes.dex */
    public static class ExtensionalActionList {
        private int mActionCount;
        private List<ExtensionalAction> mExtensionalActionList;
        private Version mExtensionalActionVersion;

        public ExtensionalActionList() {
        }

        public int getActionCount() {
            return this.mActionCount;
        }

        public List<ExtensionalAction> getExtensionalActionList() {
            return this.mExtensionalActionList;
        }

        public Version getExtensionalActionVersion() {
            return this.mExtensionalActionVersion;
        }

        public void setActionCount(int i5) {
            this.mActionCount = i5;
        }

        public void setExtensionalActionList(List<ExtensionalAction> list) {
            this.mExtensionalActionList = list;
        }

        public void setExtensionalActionVersion(Version version) {
            this.mExtensionalActionVersion = version;
        }

        public ExtensionalActionList(long j2, long j4, int i5, ExtensionalAction[] extensionalActionArr) {
            this.mExtensionalActionVersion = new Version(j2, j4);
            this.mActionCount = i5;
            this.mExtensionalActionList = new ArrayList();
            if (extensionalActionArr != null) {
                for (ExtensionalAction extensionalAction : extensionalActionArr) {
                    this.mExtensionalActionList.add(extensionalAction);
                }
            }
        }
    }

    /* loaded from: classes.dex */
    public static class ExtensionalActionNameValue {
        private long mBinSize;
        private String mKeyName;
        private Object mValue;
        private long mValueType;

        public ExtensionalActionNameValue() {
        }

        public long getBinSize() {
            return this.mBinSize;
        }

        public String getKeyName() {
            return this.mKeyName;
        }

        public Object getValue() {
            return this.mValue;
        }

        public long getValueType() {
            return this.mValueType;
        }

        public void setBinSize(long j2) {
            this.mBinSize = j2;
        }

        public void setKeyName(String str) {
            this.mKeyName = str;
        }

        public void setValue(Object obj) {
            this.mValue = obj;
        }

        public void setValueType(long j2) {
            this.mValueType = j2;
        }

        public ExtensionalActionNameValue(String str, Object obj, long j2, long j4) {
            this.mKeyName = str;
            this.mValue = obj;
            this.mBinSize = j2;
            this.mValueType = j4;
        }
    }

    /* loaded from: classes.dex */
    public static class ExtensionalActionReferenceArgument {
        private ExtensionalActionNameValue[] mExtensionalActionNameValueList;
        private int mReferenceArgumentTotal;

        public ExtensionalActionReferenceArgument() {
        }

        public ExtensionalActionNameValue[] getExtensionalActionNameValueList() {
            return this.mExtensionalActionNameValueList;
        }

        public int getReferenceArgumentTotal() {
            return this.mReferenceArgumentTotal;
        }

        public void setExtensionalActionNameValueList(ExtensionalActionNameValue[] extensionalActionNameValueArr) {
            this.mExtensionalActionNameValueList = extensionalActionNameValueArr;
        }

        public void setReferenceArgumentTotal(int i5) {
            this.mReferenceArgumentTotal = i5;
        }

        public ExtensionalActionReferenceArgument(int i5, Object[] objArr) {
            this.mReferenceArgumentTotal = i5;
            if (objArr instanceof ExtensionalActionNameValue[]) {
                this.mExtensionalActionNameValueList = (ExtensionalActionNameValue[]) objArr;
            }
        }
    }

    /* loaded from: classes.dex */
    public static class Fraction {
        private long mDenominator;
        private int mNumerator;

        public Fraction() {
        }

        public long getDenominator() {
            return this.mDenominator;
        }

        public int getNumerator() {
            return this.mNumerator;
        }

        public void setDenominator(long j2) {
            this.mDenominator = j2;
        }

        public void setNumerator(int i5) {
            this.mNumerator = i5;
        }

        public Fraction(int i5, long j2) {
            this.mNumerator = i5;
            this.mDenominator = j2;
        }
    }

    /* loaded from: classes.dex */
    public static class GPSData {
        private String mAddress;
        private Fraction mAltitude;
        private List<Fraction> mLatitude;
        private List<Fraction> mLongitude;

        public GPSData() {
        }

        public String getAddress() {
            return this.mAddress;
        }

        public Fraction getAltitude() {
            return this.mAltitude;
        }

        public List<Fraction> getLatitude() {
            return this.mLatitude;
        }

        public List<Fraction> getLongitude() {
            return this.mLongitude;
        }

        public void setAddress(String str) {
            this.mAddress = str;
        }

        public void setAltitude(Fraction fraction) {
            this.mAltitude = fraction;
        }

        public void setLatitude(List<Fraction> list) {
            this.mLatitude = list;
        }

        public void setLongitude(List<Fraction> list) {
            this.mLongitude = list;
        }

        public GPSData(Fraction[] fractionArr, Fraction[] fractionArr2, Fraction fraction, String str) {
            this.mLatitude = new ArrayList();
            this.mLongitude = new ArrayList();
            this.mAltitude = fraction;
            this.mAddress = str;
            if (fractionArr != null) {
                for (Fraction fraction2 : fractionArr) {
                    this.mLatitude.add(fraction2);
                }
            }
            if (fractionArr2 != null) {
                for (Fraction fraction3 : fractionArr2) {
                    this.mLongitude.add(fraction3);
                }
            }
        }
    }

    /* loaded from: classes.dex */
    public static class GPSInformation {
        private String mGps;
        private long mObjectId;

        public GPSInformation() {
        }

        public String getGPS() {
            return this.mGps;
        }

        public long getObjectId() {
            return this.mObjectId;
        }

        public void setGPS(String str) {
            this.mGps = str;
        }

        public void setObjectId(long j2) {
            this.mObjectId = j2;
        }

        public GPSInformation(long j2, String str) {
            this.mObjectId = j2;
            this.mGps = str;
        }
    }

    /* loaded from: classes.dex */
    public static class GroupObjectIDType {
        private long mGrouped_Num;
        private long mObjectID;
        private long mObjectType;

        public GroupObjectIDType() {
        }

        public long getGrouped_Num() {
            return this.mGrouped_Num;
        }

        public long getObjectID() {
            return this.mObjectID;
        }

        public long getObjectType() {
            return this.mObjectType;
        }

        public void setGrouped_Num(long j2) {
            this.mGrouped_Num = j2;
        }

        public void setObjectID(long j2) {
            this.mObjectID = j2;
        }

        public void setObjectType(long j2) {
            this.mObjectType = j2;
        }

        public GroupObjectIDType(long j2, long j4, long j5) {
            this.mObjectID = j2;
            this.mObjectType = j4;
            this.mGrouped_Num = j5;
        }
    }

    /* loaded from: classes.dex */
    public static class IPAddressParameters {
        private String mIPAdress;
        private String mSubnetmask;

        public IPAddressParameters() {
        }

        public String getMyIPAddress() {
            return this.mIPAdress;
        }

        public String getSubnetmask() {
            return this.mSubnetmask;
        }

        public void setMyIPAddress(String str) {
            this.mIPAdress = str;
        }

        public void setSubnetmask(String str) {
            this.mSubnetmask = str;
        }

        public IPAddressParameters(String str, String str2) {
            this.mIPAdress = str;
            this.mSubnetmask = str2;
        }
    }

    /* loaded from: classes.dex */
    public static class ImageLinkCallBack {
        static final int MSG_DESTROY = 2;
        static final int MSG_REQUEST = 1;
        static final int MSG_RESPONSE = 3;
        private static ImageLinkCallBack mInstance;
        private EventHandler mHandler;
        private RequestListener mRequestListener = null;
        private HashMap<Integer, ResponseListener> mResponseListener = new HashMap<>();
        private DestroyEndListener mDestroyListener = null;

        /* loaded from: classes.dex */
        public class EventHandler extends Handler {
            public EventHandler(Looper looper) {
                super(looper);
            }

            @Override // android.os.Handler
            public void handleMessage(Message message) {
                if (message != null) {
                    int i5 = message.what;
                    if (i5 == ImageLinkCallBack.MSG_REQUEST) {
                        ImageLinkCallBack.onRequest(message.arg1, message.obj);
                    } else if (i5 == ImageLinkCallBack.MSG_DESTROY) {
                        ImageLinkCallBack.access$200();
                    } else {
                        if (i5 != ImageLinkCallBack.MSG_RESPONSE) {
                            return;
                        }
                        ImageLinkCallBack.onResponse(message.arg1, message.arg2, message.obj);
                    }
                }
            }
        }

        public static /* synthetic */ int access$200() {
            return onDestroy();
        }

        public static void deleteDestroyListener() {
            getInstance().mDestroyListener = null;
        }

        public static void deleteRequestListener() {
            getInstance().mRequestListener = null;
        }

        public static void deleteResponseListener(int i5) {
            if (getInstance().mResponseListener != null) {
                getInstance().mResponseListener.remove(Integer.valueOf(i5));
            }
        }

        private EventHandler getHandler() {
            if (this.mHandler == null) {
                Looper myLooper = Looper.myLooper();
                if (myLooper != null) {
                    this.mHandler = new EventHandler(myLooper);
                } else {
                    Looper mainLooper = Looper.getMainLooper();
                    if (mainLooper != null) {
                        this.mHandler = new EventHandler(mainLooper);
                    } else {
                        this.mHandler = new EventHandler(null);
                    }
                }
            }
            return this.mHandler;
        }

        public static ImageLinkCallBack getInstance() {
            if (mInstance == null) {
                mInstance = new ImageLinkCallBack();
            }
            return mInstance;
        }

        public static ResponseListener getResponseListener(int i5) {
            if (getInstance().mResponseListener != null) {
                return getInstance().mResponseListener.get(Integer.valueOf(i5));
            }
            return null;
        }

        private static int onDestroy() {
            ImageLinkService.a = 0;
            DestroyEndListener destroyEndListener = getInstance().mDestroyListener;
            if (destroyEndListener != null) {
                destroyEndListener.onDestroyEnd();
            }
            return 0;
        }

        public static void onDestroyFromNative() {
            onDestroy();
        }

        /* JADX INFO: Access modifiers changed from: private */
        public static void onRequest(int i5, Object obj) {
            RequestListener requestListener = getInstance().mRequestListener;
            if (requestListener != null) {
                switch (i5) {
                    case 12033:
                        requestListener.notifyDeviceAppeared(obj instanceof PeerDeviceInformation ? (PeerDeviceInformation) obj : null);
                        return;
                    case 12034:
                        requestListener.notifyRecvConnectRequest(obj instanceof String ? (String) obj : null);
                        return;
                    case 12035:
                        requestListener.notifyDeviceDisappeared(obj instanceof String ? (String) obj : null);
                        return;
                    case 12036:
                    default:
                        return;
                    case 12037:
                        requestListener.notifyRespResPacketStart();
                        return;
                    case 12038:
                        requestListener.notifyRespResPacketEnd();
                        return;
                }
            }
        }

        public static int onRequestFromNative(int i5, Object obj) {
            onRequest(i5, obj);
            return 0;
        }

        public static Object onRequestFromNativeReturnValue(int i5, Object obj) {
            RequestListener requestListener = getInstance().mRequestListener;
            if (requestListener != null) {
                if (i5 == 8225) {
                    return requestListener.getObjectReceiveCapability();
                }
                if (i5 == 12036) {
                    return requestListener.notifyRecvExtActReq(obj instanceof ExtensionalActionIn ? (ExtensionalActionIn) obj : null);
                }
                switch (i5) {
                    case 8229:
                        return requestListener.setUsecaseStatus(obj instanceof UsecaseInformation ? (UsecaseInformation) obj : null);
                    case 8230:
                        return requestListener.setSendObjectInformation(obj instanceof SendObjectInformation ? (SendObjectInformation) obj : null);
                    case 8231:
                        return requestListener.setObjectData(obj instanceof SendObjectData ? (SendObjectData) obj : null);
                    case 8232:
                        return requestListener.setMovieExtProperty(obj instanceof RequestMovieExtProperty ? (RequestMovieExtProperty) obj : null);
                }
            }
            return null;
        }

        /* JADX INFO: Access modifiers changed from: private */
        public static int onResponse(int i5, int i6, Object obj) {
            ResponseListener responseListener = getResponseListener(i5);
            if (responseListener != null) {
                return responseListener.onResponse(i6, obj);
            }
            return 0;
        }

        public static int onResponseFromNative(int i5, int i6, Object obj) {
            return onResponse(i5, i6, obj);
        }

        public static void setDestroyListener(DestroyEndListener destroyEndListener) {
            if (destroyEndListener != null) {
                getInstance().mDestroyListener = destroyEndListener;
            }
        }

        public static void setRequestListener(RequestListener requestListener) {
            if (requestListener != null) {
                getInstance().mRequestListener = requestListener;
            }
        }

        public static void setResponseListener(int i5, ResponseListener responseListener) {
            if (responseListener != null) {
                getInstance().mResponseListener.put(Integer.valueOf(i5), responseListener);
            }
        }
    }

    /* loaded from: classes.dex */
    public static class MyDeviceInformation {
        private String mFriendlyName;
        private String mModelName;
        private String mTargetID;
        private String mVendorExtVersion;

        public MyDeviceInformation() {
        }

        public String getFriendlyName() {
            return this.mFriendlyName;
        }

        public String getModelName() {
            return this.mModelName;
        }

        public String getTargetID() {
            return this.mTargetID;
        }

        public String getVendorExtVersion() {
            return this.mVendorExtVersion;
        }

        public void setFriendlyName(String str) {
            this.mFriendlyName = str;
        }

        public void setModelName(String str) {
            this.mModelName = str;
        }

        public void setTargetID(String str) {
            this.mTargetID = str;
        }

        public void setVendorExtVersion(String str) {
            this.mVendorExtVersion = str;
        }

        public MyDeviceInformation(String str, String str2, String str3, String str4) {
            this.mModelName = str;
            this.mFriendlyName = str2;
            this.mTargetID = str3;
            this.mVendorExtVersion = str4;
        }
    }

    /* loaded from: classes.dex */
    public static class ObjectIDType {
        private long mObjectID;
        private long mObjectType;

        public ObjectIDType() {
        }

        public long getObjectID() {
            return this.mObjectID;
        }

        public long getObjectType() {
            return this.mObjectType;
        }

        public void setObjectID(long j2) {
            this.mObjectID = j2;
        }

        public void setObjectType(long j2) {
            this.mObjectType = j2;
        }

        public ObjectIDType(long j2, long j4) {
            this.mObjectID = j2;
            this.mObjectType = j4;
        }
    }

    /* loaded from: classes.dex */
    public static class ObjectProperty {
        private long mApproxDataSize;
        private long mDataSize;
        private Resolution mResolution;

        public ObjectProperty() {
        }

        public long getApproxDataSize() {
            return this.mApproxDataSize;
        }

        public long getDataSize() {
            return this.mDataSize;
        }

        public Resolution getResolution() {
            return this.mResolution;
        }

        public void setApproxDataSize(long j2) {
            this.mApproxDataSize = j2;
        }

        public void setDataSize(long j2) {
            this.mDataSize = j2;
        }

        public void setResolution(Resolution resolution) {
            this.mResolution = resolution;
        }

        public ObjectProperty(long j2, long j4, long j5) {
            this.mResolution = new Resolution(j2, j4);
            this.mDataSize = j5;
        }

        public ObjectProperty(long j2, long j4, long j5, long j6) {
            this.mResolution = new Resolution(j2, j4);
            this.mDataSize = j5;
            this.mApproxDataSize = j6;
        }
    }

    /* loaded from: classes.dex */
    public static class PeerDeviceInformation {
        private Version mExtentionVersion;
        private String mHostName;
        private String mIPAdress;
        private String mModelName;
        private long mServiceType;
        private long mServiceVersion;
        private String mTargetID;
        private String mVenderExtentionVersion;
        private String mVenderName;

        public PeerDeviceInformation() {
        }

        public Version getExtentionVersion() {
            return this.mExtentionVersion;
        }

        public String getHostName() {
            return this.mHostName;
        }

        public String getIPAdress() {
            return this.mIPAdress;
        }

        public String getModelName() {
            return this.mModelName;
        }

        public long getServiceType() {
            return this.mServiceType;
        }

        public long getServiceVersion() {
            return this.mServiceVersion;
        }

        public String getTargetID() {
            return this.mTargetID;
        }

        public String getVenderExtentionVersion() {
            return this.mVenderExtentionVersion;
        }

        public String getVendorName() {
            return this.mVenderName;
        }

        public void setExtentionVersion(Version version) {
            this.mExtentionVersion = version;
        }

        public void setHostName(String str) {
            this.mHostName = str;
        }

        public void setIPAdress(String str) {
            this.mIPAdress = str;
        }

        public void setModelName(String str) {
            this.mModelName = str;
        }

        public void setServiceType(long j2) {
            this.mServiceType = j2;
        }

        public void setServiceVersion(long j2) {
            this.mServiceVersion = j2;
        }

        public void setTargetID(String str) {
            this.mTargetID = str;
        }

        public void setVenderExtentionVersion(String str) {
            this.mVenderExtentionVersion = str;
        }

        public void setVendorName(String str) {
            this.mVenderName = str;
        }

        public PeerDeviceInformation(String str, String str2, String str3, String str4, long j2, long j4, long j5, long j6, String str5, String str6) {
            this.mTargetID = str;
            this.mModelName = str2;
            this.mHostName = str3;
            this.mVenderName = str4;
            this.mServiceType = j2;
            this.mServiceVersion = j4;
            this.mExtentionVersion = new Version(j5, j6);
            this.mIPAdress = str5;
            this.mVenderExtentionVersion = str6;
        }
    }

    /* loaded from: classes.dex */
    public static class ReceiveCapability {
        private long mBufferSize;
        private long mMaxPartialSize;
        private long mMaxSize;

        public ReceiveCapability() {
        }

        public long getBufferSize() {
            return this.mBufferSize;
        }

        public long getMaxPartialSize() {
            return this.mMaxPartialSize;
        }

        public long getMaxSize() {
            return this.mMaxSize;
        }

        public void setBufferSize(long j2) {
            this.mBufferSize = j2;
        }

        public void setMaxPartialSize(long j2) {
            this.mMaxPartialSize = j2;
        }

        public void setMaxSize(long j2) {
            this.mMaxSize = j2;
        }

        public ReceiveCapability(long j2, long j4, long j5) {
            this.mBufferSize = j2;
            this.mMaxSize = j4;
            this.mMaxPartialSize = j5;
        }
    }

    /* loaded from: classes.dex */
    public static class RequestGroupedObjIDList {
        private long mFilterType;
        private long mGroupType;
        private long mGroupedObjID;
        private long mIndex;
        private long mMaxNumber;
        private long mObjectType;

        public RequestGroupedObjIDList() {
        }

        public long getFilterType() {
            return this.mFilterType;
        }

        public long getGroupType() {
            return this.mGroupType;
        }

        public long getGroupedObjID() {
            return this.mGroupedObjID;
        }

        public long getIndex() {
            return this.mIndex;
        }

        public long getMaxNumber() {
            return this.mMaxNumber;
        }

        public long getObjectType() {
            return this.mObjectType;
        }

        public void setFilterType(long j2) {
            this.mFilterType = j2;
        }

        public void setGroupType(long j2) {
            this.mGroupType = j2;
        }

        public void setGroupedObjID(long j2) {
            this.mGroupedObjID = j2;
        }

        public void setIndex(long j2) {
            this.mIndex = j2;
        }

        public void setMaxNumber(long j2) {
            this.mMaxNumber = j2;
        }

        public void setObjectType(long j2) {
            this.mObjectType = j2;
        }

        public RequestGroupedObjIDList(long j2, long j4, long j5, long j6, long j7, long j8) {
            this.mIndex = j2;
            this.mMaxNumber = j4;
            this.mObjectType = j5;
            this.mGroupType = j6;
            this.mFilterType = j7;
            this.mGroupedObjID = j8;
        }
    }

    /* loaded from: classes.dex */
    public interface RequestListener {
        Object getObjectReceiveCapability();

        void notifyDeviceAppeared(PeerDeviceInformation peerDeviceInformation);

        void notifyDeviceDisappeared(String str);

        void notifyRecvConnectRequest(String str);

        Object notifyRecvExtActReq(ExtensionalActionIn extensionalActionIn);

        void notifyRespResPacketEnd();

        void notifyRespResPacketStart();

        Object setMovieExtProperty(RequestMovieExtProperty requestMovieExtProperty);

        Object setObjectData(SendObjectData sendObjectData);

        Object setSendObjectInformation(SendObjectInformation sendObjectInformation);

        Object setUsecaseStatus(UsecaseInformation usecaseInformation);
    }

    /* loaded from: classes.dex */
    public static class RequestMovieExtProperty {
        private long mFileVersion;
        private ObjectIDType mObjectIDType;
        private long mPlayTime;

        public RequestMovieExtProperty() {
        }

        public long getFileVersion() {
            return this.mFileVersion;
        }

        public ObjectIDType getObjectIDType() {
            return this.mObjectIDType;
        }

        public long getPlayTime() {
            return this.mPlayTime;
        }

        public void setFileVersion(long j2) {
            this.mFileVersion = j2;
        }

        public void setObjectIDType(ObjectIDType objectIDType) {
            this.mObjectIDType = objectIDType;
        }

        public void setPlayTime(long j2) {
            this.mPlayTime = j2;
        }

        public RequestMovieExtProperty(long j2, long j4, long j5, long j6) {
            this.mObjectIDType = new ObjectIDType(j2, j4);
            this.mFileVersion = j5;
            this.mPlayTime = j6;
        }
    }

    /* loaded from: classes.dex */
    public static class RequestObjectID {
        private long mIndex;
        private long mMaxNumber;
        private long mObjectType;

        public RequestObjectID() {
        }

        public long getIndex() {
            return this.mIndex;
        }

        public long getMaxNumber() {
            return this.mMaxNumber;
        }

        public long getObjectType() {
            return this.mObjectType;
        }

        public void setIndex(long j2) {
            this.mIndex = j2;
        }

        public void setMaxNumber(long j2) {
            this.mMaxNumber = j2;
        }

        public void setObjectType(long j2) {
            this.mObjectType = j2;
        }

        public RequestObjectID(long j2, long j4, long j5) {
            this.mIndex = j2;
            this.mMaxNumber = j4;
            this.mObjectType = j5;
        }
    }

    /* loaded from: classes.dex */
    public static class RequestObjectInformation {
        private long mMaxSize;
        private ObjectIDType mObjectIDType;
        private long mOffset;
        private long mPartialSize;
        private long mResizeSize;

        public RequestObjectInformation() {
        }

        public long getMaxSize() {
            return this.mMaxSize;
        }

        public ObjectIDType getObjectIDType() {
            return this.mObjectIDType;
        }

        public long getOffset() {
            return this.mOffset;
        }

        public long getPartialSize() {
            return this.mPartialSize;
        }

        public long getResizeSize() {
            return this.mResizeSize;
        }

        public void setMaxSize(long j2) {
            this.mMaxSize = j2;
        }

        public void setObjectIDType(ObjectIDType objectIDType) {
            this.mObjectIDType = objectIDType;
        }

        public void setOffset(long j2) {
            this.mOffset = j2;
        }

        public void setPartialSize(long j2) {
            this.mPartialSize = j2;
        }

        public void setResizeSize(long j2) {
            this.mResizeSize = j2;
        }

        public RequestObjectInformation(long j2, long j4, long j5, long j6, long j7, long j8) {
            this.mObjectIDType = new ObjectIDType(j2, j4);
            this.mResizeSize = j5;
            this.mMaxSize = j6;
            this.mOffset = j7;
            this.mPartialSize = j8;
        }
    }

    /* loaded from: classes.dex */
    public static class RequestObjectProperty {
        private ObjectIDType mObjectIDType;
        private long mResizeSize;

        public RequestObjectProperty() {
        }

        public long getObjectID() {
            return this.mObjectIDType.getObjectID();
        }

        public ObjectIDType getObjectIDType() {
            return this.mObjectIDType;
        }

        public long getObjectType() {
            return this.mObjectIDType.getObjectType();
        }

        public long getResizeSize() {
            return this.mResizeSize;
        }

        public void setObjectIDType(ObjectIDType objectIDType) {
            this.mObjectIDType = objectIDType;
        }

        public void setResizeSize(long j2) {
            this.mResizeSize = j2;
        }

        public RequestObjectProperty(ObjectIDType objectIDType, long j2) {
            this.mObjectIDType = objectIDType;
            this.mResizeSize = j2;
        }
    }

    /* loaded from: classes.dex */
    public static class RequestTimeList {
        private String mFrom;
        private long mIndex;
        private long mMaxNumber;
        private String mTo;

        public RequestTimeList() {
        }

        public String getFrom() {
            return this.mFrom;
        }

        public long getIndex() {
            return this.mIndex;
        }

        public long getMaxNumber() {
            return this.mMaxNumber;
        }

        public String getTo() {
            return this.mTo;
        }

        public void setFrom(String str) {
            this.mFrom = str;
        }

        public void setIndex(long j2) {
            this.mIndex = j2;
        }

        public void setMaxNumber(long j2) {
            this.mMaxNumber = j2;
        }

        public void setTo(String str) {
            this.mTo = str;
        }

        public RequestTimeList(String str, String str2, long j2, long j4) {
            this.mFrom = str;
            this.mTo = str2;
            this.mIndex = j2;
            this.mMaxNumber = j4;
        }
    }

    /* loaded from: classes.dex */
    public static class ResizeProperty {
        private long mDefResize;
        private long mResizeRange;

        public ResizeProperty() {
        }

        public long getDefResize() {
            return this.mDefResize;
        }

        public long getResizeRange() {
            return this.mResizeRange;
        }

        public void setDefResize(long j2) {
            this.mDefResize = j2;
        }

        public void setResizeRange(long j2) {
            this.mResizeRange = j2;
        }

        public ResizeProperty(long j2, long j4) {
            this.mResizeRange = j2;
            this.mDefResize = j4;
        }
    }

    /* loaded from: classes.dex */
    public static class Resolution {
        private long mHeight;
        private long mwidth;

        public Resolution() {
        }

        public long getHeight() {
            return this.mHeight;
        }

        public long getWidth() {
            return this.mwidth;
        }

        public void setHeight(long j2) {
            this.mHeight = j2;
        }

        public void setWidth(long j2) {
            this.mwidth = j2;
        }

        public Resolution(long j2, long j4) {
            this.mwidth = j2;
            this.mHeight = j4;
        }
    }

    /* loaded from: classes.dex */
    public interface ResponseListener {
        int onResponse(int i5, Object obj);
    }

    /* loaded from: classes.dex */
    public static class RetGroupedObjIDList {
        private List<GroupObjectIDType> mGrpObjectIDTypeList;
        private long mListNumber;
        private long mTotalNumber;

        public RetGroupedObjIDList() {
        }

        public List<GroupObjectIDType> getGrpObjectIDTypeList() {
            return this.mGrpObjectIDTypeList;
        }

        public long getListNumber() {
            return this.mListNumber;
        }

        public long getTotalNumber() {
            return this.mTotalNumber;
        }

        public void setGrpObjectIDTypeList(List<GroupObjectIDType> list) {
            this.mGrpObjectIDTypeList = list;
        }

        public void setListNumber(long j2) {
            this.mListNumber = j2;
        }

        public void setTotalNumber(long j2) {
            this.mTotalNumber = j2;
        }

        public RetGroupedObjIDList(long j2, long j4, long[] jArr, long[] jArr2, long[] jArr3) {
            this.mTotalNumber = j2;
            this.mListNumber = j4;
            this.mGrpObjectIDTypeList = new ArrayList();
            for (int i5 = 0; i5 < this.mListNumber; i5++) {
                this.mGrpObjectIDTypeList.add(new GroupObjectIDType(jArr[i5], jArr2[i5], jArr3[i5]));
            }
        }
    }

    /* loaded from: classes.dex */
    public static class RetMovieExtProperty {
        private long mFileVersion;
        private long mPlayTime;

        public RetMovieExtProperty() {
        }

        public long getFileVersion() {
            return this.mFileVersion;
        }

        public long getPlayTime() {
            return this.mPlayTime;
        }

        public void setFileVersion(long j2) {
            this.mFileVersion = j2;
        }

        public void setPlayTime(long j2) {
            this.mPlayTime = j2;
        }

        public RetMovieExtProperty(long j2, long j4) {
            this.mFileVersion = j2;
            this.mPlayTime = j4;
        }
    }

    /* loaded from: classes.dex */
    public static class RetObjectData {
        private byte[] mData;
        private long mObjStatus;
        private long mProgress;
        private long mSendSize;
        private long mTotalSize;

        public RetObjectData() {
        }

        public byte[] getData() {
            return this.mData;
        }

        public long getObjStatus() {
            return this.mObjStatus;
        }

        public long getProgress() {
            return this.mProgress;
        }

        public long getSendSize() {
            return this.mSendSize;
        }

        public long getTotalSize() {
            return this.mTotalSize;
        }

        public void setData(byte[] bArr) {
            this.mData = bArr;
        }

        public void setObjStatus(long j2) {
            this.mObjStatus = j2;
        }

        public void setProgress(long j2) {
            this.mProgress = j2;
        }

        public void setSendSize(long j2) {
            this.mSendSize = j2;
        }

        public void setTotalSize(long j2) {
            this.mTotalSize = j2;
        }

        public RetObjectData(long j2, long j4, byte[] bArr) {
            this.mTotalSize = j2;
            this.mSendSize = j4;
            this.mData = bArr;
        }

        public RetObjectData(long j2, long j4, byte[] bArr, long j5, long j6) {
            this.mTotalSize = j2;
            this.mSendSize = j4;
            this.mData = bArr;
            this.mObjStatus = j5;
            this.mProgress = j6;
        }
    }

    /* loaded from: classes.dex */
    public static class RetObjectIDList {
        private long mListNumber;
        private List<ObjectIDType> mObjectIDTypeList;
        private long mTotalNumber;

        public RetObjectIDList() {
        }

        public long getListNumber() {
            return this.mListNumber;
        }

        public List<ObjectIDType> getObjectIDTypeList() {
            return this.mObjectIDTypeList;
        }

        public long getTotalNumber() {
            return this.mTotalNumber;
        }

        public void setListNumber(long j2) {
            this.mListNumber = j2;
        }

        public void setObjectIDTypeList(List<ObjectIDType> list) {
            this.mObjectIDTypeList = list;
        }

        public void setTotalNumber(long j2) {
            this.mTotalNumber = j2;
        }

        public RetObjectIDList(long j2, long j4, long[] jArr, long[] jArr2) {
            this.mTotalNumber = j2;
            this.mListNumber = j4;
            this.mObjectIDTypeList = new ArrayList();
            for (int i5 = 0; i5 < this.mListNumber; i5++) {
                this.mObjectIDTypeList.add(new ObjectIDType(jArr[i5], jArr2[i5]));
            }
        }
    }

    /* loaded from: classes.dex */
    public static class SendObjectData {
        private long mObjStatus;
        private byte[] mObjectData;
        private ObjectIDType mObjectIDType;
        private long mOffset;
        private long mProgress;
        private long mSendObjectIndex;
        private long mSendObjectNumber;
        private long mSendSize;
        private long mTotalSize;

        public SendObjectData() {
        }

        public long getObjStatus() {
            return this.mObjStatus;
        }

        public byte[] getObjectData() {
            return this.mObjectData;
        }

        public ObjectIDType getObjectIDType() {
            return this.mObjectIDType;
        }

        public long getOffset() {
            return this.mOffset;
        }

        public long getProgress() {
            return this.mProgress;
        }

        public long getSendObjectIndex() {
            return this.mSendObjectIndex;
        }

        public long getSendObjectNumber() {
            return this.mSendObjectNumber;
        }

        public long getSendSize() {
            return this.mSendSize;
        }

        public long getTotalSize() {
            return this.mTotalSize;
        }

        public void setObjStatus(long j2) {
            this.mObjStatus = j2;
        }

        public void setObjectData(byte[] bArr) {
            this.mObjectData = bArr;
        }

        public void setObjectIDType(ObjectIDType objectIDType) {
            this.mObjectIDType = objectIDType;
        }

        public void setOffset(long j2) {
            this.mOffset = j2;
        }

        public void setProgress(long j2) {
            this.mProgress = j2;
        }

        public void setSendObjectIndex(long j2) {
            this.mSendObjectIndex = j2;
        }

        public void setSendObjectNumber(long j2) {
            this.mSendObjectNumber = j2;
        }

        public void setSendSize(long j2) {
            this.mSendSize = j2;
        }

        public void setTotalSize(long j2) {
            this.mTotalSize = j2;
        }

        public SendObjectData(long j2, long j4, long j5, long j6, long j7, byte[] bArr, long j8, long j9) {
            this.mObjectIDType = new ObjectIDType(j2, j4);
            this.mOffset = j5;
            this.mTotalSize = j6;
            this.mSendSize = j7;
            this.mObjectData = bArr;
            this.mSendObjectNumber = j8;
            this.mSendObjectIndex = j9;
        }

        public SendObjectData(long j2, long j4, long j5, long j6, long j7, byte[] bArr, long j8, long j9, long j10, long j11) {
            this.mObjectIDType = new ObjectIDType(j2, j4);
            this.mOffset = j5;
            this.mTotalSize = j6;
            this.mSendSize = j7;
            this.mObjectData = bArr;
            this.mSendObjectNumber = j8;
            this.mSendObjectIndex = j9;
            this.mObjStatus = j10;
            this.mProgress = j11;
        }
    }

    /* loaded from: classes.dex */
    public static class SendObjectInformation {
        private long mApproxDataSize;
        private ObjectIDType mObjectIDType;
        private long mObjectSize;
        private Resolution mResolution;
        private long mSendObjectIndex;
        private long mSendObjectNumber;
        private byte[] mThumbnailData;
        private long mThumbnailSize;

        public SendObjectInformation() {
        }

        public long getApproxDataSize() {
            return this.mApproxDataSize;
        }

        public ObjectIDType getObjectIDType() {
            return this.mObjectIDType;
        }

        public long getObjectSize() {
            return this.mObjectSize;
        }

        public Resolution getResolution() {
            return this.mResolution;
        }

        public long getSendObjectIndex() {
            return this.mSendObjectIndex;
        }

        public long getSendObjectNumber() {
            return this.mSendObjectNumber;
        }

        public byte[] getThumbnailData() {
            return this.mThumbnailData;
        }

        public long getThumbnailSize() {
            return this.mThumbnailSize;
        }

        public void setApproxDataSize(long j2) {
            this.mApproxDataSize = j2;
        }

        public void setObjectIDType(ObjectIDType objectIDType) {
            this.mObjectIDType = objectIDType;
        }

        public void setObjectSize(long j2) {
            this.mObjectSize = j2;
        }

        public void setResolution(Resolution resolution) {
            this.mResolution = resolution;
        }

        public void setSendObjectIndex(long j2) {
            this.mSendObjectIndex = j2;
        }

        public void setSendObjectNumber(long j2) {
            this.mSendObjectNumber = j2;
        }

        public void setThumbnailData(byte[] bArr) {
            this.mThumbnailData = bArr;
        }

        public void setThumbnailSize(long j2) {
            this.mThumbnailSize = j2;
        }

        public SendObjectInformation(long j2, long j4, long j5, long j6, long j7, long j8, long j9, long j10, byte[] bArr) {
            this.mObjectIDType = new ObjectIDType(j2, j4);
            this.mResolution = new Resolution(j5, j6);
            this.mObjectSize = j7;
            this.mSendObjectNumber = j8;
            this.mSendObjectIndex = j9;
            this.mThumbnailSize = j10;
            this.mThumbnailData = bArr;
        }

        public SendObjectInformation(long j2, long j4, long j5, long j6, long j7, long j8, long j9, long j10, byte[] bArr, long j11) {
            this.mObjectIDType = new ObjectIDType(j2, j4);
            this.mResolution = new Resolution(j5, j6);
            this.mObjectSize = j7;
            this.mSendObjectNumber = j8;
            this.mSendObjectIndex = j9;
            this.mThumbnailSize = j10;
            this.mThumbnailData = bArr;
            this.mApproxDataSize = j11;
        }
    }

    /* loaded from: classes.dex */
    public static class ServiceInfo {
        private int mPortNum;
        private long mServiceType;
        private long mServiceVer;

        public ServiceInfo() {
        }

        public int getPortNum() {
            return this.mPortNum;
        }

        public long getServiceType() {
            return this.mServiceType;
        }

        public long getServiceVer() {
            return this.mServiceVer;
        }

        public void setPortNum(int i5) {
            this.mPortNum = i5;
        }

        public void setServiceType(long j2) {
            this.mServiceType = j2;
        }

        public void setServiceVer(long j2) {
            this.mServiceVer = j2;
        }

        public ServiceInfo(int i5, long j2, long j4) {
            this.mPortNum = i5;
            this.mServiceType = j2;
            this.mServiceVer = j4;
        }
    }

    /* loaded from: classes.dex */
    public static class ThumbnailData {
        private String mCaptureDate;
        private long mDataSize;
        private GPSData mGPSData;
        private int mGPSExist;
        private long mObjectID;
        private byte[] mThumbnailData;
        private long mThumbnailSize;

        public ThumbnailData() {
        }

        public String getCaptureDate() {
            return this.mCaptureDate;
        }

        public long getDataSize() {
            return this.mDataSize;
        }

        public GPSData getGPSData() {
            return this.mGPSData;
        }

        public int getGPSExist() {
            return this.mGPSExist;
        }

        public long getObjectID() {
            return this.mObjectID;
        }

        public byte[] getThumbnailData() {
            return this.mThumbnailData;
        }

        public long getThumbnailSize() {
            return this.mThumbnailSize;
        }

        public void setCaptureDate(String str) {
            this.mCaptureDate = str;
        }

        public void setDataSize(long j2) {
            this.mDataSize = j2;
        }

        public void setGpsData(GPSData gPSData) {
            this.mGPSData = gPSData;
        }

        public void setGpsExist(int i5) {
            this.mGPSExist = i5;
        }

        public void setObjectID(long j2) {
            this.mObjectID = j2;
        }

        public void setThumbnailData(byte[] bArr) {
            this.mThumbnailData = bArr;
        }

        public void setThumbnailSize(long j2) {
            this.mThumbnailSize = j2;
        }

        public ThumbnailData(long j2, long j4, String str, int i5, int[] iArr, long[] jArr, int[] iArr2, long[] jArr2, int i6, long j5, String str2, long j6, byte[] bArr) {
            this.mObjectID = j2;
            this.mDataSize = j4;
            this.mCaptureDate = str;
            this.mGPSExist = i5;
            Fraction[] fractionArr = new Fraction[3];
            for (int i7 = 0; i7 < 3; i7++) {
                fractionArr[i7] = new Fraction(iArr[i7], jArr[i7]);
            }
            Fraction[] fractionArr2 = new Fraction[3];
            for (int i8 = 0; i8 < 3; i8++) {
                fractionArr2[i8] = new Fraction(iArr2[i8], jArr2[i8]);
            }
            this.mGPSData = new GPSData(fractionArr, fractionArr2, new Fraction(i6, j5), str2);
            this.mThumbnailSize = j6;
            this.mThumbnailData = bArr;
        }
    }

    /* loaded from: classes.dex */
    public static class ThumbnailDataList {
        private ThumbnailData[] mThumbnailDataList;

        public ThumbnailDataList() {
        }

        public ThumbnailData[] getThumbnailDataList() {
            return this.mThumbnailDataList;
        }

        public void setThumbnailDataList(Object[] objArr) {
            this.mThumbnailDataList = (ThumbnailData[]) objArr;
        }

        public ThumbnailDataList(Object[] objArr) {
            this.mThumbnailDataList = (ThumbnailData[]) objArr;
        }
    }

    /* loaded from: classes.dex */
    public static class UsecaseInformation {
        private String mName;
        long mStatus;
        private Version mVersion;

        public UsecaseInformation() {
        }

        public String getName() {
            return this.mName;
        }

        public long getStatus() {
            return this.mStatus;
        }

        public Version getVersion() {
            return this.mVersion;
        }

        public Object getVersionObject() {
            return this.mVersion;
        }

        public void setName(String str) {
            this.mName = str;
        }

        public void setStatus(long j2) {
            this.mStatus = j2;
        }

        public void setVersion(Version version) {
            this.mVersion = version;
        }

        public UsecaseInformation(String str, long j2, long j4, long j5) {
            this.mName = str;
            this.mVersion = new Version(j2, j4);
            this.mStatus = j5;
        }
    }

    /* loaded from: classes.dex */
    public static class Version {
        private long mMajorVersion;
        private long mMinorVersion;

        public Version() {
        }

        public long getMajorVersion() {
            return this.mMajorVersion;
        }

        public long getMinorVersion() {
            return this.mMinorVersion;
        }

        public void setMajorVersion(long j2) {
            this.mMajorVersion = j2;
        }

        public void setMinorVersion(long j2) {
            this.mMinorVersion = j2;
        }

        public Version(long j2, long j4) {
            this.mMajorVersion = j2;
            this.mMinorVersion = j4;
        }
    }

    public ImageLinkService() {
        try {
            System.loadLibrary("imagelink");
            System.loadLibrary("imagelinkjni");
            if (!nativeInit()) {
                throw new RuntimeException("native init failed.");
            }
        } catch (NullPointerException | SecurityException | UnsatisfiedLinkError unused) {
            throw new RuntimeException("native load failed.");
        }
    }

    private native int nativeCreate(String str, String str2, String str3, String str4, long j2, long j4, ExtensionalAction[] extensionalActionArr, RequestListener requestListener);

    private native void nativeDestroy();

    private native void nativeFinalize();

    private native int nativeGetSrvInfo(ServiceInfo serviceInfo);

    private native boolean nativeInit();

    private native int nativeRequest(int i5, Object obj);

    public final int a(RequestListener n22, ApplicationParameter applicationParameter, ExtensionalActionList extensionalActionList) {
        String str;
        String str2;
        String str3;
        String str4;
        long j2;
        long j4;
        if (a != 0) {
            return -1;
        }
        MyDeviceInformation deviceInformation = applicationParameter.getDeviceInformation();
        if (deviceInformation != null) {
            String modelName = deviceInformation.getModelName();
            String friendlyName = deviceInformation.getFriendlyName();
            String targetID = deviceInformation.getTargetID();
            str4 = deviceInformation.getVendorExtVersion();
            str2 = friendlyName;
            str3 = targetID;
            str = modelName;
        } else {
            str = null;
            str2 = null;
            str3 = null;
            str4 = null;
        }
        Version extensionalActionVersion = extensionalActionList.getExtensionalActionVersion();
        if (extensionalActionVersion != null) {
            long majorVersion = extensionalActionVersion.getMajorVersion();
            j4 = extensionalActionVersion.getMinorVersion();
            j2 = majorVersion;
        } else {
            j2 = 0;
            j4 = 0;
        }
        ExtensionalAction[] extensionalActionArr = (ExtensionalAction[]) extensionalActionList.getExtensionalActionList().toArray(new ExtensionalAction[0]);
        ImageLinkCallBack.setRequestListener(n22);
        int nativeCreate = nativeCreate(str, str2, str3, str4, j2, j4, extensionalActionArr, n22);
        if (nativeCreate == 0) {
            a = 1;
        }
        return nativeCreate;
    }

    public final int b(DestroyEndListener s22) {
        if (a != 1) {
            return -1;
        }
        ImageLinkCallBack.setDestroyListener(s22);
        nativeDestroy();
        return 0;
    }

    public final int c(ServiceInfo serviceInfo) {
        return nativeGetSrvInfo(serviceInfo);
    }

    public final int d(int i5, Object obj, ResponseListener responseListener) {
        if (a != 1) {
            return -1;
        }
        ImageLinkCallBack.setResponseListener(i5, responseListener);
        return nativeRequest(i5, obj);
    }

    protected final void finalize() throws Throwable {
        nativeFinalize();
        super.finalize();
    }
}
