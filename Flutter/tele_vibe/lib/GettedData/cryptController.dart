import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/api.dart'; // Импорт необходимых классов и интерфейсов
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart' as keygen;
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';

class CryptController {
  // Функция для создания AES шифратора
  static (encrypt.IV, encrypt.Encrypter) GenCrypter(String aesEncryptionKey) {
    final String paddedKey = aesEncryptionKey.padRight(32, '0').substring(0, 32);
    final key = encrypt.Key.fromUtf8(paddedKey);
    String ivString = aesEncryptionKey.padRight(16, '0').substring(0, 16);
    final iv = encrypt.IV.fromUtf8(ivString);

    return (
      iv,
      encrypt.Encrypter(
        encrypt.AES(
          key, 
          mode: encrypt.AESMode.ctr, 
          padding: null
        )
      )
    );
  }
    
  static String generateRandomString(int len) {
    var r = Random();
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => chars[r.nextInt(chars.length)]).join();
  }

  static (String, String) getRandomKeys(){
    return (generateRandomString(128), generateRandomString(128));
  }

  // Функция для шифрования текста (AES)
  static String encryptAES(String text, String key) {
    final (iv, encrypter) = GenCrypter(key);
    final encrypted = encrypter.encrypt(text, iv: iv);
    return encrypted.base64;
  }

  // Функция для расшифровки текста (AES)
  static String decryptAES(String encrypted, String key) {
    final encryptedBytes = base64.decode(encrypted);
    final (iv, encrypter) = GenCrypter(key);
    final decrypted = encrypter.decrypt(
      encrypt.Encrypted(encryptedBytes),
      iv: iv,
    );
    return decrypted;
  }

  // Функция для генерации пары RSA-ключей
  static (RSAPublicKey, RSAPrivateKey) generateRSAKeyPair() {
    final keyParams = keygen.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 12);
    final secureRandom = _getSecureRandom();
    final generator = RSAKeyGenerator()
      ..init(ParametersWithRandom(keyParams, secureRandom));
    final pair = generator.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    return (publicKey, privateKey);
  }

  // Генерация криптостойкого случайного генератора
  static FortunaRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final seedSource = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seedSource)));
    return secureRandom;
  }

  // Шифрование текста с использованием RSA (подписывание приватным ключом)
  static String encryptRSA(String text, RSAPrivateKey privateKey) {
    final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
    final encrypted = encrypter.encrypt(text);
    return encrypted.base64;
  }

  // Расшифровка текста с использованием RSA (любой с публичным ключом может расшифровать)
  static String decryptRSA(String encrypted, RSAPublicKey publicKey) {
    final encryptedBytes = base64.decode(encrypted);
    final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
    final decrypted = encrypter.decrypt(encrypt.Encrypted(encryptedBytes));
    return decrypted;
  }
  
  static String xorEncryptWithExtendedKey(String text, String key) {
    // Расширение ключа до длины текста
    String extendedKey = _extendKey(key, text.length);
    
    // Шифрование с использованием XOR
    List<int> encryptedChars = List<int>.generate(text.length, (i) {
      return text.codeUnitAt(i) ^ extendedKey.codeUnitAt(i);
    });

    return String.fromCharCodes(encryptedChars);
  }

  static String _extendKey(String key, int length) {
    // Если ключ короче нужной длины, повторить его
    while (key.length < length) {
      key += key;
    }
    // Обрезать ключ до нужной длины
    return key.substring(0, length);
  }

  static String encryptPublicKey(String publicKey, String chatId, String chatPassword) {
    String combinedKey = chatId + chatPassword;
    return xorEncryptWithExtendedKey(publicKey, combinedKey);
  }

  static String encryptPrivateKey(String privateKey, String chatId, String chatPassword, int login, String password) {
    String combinedKey = chatId + chatPassword + login.toString() + password;
    return xorEncryptWithExtendedKey(privateKey, combinedKey);
  }

  static String decryptPublicKey(String encryptedPublicKey, String chatId, String chatPassword) {
    String combinedKey = chatId + chatPassword;
    return xorEncryptWithExtendedKey(encryptedPublicKey, combinedKey);
  }

  static String decryptPrivateKey(String encryptedPrivateKey, String chatId, String chatPassword, int login, String password) {
    String combinedKey = chatId + chatPassword + login.toString() + password;
    return xorEncryptWithExtendedKey(encryptedPrivateKey, combinedKey);
  }

  static String encryptAnonId(String anonId, String chatId, String chatPassword, String password) {
    String combinedKey = chatId + chatPassword + password;
    return xorEncryptWithExtendedKey(anonId, combinedKey);
  }

  static String decryptAnonId(String encryptedAnonId, String chatId, String chatPassword, String password) {
    String combinedKey = chatId + chatPassword + password;
    return xorEncryptWithExtendedKey(encryptedAnonId, combinedKey);
  }
}
