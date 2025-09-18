import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/parameter_groups_bloc.dart';
import 'package:manage_center/models/parameter_group_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ParamGroupsManagementScreen extends StatefulWidget {
  const ParamGroupsManagementScreen({super.key});

  @override
  State<ParamGroupsManagementScreen> createState() => _ParamGroupsManagementScreenState();
}

class _ParamGroupsManagementScreenState extends State<ParamGroupsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    // Загружаем группы параметров при открытии
    context.read<ParameterGroupsBloc>().add(FetchParameterGroups());
  }
  
  // Проверка прав на управление (из AuthBloc)
  bool get _hasManageRights {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      return authState.userInfo.role?.canManageBoilers ?? false;
    }
    return false; // Если не авторизован или нет прав
  }

  // Получение иконки для группы
  void _loadGroupIcon(int groupId) {
    final bloc = context.read<ParameterGroupsBloc>();
    
    // Проверяем, есть ли иконка уже в кэше блока
    if (!bloc.iconCache.containsKey(groupId)) {
      try {
        bloc.add(FetchParameterGroupIcon(groupId));
      } catch (e) {
        print('Ошибка при загрузке иконки: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasManageRights) {
      return Scaffold(
        appBar: AppBar(title: const Text('Управление группами параметров')),
        body: const Center(
          child: Text(
            'У вас нет прав на управление группами параметров.',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление группами параметров'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue, // Адаптируй под primary color
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ParameterGroupsBloc>().add(FetchParameterGroups()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ParameterGroupsBloc>().add(FetchParameterGroups());
          return Future.delayed(const Duration(milliseconds: 300));
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск по названию группы',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
            Expanded(
              child: BlocBuilder<ParameterGroupsBloc, ParameterGroupsState>(
                builder: (context, state) {
                  // Получаем блок для доступа к кэшу иконок
                  final bloc = context.read<ParameterGroupsBloc>();
                  
                  if (state is ParameterGroupsLoadInProgress) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  } else if (state is ParameterGroupsLoadSuccess || 
                            state is ParameterGroupIconLoadSuccess ||
                            state is ParameterGroupIconLoadInProgress) {
                    
                    // Получаем список групп из разных состояний
                    List<ParameterGroup> groups = [];
                    if (state is ParameterGroupsLoadSuccess) {
                      groups = state.parameterGroups;
                    } else if (state is ParameterGroupIconLoadSuccess) {
                      groups = state.parameterGroups;
                    } else if (state is ParameterGroupIconLoadInProgress) {
                      groups = state.parameterGroups;
                    }
                    
                    final filteredGroups = groups
                        .where((group) => group.name.toLowerCase().contains(_searchQuery))
                        .toList();
                        
                    if (filteredGroups.isEmpty) {
                      return const Center(child: Text('Нет групп параметров или ничего не найдено.'));
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = filteredGroups[index];
                        // Загружаем иконку для группы, если она есть
                        if (group.iconFileName != null && group.iconFileName!.isNotEmpty) {
                          _loadGroupIcon(group.id);
                        }
                        
                        return Dismissible(
                          key: Key(group.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) => _confirmDelete(context, group),
                          onDismissed: (direction) => _deleteParameterGroup(group.id),
                          child: Card(
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            color: Colors.white,
                            child: ListTile(
                              leading: _buildGroupIcon(group, bloc.iconCache),
                              title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('ID: ${group.id}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showParameterGroupForm(context, group: group),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is ParameterGroupsLoadFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ошибка: ${state.error}', style: const TextStyle(color: Colors.red)),
                          TextButton(
                            onPressed: () => context.read<ParameterGroupsBloc>().add(FetchParameterGroups()),
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
        onPressed: () => _showParameterGroupForm(context),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Виджет для отображения иконки группы
  Widget _buildGroupIcon(ParameterGroup group, Map<int, String> iconCache) {
    // Если у группы есть цвет, преобразуем его из строки в Color
    Color groupColor = Colors.blue;
    if (group.color != null && group.color!.isNotEmpty) {
      try {
        // Формат цвета: #RRGGBBAA
        final colorStr = group.color!;
        if (colorStr.startsWith('#') && colorStr.length == 9) {
          final hexColor = colorStr.substring(1);
          final r = int.parse(hexColor.substring(0, 2), radix: 16);
          final g = int.parse(hexColor.substring(2, 4), radix: 16);
          final b = int.parse(hexColor.substring(4, 6), radix: 16);
          final a = int.parse(hexColor.substring(6, 8), radix: 16);
          groupColor = Color.fromARGB(a, r, g, b);
        }
      } catch (e) {
        print('Ошибка при парсинге цвета: $e');
      }
    }
    
    // Если у группы есть иконка и она загружена в кэш
    if (group.iconFileName != null && group.iconFileName!.isNotEmpty && iconCache.containsKey(group.id)) {
      try {
        // Предполагаем, что иконка хранится в base64
        final iconData = iconCache[group.id]!;
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: groupColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.memory(
              base64Decode(iconData),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        print('Ошибка при отображении иконки: $e');
      }
    }
    
    // Если иконки нет или ошибка, показываем стандартную иконку
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: groupColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.folder, color: groupColor),
    );
  }

  // Диалог подтверждения удаления
  Future<bool?> _confirmDelete(BuildContext context, ParameterGroup group) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить группу параметров "${group.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // Метод удаления группы параметров
  void _deleteParameterGroup(int groupId) async {
    try {
      // Вызов события удаления группы параметров
      context.read<ParameterGroupsBloc>().add(DeleteParameterGroup(groupId));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Группа параметров успешно удалена')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении группы параметров: $e')),
      );
    }
  }

  // Диалог формы для создания/обновления группы параметров
  void _showParameterGroupForm(BuildContext context, {ParameterGroup? group}) {
    final isEdit = group != null;
    final nameController = TextEditingController(text: group?.name ?? '');
    
    // Начальные значения для цвета и иконки
    String selectedColor = group?.color ?? '#0000FFFF'; // Синий по умолчанию
    String? selectedIconFileName = group?.iconFileName;
    File? selectedIconFile;
    
    // Преобразуем строку цвета в объект Color для отображения
    Color pickerColor = Colors.blue;
    if (selectedColor.startsWith('#') && selectedColor.length == 9) {
      try {
        final hexColor = selectedColor.substring(1);
        final r = int.parse(hexColor.substring(0, 2), radix: 16);
        final g = int.parse(hexColor.substring(2, 4), radix: 16);
        final b = int.parse(hexColor.substring(4, 6), radix: 16);
        final a = int.parse(hexColor.substring(6, 8), radix: 16);
        pickerColor = Color.fromARGB(a, r, g, b);
      } catch (e) {
        print('Ошибка при парсинге цвета: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Получаем блок для доступа к кэшу иконок
            final bloc = context.read<ParameterGroupsBloc>();
            
            return AlertDialog(
              title: Text(isEdit ? 'Редактировать группу параметров' : 'Добавить группу параметров'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название группы'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Выбор цвета
                    const Text('Выберите цвет:'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Выберите цвет'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: pickerColor,
                                  onColorChanged: (Color color) {
                                    setState(() {
                                      pickerColor = color;
                                      // Преобразуем Color в строку формата #RRGGBBAA
                                      selectedColor = '#${color.red.toRadixString(16).padLeft(2, '0')}'
                                          '${color.green.toRadixString(16).padLeft(2, '0')}'
                                          '${color.blue.toRadixString(16).padLeft(2, '0')}'
                                          '${color.alpha.toRadixString(16).padLeft(2, '0')}';
                                    });
                                  },
                                  pickerAreaHeightPercent: 0.8,
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Готово'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: pickerColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Выбор иконки
                    const Text('Иконка группы:'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Отображение текущей иконки или заглушки
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: pickerColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: selectedIconFile != null
                              ? ClipOval(
                                  child: Image.file(
                                    selectedIconFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : selectedIconFileName != null && group != null && bloc.iconCache.containsKey(group.id)
                                  ? ClipOval(
                                      child: Image.memory(
                                        base64Decode(bloc.iconCache[group.id]!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(Icons.folder, color: pickerColor),
                        ),
                        
                        // Кнопка выбора файла
                        ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );
                            
                            if (result != null && result.files.single.path != null) {
                              setState(() {
                                selectedIconFile = File(result.files.single.path!);
                                selectedIconFileName = result.files.single.name;
                              });
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Выбрать иконку'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Название группы обязательно для заполнения')),
                      );
                      return;
                    }
                    
                    if (isEdit) {
                      _updateParameterGroup(
                        group!.id,
                        nameController.text,
                        selectedColor,
                        selectedIconFileName ?? '',
                        selectedIconFile,
                      );
                    } else {
                      _createParameterGroup(
                        nameController.text,
                        selectedColor,
                        selectedIconFileName ?? '',
                        selectedIconFile,
                      );
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

  // Метод создания группы параметров
void _createParameterGroup(String name, String color, String iconFileName, File? iconFile) async {
  try {
    // Показываем индикатор загрузки
    final loadingDialog = _showLoadingDialog(context, 'Создание группы...');
    
    // Вызов события создания группы параметров
    final bloc = context.read<ParameterGroupsBloc>();
    
    // Если есть файл иконки, сначала нужно его загрузить на сервер
    if (iconFile != null) {
      // Здесь должен быть код для загрузки файла иконки
      // Например:
      // final uploadResult = await _apiService.uploadGroupIcon(iconFile);
      // iconFileName = uploadResult.fileName;
    }
    
    // Создаем группу
    bloc.add(CreateParameterGroup(name, color, iconFileName));
    
    // Ждем небольшую задержку для завершения операции
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Закрываем диалог загрузки
    Navigator.of(context, rootNavigator: true).pop();
    
    // Показываем сообщение об успехе
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Группа параметров успешно создана')),
    );
    
    // Принудительно обновляем список групп
    bloc.add(FetchParameterGroups());
  } catch (e) {
    // Закрываем диалог загрузки, если он открыт
    Navigator.of(context, rootNavigator: true).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при создании группы параметров: $e')),
    );
  }
}

// Метод обновления группы параметров
void _updateParameterGroup(int groupId, String name, String color, String iconFileName, File? iconFile) async {
  try {
    // Показываем индикатор загрузки
    final loadingDialog = _showLoadingDialog(context, 'Обновление группы...');
    
    // Вызов события обновления группы параметров
    final bloc = context.read<ParameterGroupsBloc>();
    
    // Если есть файл иконки, сначала нужно его загрузить на сервер
    if (iconFile != null) {
      // Здесь должен быть код для загрузки файла иконки
      // Например:
      // final uploadResult = await _apiService.uploadGroupIcon(iconFile);
      // iconFileName = uploadResult.fileName;
    }
    
    // Обновляем группу
    bloc.add(UpdateParameterGroup(
      groupId,
      name,
      color,
      iconFileName,
    ));
    
    // Ждем небольшую задержку для завершения операции
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Закрываем диалог загрузки
    Navigator.of(context, rootNavigator: true).pop();
    
    // Показываем сообщение об успехе
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Группа параметров успешно обновлена')),
    );
    
    // Принудительно обновляем список групп
    bloc.add(FetchParameterGroups());
  } catch (e) {
    // Закрываем диалог загрузки, если он открыт
    Navigator.of(context, rootNavigator: true).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при обновлении группы параметров: $e')),
    );
  }
}

// Вспомогательный метод для отображения диалога загрузки
Widget _showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      );
    },
  );
  
  // Возвращаем пустой виджет, так как диалог показывается через showDialog
  return const SizedBox.shrink();
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}