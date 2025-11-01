import 'package:flutter/material.dart';
import '../../../data/services/reading_status_service.dart';

/// Shared widget for displaying and updating reading status.
/// Includes buttons for different statuses (Want to Read, Reading, Completed, etc.).
class ReadingStatusPanel extends StatelessWidget {
  final String uid;
  final String titleId;
  final ReadingStatusService statusService;

  const ReadingStatusPanel({
    super.key,
    required this.uid,
    required this.titleId,
    required this.statusService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: statusService.watchStatus(userId: uid, titleId: titleId),
      builder: (context, snapshot) {
        final currentStatus = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Status',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusButton(
                  label: 'Want to Read',
                  isSelected: currentStatus == 'WANT_TO_READ',
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'WANT_TO_READ'
                  ),
                ),
                _StatusButton(
                  label: 'Reading',
                  isSelected: currentStatus == 'READING',
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'READING'
                  ),
                ),
                _StatusButton(
                  label: 'Completed',
                  isSelected: currentStatus == 'COMPLETED',
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'COMPLETED'
                  ),
                ),
                _StatusButton(
                  label: 'Dropped',
                  isSelected: currentStatus == 'DROPPED',
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'DROPPED'
                  ),
                ),
                _StatusButton(
                  label: 'Paused',
                  isSelected: currentStatus == 'PAUSED',
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'PAUSED'
                  ),
                ),
                _StatusButton(
                  label: 'Remove',
                  isSelected: currentStatus == null,
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'REMOVED'
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

