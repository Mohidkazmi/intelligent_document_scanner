class AppConstants {
  static const String appName = "DocScanner AI";

  // API base — must match how the device/emulator reaches your machine running the backend.
  //
  // - Android Emulator: http://10.0.2.2:8000/api/v1  (10.0.2.2 = host loopback from the emulator)
  // - Physical device (same Wi‑Fi): your Mac LAN IP + port 8000, e.g. http://192.168.x.x:8000/api/v1
  //   Run on Mac: ipconfig getifaddr en0  (Wi‑Fi) or pick the interface you use — update when DHCP changes Wi‑Fi.
  // - iOS Simulator: http://127.0.0.1:8000/api/v1
  //
  static const String baseUrl = "http://192.168.1.7:8000/api/v1";
}
