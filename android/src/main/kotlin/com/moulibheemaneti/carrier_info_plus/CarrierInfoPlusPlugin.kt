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
import io.flutter.plugin.common.PluginRegistry
import kotlin.coroutines.resume
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine

/** Distinctive enough not to collide with an app's own permission requests. */
private const val PERMISSION_REQUEST_CODE = 0xC1F0

/**
 * Reads cellular state from [TelephonyManager] and [SubscriptionManager].
 *
 * Every read is defensive. OEMs return nulls, empty strings and
 * SecurityExceptions from these APIs well outside what the documentation admits
 * to, and a carrier lookup is never important enough to crash an app over.
 * Anything unreadable degrades to null or a safe default and is explained
 * through the `support` block instead.
 *
 * Two tiers of data exist here, and the split is not arbitrary:
 *
 *  - Without `READ_PHONE_STATE`, [TelephonyManager] still reports the active
 *    SIM's operator, country and state. It cannot see a second SIM.
 *  - With it, [SubscriptionManager] enumerates every subscription.
 *
 * The permission-free tier deliberately under-reports rather than guessing, and
 * says so through `support.perSimDataAvailable`.
 *
 * ## Threading
 *
 * [getCarrierInfo] is bound to a background task queue, because it makes
 * roughly fifteen binder IPC calls and has no business holding the host app's
 * main thread. Everything it touches -- [TelephonyManager],
 * [SubscriptionManager], [EuiccManager] and the permission check -- is safe off
 * the main thread.
 *
 * Everything else stays on the platform thread. [hasPermission] is a trivial
 * local check, and [requestPermission] puts a system dialog on screen, which
 * belongs on the main thread. [activity] and [pendingPermission] are therefore
 * only ever touched from the platform thread and need no synchronisation;
 * [context] is the one field crossing threads.
 */
