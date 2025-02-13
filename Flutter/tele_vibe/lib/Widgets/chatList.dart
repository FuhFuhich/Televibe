import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tele_vibe/Data/chats.dart';
import 'package:tele_vibe/ViewModel/chatListVM.dart';
import 'chatInfo.dart';
import 'UnderWidgets/messageBubble.dart';
import 'UnderWidgets/fileUtils.dart';
import 'searchMessagesScreen.dart';
import 'package:tele_vibe/GettedData/netServerController.dart';
import 'dart:convert';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatListPage> {
  //final List<Map<String, dynamic>> entries = [
  //  {'text': 'Привет!', 'isMe': false, 'userName': 'Пользователь 1', 'time': '12:01'},
  //  {'text': 'Как дела?', 'isMe': false, 'userName': 'Пользователь 1', 'time': '12:02'},
  //  {'text': 'Хорошо, а у тебя?', 'isMe': true, 'userName': 'Я', 'time': '12:03'},
  //  {'text': 'Тоже хорошо!', 'isMe': true, 'userName': 'Я', 'time': '12:04'},
  //  {'text': 'Что нового?', 'isMe': false, 'userName': 'Пользователь 2', 'time': '12:05'},
  //  {'text': 'Ничего особенного.', 'isMe': true, 'userName': 'Я', 'time': '12:06'},
  //  {'text': 'Понятно.', 'isMe': false, 'userName': 'Пользователь 2', 'time': '12:07'},
  //];

  List<Map<String, dynamic>> filteredEntries = [];
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ChatListVM _chatListVM = ChatListVM();
  bool _isSearching = false;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();

    int kUsers = _chatListVM.getCountUsers();

    // Кинуть это в VM когда пойму как
    int queueId = Chats.getValue()
            .chats
            .where((chat) => chat.chatId == Chats.nowChat)
            .firstOrNull
            ?.nowQueueId ?? -1;

    List<(String, int)> queueChatNewMessages = [];

    NetServerController().getMessages(Chats.nowChat, queueId).then((newMessages) {
      if (newMessages != null && newMessages.isNotEmpty) {
        List<(String, int)> newMessagesFix = [];
        for (int i = 0; i < newMessages.length; i++) {
          if (newMessages[i] == "[]"){

          } else if (newMessages[i][0] == "[") {
            newMessagesFix.add((newMessages[i], -1));
          } else {
            newMessagesFix[newMessagesFix.length - 1] = 
            (newMessagesFix[newMessagesFix.length - 1].$1 + " " + newMessages[i],
            -1);
          }
        }
        queueChatNewMessages.addAll(newMessagesFix);

        int lastChangeId = -1;
        List<(String, int)> queues = [];
        for ((String, int) jsonString in queueChatNewMessages) {
          try {
            List<dynamic> decodedList = jsonDecode(jsonString.$1);
            List<Map<String, dynamic>> queueMap = [];
            if (decodedList.isNotEmpty && decodedList[0] is Map<String, dynamic>) {
              queueMap.addAll(List<Map<String, dynamic>>.from(decodedList));
            }

            for(int i = 0; i < queueMap.length; i++){
              if (queueMap[i].containsKey("changeId") && queueMap[i].containsKey("changeData") && queueMap[i].containsKey("senderId")) {
                int changeId = queueMap[i]["changeId"];
                if(lastChangeId < changeId){
                  lastChangeId = changeId;
                }
                String changeData = queueMap[i]["changeData"].toString();
                int senderid = queueMap[i]["senderId"];

                queues.add((changeData, senderid));
              }
            }
          } catch (e) {
            print("Ошибка парсинга JSON: $e");
          }
        }

        List<(String, int)> queueChat = Chats.getNowChatQueue();
        if(queueChat.isEmpty) {
          queueChat = [];
        }
        queueChat.addAll(queues);

        Chats.setNowChatQueue(queueChat, lastChangeId);

        for (int i = 0; i < queues.length; i++) {
          print(queues[i]);
        }
        _updateFilteredEntries(queueChat, context);
      }
    }).catchError((error) {
      print("Ошибка получения сообщений: $error");
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _updateFilteredEntries(List<(String, int)> queueChat, BuildContext context) async {
    List<Map<String, dynamic>> newEntries = await _chatListVM.queueToFiltred(queueChat, context);
    setState(() {
      filteredEntries = newEntries;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF141414),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.08),
        child: AppBar(
          backgroundColor: const Color(0xFF222222),
          automaticallyImplyLeading: false,
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatInfo(initialGroupName: 'Название группы')),
              );
            },
            child: _isSearching ? _buildSearchField() : _buildTitle(),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  // Я тут чото поменял 
                  MaterialPageRoute(builder: (context) => SearchMessagesScreen(messages: filteredEntries)),
                );
              }
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    return true;
                  },
                  child: ListView.builder(
                    reverse: true,
                    itemCount: filteredEntries.length,
                    controller: _scrollController,
                                      physics: const BouncingScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final messageIndex = filteredEntries.length - 1 - index;
                      final entry = filteredEntries[messageIndex];
                      bool showAvatar = false;

                      if (messageIndex == 0 || 
                          entry['userName'] != filteredEntries[messageIndex - 1]['userName']) {
                        showAvatar = !entry['isMe'];
                      }

                      return GestureDetector(
                        onLongPress: () => _showParticipantOptions(context, messageIndex),
                        child: MessageBubble(
                          text: entry['text'],
                          isMe: entry['isMe'],
                          userName: entry['userName'],
                          time: entry['time'],
                          showAvatar: showAvatar,
                          showUserName: !entry['isMe'],
                        ),
                      );
                    },
                  ),
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Поиск...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 18.0),
    );
  }

  Widget _buildTitle() {
    int kUsers = _chatListVM.getCountUsers();
    
    return Row(
      children: <Widget>[
        const CircleAvatar(
          backgroundImage: NetworkImage(
              'https://upload.wikimedia.org/wikipedia/commons/a/a8/Sample_Network.jpg'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _chatListVM.getNameGroup(), // Название группы
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              Text(
                kUsers == 1
                  ? "${kUsers.toString()} участник"
                  : kUsers >= 2 && kUsers <= 4
                      ? "${kUsers.toString()} участника"
                      : "${kUsers.toString()} участников",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 58.0,
      color: const Color(0xFF141414),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.white),
            onPressed: () async {
              final pickedImage = await FileUtils.pickImage();

              if (pickedImage != null) {
                setState(() {
                  // Логика сохранения пути к изображению
                  // Например, добавьте поле _profileImagePath
                  _profileImagePath = pickedImage.path;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Изображение не выбрано', 
                      style: TextStyle(color: Colors.white)
                    ),
                    backgroundColor: Color(0xFF222222)
                  ), // Если изображение не выбрано
                );
              }
            },
          ),
          Expanded(
            child: TextField(
              cursorColor: Colors.white,
              focusNode: _focusNode,
              maxLines: null,
              autocorrect: true,
              enableSuggestions: true,
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Введите ваше сообщение...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              String message = _textController.text;
              if (message.isNotEmpty) {
                _chatListVM.sendMessage(message);
                _textController.clear();
                _focusNode.requestFocus();
                _scrollToBottom();
              }
            },
          ),
        ],
      ),
    );
  }



  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    }
  }

  void _showParticipantOptions(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Сообщение',
            style: TextStyle(color: Colors.white), 
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white),
                title: const Text(
                  'Копировать',
                  style: TextStyle(color: Colors.white), 
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: filteredEntries[index]['text']));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Изменить',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.white), 
                title: const Text(
                  'Удалить',
                  style: TextStyle(color: Colors.white), 
                ),
                onTap: () {
                  setState(() {
                    _chatListVM.deleteMessage(filteredEntries[index]['id']);
                    //entries.removeAt(index);
                    //_filterMessages();  // Обновляем результаты поиска после удаления сообщения
                  });
                  Navigator.pop(context);
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


  void _showEditDialog(BuildContext context, int index) {
    TextEditingController editController = TextEditingController(text: filteredEntries[index]['text']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,  
          title: const Text(
            'Изменить сообщение',
            style: TextStyle(color: Colors.white),  
          ),
          content: TextField(
            controller: editController,
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white), 
            decoration: const InputDecoration(
              hintText: 'Введите текст сообщения',
              hintStyle: TextStyle(color: Colors.white60), 
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white), 
              ),
            ),
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
            TextButton(
              child: const Text(
                'Сохранить',
                style: TextStyle(color: Colors.white),  
              ),
              onPressed: () {
                setState(() {
                  //entries[index]['text'] = editController.text;
                  //_filterMessages();  // Обновляем результаты поиска после изменения сообщения
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String userName;
  final String time;
  final bool showAvatar;
  final bool showUserName;

  const MessageBubble({super.key, 
    required this.text,
    required this.isMe,
    required this.userName,
    required this.time,
    required this.showAvatar,
    required this.showUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        if (!isMe) ...[
          showAvatar
              ? const CircleAvatar(
                  backgroundImage: NetworkImage(
                      'https://upload.wikimedia.org/wikipedia/commons/a/a8/Sample_Network.jpg'),
                  radius: 15,
                )
              : const SizedBox(width: 31),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF222222) : const Color(0xFF222222), // Также изменить. 
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12.0),
                topRight: const Radius.circular(12.0),
                bottomLeft: isMe ? const Radius.circular(12.0) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(12.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (showUserName)
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.0),
                  ),
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.white, // Убрать позже
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 5.0),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
