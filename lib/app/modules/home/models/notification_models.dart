import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NotificationItem {
  final String titleKey;
  final String subtitleKey;
  final String descriptionKey;
  final String timeKey;
  final String? actionLabelKey;
  final String? actionRoute;
  final IconData icon;
  final Color iconColor;
  final bool isRead;

  const NotificationItem({
    required this.titleKey,
    required this.subtitleKey,
    this.descriptionKey = '',
    required this.timeKey,
    this.actionLabelKey,
    this.actionRoute,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        titleKey: titleKey,
        subtitleKey: subtitleKey,
        descriptionKey: descriptionKey,
        timeKey: timeKey,
        actionLabelKey: actionLabelKey,
        actionRoute: actionRoute,
        icon: icon,
        iconColor: iconColor,
        isRead: isRead ?? this.isRead,
      );
}