class CarrierInfoPlusPlugin :
    FlutterPlugin,
    ActivityAware,
    CarrierInfoApi,
    PluginRegistry.RequestPermissionsResultListener {

    /**
     * Written on the platform thread when the engine attaches, read on the
     * background queue by [getCarrierInfo]. Volatile so the background thread
     * cannot observe a stale value, and nullable so a call that outlives
     * detachment fails honestly instead of throwing
     * UninitializedPropertyAccessException.
     */
    @Volatile
    private var context: Context? = null

    private var activity: Activity? = null
    private var pendingPermission: CancellableContinuation<Boolean>? = null

    // ------------------------------------------------------------- lifecycle

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        CarrierInfoApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CarrierInfoApi.setUp(binding.binaryMessenger, null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onDetachedFromActivity() {
        // A prompt cannot survive losing the activity. Settle the caller with
        // whatever the real answer is now rather than leaving the Dart future
        // hanging forever.
        resumePendingPermission(hasPermission())
        activity = null
    }

    // ------------------------------------------------------------ permission

    override fun hasPermission(): Boolean {
        val context = this.context ?: return false
        return context.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) ==
            PackageManager.PERMISSION_GRANTED
    }

    override suspend fun requestPermission(): Boolean {
        if (hasPermission()) return true

        val currentActivity = activity
            ?: throw FlutterError(
                "no_activity",
                "Cannot request a permission without a foreground activity.",
            )
        if (pendingPermission != null) {
            throw FlutterError("already_requesting", "A permission request is already in flight.")
        }

        return suspendCancellableCoroutine { continuation ->
            pendingPermission = continuation
            continuation.invokeOnCancellation { pendingPermission = null }
            currentActivity.requestPermissions(
                arrayOf(Manifest.permission.READ_PHONE_STATE),
                PERMISSION_REQUEST_CODE,
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        // An empty grantResults means the request was cancelled, which counts as
        // "not granted" rather than as an error.
        resumePendingPermission(
            grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED,
        )
        return true
    }

    /** Resumes at most once; resuming a continuation twice would crash. */
    private fun resumePendingPermission(granted: Boolean) {
        val continuation = pendingPermission ?: return
        pendingPermission = null
        if (continuation.isActive) continuation.resume(granted)
    }

    // --------------------------------------------------------------- reading

    override fun getCarrierInfo(): PlatformCarrierInfo {
        // Read the volatile exactly once: a detach racing with this call should
        // not make the snapshot internally inconsistent.
        val context = this.context
            ?: throw FlutterError(
                "detached",
                "The plugin is no longer attached to a Flutter engine.",
            )

        val telephony = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        val subscriptions = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE)
            as? SubscriptionManager
        val hasTelephony = telephony != null &&
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
        val granted = hasPermission()

        val limitation = when {
            // Ordered most fundamental first: there is no point telling an app to
            // prompt for a permission on a device with no radio to read.
            !hasTelephony -> PlatformDataLimitation.NO_TELEPHONY_HARDWARE
            !granted -> PlatformDataLimitation.PERMISSION_NOT_GRANTED
            else -> PlatformDataLimitation.NONE
        }

        return PlatformCarrierInfo(
            simCards = readSimCards(telephony, subscriptions, hasTelephony, granted),
            capabilities = readCapabilities(context, telephony, hasTelephony),
            network = readNetwork(telephony, granted),
            support = PlatformSupportInfo(
                carrierIdentityAvailable = hasTelephony,
                perSimDataAvailable = hasTelephony && granted,
                permissionGranted = granted,
                limitation = limitation,
            ),
            simCount = readSimCount(subscriptions, granted),
        )
    }

    /**
     * How many SIMs the platform admits to, or null when it will not say.
     *
     * `getActiveSubscriptionInfoCount` needs `READ_PHONE_STATE`, so the count is
     * genuinely unknown without it -- not zero, and not one.
     */
    private fun readSimCount(subscriptions: SubscriptionManager?, granted: Boolean): Long? {
        if (subscriptions == null || !granted) return null
        return runCatching { subscriptions.activeSubscriptionInfoCount.toLong() }.getOrNull()
    }

    private fun readSimCards(
        telephony: TelephonyManager?,
        subscriptions: SubscriptionManager?,
        hasTelephony: Boolean,
        granted: Boolean,
    ): List<PlatformSimCard> {
        if (telephony == null || !hasTelephony) return emptyList()
        if (!granted || subscriptions == null) return permissionFreeSimCards(telephony)

        val active = runCatching { subscriptions.activeSubscriptionInfoList }.getOrNull()
            ?: return permissionFreeSimCards(telephony)

        // API 24, and readable without any runtime permission.
        val defaultData = runCatching { SubscriptionManager.getDefaultDataSubscriptionId() }
            .getOrDefault(SubscriptionManager.INVALID_SUBSCRIPTION_ID)
        val defaultVoice = runCatching { SubscriptionManager.getDefaultVoiceSubscriptionId() }
            .getOrDefault(SubscriptionManager.INVALID_SUBSCRIPTION_ID)

        return active.map { info ->
            mapSubscription(telephony, subscriptions, info, defaultData, defaultVoice)
        }
    }

    /**
     * The subset readable without `READ_PHONE_STATE`.
     *
     * [TelephonyManager] exposes the active SIM's operator, country and state
     * permission-free. It cannot see a second SIM, so this returns at most one
     * entry -- a deliberate under-report, flagged through
     * `support.perSimDataAvailable`.
     *
     * That single entry *is* the default subscription, since a default
     * [TelephonyManager] is bound to it, so both default flags are true here
     * without needing to compare subscription ids we do not have.
     */
    private fun permissionFreeSimCards(telephony: TelephonyManager): List<PlatformSimCard> {
        val simState = runCatching { telephony.simState }
            .getOrDefault(TelephonyManager.SIM_STATE_UNKNOWN)
        if (simState == TelephonyManager.SIM_STATE_ABSENT) return emptyList()

        // Documented as only meaningful once the SIM is READY; blank otherwise.
        val operator = runCatching { telephony.simOperator }.getOrNull().orEmpty()

        return listOf(
            PlatformSimCard(
                isEmbedded = false,
                isRoaming = runCatching { telephony.isNetworkRoaming }.getOrDefault(false),
                simState = simState.toPlatformSimState(),
                isDefaultData = true,
                isDefaultVoice = true,
                carrierName = runCatching { telephony.simOperatorName }.getOrNull().nullIfBlank(),
                mobileCountryCode = operator.take(3).nullIfBlank(),
                mobileNetworkCode = operator.drop(3).nullIfBlank(),
                countryIso = runCatching { telephony.simCountryIso }.getOrNull().nullIfBlank(),
            ),
        )
    }

    private fun mapSubscription(
        telephony: TelephonyManager,
        subscriptions: SubscriptionManager,
        info: SubscriptionInfo,
        defaultDataSubId: Int,
        defaultVoiceSubId: Int,
    ): PlatformSimCard {
        val mcc: String?
        val mnc: String?
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            mcc = info.mccString.nullIfBlank()
            mnc = info.mncString.nullIfBlank()
        } else {
            // The int accessors drop leading zeros, so pad them back. MCC is
            // always three digits; a three-digit MNC cannot be recovered at all,
            // which is exactly why API 29 replaced these.
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
            info.carrierId.takeIf { it != TelephonyManager.UNKNOWN_CARRIER_ID }?.toLong()
        } else {
            null
        }

        // SubscriptionInfo.isEmbedded is API 28, not 25.
        val isEmbedded = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            runCatching { info.isEmbedded }.getOrDefault(false)

        return PlatformSimCard(
            isEmbedded = isEmbedded,
            isRoaming = runCatching {
                subscriptions.isNetworkRoaming(info.subscriptionId)
            }.getOrDefault(false),
            simState = (slotState ?: telephony.simState).toPlatformSimState(),
            isDefaultData = info.subscriptionId == defaultDataSubId,
            isDefaultVoice = info.subscriptionId == defaultVoiceSubId,
            subscriptionId = info.subscriptionId.toLong(),
            slotIndex = info.simSlotIndex.toLong(),
            carrierName = info.carrierName?.toString().nullIfBlank(),
            displayName = info.displayName?.toString().nullIfBlank(),
            mobileCountryCode = mcc,
            mobileNetworkCode = mnc,
            countryIso = info.countryIso.nullIfBlank(),
            carrierId = carrierId,
        )
    }

    private fun readCapabilities(
        context: Context,
        telephony: TelephonyManager?,
        hasTelephony: Boolean,
    ): PlatformTelephonyCapabilities {
        if (telephony == null || !hasTelephony) {
            return PlatformTelephonyCapabilities(
                isVoiceCapable = false,
                isSmsCapable = false,
                isDataCapable = false,
                isDataEnabled = false,
                isMultiSimSupported = false,
                supportsEmbeddedSim = false,
            )
        }

        // isDataCapable is API 31 and wants ACCESS_NETWORK_STATE. Below that,
        // owning any phone radio at all is the closest honest approximation.
        val isDataCapable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            runCatching { telephony.isDataCapable }.getOrDefault(false)
        } else {
            runCatching { telephony.phoneType != TelephonyManager.PHONE_TYPE_NONE }
                .getOrDefault(false)
        }

        // isDataEnabled is API 26. Note it does *not* want READ_PHONE_STATE: the
        // documented set is ACCESS_NETWORK_STATE, MODIFY_PHONE_STATE or
        // READ_BASIC_PHONE_STATE. So it is attempted regardless of our own
        // permission state, and simply fails closed if the app declared none of
        // them.
        val isDataEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            runCatching { telephony.isDataEnabled }.getOrDefault(false)
        } else {
            false
        }

        // isMultiSimSupported is API 29, and does want READ_PHONE_STATE.
        val isMultiSimSupported = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
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

        return PlatformTelephonyCapabilities(
            isVoiceCapable = runCatching { telephony.isVoiceCapable }.getOrDefault(false),
            isSmsCapable = runCatching { telephony.isSmsCapable }.getOrDefault(false),
            isDataCapable = isDataCapable,
            isDataEnabled = isDataEnabled,
            isMultiSimSupported = isMultiSimSupported,
            supportsEmbeddedSim = supportsEmbeddedSim,
        )
    }

    private fun readNetwork(
        telephony: TelephonyManager?,
        granted: Boolean,
    ): PlatformNetworkInfo {
        val radios = mutableListOf<PlatformRadioAccessTechnology>()
        // getDataNetworkType is API 24 but requires READ_PHONE_STATE (or
        // READ_BASIC_PHONE_STATE, or carrier privileges), so it stays gated.
        if (telephony != null && granted) {
            val networkType = runCatching { telephony.dataNetworkType }.getOrNull()
            if (networkType != null && networkType != TelephonyManager.NETWORK_TYPE_UNKNOWN) {
                radios.add(networkType.toPlatformRadioAccessTechnology())
            }
        }

        // Android has no per-app cellular restriction to mirror iOS's
        // CTCellularData, so the device-wide data switch is the closest
        // equivalent. Unknown when we could not read it at all.
        val dataEnabled = if (telephony != null &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
        ) {
            runCatching { telephony.isDataEnabled }.getOrNull()
        } else {
            null
        }
        val dataState = when (dataEnabled) {
            null -> PlatformCellularDataState.UNKNOWN
            true -> PlatformCellularDataState.NOT_RESTRICTED
            false -> PlatformCellularDataState.RESTRICTED
        }

        return PlatformNetworkInfo(
            radioTechnologies = radios,
            cellularDataState = dataState,
            operatorName = runCatching { telephony?.networkOperatorName }.getOrNull().nullIfBlank(),
            countryIso = runCatching { telephony?.networkCountryIso }.getOrNull().nullIfBlank(),
        )
    }
}

