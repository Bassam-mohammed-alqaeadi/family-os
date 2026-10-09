import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/policy/sos_ladder.dart';

/// Trusted backup contact row with verification + priority (FAT-028).
class TrustedContactCard extends StatelessWidget {
  const TrustedContactCard({
    super.key,
    required this.contact,
    required this.priorityLabel,
    required this.verificationLabel,
    required this.delayLabel,
    required this.onToggle,
    required this.onRemove,
    this.phoneLabel = '',
    this.relationLabel = '',
    this.escalationHint = '',
    this.verifyLabel,
    this.onVerify,
    this.onEdit,
    this.canEdit = true,
    this.switchKey,
    this.removeKey,
    this.verifyKey,
    this.editKey,
  });

  final SosBackupContact contact;
  final String priorityLabel;
  final String verificationLabel;
  final String delayLabel;
  final String phoneLabel;
  final String relationLabel;
  final String escalationHint;
  final String? verifyLabel;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onRemove;
  final VoidCallback? onVerify;
  final VoidCallback? onEdit;
  final bool canEdit;
  final Key? switchKey;
  final Key? removeKey;
  final Key? verifyKey;
  final Key? editKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  priorityLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.p600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                    if (relationLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        relationLabel,
                        style: TextStyle(fontSize: 11, color: colors.ink2),
                      ),
                    ],
                    if (phoneLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phoneLabel,
                        style: TextStyle(fontSize: 11, color: colors.ink2),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      delayLabel,
                      style: TextStyle(fontSize: 11, color: colors.ink2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      verificationLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            contact.verification ==
                                SosVerificationStatus.verified
                            ? colors.mint
                            : colors.amber,
                      ),
                    ),
                    if (escalationHint.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        escalationHint,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.coral,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                key: switchKey,
                value: contact.enabled,
                onChanged: canEdit ? onToggle : null,
              ),
              if (canEdit && onEdit != null)
                IconButton(
                  key: editKey,
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, color: colors.p600, size: 20),
                ),
              if (canEdit && onRemove != null)
                IconButton(
                  key: removeKey,
                  onPressed: onRemove,
                  icon: Icon(Icons.close, color: colors.coral, size: 18),
                ),
            ],
          ),
          if (canEdit && onVerify != null && verifyLabel != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: verifyKey,
                onPressed: onVerify,
                child: Text(verifyLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
