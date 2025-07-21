import 'package:flutter/material.dart';

class NotificationsBottomSheet extends StatelessWidget {
  const NotificationsBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        "title": "+ 0.1036 base received!",
        "subtitle": "Easy Game , level 4 от ID 310375",
        "description": "Congratulations!",
        "time": "1 minute",
        "icon": Icons.card_giftcard,
        "iconColor": Colors.greenAccent,
      },
      {
        "title": "+ 0.0182 Affiliate base bonus received!",
        "subtitle": "Easy Game, level 4 от ID 310112",
        "description": "Congratulations!",
        "time": "about 1 hour",
        "icon": Icons.people,
        "iconColor": Colors.green,
      },
      {
        "title": "New partner joins",
        "subtitle": "ID 310112 has joined your team!",
        "description": "",
        "time": "about 1 hour",
        "icon": Icons.person_add,
        "iconColor": Colors.blueAccent,
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Notifications",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Notifications List
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: notification["iconColor"] as Color,
                        child: Icon(notification["icon"] as IconData, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification["title"] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              notification["subtitle"] as String,
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            if ((notification["description"] as String).isNotEmpty)
                              Text(
                                notification["description"] as String,
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        children: [
                          Text(
                            notification["time"] as String,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Icon(Icons.share, color: Colors.grey, size: 20),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}