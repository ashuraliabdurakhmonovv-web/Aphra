import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<(String, String)?> showProfileEditDialog({
  required BuildContext context,
  required String title,
  required String firstName,
  required String lastName,
}) async {
  final firstNameController = TextEditingController(text: firstName);
  final lastNameController = TextEditingController(text: lastName);

  final result = await showDialog<(String, String)>(
    context: context,
    barrierColor: const Color(0x990D1018),
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      elevation: 0,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF101827),
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEDF6),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ProfileEditField(
              controller: firstNameController,
              label: 'auth.first_name'.tr(),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            _ProfileEditField(
              controller: lastNameController,
              label: 'auth.last_name'.tr(),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6F6670),
                        side: const BorderSide(color: Color(0xFFE8DCE3)),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text('profile.cancel'.tr()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, (
                        firstNameController.text.trim(),
                        lastNameController.text.trim(),
                      )),
                      style: FilledButton.styleFrom(
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text('profile.save'.tr()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  firstNameController.dispose();
  lastNameController.dispose();
  return result;
}

class _ProfileEditField extends StatelessWidget {
  const _ProfileEditField({
    required this.controller,
    required this.label,
    required this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 7),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF737080),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      TextField(
        controller: controller,
        textInputAction: textInputAction,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
          color: Color(0xFF101827),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFFFF7FB),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: Color(0xFFF0E5EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: Color(0xFFE60093), width: 1.5),
          ),
        ),
      ),
    ],
  );
}
