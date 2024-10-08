import 'package:flutter/material.dart';
import 'package:tele_vibe/GettedData/localDataSaveController.dart';
import 'package:tele_vibe/GettedData/netServerController.dart';
import 'package:tele_vibe/Widgets/allChatsClass.dart';
import 'package:tele_vibe/Widgets/registrationClass.dart';

class LoginVM {

  void navigateToRegisterPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationPage()),
    );
  }

  void fakeLoginAccount(BuildContext context, 
  TextEditingController loginController, TextEditingController passwordController) {
    String login = loginController.text;
    String password = passwordController.text;

    print('Login: $login');
    print('Password: $password');

    print('Return Login');
    
    _startChatsAddiction();
    _navigateToAllChats(context);
  }

  void loginAccount(BuildContext context, 
  TextEditingController loginController, TextEditingController passwordController) {
    String login = loginController.text;
    String password = passwordController.text;

    print('Login: $login');
    print('Password: $password');

    NetServerController().login(login, password).then((goin) {
      if (goin != " ") {
        print('Return Login');
        _startChatsAddiction();
        _navigateToAllChats(context);
      }
    });
  }

  void _startChatsAddiction(){
    // Код вызывающий подгрузку Json и WS чатов
    LocalDataSave.loadChatsData();
    
  }

  void _navigateToAllChats(BuildContext context){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AllChatsPage()),
    );
  }
}