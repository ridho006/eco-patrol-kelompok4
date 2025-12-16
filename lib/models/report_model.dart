// models/report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String? id;
  final String title;
  final String description;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final String status; // 'pending' atau 'selesai'
  final DateTime createdAt;
  final String? completionDescription;
  final String? completionPhotoUrl;

  ReportModel({
    this.id,
    required this.title,
    required this.description,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    this.status = 'pending',
    required this.createdAt,
    this.completionDescription,
    this.completionPhotoUrl,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completionDescription': completionDescription,
      'completionPhotoUrl': completionPhotoUrl,
    };
  }

  // Create from Firestore Document
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      status: data['status'] ?? 'pending',
      createdAt: DateTime.parse(data['createdAt']),
      completionDescription: data['completionDescription'],
      completionPhotoUrl: data['completionPhotoUrl'],
    );
  }

  // Copy with method untuk update
  ReportModel copyWith({
    String? id,
    String? title,
    String? description,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
    String? completionDescription,
    String? completionPhotoUrl,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completionDescription: completionDescription ?? this.completionDescription,
      completionPhotoUrl: completionPhotoUrl ?? this.completionPhotoUrl,
    );
  }
}