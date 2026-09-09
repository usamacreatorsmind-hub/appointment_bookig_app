import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../models/doctor_model.dart';
import '../../../utils/app_routes.dart';
import '../../../utils/helper.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../dashboard/patient_dashboard_controller.dart';

class DoctorSearchController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  final searchController = TextEditingController();
  final scrollController = ScrollController();

  final isLoading = false.obs;
  final isLoadMore = false.obs;
  final searchResults = <DoctorModel>[].obs;

  // Pagination fields
  DocumentSnapshot? lastDocument;
  final hasMore = true.obs;
  final int limit = 10;

  // Filters
  final selectedSpecialization = ''.obs;
  final specializations = <String>[].obs;
  final symptoms = <String>[].obs;
  final diseases = <String>[].obs;
  final suggestions = <String>[].obs;
  final maxFee = 5000.0.obs;
  final isSuggestionsVisible = false.obs;

  // Voice Search
  final stt.SpeechToText _speech = stt.SpeechToText();
  final isListening = false.obs;

  // Debounce query
  final searchQuery = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadMasterData();

    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['specialization'] != null) {
      selectedSpecialization.value = args['specialization'];
      searchController.text = args['specialization'];
      searchQuery.value = args['specialization'];
    }

    // Debounce search for user typing
    debounce(searchQuery, (_) => searchDoctors(), time: const Duration(milliseconds: 500));

    // Scroll listener for pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        loadMoreDoctors();
      }
    });
    // Always trigger initial search
    searchDoctors();
  }

  Future<void> loadMasterData() async {
    try {
      final specs = await _firestoreService.getUsedSpecializations();
      final symps = await _firestoreService.getSymptoms();
      final diss = await _firestoreService.getDiseases();

      specializations.assignAll(specs);
      symptoms.assignAll(symps);
      diseases.assignAll(diss);
    } catch (e) {
      print("Error loading master data: $e");
    }
  }

  void onSearchChanged(String val) {
    searchQuery.value = val;
    if (val.length >= 2) {
      final query = val.toLowerCase();
      final List<String> matches = [];

      // Add matching symptoms
      matches.addAll(symptoms.where((s) => s.toLowerCase().contains(query)).take(3));
      // Add matching diseases
      matches.addAll(diseases.where((d) => d.toLowerCase().contains(query)).take(3));
      // Add matching specializations
      matches.addAll(specializations.where((s) => s.toLowerCase().contains(query)).take(2));

      suggestions.assignAll(matches.toSet().toList()); // Unique matches
      isSuggestionsVisible.value = suggestions.isNotEmpty;
    } else {
      isSuggestionsVisible.value = false;
    }
  }

  void selectSuggestion(String value) {
    searchController.text = value;
    searchQuery.value = value;
    isSuggestionsVisible.value = false;
    searchDoctors();
  }

  Future<void> searchDoctors() async {
    isSuggestionsVisible.value = false;
    isLoading.value = true;
    lastDocument = null;
    hasMore.value = true;
    searchResults.clear();
    update();

    try {
      String? sector;
      try {
        sector = Get.find<PatientDashboardController>().currentSector.value;
      } catch (e) {}

      final result = await _firestoreService.searchDoctorsPaginated(
        sector: sector,
        name: searchQuery.value.trim(),
        specialization: selectedSpecialization.value,
        maxFee: maxFee.value,
        lastDocument: null,
        limit: limit,
      );

      final List<DoctorModel> docs = List<DoctorModel>.from(result['docs']);

      // In-memory sort fallback for missing composite indexes
      docs.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

      searchResults.assignAll(docs);
      lastDocument = result['lastDoc'] as DocumentSnapshot?;
      hasMore.value = result['hasMore'] as bool;
    } catch (e) {
      if (e.toString().contains('failed-precondition')) {
        AppSnackBar.show('Sorting index missing. Results may not be ordered correctly.');
        print("Firestore Error: $e");
      } else {
        AppSnackBar.show('Failed to search doctors: $e');
      }
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> loadMoreDoctors() async {
    if (isLoading.value || isLoadMore.value || !hasMore.value) return;

    isLoadMore.value = true;
    update();

    try {
      String? sector;
      try {
        sector = Get.find<PatientDashboardController>().currentSector.value;
      } catch (e) {}

      final result = await _firestoreService.searchDoctorsPaginated(
        sector: sector,
        name: searchQuery.value.trim(),
        specialization: selectedSpecialization.value,
        maxFee: maxFee.value,
        lastDocument: lastDocument,
        limit: limit,
      );

      final List<DoctorModel> newDocs = List<DoctorModel>.from(result['docs']);
      if (newDocs.isNotEmpty) {
        searchResults.addAll(newDocs);
        // Keep the list sorted in-memory
        searchResults.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        lastDocument = result['lastDoc'] as DocumentSnapshot?;
      }
      hasMore.value = result['hasMore'] as bool;
    } catch (e) {
      print("Error loading more doctors: $e");
    } finally {
      isLoadMore.value = false;
      update();
    }
  }

  void onSpecializationFilter(String spec) {
    if (selectedSpecialization.value == spec) {
      selectedSpecialization.value = '';
    } else {
      selectedSpecialization.value = spec;
    }
    searchDoctors();
  }

  void clearFilters() {
    searchController.clear();
    searchQuery.value = "";
    selectedSpecialization.value = '';
    maxFee.value = 5000.0;
    searchDoctors();
  }

  Future<void> toggleVoiceSearch() async {
    if (isListening.value) {
      _speech.stop();
      isListening.value = false;
    } else {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') isListening.value = false;
        },
        onError: (val) => print('Speech Error: $val'),
      );
      if (available) {
        isListening.value = true;
        _speech.listen(onResult: (val) {
          searchController.text = val.recognizedWords;
          searchQuery.value = val.recognizedWords;
          if (val.finalResult) {
            isListening.value = false;
            searchDoctors();
          }
        });
      }
    }
    update();
  }

  void goToDoctorProfile(DoctorModel doctor) {
    Get.toNamed(AppRoutes.doctorProfile, arguments: {'doctor': doctor});
  }

  @override
  void onClose() {
    // Note: In some cases, disposing these here can lead to "used after disposed" errors
    // if the UI tries to rebuild during navigation or disposal.
    // Removing these explicit disposes to prevent the crash.
    super.onClose();
  }
}
