import 'package:flutter/material.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';

class AvatarSelectorDialog extends StatefulWidget {
  final int? currentAvatarId;

  const AvatarSelectorDialog({
    super.key,
    this.currentAvatarId,
  });

  @override
  State<AvatarSelectorDialog> createState() => _AvatarSelectorDialogState();
}

class _AvatarSelectorDialogState extends State<AvatarSelectorDialog> {
  int? selectedAvatarId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedAvatarId = widget.currentAvatarId;
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    try {
      // Preload all avatar images
      final futures = <Future>[];
      for (int i = 1; i <= 20; i++) {
        futures.add(
          precacheImage(
            AssetImage('assets/images/png/avatars/$i.png'),
            context,
          ),
        );
      }
      await Future.wait(futures);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error preloading images: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              loc.selectImage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Avatar Grid
            SizedBox(
              height: 400,
              width: double.maxFinite,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 20, // We have 20 avatars
                      itemBuilder: (context, index) {
                        final avatarId = index + 1;
                        final isSelected = selectedAvatarId == avatarId;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedAvatarId = avatarId;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected 
                                    ? AppColors.secondary 
                                    : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.secondary.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/png/avatars/$avatarId.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading avatar $avatarId: $error');
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.person,
                                          color: AppColors.primary,
                                          size: 30,
                                        ),
                                        Text(
                                          '$avatarId',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    loc.cancel,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: selectedAvatarId == null
                      ? null
                      : () => Navigator.pop(context, selectedAvatarId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(loc.yes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

