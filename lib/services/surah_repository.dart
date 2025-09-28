// lib/services/surah_repository.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_app/models/surah_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SurahRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fungsi utama untuk mendapatkan data surah
  Future<Surah> getSurahById(int surahId) async {
    final docRef = _firestore.collection('surahs').doc(surahId.toString());
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      // Jika ada di Firestore, ambil dari sana
      print("Mengambil Surah $surahId dari Firestore...");
      return Surah.fromJson(docSnap.data()!);
    } else {
      // Jika tidak ada, ambil dari JSON lokal, simpan ke Firestore, lalu kembalikan
      print("Surah $surahId tidak ditemukan di Firestore. Migrasi dari JSON lokal...");
      final surah = await _migrateSurahFromJson(surahId);
      return surah;
    }
  }

  // Fungsi untuk memigrasi data dari JSON ke Firestore
  Future<Surah> _migrateSurahFromJson(int surahId) async {
    String jsonString = await rootBundle.loadString('assets/surah/$surahId.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    final surah = Surah.fromJson(jsonMap);

    // Simpan ke Firestore
    await _firestore.collection('surahs').doc(surahId.toString()).set(surah.toJson());
    
    return surah;
  }
  
  // Fungsi untuk menyimpan perubahan (setelah edit)
  Future<void> updateSurah(Surah surah) async {
    final docRef = _firestore.collection('surahs').doc(surah.id.toString());
    await docRef.set(surah.toJson());
    print("Surah ${surah.id} berhasil diperbarui di Firestore.");
  }
  Future<List<int>> getSyncedSurahIds() async {
    try {
      final snapshot = await _firestore.collection('surahs').get();
      return snapshot.docs.map((doc) => int.parse(doc.id)).toList();
    } catch (e) {
      print("Gagal mendapatkan status sinkronisasi: $e");
      return [];
    }
  }
}

/// Provider untuk repository
final surahRepositoryProvider = Provider((ref) => SurahRepository());

// Provider untuk mengambil data surah tunggal
final surahDataProvider = FutureProvider.family<Surah, int>((ref, surahId) {
  final repository = ref.watch(surahRepositoryProvider);
  return repository.getSurahById(surahId);
});

final syncedSurahIdsProvider = FutureProvider<List<int>>((ref) {
  final repository = ref.watch(surahRepositoryProvider);
  return repository.getSyncedSurahIds();
});
