import 'package:flutter/material.dart';

import 'package:cityvista/other/models/city_review.dart';

class ReviewsView extends StatelessWidget {
  final List<CityReview> reviews;

  const ReviewsView({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Center(child: Text("You don't have any reviews!"));
    }
    // TODO: implement build
    throw UnimplementedError();
  }
}