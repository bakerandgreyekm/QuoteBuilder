import 'package:flutter/material.dart';

const Map<String, IconData> systemIconMap = {
  'CCTV': Icons.videocam,
  'Networking': Icons.wifi,
  'Intercom': Icons.phone,
  'Fire Alarm': Icons.local_fire_department,
  'Lighting Automation': Icons.lightbulb,
  'Access Control': Icons.lock,
  'Attendance System': Icons.fingerprint,
  'Gate Automation': Icons.garage,
  'Channel Music': Icons.music_note,
  'Display': Icons.monitor,
  'Video Conferencing': Icons.video_camera_front,
};

IconData iconForSystem(String systemType) =>
    systemIconMap[systemType] ?? Icons.settings;
