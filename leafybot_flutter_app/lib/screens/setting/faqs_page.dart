import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Comman_Widget/app_bar.dart';
import '../../constant/appColors.dart';

class FaqsPage extends StatelessWidget {
  const FaqsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        "question": "What is the LeafyBot?",
        "answer":
            "LeafyBot is a smart planter device designed for indoor plant enthusiasts in urban India. It uses sensors, AI insights, and expressive visual feedback to help users keep their plants healthy while building emotional connection through a friendly interface.",
      },
      {
        "question": "How does the self-watering system work?",
        "answer":
            "The self-watering system uses soil moisture sensors to detect when the plant needs water. It then automatically dispenses the right amount of water from its reservoir.",
      },
      {
        "question": "What types of plants are compatible with LeafyBot?",
        "answer":
            "LeafyBot is compatible with most small to medium-sized indoor plants, including herbs, succulents, and decorative plants.",
      },
      {
        "question": "How long does the battery last?",
        "answer":
            "LeafyBot’s battery lasts for up to 2 weeks on a full charge, depending on usage and connected features.",
      },
      {
        "question": "Does LeafyBot receive software updates?",
        "answer":
            "Yes, LeafyBot receives regular over-the-air software updates to improve functionality and add new features.",
      },
    ];
    final RxInt expandedIndex = (-1).obs; // -1 means nothing expanded
    return Scaffold(
      appBar: CustomAppBar(
        title: "FAQs",
        showBack: true, // first page no back button
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Frequently Asked Questions",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 16,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "An FAQ or Frequently Asked Questions is a section for helps users find information quickly without needing to contact customer support",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 14,
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppColors.grayLight, // Border color
                        width: 1, // Border width
                      ),
                    ),
                    margin: const EdgeInsets.only(top: 16),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: Obx(() {
                        final isExpanded = expandedIndex.value == index;

                        return ExpansionTile(
                          key: Key(index.toString()),
                          initiallyExpanded: isExpanded,
                          collapsedIconColor: AppColors.gray,
                          tilePadding: const EdgeInsets.only(
                            left: 14,
                            right: 14,
                          ),
                          onExpansionChanged: (expanded) {
                            expandedIndex.value = expanded
                                ? index
                                : -1; // update expanded index
                          },

                          title: Text(
                            faq["question"]!,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontSize: 14,
                                  letterSpacing: 0,
                                  fontWeight: isExpanded
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 14,
                                right: 14,
                                bottom: 14,
                                top: 0,
                              ),
                              child: Text(
                                faq["answer"]!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontSize: 14,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
