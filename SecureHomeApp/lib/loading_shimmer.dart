import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'theme.dart';

class ShimmerLoading extends StatelessWidget {
  final int itemCount;

  const ShimmerLoading({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 350,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 150,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBase,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBase,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TableShimmerLoading extends StatelessWidget {
  final int rowCount;
  final bool isError;

  const TableShimmerLoading({
    super.key,
    this.rowCount = 5,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isError ? AppColors.shimmerErrorBase : AppColors.shimmerBase,
      highlightColor: isError
          ? AppColors.shimmerErrorHighlight
          : AppColors.shimmerHighlight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: List.generate(
            4,
            (_) => const DataColumn(label: _ShimmerBox(width: 60)),
          ),
          rows: List.generate(
            rowCount,
            (_) => DataRow(
              cells: List.generate(4, (_) => DataCell(_ShimmerBox(width: 80))),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBox({required this.width, this.height = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
    );
  }
}
