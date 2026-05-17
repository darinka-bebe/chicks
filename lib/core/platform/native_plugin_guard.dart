import 'package:flutter/services.dart';

/// Returns true when [error] indicates a native plugin was not registered.
bool isMissingPluginError(Object error) {
  return error is MissingPluginException ||
      error.toString().contains('MissingPluginException');
}
