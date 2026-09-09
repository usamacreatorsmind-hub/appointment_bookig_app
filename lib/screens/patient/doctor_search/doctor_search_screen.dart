import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_colors.dart';
import '../../../models/doctor_model.dart';
import 'doctor_search_controller.dart';

class DoctorSearchScreen extends GetView<DoctorSearchController> {
  const DoctorSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('Find Doctors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 8),
              _buildSpecializationFilters(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.searchResults.isEmpty) {
                    return _buildEmptyState();
                  }
                  return SafeArea(
                    child: ListView.separated(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 10),
                      itemCount: controller.searchResults.length + (controller.hasMore.value ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index < controller.searchResults.length) {
                          return _DoctorResultCard(
                            doctor: controller.searchResults[index],
                            onTap: () => controller.goToDoctorProfile(controller.searchResults[index]),
                            matchTerm: controller.searchQuery.value,
                          );
                        }

                        return controller.hasMore.value
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
          _buildSuggestionsOverlay(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Obx(() {
      if (!controller.isSuggestionsVisible.value || controller.suggestions.isEmpty) {
        return const SizedBox.shrink();
      }
      return Positioned(
        top: 60, // Below search bar
        left: 16,
        right: 16,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: controller.suggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final suggestion = controller.suggestions[index];
              return ListTile(
                leading: const Icon(Icons.history_rounded, size: 20, color: AppColors.textHint),
                title: Text(suggestion, style: const TextStyle(fontSize: 14)),
                onTap: () => controller.selectSuggestion(suggestion),
                dense: true,
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search doctor, symptoms, disease...',
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => IconButton(
                    icon: Icon(
                      controller.isListening.value ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: controller.isListening.value ? Colors.red : AppColors.primary,
                    ),
                    onPressed: controller.toggleVoiceSearch,
                  )),
              IconButton(icon: const Icon(Icons.clear_rounded), onPressed: controller.clearFilters),
            ],
          ),
          filled: true,
          fillColor: AppColors.bgPage,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildSpecializationFilters() {
    return Obx(
      () => Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: controller.specializations.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Obx(() {
                final isSelected = controller.selectedSpecialization.value == '';
                return FilterChip(
                  label: const Text('All Doctors'),
                  selected: isSelected,
                  onSelected: (_) => controller.clearFilters(),
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.primaryBorder),
                  ),
                );
              });
            }

            final spec = controller.specializations[index - 1];
            return Obx(() {
              final isSelected = controller.selectedSpecialization.value == spec;
              return FilterChip(
                label: Text(spec),
                selected: isSelected,
                onSelected: (_) => controller.onSpecializationFilter(spec),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.primaryBorder),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No doctors found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DoctorResultCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;
  final String matchTerm;
  const _DoctorResultCard({required this.doctor, required this.onTap, this.matchTerm = ''});

  @override
  Widget build(BuildContext context) {
    String? matchedTag;
    if (matchTerm.isNotEmpty) {
      final term = matchTerm.toLowerCase();
      final symMatch = doctor.symptomsCovered.firstWhereOrNull((s) => s.toLowerCase().contains(term));
      final disMatch = doctor.diseasesCovered.firstWhereOrNull((d) => d.toLowerCase().contains(term));
      if (symMatch != null) {
        matchedTag = "Treats: $symMatch";
      } else if (disMatch != null) {
        matchedTag = "Specialist: $disMatch";
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    image: doctor.photoUrl != null ? DecorationImage(image: NetworkImage(doctor.photoUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: doctor.photoUrl == null ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 40) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.doctorName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        doctor.specialization.join(', '),
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(doctor.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(' (${doctor.totalReviews})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${doctor.experience} yrs exp', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '₹${doctor.consultationFee.toInt()}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (matchedTag != null) ...[
              const Divider(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      matchedTag,
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
