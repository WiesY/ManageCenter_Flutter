
// // Замените метод _buildBoilerCard в dashboard_screen.dart на этот:

// Widget _buildBoilerCard(BuildContext context, BoilerListItem boiler) {
//   return InkWell(
//     onTap: () {
//       Navigator.push(
//         context, 
//         MaterialPageRoute(
//           builder: (context) => BlocProvider(
//             create: (context) => BoilerDetailBloc(
//               apiService: context.read<ApiService>(),
//               storageService: context.read<StorageService>(),
//             ),
//             child: BoilerDetailScreen(
//               boilerId: boiler.id,
//               boilerName: boiler.name,
//               districtName: boiler.district.name,
//             ),
//           ),
//         ),
//       );
//     },
//     child: Container(
//       width: 120, // Можно задать ширину для единообразия
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.blue.shade100),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             boiler.name,
//             softWrap: true,
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Тип: ${boiler.boilerType.name}',
//             style: TextStyle(color: Colors.grey.shade700),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // Также добавьте эти импорты в начало dashboard_screen.dart:
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:manage_center/bloc/boiler_detail_bloc.dart';
// import 'package:manage_center/bloc/boiler_detail_bloc.dart';
// import 'package:manage_center/models/boiler_list_item_model.dart';
// import 'package:manage_center/screens/boiler_detail_screen.dart';
// import 'package:manage_center/services/api_service.dart';
// import 'package:manage_center/services/storage_service.dart';
