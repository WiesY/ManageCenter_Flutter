import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/boilers_bloc.dart';
import 'package:manage_center/bloc/districts_bloc.dart';
import 'package:manage_center/bloc/boiler_types_bloc.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/models/district_model.dart';
import 'package:manage_center/models/boiler_type_model.dart';

class BoilersManagementScreen extends StatefulWidget {
  const BoilersManagementScreen({super.key});

  @override
  State<BoilersManagementScreen> createState() => _BoilersManagementScreenState();
}

class _BoilersManagementScreenState extends State<BoilersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<District> _districts = [];
  List<BoilerType> _boilerTypes = [];

  StreamSubscription? _districtsSubscription;
  StreamSubscription? _boilerTypesSubscription;
  
  @override
  void initState() {
    super.initState();
    // Загружаем объекты при открытии
    context.read<BoilersBloc>().add(FetchBoilers());
    
    // Загружаем районы и типы объектов для форм создания/редактирования
    _loadDistrictsAndBoilerTypes();
  }
  
  void _loadDistrictsAndBoilerTypes() {
    // Загрузка районов
    context.read<DistrictsBloc>().add(FetchDistricts());
    // Загрузка типов объектов
    context.read<BoilerTypesBloc>().add(FetchBoilerTypes());
    
    // Слушаем изменения в блоках и сохраняем подписки
    _districtsSubscription = context.read<DistrictsBloc>().stream.listen((state) {
      if (state is DistrictsLoaded && mounted) {
        setState(() {
          _districts = state.districts;
        });
      }
    });
    
    _boilerTypesSubscription = context.read<BoilerTypesBloc>().stream.listen((state) {
      if (state is BoilerTypesLoaded && mounted) {
        setState(() {
          _boilerTypes = state.boilerTypes;
        });
      }
    });
  }

  // Проверка прав на управление (из AuthBloc)
  bool get _hasManageRights {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      return authState.userInfo.role?.canManageBoilers ?? false;
    }
    return false; // Если не авторизован или нет прав
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasManageRights) {
      return Scaffold(
        appBar: AppBar(title: const Text('Управление объектами')),
        body: const Center(
          child: Text(
            'У вас нет прав на управление объектами.',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление объектами'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue, // Адаптируй под primary color
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<BoilersBloc>().add(FetchBoilers()),
          ),
        ],
      ),
      body: RefreshIndicator(
    onRefresh: () async {
      context.read<BoilersBloc>().add(FetchBoilers());
      return Future.delayed(const Duration(milliseconds: 300));
    },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск по названию объекта',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
            Expanded(
              child: BlocBuilder<BoilersBloc, BoilersState>(
                builder: (context, state) {
                  if (state is BoilersLoadInProgress) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  } else if (state is BoilersLoadSuccess) {
                    final filteredBoilers = state.boilers
                        .where((boiler) => boiler.name.toLowerCase().contains(_searchQuery))
                        .toList();
                    if (filteredBoilers.isEmpty) {
                      return const Center(child: Text('Нет объектов или ничего не найдено.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredBoilers.length,
                      itemBuilder: (context, index) {
                        final boiler = filteredBoilers[index];
                        return Dismissible(
                          key: Key(boiler.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) => _confirmDelete(context, boiler),
                          onDismissed: (direction) => _deleteBoiler(boiler.id),
                          child: Card(
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            color: Colors.white,
                            child: ListTile(
                              title: Text(boiler.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Район: ${boiler.district.name}'),
                                  Text('Тип: ${boiler.boilerType.name}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showBoilerForm(context, boiler: boiler),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is BoilersLoadFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ошибка: ${state.error}', style: const TextStyle(color: Colors.red)),
                          TextButton(
                            onPressed: () => context.read<BoilersBloc>().add(FetchBoilers()),
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBoilerForm(context),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Диалог подтверждения удаления
  Future<bool?> _confirmDelete(BuildContext context, BoilerListItem boiler) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить объект "${boiler.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // Метод удаления объекта
void _deleteBoiler(int boilerId) async {
  try {
    // Вызов события удаления объекта
    context.read<BoilersBloc>().add(DeleteBoiler(boilerId));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Объект успешно удален')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при удалении объекта: $e')),
    );
  }
}

  // Диалог формы для создания/обновления объекта
  void _showBoilerForm(BuildContext context, {BoilerListItem? boiler}) {
    final isEdit = boiler != null;
    final nameController = TextEditingController(text: boiler?.name ?? '');
    
    // Начальные значения для выпадающих списков
    int? selectedDistrictId = boiler?.district.id;
    int? selectedBoilerTypeId = boiler?.boilerType.id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Редактировать объект' : 'Добавить объект'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название объекта'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Выпадающий список районов
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Район'),
                      value: selectedDistrictId,
                      items: _districts.map((district) {
                        return DropdownMenuItem<int>(
                          value: district.id,
                          child: Text(district.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDistrictId = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Выпадающий список типов объектов
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Тип объекта'),
                      value: selectedBoilerTypeId,
                      items: _boilerTypes.map((type) {
                        return DropdownMenuItem<int>(
                          value: type.id,
                          child: Text(type.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBoilerTypeId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isEmpty || selectedDistrictId == null || selectedBoilerTypeId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Все поля обязательны для заполнения')),
                      );
                      return;
                    }
                    
                    final boilerData = {
                      'name': nameController.text,
                      'districtId': selectedDistrictId,
                      'boilerTypeId': selectedBoilerTypeId,
                    };
                    
                    if (isEdit) {
                      _updateBoiler(boiler.id, boilerData);
                    } else {
                      _createBoiler(boilerData);
                    }
                    
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'Сохранить' : 'Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Метод создания объекта
void _createBoiler(Map<String, dynamic> boilerData) async {
  try {
    // Вызов события создания объекта
    context.read<BoilersBloc>().add(CreateBoiler(boilerData));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Объект успешно создан')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при создании объекта: $e')),
    );
  }
}

// Метод обновления объекта
void _updateBoiler(int boilerId, Map<String, dynamic> boilerData) async {
  try {
    // Вызов события обновления объекта
    context.read<BoilersBloc>().add(UpdateBoiler(boilerId, boilerData));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Объект успешно обновлен')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при обновлении объекта: $e')),
    );
  }
}
@override
  void dispose() {
    // Отписываемся от стримов при уничтожении экрана
    _districtsSubscription?.cancel();
    _boilerTypesSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
