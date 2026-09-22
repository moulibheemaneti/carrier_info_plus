# carrier_info_plus example

The platform folders are not checked in. Generate them once, then run:

```sh
cd example
flutter create --platforms=android,ios .
flutter run
```

To see per-SIM data on Android, add `READ_PHONE_STATE` to
`example/android/app/src/main/AndroidManifest.xml` and grant it with the button
in the app:

```xml
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

Without it the app still runs and shows the permission-free subset — which is
the point worth seeing.
