import 'dart:async';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:tele_vibe/Data/chats.dart';
import 'package:tele_vibe/ViewModel/allChatsVM.dart';
import 'package:tele_vibe/Widgets/chatList.dart';
import 'package:tele_vibe/Widgets/profileScreen.dart';
import 'package:tele_vibe/Widgets/settings.dart';
import 'package:tele_vibe/Widgets/chatGroupOptionsPage.dart';
import 'package:tele_vibe/Widgets/searchScreen.dart';

class AllChatsPage extends StatefulWidget {
  const AllChatsPage({super.key});

  @override
  _AllChatsClassState createState() => _AllChatsClassState();
}

class _AllChatsClassState extends State<AllChatsPage> {
  int _selectedIndex = 1;
  bool _isSearching = false; // Флаг для отображения строки поиска
  final TextEditingController _searchController = TextEditingController(); // Контроллер для строки поиска
  final AllChatsVM _allChatsVM = AllChatsVM();
  late final StreamSubscription subscriptionChats;
  ChatCollection chatsData = ChatCollection();






  final List<ChatData> _initialChats = [
    ChatData(
      chatName: 'Chat 1',
      chatId: '123abc',
      password: 'password1',
      nowQueueId: 1,
      chatIp: '',
      users: null,
      yourUserId: null,
    ),
    ChatData(
      chatName: 'Chat 2',
      chatId: '456def',
      password: 'password2',
      nowQueueId: 2,
      chatIp: '',
      users: null,
      yourUserId: null,
    ),
    ChatData(
      chatName: 'Chat 3',
      chatId: '789ghi',
      password: 'password3',
      nowQueueId: 3,
      chatIp: '',
      users: null,
      yourUserId: null,
    ),
    ChatData(
      chatName: 'Chat 4',
      chatId: '101jkl',
      password: 'password4',
      nowQueueId: 4,
      chatIp: '',
      users: null,
      yourUserId: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Инициализируем chatsData начальными значениями
    if(Chats.getValue().chats.isEmpty) {
      chatsData = ChatCollection(chats: _initialChats);
    }
    else {
      chatsData = Chats.getValue();
    }
    subscriptionChats = Chats.onValueChanged.listen((newValue) {
      chatsData = newValue;
      _getSelectedScreen();
    });
  }








  // @override
  // void initState() {
  //   subscriptionChats = Chats.onValueChanged.listen((newValue) {
  //     chatsData = newValue;
  //     _getSelectedScreen();
  //   });
  //   super.initState();
  // }

  @override
  void dispose() {
    _allChatsVM.dispose();
    super.dispose();
  }

  // Метод для выбора экрана в зависимости от выбранного индекса
  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const Settings(); // Экран настроек
      case 1:
        print('Case 1: показывается.Settings');
        return _buildChatList(); // Список чатов
      case 2:
        return const ProfileScreen(nickname: 'YourNickname'); // Экран профиля
      default:
        print('Default case: показывается список чатов');
        return _buildChatList(); // По умолчанию показывается список чатов
    }
  }

  // Строим список чатов как отдельный метод
  Widget _buildChatList() {
  return chatsData.chats.isNotEmpty
      ? ListView.builder(
          itemCount: chatsData.chats.length,
          itemBuilder: (BuildContext context, int index) {
            final chat = chatsData.chats[index]; // Ссылка на текущий чат
            return GestureDetector(
              onLongPress: () {
                _showParticipantOptions(context, index);
              },
              child: ListTile(
                onTap: () {
                  Chats.nowChat = chat.chatId;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatListPage()), // Переход на экран чата
                  );
                },
                leading: const CircleAvatar(
                  backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/a/a8/Sample_Network.jpg'), // Заменить на фотографию из БД
                ),
                tileColor: const Color(0xFF141414),
                textColor: Colors.white,
                title: Text(chat.chatName), // Название чата
                subtitle: Text(chat.getLastMessage()), // Сообщение
                trailing: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 32), // Отступ сверху
                    //Text(
                      //DateFormat.jm().format(chat.time), // Форматирование времени
                    //),

                    // Тут что такое время вопрос жЫзненный


                  ],
                ),
              ),
            );
          },
        )
      : const Center(
          child: Text(
            'You don\'t have chats(',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        );
  }

  void _showParticipantOptions(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Чат',
            style: TextStyle(color: Colors.white), 
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white),
                title: const Text(
                  'Очистить историю',
                  style: TextStyle(color: Colors.white), 
                ),
                onTap: () {
                  _allChatsVM.clearChatHistory();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Выйти из группы',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _allChatsVM.leaveGroup();
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Отмена',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isSearching = false; // Сбрасываем строку поиска при переключении вкладок
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: (_selectedIndex == 1)
          ? PreferredSize(
              preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.08),
              child: AppBar(
                backgroundColor: const Color(0xFF222222),
                automaticallyImplyLeading: false,
                title: const Text(
                  "Televibe", 
                  style: TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    color: Colors.white,
                    onPressed: () {
                      // Переход на новую активность
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                  ),
                ],
              ),
            )
          : null,
      body: _getSelectedScreen(), // Показ выбранного экрана
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF141414),
        //selectedItemColor: const Color(0xFF02040E),
        selectedItemColor: Colors.white.withOpacity(0.5),
        unselectedItemColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatGroupOptionsPage()),
          );
        },
        backgroundColor: const Color(0xFF222222),
        child: const Icon(Icons.add, color: Colors.white,),
      ),
    );
  }
}
