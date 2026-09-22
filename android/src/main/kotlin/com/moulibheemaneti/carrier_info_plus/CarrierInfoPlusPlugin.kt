package com.moulibheemaneti.carrier_info_plus

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.telephony.euicc.EuiccManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

private const val CHANNEL_NAME = "carrier_info_plus"
private const val PERMISSION_REQUEST_CODE = 0xC1F0

/**
 * Reads cellular state from [TelephonyManager] and [SubscriptionManager].
 *
 * Every read is defensive. OEMs return nulls, empty strings and SecurityExceptions
 * from these APIs well outside what the documentation admits to, and a carrier
 * lookup is never important enough to crash an app over. Anything unreadable
 * degrades to null and is explained through the `support` block instead.
 */
class CarrierInfoPlusPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onDetachedFromActivity() {
        // A pending prompt cannot survive losing the activity, so settle it
        // rather than leaving the Dart future hanging forever.
        pendingPermissionResult?.success(hasPhoneStatePermission())
        pendingPermissionResult = null
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCarrierInfo" -> result.success(collect())
            "hasPermission" -> result.success(hasPhoneStatePermission())
            "requestPermission" -> requestPhoneStatePermission(result)
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------- permissions

    private fun hasPhoneStatePermission(): Boolean =
        context.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) ==
            PackageManager.PERMISSION_GRANTED

    private fun requestPhoneStatePermission(result: MethodChannel.Result) {
        if (hasPhoneStatePermission()) {
            result.success(true)
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(
                "no_activity",
                "Cannot request a permission without a foreground activity.",
                null,
            )
            return
        }
        if (pendingPermissionResult != null) {
            result.error(
                "already_requesting",
                "A permission request is already in flight.",
                null,
            )
            return
        }
        pendingPermissionResult = result
        currentActivity.requestPermissions(
            arrayOf(Manifest.permission.READ_PHONE_STATE),
            PERMISSION_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val result = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        // An empty grantResults means the request was cancelled, which counts
        // as "not granted" rather than as an error.
        result.success(
            grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED,
        )
        return true
    }

    // ------------------------------------------------------------------- reading

    private fun collect(): Map<String, Any?> {
        val telephony = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        val granted = hasPhoneStatePermission()
        val limitation = when {
            telephony == null -> "noTelephonyHardware"
            !granted -> "permissionNotGranted"
            else -> "none"
        }
        return mapOf(
            "simCards" to readSimCards(telephony, granted),
            "capabilities" to readCapabilities(telephony, granted),
            "network" to readNetwork(telephony, granted),
            "support" to mapOf(
                "carrierIdentityAvailable" to (telephony != null),
                "perSimDataAvailable" to (telephony != null && granted),
                "permissionGranted" to granted,
                "limitation" to limitation,
            ),
        )
    }

    private fun readSimCards(
        telephony: TelephonyManager?,
        granted: Boolean,
    ): List<Map<String, Any?>> {
        if (telephony == null) return emptyList()
        if (!granted) return permissionFreeSimCards(telephony)

        val subscriptions =
            context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE)
                as? SubscriptionManager
                ?: return permissionFreeSimCards(telephony)

        val active = runCatching { subscriptions.activeSubscriptionInfoList }
            .getOrNull()
            ?: return permissionFreeSimCards(telephony)

        return active.map { info -> mapSubscription(telephony, subscriptions, info) }
    }

    /**
     * The subset readable without `READ_PHONE_STATE`.
     *
     * [TelephonyManager] still exposes the active SIM's operator, country and
     * slot state permission-free. It cannot see a second SIM, so this always
     * returns at most one entry — a deliberate under-report, flagged through
     * `support.perSimDataAvailable`.
     */
    private fun permissionFreeSimCards(telephony: TelephonyManager): List<Map<String, Any?>> {
        val simState = runCatching { telephony.simState }
            .getOrDefault(TelephonyManager.SIM_STATE_UNKNOWN)
        if (simState == TelephonyManager.SIM_STATE_ABSENT) return emptyList()

        val operator = runCatching { telephony.simOperator }.getOrNull().orEmpty()
        return listOf(
            mapOf(
                "subscriptionId" to null,
                "slotIndex" to null,
                "carrierName" to runCatching { telephony.simOperatorName }.getOrNull().nullIfBlank(),
                "displayName" to null,
                "mobileCountryCode" to operator.take(3).nullIfBlank(),
                "mobileNetworkCode" to operator.drop(3).nullIfBlank(),
                "countryIso" to runCatching { telephony.simCountryIso }.getOrNull().nullIfBlank(),
                "carrierId" to null,
                "isEmbedded" to false,
                "isRoaming" to runCatching { telephony.isNetworkRoaming }.getOrDefault(false),
                "simState" to simStateName(simState),
            ),
        )
    }

    private fun mapSubscription(
        telephony: TelephonyManager,
        subscriptions: SubscriptionManager,
        info: SubscriptionInfo,
    ): Map<String, Any?> {
        val mcc: String?
        val mnc: String?
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            mcc = info.mccString.nullIfBlank()
            mnc = info.mncString.nullIfBlank()
        } else {
            // The int accessors drop leading zeros, so pad them back. MCC is
            // always three digits; MNC is two or three and cannot be recovered
            // beyond two, which is why Android replaced these in API 29.
            @Suppress("DEPRECATION")
            mcc = info.mcc.takeIf { it != 0 }?.toString()?.padStart(3, '0')
            @Suppress("DEPRECATION")
            mnc = info.mnc.takeIf { it != 0 }?.toString()?.padStart(2, '0')
        }

        val slotState = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            runCatching { telephony.getSimState(info.simSlotIndex) }.getOrNull()
        } else {
            null
        }

        val carrierId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            info.carrierId.takeIf { it != TelephonyManager.UNKNOWN_CARRIER_ID }
        } else {
            null
        }

        val isEmbedded = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1 &&
            runCatching { info.isEmbedded }.getOrDefault(false)

        return mapOf(
            "subscriptionId" to info.subscriptionId,
            "slotIndex" to info.simSlotIndex,
            "carrierName" to info.carrierName?.toString().nullIfBlank(),
            "displayName" to info.displayName?.toString().nullIfBlank(),
            "mobileCountryCode" to mcc,
            "mobileNetworkCode" to mnc,
            "countryIso" to info.countryIso.nullIfBlank(),
            "carrierId" to carrierId,
            "isEmbedded" to isEmbedded,
            "isRoaming" to runCatching {
                subscriptions.isNetworkRoaming(info.subscriptionId)
            }.getOrDefault(false),
            "simState" to simStateName(slotState ?: telephony.simState),
        )
    }

    private fun readCapabilities(
        telephony: TelephonyManager?,
        granted: Boolean,
    ): Map<String, Any?> {
        if (telephony == null) {
            return mapOf(
                "isVoiceCapable" to false,
                "isSmsCapable" to false,
                "isDataCapable" to false,
                "isDataEnabled" to false,
                "isMultiSimSupported" to false,
                "supportsEmbeddedSim" to false,
            )
        }

        val isDataCapable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            runCatching { telephony.isDataCapable }.getOrDefault(false)
        } else {
            // No public equivalent below API 33; having any phone radio at all
            // is the closest honest approximation.
            runCatching { telephony.phoneType != TelephonyManager.PHONE_TYPE_NONE }
                .getOrDefault(false)
        }

        val isDataEnabled =
            if (granted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                runCatching { telephony.isDataEnabled }.getOrDefault(false)
            } else {
                false
            }

        val isMultiSimSupported =
            if (granted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                runCatching {
                    telephony.isMultiSimSupported == TelephonyManager.MULTISIM_ALLOWED
                }.getOrDefault(false)
            } else {
                @Suppress("DEPRECATION")
                runCatching { telephony.phoneCount > 1 }.getOrDefault(false)
            }

        val supportsEmbeddedSim = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            runCatching {
                (context.getSystemService(Context.EUICC_SERVICE) as? EuiccManager)?.isEnabled
            }.getOrNull() == true

        return mapOf(
            "isVoiceCapable" to runCatching { telephony.isVoiceCapable }.getOrDefault(false),
            "isSmsCapable" to runCatching { telephony.isSmsCapable }.getOrDefault(false),
            "isDataCapable" to isDataCapable,
            "isDataEnabled" to isDataEnabled,
            "isMultiSimSupported" to isMultiSimSupported,
            "supportsEmbeddedSim" to supportsEmbeddedSim,
        )
    }

    private fun readNetwork(
        telephony: TelephonyManager?,
        granted: Boolean,
    ): Map<String, Any?> {
        val radios = mutableListOf<String>()
        if (telephony != null && granted) {
            val networkType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                runCatching { telephony.dataNetworkType }.getOrNull()
            } else {
                @Suppress("DEPRECATION")
                runCatching { telephony.networkType }.getOrNull()
            }
            if (networkType != null && networkType != TelephonyManager.NETWORK_TYPE_UNKNOWN) {
                radios.add(radioName(networkType))
            }
        }

        // Android has no per-app cellular restriction to mirror iOS's
        // CTCellularData, so the device-wide data switch is the closest
        // equivalent. Unknown without the permission to read it.
        val dataState = when {
            telephony == null -> "unknown"
            !granted || Build.VERSION.SDK_INT < Build.VERSION_CODES.O -> "unknown"
            runCatching { telephony.isDataEnabled }.getOrDefault(false) -> "notRestricted"
            else -> "restricted"
        }

        return mapOf(
            "radioTechnologies" to radios,
            "operatorName" to
                runCatching { telephony?.networkOperatorName }.getOrNull().nullIfBlank(),
            "countryIso" to
                runCatching { telephony?.networkCountryIso }.getOrNull().nullIfBlank(),
            "cellularDataState" to dataState,
        )
    }

    // ------------------------------------------------------------------ mapping

    private fun simStateName(state: Int): String = when (state) {
        TelephonyManager.SIM_STATE_ABSENT -> "absent"
        TelephonyManager.SIM_STATE_PIN_REQUIRED -> "pinRequired"
        TelephonyManager.SIM_STATE_PUK_REQUIRED -> "pukRequired"
        TelephonyManager.SIM_STATE_NETWORK_LOCKED -> "networkLocked"
        TelephonyManager.SIM_STATE_READY -> "ready"
        TelephonyManager.SIM_STATE_NOT_READY -> "notReady"
        TelephonyManager.SIM_STATE_PERM_DISABLED -> "permanentlyDisabled"
        TelephonyManager.SIM_STATE_CARD_IO_ERROR -> "cardIoError"
        TelephonyManager.SIM_STATE_CARD_RESTRICTED -> "cardRestricted"
        else -> "unknown"
    }

    private fun radioName(networkType: Int): String = when (networkType) {
        TelephonyManager.NETWORK_TYPE_GPRS -> "gprs"
        TelephonyManager.NETWORK_TYPE_EDGE -> "edge"
        TelephonyManager.NETWORK_TYPE_GSM -> "gsm"
        TelephonyManager.NETWORK_TYPE_CDMA -> "cdma"
        TelephonyManager.NETWORK_TYPE_1xRTT -> "oneXrtt"
        TelephonyManager.NETWORK_TYPE_IDEN -> "iden"
        TelephonyManager.NETWORK_TYPE_UMTS -> "umts"
        TelephonyManager.NETWORK_TYPE_HSDPA -> "hsdpa"
        TelephonyManager.NETWORK_TYPE_HSUPA -> "hsupa"
        TelephonyManager.NETWORK_TYPE_HSPA -> "hspa"
        TelephonyManager.NETWORK_TYPE_HSPAP -> "hspap"
        TelephonyManager.NETWORK_TYPE_EVDO_0 -> "evdo0"
        TelephonyManager.NETWORK_TYPE_EVDO_A -> "evdoA"
        TelephonyManager.NETWORK_TYPE_EVDO_B -> "evdoB"
        TelephonyManager.NETWORK_TYPE_EHRPD -> "ehrpd"
        TelephonyManager.NETWORK_TYPE_TD_SCDMA -> "tdScdma"
        TelephonyManager.NETWORK_TYPE_LTE -> "lte"
        TelephonyManager.NETWORK_TYPE_IWLAN -> "iwlan"
        TelephonyManager.NETWORK_TYPE_NR -> "nr"
        else -> "unknown"
    }
}

/** Treats blank strings as absent, which these APIs use interchangeably with null. */
private fun String?.nullIfBlank(): String? = if (isNullOrBlank()) null else this
