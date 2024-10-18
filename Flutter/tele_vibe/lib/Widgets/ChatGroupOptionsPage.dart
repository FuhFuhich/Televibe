import 'package:flutter/material.dart';

class ChatGroupOptionsPage extends StatefulWidget {
  const ChatGroupOptionsPage({super.key});

  @override
  _ChatGroupOptionsPageState createState() => _ChatGroupOptionsPageState();
}

class _ChatGroupOptionsPageState extends State<ChatGroupOptionsPage> {
  bool _isCreatingGroup = false;
  bool _isAddingChat = false;

  // Переменные для хранения данных
  String _groupName = '';
  String _groupPassword = '';
  String _textField = "";
  String _chatPassword = '';

  // Контроллеры для текстовых полей
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupPasswordController = TextEditingController();
  final TextEditingController _chatPasswordController = TextEditingController();
  bool _isPasswordRequired = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupPasswordController.dispose();
    _chatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Создание/Добавление чата")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Прижимаем к верхней части
          crossAxisAlignment: CrossAxisAlignment.center, // Центрируем по ширине
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isCreatingGroup = true;
                  _isAddingChat = false;
                });
              },
              child: const Text("Создать чат/группу"),
            ),
            const SizedBox(height: 16), // Отступ между кнопками
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isAddingChat = true;
                  _isCreatingGroup = false;
                });
              },
              child: const Text("Добавить чат/группу"),
            ),
            const SizedBox(height: 32), // Отступ перед полями ввода
            if (_isCreatingGroup) ...[
              TextField(
                controller: _groupNameController,
                onChanged: (value) {
                  setState(() {
                    _groupName = value; // Сохранение названия группы
                  });
                },
                decoration: const InputDecoration(labelText: "Название группы"),
              ),
              TextField(
                controller: _groupPasswordController,
                onChanged: (value) {
                  setState(() {
                    _groupPassword = value; // Сохранение пароля группы
                  });
                },
                decoration: const InputDecoration(labelText: "Пароль (если нужен)"),
                obscureText: true,
              ),
              TextField(
                controller: _groupPasswordController,
                onChanged: (value) {
                  setState(() {
                    _textField = value; // Сохранение пароля группы
                  });
                },
                decoration: const InputDecoration(labelText: "Текстовое поле"),
                obscureText: true,
              ),
              SwitchListTile(
                title: const Text("Чат/группа?"),
                value: _isPasswordRequired,
                onChanged: (value) {
                  setState(() {
                    _isPasswordRequired = value;
                  });
                },
              ),
            ],
            if (_isAddingChat) ...[
              TextField(
                controller: _chatPasswordController,
                onChanged: (value) {
                  setState(() {
                    _chatPassword = value; // Сохранение пароля чата/группы
                  });
                },
                decoration: const InputDecoration(labelText: "Пароль"),
                obscureText: true,
              ),
              SwitchListTile(
                title: const Text("Чат/группа?"),
                value: _isPasswordRequired,
                onChanged: (value) {
                  setState(() {
                    _isPasswordRequired = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      // Кнопка внизу экрана
      bottomNavigationBar: _isCreatingGroup || _isAddingChat
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_isCreatingGroup) {
                    // Логика создания группы с сохраненными данными
                    print("Создание группы: $_groupName с паролем: $_groupPassword");
                  } else if (_isAddingChat) {
                    // Логика добавления чата с сохраненными данными
                    print("Добавление чата с паролем: $_chatPassword");
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Кнопка по ширине экрана
                ),
                child: Text(_isCreatingGroup ? "Создать" : "Добавить"),
              ),
            )
          : null,
    );
  }
}
