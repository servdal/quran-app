//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audioplayers_windows/audioplayers_windows_plugin.h>
#include <flutter_inappwebview_windows/flutter_inappwebview_windows_plugin_c_api.h>
#include <geolocator_windows/geolocator_windows.h>
#include <record_windows/record_windows_plugin_c_api.h>
#include <share_plus/share_plus_windows_plugin_c_api.h>
#include <sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.h>
#include <url_launcher_windows/url_launcher_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AudioplayersWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AudioplayersWindowsPlugin"));
  FlutterInappwebviewWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterInappwebviewWindowsPluginCApi"));
  GeolocatorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("GeolocatorWindows"));
  RecordWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("RecordWindowsPluginCApi"));
  SharePlusWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SharePlusWindowsPluginCApi"));
  Sqlite3FlutterLibsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("Sqlite3FlutterLibsPlugin"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
}
