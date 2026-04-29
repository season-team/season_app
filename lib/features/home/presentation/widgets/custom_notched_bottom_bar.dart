import 'package:flutter/material.dart';
import 'package:season_app/core/constants/app_assets.dart';
import 'package:season_app/core/constants/app_colors.dart';

class CustomNotchedBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onFabTap;
  final List<BottomNavItem> items;
  final bool isRtl;

  const CustomNotchedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    required this.items,
    this.isRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    const double circleSize = 54;
    const double notchWidth = 105.0;
    const double notchDepth = 47;
    const double bottomPadding = 15;
    const double borderRadius = 16.0;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double containerWidth = screenWidth - 30;

    // Reorder items for RTL
    final displayItems = isRtl ? items.reversed.toList() : items;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: bottomPadding,
          left: (screenWidth - containerWidth) / 2,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Bottom bar with notch and rounded corners
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius - 1),
                      child: PhysicalShape(
                        clipper: _InwardTopNotchClipper(notchWidth, notchDepth),
                        color: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        child: SizedBox(
                          height: 63,
                          width: containerWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(items.length + 1, (i) {
                              // Insert spacing in the middle for FAB
                              if (i == (items.length ~/ 2)) {
                                return const SizedBox(width: 50);
                              }
                              // Adjust index to skip spacing
                              final actualIndex = i > (items.length ~/ 2) ? i - 1 : i;
                            
                              return _buildNavItem(
                                item: displayItems[actualIndex],
                                index: actualIndex,
                                isSelected: currentIndex == actualIndex,
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Floating FAB button
              Positioned(
                bottom: 35,
                child: SizedBox(
                  height: circleSize,
                  width: circleSize,
                  child: Material(
                    shape: const CircleBorder(),
                    elevation: 0,
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onFabTap,
                      splashColor: AppColors.primary.withOpacity(0.3),
                      highlightColor: AppColors.primary.withOpacity(0.1),
                      child: Container(
                        height: circleSize,
                        width: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.85),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            AppAssets.seasonWelcomeImage,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required BottomNavItem item,
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  item.icon,
                  size: 24,
                  color: isSelected ? AppColors.secondary : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 0),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.secondary : Colors.grey.shade600,
                  fontFamily: 'Cairo',
                ),
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Model for bottom navigation items
class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.label,
  });
}

// Custom clipper for the notch
class _InwardTopNotchClipper extends CustomClipper<Path> {
  final double notchWidth;
  final double notchDepth;

  _InwardTopNotchClipper(this.notchWidth, this.notchDepth);

  @override
  Path getClip(Size size) {
    final path = Path();
    final double centerX = size.width / 2;
    final double leftNotchStart = centerX - (notchWidth / 2);
    final double rightNotchStart = centerX + (notchWidth / 2);

    // Start from bottom left
    path.moveTo(0, size.height);
    
    // Left edge
    path.lineTo(0, 0);
    
    // Top edge to notch start
    path.lineTo(leftNotchStart, 0);

    // Create smooth inward curve for notch
    path.quadraticBezierTo(
      leftNotchStart + (notchWidth * 0.15),
      0,
      leftNotchStart + (notchWidth * 0.25),
      notchDepth * 0.4,
    );

    path.quadraticBezierTo(
      centerX,
      notchDepth,
      rightNotchStart - (notchWidth * 0.25),
      notchDepth * 0.4,
    );

    path.quadraticBezierTo(
      rightNotchStart - (notchWidth * 0.15),
      0,
      rightNotchStart,
      0,
    );

    // Continue to right edge
    path.lineTo(size.width, 0);
    
    // Right edge
    path.lineTo(size.width, size.height);
    
    // Bottom edge
    path.lineTo(0, size.height);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

