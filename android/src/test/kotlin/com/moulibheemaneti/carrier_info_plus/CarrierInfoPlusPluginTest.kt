package com.moulibheemaneti.carrier_info_plus

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.telephony.TelephonyManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/*
 * Unit tests of the Kotlin side, against a mocked TelephonyManager.
 *
 * These run on the JVM against Android's stub jar, where Build.VERSION.SDK_INT
 * is 0, so every API-level gate takes its oldest branch. That suits what they
 * guard: the permission-free tier reads nothing that is gated.
 *
 * Once the example app has been built, run them from example/android with
 * `./gradlew :carrier_info_plus:testDebugUnitTest`, or from Android Studio.
 */
internal class CarrierInfoPlusPluginTest {

    /** A phone whose modem, SIM and network all answer permission-free reads. */
    private fun phone(simState: Int): TelephonyManager =
        mock(TelephonyManager::class.java).also {
            `when`(it.simState).thenReturn(simState)
            `when`(it.phoneType).thenReturn(TelephonyManager.PHONE_TYPE_GSM)
            `when`(it.isVoiceCapable).thenReturn(true)
            `when`(it.isSmsCapable).thenReturn(true)
            `when`(it.networkOperatorName).thenReturn("Airtel")
            `when`(it.networkCountryIso).thenReturn("in")
            if (simState != TelephonyManager.SIM_STATE_ABSENT) {
                `when`(it.simOperator).thenReturn("40410")
                `when`(it.simOperatorName).thenReturn("Airtel")
                `when`(it.simCountryIso).thenReturn("in")
            }
        }

    private fun attachedPlugin(
        telephony: TelephonyManager,
        granted: Boolean,
    ): CarrierInfoPlusPlugin {
        val packageManager = mock(PackageManager::class.java)
        `when`(packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)).thenReturn(true)

        val context = mock(Context::class.java)
        `when`(context.packageManager).thenReturn(packageManager)
        `when`(context.getSystemService(Context.TELEPHONY_SERVICE)).thenReturn(telephony)
        // Stubbed explicitly either way: a mock's default int is 0, which
        // happens to be PERMISSION_GRANTED.
        `when`(context.checkSelfPermission(Manifest.permission.READ_PHONE_STATE)).thenReturn(
            if (granted) PackageManager.PERMISSION_GRANTED else PackageManager.PERMISSION_DENIED,
        )

        val binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        `when`(binding.applicationContext).thenReturn(context)
        `when`(binding.binaryMessenger).thenReturn(mock(BinaryMessenger::class.java))

        return CarrierInfoPlusPlugin().apply { onAttachedToEngine(binding) }
    }

    // ------------------------------------------------- permission denied, SIM

    @Test
    fun permissionDenied_withSim_stillReportsTheSim() {
        // The case the README's permission-free promise rests on: a missing
        // permission must not be read as a missing SIM.
        val info = attachedPlugin(phone(TelephonyManager.SIM_STATE_READY), granted = false)
            .getCarrierInfo()

        val sim = info.simCards.single()
        assertEquals(PlatformSimState.READY, sim.simState)
        assertEquals("Airtel", sim.carrierName)
        assertEquals("404", sim.mobileCountryCode)
        assertEquals("10", sim.mobileNetworkCode)
        assertEquals("in", sim.countryIso)
        assertTrue(sim.isDefaultData)
        assertTrue(sim.isDefaultVoice)
        // Unknowable without the permission, and left unknown rather than
        // guessed.
        assertNull(sim.subscriptionId)
        assertNull(info.simCount)
    }

    @Test
    fun permissionDenied_withSim_explainsWhatIsMissing() {
        val info = attachedPlugin(phone(TelephonyManager.SIM_STATE_READY), granted = false)
            .getCarrierInfo()

        assertEquals(PlatformDataLimitation.PERMISSION_NOT_GRANTED, info.support.limitation)
        assertFalse(info.support.permissionGranted)
        assertFalse(info.support.perSimDataAvailable)
        assertTrue(info.support.carrierIdentityAvailable)
        assertEquals("Airtel", info.network.operatorName)
        assertEquals("in", info.network.countryIso)
    }

    @Test
    fun permissionDenied_withSimInAnotherSlot_stillReportsASim() {
        // getSimState() answers UNKNOWN, not ABSENT, when the default slot is
        // empty but another slot holds a SIM. That is still a SIM.
        val info = attachedPlugin(phone(TelephonyManager.SIM_STATE_UNKNOWN), granted = false)
            .getCarrierInfo()

        assertEquals(PlatformSimState.UNKNOWN, info.simCards.single().simState)
    }

    // ---------------------------------------------- permission denied, no SIM

    @Test
    fun permissionDenied_withoutSim_reportsNoSim() {
        val info = attachedPlugin(phone(TelephonyManager.SIM_STATE_ABSENT), granted = false)
            .getCarrierInfo()

        assertTrue(info.simCards.isEmpty())
        assertNull(info.simCount)
        assertEquals(PlatformDataLimitation.PERMISSION_NOT_GRANTED, info.support.limitation)
    }

    @Test
    fun permissionDenied_withoutSim_keepsTheHardwareCapabilities() {
        // Matches the device run: no SIM, permission denied, and the modem is
        // still reported as a modem.
        val info = attachedPlugin(phone(TelephonyManager.SIM_STATE_ABSENT), granted = false)
            .getCarrierInfo()

        assertTrue(info.capabilities.isVoiceCapable)
        assertTrue(info.capabilities.isSmsCapable)
        assertTrue(info.capabilities.isDataCapable)
        assertEquals("in", info.network.countryIso)
    }

    // ------------------------------------------------------------- multi-SIM

    @Test
    fun permissionDenied_dualSimHardware_isStillMultiSim() {
        val telephony = phone(TelephonyManager.SIM_STATE_ABSENT)
        @Suppress("DEPRECATION")
        `when`(telephony.phoneCount).thenReturn(2)

        val info = attachedPlugin(telephony, granted = false).getCarrierInfo()

        // Answered by the modem count, which needs no permission. SDK_INT is 0
        // here, so this is getPhoneCount; API 30+ asks getSupportedModemCount
        // the same question.
        assertTrue(info.capabilities.isMultiSimSupported)
    }

    @Test
    fun permissionDenied_singleSimHardware_isNotMultiSim() {
        val telephony = phone(TelephonyManager.SIM_STATE_READY)
        @Suppress("DEPRECATION")
        `when`(telephony.phoneCount).thenReturn(1)

        val info = attachedPlugin(telephony, granted = false).getCarrierInfo()

        assertFalse(info.capabilities.isMultiSimSupported)
    }
}
