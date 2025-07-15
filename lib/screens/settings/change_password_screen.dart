// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:manage_center/bloc/user_bloc.dart';
// import 'package:manage_center/services/api_service.dart';
// import 'package:manage_center/services/storage_service.dart';

// class ChangePasswordScreen extends StatelessWidget {
//   const ChangePasswordScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => UserBloc(
//         apiService: context.read<ApiService>(),
//         storageService: context.read<StorageService>(),
//       ),
//       child: const ChangePasswordView(),
//     );
//   }
// }

// class ChangePasswordView extends StatelessWidget {
//   const ChangePasswordView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('Изменить пароль'),
//         backgroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: BlocConsumer<UserBloc, UserState>(
//         listener: (context, state) {
//           if (state is UserOperationSuccess) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: Colors.green,
//               ),
//             );
//             // Возвращаемся на предыдущий экран после успешной смены пароля
//             Navigator.of(context).pop();
//           } else if (state is UserError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.error),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state is UserOperationInProgress) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const CircularProgressIndicator(),
//                   const SizedBox(height: 16),
//                   Text(state.operation),
//                 ],
//               ),
//             );
//           }

//           return Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Заголовок и описание
//                 const Text(
//                   'Смена пароля',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Для безопасности вашего аккаунта рекомендуется регулярно менять пароль.',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//                 const SizedBox(height: 32),

//                 // Карточка с формой
//                 Card(
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(24.0),
//                     child: Column(
//                       children: [
//                         Icon(
//                           Icons.lock_reset,
//                           size: 48,
//                           color: Colors.blue.shade600,
//                         ),
//                         const SizedBox(height: 16),
//                         const Text(
//                           'Введите данные для смены пароля',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 24),

//                         // Кнопка для открытия диалога смены пароля
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton.icon(
//                             onPressed: () => _showChangePasswordDialog(context),
//                             icon: const Icon(Icons.edit, color: Colors.white),
//                             label: const Text(
//                               'Изменить пароль',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue,
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // Советы по безопасности
//                 Card(
//                   elevation: 1,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.security,
//                               color: Colors.orange.shade600,
//                               size: 20,
//                             ),
//                             const SizedBox(width: 8),
//                             const Text(
//                               'Советы по безопасности',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         _buildSecurityTip('Используйте пароль длиной не менее 8 символов'),
//                         _buildSecurityTip('Включите буквы, цифры и специальные символы'),
//                         _buildSecurityTip('Не используйте личную информацию в пароле'),
//                         _buildSecurityTip('Не сообщайте пароль другим людям'),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSecurityTip(String tip) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             Icons.check_circle,
//             color: Colors.green.shade600,
//             size: 16,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               tip,
//               style: TextStyle(
//                 color: Colors.grey.shade700,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showChangePasswordDialog(BuildContext context) {
   
//   }
// }
