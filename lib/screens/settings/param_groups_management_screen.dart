import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/parameter_groups_bloc.dart';
import 'package:manage_center/models/parameter_group_model.dart';
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
    if (!bloc.iconCache.containsKey(groupId)) {
      bloc.add(FetchParameterGroupIcon(groupId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasManageRights) {
      return _buildNoAccessScreen();
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showParameterGroupForm(context),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Экран при отсутствии прав доступа
  Widget _buildNoAccessScreen() {
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
  
  // Построение AppBar
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Управление группами параметров'),
      foregroundColor: Colors.white,
      backgroundColor: Colors.blue,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<ParameterGroupsBloc>().add(FetchParameterGroups()),
        ),
      ],
    );
  }
  
  // Построение основного содержимого
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ParameterGroupsBloc>().add(FetchParameterGroups());
        return Future.delayed(const Duration(milliseconds: 300));
      },
      child: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _buildGroupsList(),
          ),
        ],
      ),
    );
  }
  
  // Поле поиска
  Widget _buildSearchField() {
    return Padding(
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
    );
  }
  
  // Список групп параметров
  Widget _buildGroupsList() {
    return BlocBuilder<ParameterGroupsBloc, ParameterGroupsState>(
      builder: (context, state) {
        final bloc = context.read<ParameterGroupsBloc>();
        
        if (state is ParameterGroupsLoadInProgress) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        } 
        
        if (state is ParameterGroupsLoadFailure) {
          return _buildErrorState(state.error);
        }
        
        // Получаем список групп из разных состояний
        List<ParameterGroup> groups = _getGroupsFromState(state);
        final filteredGroups = groups
            .where((group) => group.name.toLowerCase().contains(_searchQuery))
            .toList();
          
        if (filteredGroups.isEmpty) {
          return const Center(child: Text('Нет групп параметров или ничего не найдено.'));
        }
        
        return _buildGroupsListView(filteredGroups, bloc);
      },
    );
  }
  
  // Получение списка групп из разных состояний
  List<ParameterGroup> _getGroupsFromState(ParameterGroupsState state) {
    if (state is ParameterGroupsLoadSuccess) {
      return state.parameterGroups;
    } else if (state is ParameterGroupIconLoadSuccess) {
      return state.parameterGroups;
    } else if (state is ParameterGroupIconLoadInProgress) {
      return state.parameterGroups;
    }
    return [];
  }
  
  // Отображение ошибки загрузки
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Ошибка: $error', style: const TextStyle(color: Colors.red)),
          TextButton(
            onPressed: () => context.read<ParameterGroupsBloc>().add(FetchParameterGroups()),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
  
  // Построение списка групп
  Widget _buildGroupsListView(List<ParameterGroup> groups, ParameterGroupsBloc bloc) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        
        // Загружаем иконку для группы, если она есть
        if (group.iconFileName?.isNotEmpty == true) {
          _loadGroupIcon(group.id);
        }
        
        return _buildGroupItem(group, bloc);
      },
    );
  }
  
  // Элемент списка групп
  Widget _buildGroupItem(ParameterGroup group, ParameterGroupsBloc bloc) {
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
  }

  // Виджет для отображения иконки группы
  Widget _buildGroupIcon(ParameterGroup group, Map<int, String> iconCache) {
    // Парсинг цвета из строки
    Color groupColor = _parseColor(group.color);
    
    // Если у группы есть иконка и она загружена в кэш
    if (group.iconFileName?.isNotEmpty == true && iconCache.containsKey(group.id)) {
      try {
        return _buildIconContainer(
          groupColor, 
          ClipOval(
            child: Image.memory(
              base64Decode(iconCache[group.id]!),
              fit: BoxFit.cover,
            ),
          )
        );
      } catch (_) {}
    }
  
    // Стандартная иконка
    return _buildIconContainer(
      groupColor, 
      Icon(Icons.folder, color: groupColor)
    );
  }
  
  // Вспомогательный метод для создания контейнера иконки
  Widget _buildIconContainer(Color color, Widget child) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
  
  // Парсинг цвета из строки формата #RRGGBBAA
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.blue;
    
    try {
      if (colorStr.startsWith('#') && colorStr.length == 9) {
        final hexColor = colorStr.substring(1);
        final r = int.parse(hexColor.substring(0, 2), radix: 16);
        final g = int.parse(hexColor.substring(2, 4), radix: 16);
        final b = int.parse(hexColor.substring(4, 6), radix: 16);
        final a = int.parse(hexColor.substring(6, 8), radix: 16);
        return Color.fromARGB(a, r, g, b);
      }
    } catch (_) {}
    
    return Colors.blue;
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
  void _deleteParameterGroup(int groupId) {
    context.read<ParameterGroupsBloc>().add(DeleteParameterGroup(groupId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Группа параметров успешно удалена')),
    );
  }

// Предустановленные цвета для групп
final List<Map<String, dynamic>> _predefinedColors = [
  // Основные цвета
  {'name': 'Синий', 'color': '#1976D2FF', 'materialColor': Colors.blue[700]},
  {'name': 'Голубой', 'color': '#03A9F4FF', 'materialColor': Colors.lightBlue},
  {'name': 'Бирюзовый', 'color': '#009688FF', 'materialColor': Colors.teal},
  {'name': 'Зеленый', 'color': '#43A047FF', 'materialColor': Colors.green[600]},
  
  // Теплые цвета
  {'name': 'Лаймовый', 'color': '#7CB342FF', 'materialColor': Colors.lightGreen[700]},
  {'name': 'Янтарный', 'color': '#FFA000FF', 'materialColor': Colors.amber[700]},
  {'name': 'Оранжевый', 'color': '#F57C00FF', 'materialColor': Colors.orange[700]},
  {'name': 'Терракотовый', 'color': '#E64A19FF', 'materialColor': Colors.deepOrange[700]},
  
  // Холодные цвета
  {'name': 'Индиго', 'color': '#3949ABFF', 'materialColor': Colors.indigo[600]},
  {'name': 'Фиолетовый', 'color': '#5E35B1FF', 'materialColor': Colors.deepPurple[600]},
  {'name': 'Пурпурный', 'color': '#8E24AAFF', 'materialColor': Colors.purple[600]},
  {'name': 'Сине-серый', 'color': '#546E7AFF', 'materialColor': Colors.blueGrey[600]},
];

  // Диалог формы для создания/обновления группы параметров
  void _showParameterGroupForm(BuildContext context, {ParameterGroup? group}) {
    final isEdit = group != null;
    final nameController = TextEditingController(text: group?.name ?? '');
  
    // Начальные значения для цвета и иконки
    String selectedColor = group?.color ?? '#1976D2FF'; // Синий по умолчанию
    String? selectedIconFileName = group?.iconFileName;
    File? selectedIconFile;
  
    // Находим соответствующий цвет из предустановленных
    Color pickerColor = Colors.blue[700]!;
    int selectedColorIndex = 0;
    
    // Ищем цвет в предустановленных
    for (int i = 0; i < _predefinedColors.length; i++) {
      if (_predefinedColors[i]['color'] == selectedColor) {
        selectedColorIndex = i;
        pickerColor = _predefinedColors[i]['materialColor'];
        break;
      }
    }
    
    // Если не нашли в предустановленных, парсим из строки
    if (selectedColorIndex == 0 && selectedColor != '#1976D2FF') {
      pickerColor = _parseColor(selectedColor);
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
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(_predefinedColors.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColorIndex = index;
                              pickerColor = _predefinedColors[index]['materialColor'];
                              selectedColor = _predefinedColors[index]['color'];
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _predefinedColors[index]['materialColor'],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColorIndex == index ? Colors.black : Colors.grey,
                                width: selectedColorIndex == index ? 2 : 1,
                              ),
                            ),
                            child: selectedColorIndex == index 
                                ? const Icon(Icons.check, color: Colors.white) 
                                : null,
                          ),
                        );
                      }),
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
                      
                        // Кнопка выбора файла будет добавлена при необходимости
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

  // Обобщенный метод для создания/обновления группы параметров
  Future<void> _saveParameterGroup({
    required String name, 
    required String color, 
    required String iconFileName, 
    File? iconFile,
    int? groupId
  }) async {
    final isEdit = groupId != null;
    final message = isEdit ? 'Обновление группы...' : 'Создание группы...';
    
    try {
      _showLoadingDialog(context, message);
      final bloc = context.read<ParameterGroupsBloc>();
      
      // Здесь можно добавить код для загрузки иконки, если нужно
      
      // Создаем или обновляем группу
      if (isEdit) {
        bloc.add(UpdateParameterGroup(groupId, name, color, iconFileName));
      } else {
        bloc.add(CreateParameterGroup(name, color, iconFileName));
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.of(context, rootNavigator: true).pop();
      
      final successMessage = isEdit 
          ? 'Группа параметров успешно обновлена' 
          : 'Группа параметров успешно создана';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      
      bloc.add(FetchParameterGroups());
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
  
  // Метод создания группы параметров
  void _createParameterGroup(String name, String color, String iconFileName, File? iconFile) {
    _saveParameterGroup(
      name: name,
      color: color,
      iconFileName: iconFileName,
      iconFile: iconFile
    );
  }
  
  // Метод обновления группы параметров
  void _updateParameterGroup(int groupId, String name, String color, String iconFileName, File? iconFile) {
    _saveParameterGroup(
      name: name,
      color: color,
      iconFileName: iconFileName,
      iconFile: iconFile,
      groupId: groupId
    );
  }

// Вспомогательный метод для отображения диалога загрузки
void _showLoadingDialog(BuildContext context, String message) {
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
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}