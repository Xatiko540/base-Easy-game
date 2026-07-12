import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NotificationItem {
  final String title;
  final String subtitle;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isRead;

  const NotificationItem({
    required this.title,
    required this.subtitle,
    this.description = '',
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });
}
