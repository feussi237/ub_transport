import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/api_models.dart';
import '../widgets/common_widgets.dart';
import '../services/review_service.dart';
import '../services/api_client.dart';

/// Shows an agency's reviews. When [tripId] is provided (reached from a
/// completed booking) a rating form is shown at the top so the passenger
/// can leave their own review for that trip.
class ReviewsScreen extends StatefulWidget {
  final int agencyId;
  final String agencyName;
  final int? tripId;

  const ReviewsScreen({super.key, required this.agencyId, required this.agencyName, this.tripId});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late Future<List<ApiReview>> _reviewsFuture;
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _submitting = false;
  String? _error;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = ReviewService.instance.listForAgency(widget.agencyId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ReviewService.instance.submit(
        agencyId: widget.agencyId,
        tripId: widget.tripId!,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _reviewsFuture = ReviewService.instance.listForAgency(widget.agencyId);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(title: 'Reviews', subtitle: widget.agencyName),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (widget.tripId != null && !_submitted) _buildForm(),
          if (widget.tripId != null && !_submitted) const SizedBox(height: 24),
          if (_submitted)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text('Thanks for your feedback!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
            ),
          const Text('What other passengers say', style: AppTextStyles.label),
          const SizedBox(height: 12),
          FutureBuilder<List<ApiReview>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const StateMessage(icon: Icons.wifi_off, message: 'Could not load reviews.');
              }
              final reviews = snapshot.data!;
              if (reviews.isEmpty) {
                return const StateMessage(icon: Icons.star_border, message: 'No reviews yet for this agency.');
              }
              return Column(children: reviews.map((r) => _ReviewTile(review: r)).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rate this trip', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(filled ? Icons.star : Icons.star_border, color: AppColors.goldDark, size: 28),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: AppTextStyles.body,
            decoration: const InputDecoration(hintText: 'Optional comment about your trip'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 14),
          PrimaryButton(
            label: _submitting ? 'Submitting…' : 'Submit review',
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ApiReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.authorName, style: AppTextStyles.label),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: AppColors.goldDark, size: 16),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}
