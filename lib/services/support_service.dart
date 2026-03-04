import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> openSupportEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      final userId = user?.uid ?? 'Guest User';
      final userEmail = user?.email ?? 'Not available';

      final deviceContext = await _getDeviceContext(deviceInfo);

      final emailBody =
          '''
Support Request

......

Please describe your issue above this line.

User ID:
$userId

Email:
$userEmail

App Version:
${packageInfo.version}

Platform:
${deviceContext.platform}

OS Version:
${deviceContext.osVersion}

Device:
${deviceContext.deviceModel}
''';

      final emailUri = Uri(
        scheme: 'mailto',
        path: 'physiqai.connect@gmail.com',
        query: _encodeQueryParameters(<String, String>{
          'subject': 'Support Request - Physiq AI',
          'body': emailBody,
        }),
      );

      // Avoid canLaunchUrl for mailto on Android because it can return false
      // without manifest query declarations even when email apps are available.
      var launched = await launchUrl(
        emailUri,
        mode: LaunchMode.platformDefault,
      );
      if (!launched) {
        launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!launched) {
        throw Exception('Could not launch email client');
      }

      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('supportRequests')
            .add({
              'type': 'email_initiated',
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      throw Exception('Failed to open support email: $e');
    }
  }

  // Keep legacy entry-point to avoid breaking old call-sites.
  Future<void> sendSupportEmail(String uid, String appVersion) async {
    await openSupportEmail();
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  Future<void> submitFeatureRequest(
    String uid,
    String title,
    String description,
  ) async {
    try {
      final reqRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('featureRequests')
          .doc();

      await reqRef.set({
        'id': reqRef.id,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      });

      // Optional: Write to central collection
      await _firestore.collection('appFeatureRequests').add({
        'userId': uid,
        'userReqId': reqRef.id,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      });
    } catch (e) {
      throw Exception('Failed to submit feature request: $e');
    }
  }

  Future<_DeviceContext> _getDeviceContext(DeviceInfoPlugin deviceInfo) async {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return _DeviceContext(
        platform: 'Android',
        osVersion: 'Android ${androidInfo.version.release}',
        deviceModel: androidInfo.model,
      );
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return _DeviceContext(
        platform: 'iOS',
        osVersion: 'iOS ${iosInfo.systemVersion}',
        deviceModel: iosInfo.utsname.machine,
      );
    }

    return _DeviceContext(
      platform: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      deviceModel: 'Unknown',
    );
  }
}

class _DeviceContext {
  const _DeviceContext({
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
  });

  final String platform;
  final String osVersion;
  final String deviceModel;
}
