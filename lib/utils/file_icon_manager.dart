import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:path/path.dart' as path;

// Constants for SHChangeNotify if not already defined in win32
final int SHCNE_ASSOCCHANGED = 0x08000000;
final int SHCNF_IDLIST = 0x0000;

class FileIconManager {
  static void setAstroFileIcon(String astroFilePath, String exePath) {
    try {
      // Convert paths to absolute and normalize
      final String absoluteExePath = path
          .absolute(exePath)
          .replaceAll('/', '\\');

      // Create ProgID for .astro files
      final progIdKey = RegCreateKeyEx(
        HKEY_CURRENT_USER,
        'Software\\Classes\\AstroVisionFile'.toNativeUtf16(),
        0,
        nullptr,
        REG_OPTION_NON_VOLATILE,
        KEY_ALL_ACCESS,
        nullptr,
        calloc<HKEY>(),
        nullptr,
      );

      // Set default value for ProgID
      final progIdValue = 'Astro Vision Project File'.toNativeUtf16();
      RegSetValueEx(
        progIdKey,
        ''.toNativeUtf16(),
        0,
        REG_SZ,
        progIdValue.cast<Uint8>(),
        23,
      );

      // Create DefaultIcon subkey under ProgID
      final iconKey = RegCreateKeyEx(
        HKEY_CURRENT_USER,
        'Software\\Classes\\AstroVisionFile\\DefaultIcon'.toNativeUtf16(),
        0,
        nullptr,
        REG_OPTION_NON_VOLATILE,
        KEY_ALL_ACCESS,
        nullptr,
        calloc<HKEY>(),
        nullptr,
      );

      // Set icon path with comma and index to use first icon (index 0)
      final iconString = '$absoluteExePath,0';
      final iconValue = iconString.toNativeUtf16();
      RegSetValueEx(
        iconKey,
        ''.toNativeUtf16(),
        0,
        REG_SZ,
        iconValue.cast<Uint8>(),
        iconString.length * 2,
      );

      // Associate .astro extension with ProgID
      final extensionKey = RegCreateKeyEx(
        HKEY_CURRENT_USER,
        'Software\\Classes\\.astro'.toNativeUtf16(),
        0,
        nullptr,
        REG_OPTION_NON_VOLATILE,
        KEY_ALL_ACCESS,
        nullptr,
        calloc<HKEY>(),
        nullptr,
      );

      // Set ProgID as default value for .astro
      final extValue = 'AstroVisionFile'.toNativeUtf16();
      RegSetValueEx(
        extensionKey,
        ''.toNativeUtf16(),
        0,
        REG_SZ,
        extValue.cast<Uint8>(),
        14,
      );

      // Set up shell commands for opening files
      final shellKey = RegCreateKeyEx(
        HKEY_CURRENT_USER,
        'Software\\Classes\\AstroVisionFile\\shell\\open\\command'
            .toNativeUtf16(),
        0,
        nullptr,
        REG_OPTION_NON_VOLATILE,
        KEY_ALL_ACCESS,
        nullptr,
        calloc<HKEY>(),
        nullptr,
      );

      // Set command to open files with our application
      final commandString = '"$absoluteExePath" "%1"';
      final commandValue = commandString.toNativeUtf16();
      RegSetValueEx(
        shellKey,
        ''.toNativeUtf16(),
        0,
        REG_SZ,
        commandValue.cast<Uint8>(),
        commandString.length * 2,
      );

      // Notify shell of the change
      final shell32 = DynamicLibrary.open('shell32.dll');
      final SHChangeNotify = shell32.lookupFunction<
        Void Function(
          Int32 wEventId,
          Uint32 uFlags,
          Pointer<Void> dwItem1,
          Pointer<Void> dwItem2,
        ),
        void Function(
          int wEventId,
          int uFlags,
          Pointer<Void> dwItem1,
          Pointer<Void> dwItem2,
        )
      >('SHChangeNotify');

      SHChangeNotify(
        0x08000000, // SHCNE_ASSOCCHANGED
        0x0000, // SHCNF_IDLIST
        nullptr,
        nullptr,
      );

      // Free resources
      RegCloseKey(progIdKey);
      RegCloseKey(iconKey);
      RegCloseKey(extensionKey);
      RegCloseKey(shellKey);

      // Free allocated memory
      calloc.free(progIdValue);
      calloc.free(iconValue);
      calloc.free(extValue);
      calloc.free(commandValue);
    } catch (e) {
      print('Error setting file icon: $e');
    }
  }
}
