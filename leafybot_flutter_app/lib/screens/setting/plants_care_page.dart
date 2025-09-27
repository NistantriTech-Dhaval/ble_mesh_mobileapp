import 'package:flutter/material.dart';

import '../../Comman_Widget/app_bar.dart';

class PlantCarePage extends StatelessWidget {
  final List<Map<String, String>> topics = [
    {
      "title": "Understanding Light Needs",
      "description":
      "Deciphering direct, indirect, and low light conditions to position your plants perfectly."
    },
    {
      "title": "The Art of Watering",
      "description":
      "Mastering when and how much to water, avoiding common pitfalls like overwatering or underwatering."
    },
    {
      "title": "Soil & Potting Essentials",
      "description":
      "Choosing the right soil mix and pots for optimal drainage and root health."
    },
    {
      "title": "Humidity & Temperature",
      "description":
      "Creating the ideal environment for tropical and temperate indoor varieties."
    },
    {
      "title": "Feeding Your Plants",
      "description": "When and how to fertilize for robust growth."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "How to care for common plants",
        showBack: true, // first page no back button
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              "How to Care for Common Indoor Plants: A Beginner's Guide",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 16,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
             Text(
              "Transform your indoor space into a thriving green oasis! This comprehensive guide provides essential tips and easy-to-follow instructions for successfully nurturing the most popular houseplants in your room. Whether you're a complete beginner or looking to refresh your plant care knowledge, learn the fundamental principles to keep your leafy companions healthy and vibrant.",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 14,
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
             Text(
              "What You'll Discover:",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 16,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            ListView.builder(
              itemCount: topics.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Icon(Icons.circle, size: 6, color: Theme.of(context).textTheme.titleSmall?.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 14,
                              letterSpacing: 0,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: "${topics[index]['title']}: ",
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontSize: 15,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: topics[index]['description'],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