// ------------------------------------------------------------------- mapping

private fun Int.toPlatformSimState(): PlatformSimState = when (this) {
    TelephonyManager.SIM_STATE_ABSENT -> PlatformSimState.ABSENT
    TelephonyManager.SIM_STATE_PIN_REQUIRED -> PlatformSimState.PIN_REQUIRED
    TelephonyManager.SIM_STATE_PUK_REQUIRED -> PlatformSimState.PUK_REQUIRED
    TelephonyManager.SIM_STATE_NETWORK_LOCKED -> PlatformSimState.NETWORK_LOCKED
    TelephonyManager.SIM_STATE_READY -> PlatformSimState.READY
    TelephonyManager.SIM_STATE_NOT_READY -> PlatformSimState.NOT_READY
    TelephonyManager.SIM_STATE_PERM_DISABLED -> PlatformSimState.PERMANENTLY_DISABLED
    TelephonyManager.SIM_STATE_CARD_IO_ERROR -> PlatformSimState.CARD_IO_ERROR
    TelephonyManager.SIM_STATE_CARD_RESTRICTED -> PlatformSimState.CARD_RESTRICTED
    else -> PlatformSimState.UNKNOWN
}

/**
 * Android has no NR_NSA network type: non-standalone 5G is reported as LTE with
 * a separate NR state, so [PlatformRadioAccessTechnology.NR_NSA] is never
 * produced here. It exists for iOS, which does name it.
 */
