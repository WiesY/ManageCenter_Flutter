import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/boiler_types_bloc.dart';
import 'package:manage_center/models/boiler_type_model.dart';

class BoilerTypesManagementScreen extends StatefulWidget {
  const BoilerTypesManagementScreen({super.key});

  @override
  State<BoilerTypesManagementScreen> createState() => _BoilerTypesManagementScreenState();
}

class _BoilerTypesManagementScreenState extends State<BoilerTypesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Загружаем типы объектов при открытии
    context.read<BoilerTypesBloc>().add(FetchBoilerTypes());
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
        appBar: AppBar(title: const Text('Управление типами объектов')),
        body: const Center(
          child: Text(
            'У вас нет прав на управление типами объектов.',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление типами объектов'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue, // Адаптируй под primary color
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<BoilerTypesBloc>().add(FetchBoilerTypes()),
          ),
        ],
      ),
      body: RefreshIndicator(
    onRefresh: () async {
      context.read<BoilerTypesBloc>().add(FetchBoilerTypes());
      return Future.delayed(const Duration(milliseconds: 300));
    },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск по названию типа',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
            Expanded(
              child: BlocBuilder<BoilerTypesBloc, BoilerTypesState>(
                builder: (context, state) {
                  if (state is BoilerTypesLoading) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  } else if (state is BoilerTypesLoaded) {
                    final filteredBoilerTypes = state.boilerTypes
                        .where((boilerType) => boilerType.name.toLowerCase().contains(_searchQuery))
                        .toList();
                    if (filteredBoilerTypes.isEmpty) {
                      return const Center(child: Text('Нет типов объектов или ничего не найдено.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredBoilerTypes.length,
                      itemBuilder: (context, index) {
                        final boilerType = filteredBoilerTypes[index];
                        return Dismissible(
                          key: Key(boilerType.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) => _confirmDelete(context, boilerType),
                          onDismissed: (direction) => context.read<BoilerTypesBloc>().add(DeleteBoilerType(boilerType.id)),
                          child: Card(
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            color: Colors.white,
                            child: ListTile(
                              title: Text(boilerType.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showBoilerTypeForm(context, boilerType: boilerType),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is BoilerTypesError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ошибка: ${state.error}', style: const TextStyle(color: Colors.red)),
                          TextButton(
                            onPressed: () => context.read<BoilerTypesBloc>().add(FetchBoilerTypes()),
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
        onPressed: () => _showBoilerTypeForm(context),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Диалог подтверждения удаления
  Future<bool?> _confirmDelete(BuildContext context, BoilerType boilerType) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить тип объекта "${boilerType.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // Диалог формы для создания/обновления типа объекта
  void _showBoilerTypeForm(BuildContext context, {BoilerType? boilerType}) {
    final isEdit = boilerType != null;
    final nameController = TextEditingController(text: boilerType?.name ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Редактировать тип объекта' : 'Добавить тип объекта'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Название типа объекта'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            TextButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Название типа объекта обязательно')));
                  return;
                }
                final boilerTypeData = {
                  'name': nameController.text,
                };
                if (isEdit) {
                  context.read<BoilerTypesBloc>().add(UpdateBoilerType(boilerType!.id, boilerTypeData));
                } else {
                  context.read<BoilerTypesBloc>().add(CreateBoilerType(boilerTypeData));
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Сохранить' : 'Добавить'),
            ),
          ],
        );
      },
    );
  }
}