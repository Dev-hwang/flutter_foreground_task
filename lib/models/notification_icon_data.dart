import 'package:flutter/material.dart';

/// The resource type of the notification icon.
enum ResourceType {
  /// A resources in the drawable folder.
  /// The drawable folder is where all kinds of images are stored.
  drawable,

  /// A resources in the mipmap folder.
  /// The mipmap folder is usually where the launcher icon image is stored.
  mipmap,
}

/// The resource prefix of the notification icon.
enum ResourcePrefix {
  /// A resources with the `ic_` prefix.
  ic,

  /// A resources with the `img_` prefix.
  img,
}

/// Data for setting the icon.
class IconResourceData {
  /// Constructs an instance of [IconData].
  const IconResourceData({
    required this.resType,
    required this.resPrefix,
    required this.name,
  }) : _backgroundColor = null;

  /// Constructs an instance of [NotificationIconData].
  const IconResourceData._notificationIcon(
    this.resType,
    this.resPrefix,
    this.name,
    this._backgroundColor,
  );

  /// The resource type of the notification icon.
  /// If the resource is in the drawable folder, set it to [ResourceType.drawable],
  /// if the resource is in the mipmap folder, set it to [ResourceType.mipmap].
  final ResourceType resType;

  /// The resource prefix of the notification icon.
  /// If the notification icon name is `ic_simple_notification`,
  /// set it to [ResourcePrefix.ic] and set [name] to `simple_notification`.
  final ResourcePrefix resPrefix;

  /// Notification icon name without prefix.
  final String name;

  /// Notification icon background color.
  final Color? _backgroundColor;

  /// Returns the data fields of [NotificationIconData] in JSON format.
  Map<String, dynamic> toJson() {
    String? backgroundColorRgb;
    if (_backgroundColor != null) {
      backgroundColorRgb =
          '${_backgroundColor!.red},${_backgroundColor!.green},${_backgroundColor!.blue}';
    }

    return {
      'resType': resType.toString().split('.').last,
      'resPrefix': resPrefix.toString().split('.').last,
      'name': name,
      'backgroundColorRgb': backgroundColorRgb,
    };
  }
}

/// Data for setting the notification icon.
class NotificationIconData extends IconResourceData {
  /// Constructs an instance of [NotificationIconData].
  const NotificationIconData({
    required ResourceType resType,
    required ResourcePrefix resPrefix,
    required String name,
    Color? backgroundColor,
  }) : super._notificationIcon(resType, resPrefix, name, backgroundColor);

  Color? get backgroundColor => _backgroundColor;
}