private fun Int.toPlatformRadioAccessTechnology(): PlatformRadioAccessTechnology = when (this) {
    TelephonyManager.NETWORK_TYPE_GPRS -> PlatformRadioAccessTechnology.GPRS
    TelephonyManager.NETWORK_TYPE_EDGE -> PlatformRadioAccessTechnology.EDGE
    TelephonyManager.NETWORK_TYPE_GSM -> PlatformRadioAccessTechnology.GSM
    TelephonyManager.NETWORK_TYPE_CDMA -> PlatformRadioAccessTechnology.CDMA
    TelephonyManager.NETWORK_TYPE_1xRTT -> PlatformRadioAccessTechnology.ONE_XRTT
    TelephonyManager.NETWORK_TYPE_IDEN -> PlatformRadioAccessTechnology.IDEN
    TelephonyManager.NETWORK_TYPE_UMTS -> PlatformRadioAccessTechnology.UMTS
    TelephonyManager.NETWORK_TYPE_HSDPA -> PlatformRadioAccessTechnology.HSDPA
    TelephonyManager.NETWORK_TYPE_HSUPA -> PlatformRadioAccessTechnology.HSUPA
    TelephonyManager.NETWORK_TYPE_HSPA -> PlatformRadioAccessTechnology.HSPA
    TelephonyManager.NETWORK_TYPE_HSPAP -> PlatformRadioAccessTechnology.HSPAP
    TelephonyManager.NETWORK_TYPE_EVDO_0 -> PlatformRadioAccessTechnology.EVDO0
    TelephonyManager.NETWORK_TYPE_EVDO_A -> PlatformRadioAccessTechnology.EVDO_A
    TelephonyManager.NETWORK_TYPE_EVDO_B -> PlatformRadioAccessTechnology.EVDO_B
    TelephonyManager.NETWORK_TYPE_EHRPD -> PlatformRadioAccessTechnology.EHRPD
    TelephonyManager.NETWORK_TYPE_TD_SCDMA -> PlatformRadioAccessTechnology.TD_SCDMA
    TelephonyManager.NETWORK_TYPE_LTE -> PlatformRadioAccessTechnology.LTE
    TelephonyManager.NETWORK_TYPE_IWLAN -> PlatformRadioAccessTechnology.IWLAN
    TelephonyManager.NETWORK_TYPE_NR -> PlatformRadioAccessTechnology.NR
    else -> PlatformRadioAccessTechnology.UNKNOWN
}

/** Treats blank strings as absent, which these APIs use interchangeably with null. */
private fun String?.nullIfBlank(): String? = if (isNullOrBlank()) null else this
