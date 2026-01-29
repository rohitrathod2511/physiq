import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendSupportEmail(String uid, String appVersion) async {
    try {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'support@physiq.example',
        query: _encodeQueryParameters(<String, String>{
          'subject': 'Physiq AI Support Request',
          'body': '\n\n\n--\nUID: $uid\nVersion: $appVersion',
        }),
      );

      if (await canLaunchUrlString(emailLaunchUri.toString())) {
        await launchUrlString(emailLaunchUri.toString());
        
        // Log support request locally/firestore for tracking
        await _firestore.collection('users').doc(uid).collection('supportRequests').add({
          'type': 'email_initiated',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      throw Exception('Failed to send support email: $e');
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> submitFeatureRequest(String uid, String title, String description) async {
    try {
      final reqRef = _firestore.collection('users').doc(uid).collection('featureRequests').doc();
      
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
}
