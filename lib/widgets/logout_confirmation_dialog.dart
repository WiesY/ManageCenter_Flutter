import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/theme/app_theme.dart';

Future<void> showLogoutConfirmationDialog(BuildContext context) {
  final authBloc = context.read<AuthBloc>();
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.logout, color: dialogContext.colors.error),
          const SizedBox(width: 8),
          const Text('Выход'),
        ],
      ),
      content: const Text(
        'Вы действительно хотите выйти из аккаунта?',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Отмена', style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            authBloc.add(LogoutEvent());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: dialogContext.colors.error,
            foregroundColor: dialogContext.colors.onError,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Выйти', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );
}
