package com.example.teletypesha.activitys;

import static com.example.teletypesha.fragments.ChatsFragment.CreateFictChats;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;
import android.widget.ToggleButton;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.NotificationCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;

import com.example.teletypesha.R;
import com.example.teletypesha.crypt.Crypt;
import com.example.teletypesha.fragments.AddChatFragment;
import com.example.teletypesha.fragments.ChatsFragment;
import com.example.teletypesha.fragments.CreateChatFragment;
import com.example.teletypesha.fragments.LoginFragment;
import com.example.teletypesha.fragments.RegistrationFragment;
import com.example.teletypesha.fragments.SettingsChatFragment;
import com.example.teletypesha.fragments.SettingsFragment;
import com.example.teletypesha.fragments.SingleChatFragment;
import com.example.teletypesha.itemClass.Chat;
import com.example.teletypesha.itemClass.Message;
import com.example.teletypesha.itemClass.SharedViewByChats;
import com.example.teletypesha.itemClass.User;
import com.example.teletypesha.jsons.JsonDataSaver;
import com.example.teletypesha.netCode.NetServerController;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.CompletableFuture;

public class MainActivity extends AppCompatActivity {
    FragmentManager fragmentManager = getSupportFragmentManager();
    NetServerController netServerController;
    boolean isBound = false;
    private Fragment currentFragment;
    private static final String CHANNEL_ID = "encryption_channel";
    private static final int NOTIFICATION_ID = 1;
    public static String login, password;


    /// Перенести эту гадость в воркер
    private Handler handler = new Handler();
    private static final long DELAY_MINUTES = 1 * 10 * 1000; // 1 минута * сек * миллисекундах
    private Runnable periodicTask = new Runnable() {
        @Override
        public void run() {
            GetMessages();
            handler.postDelayed(this, DELAY_MINUTES);
        }
    };
    @Override
    protected void onResume() {
        super.onResume();
        handler.postDelayed(periodicTask, DELAY_MINUTES); // Запуск первой задачи при возобновлении активности
    }
    @Override
    protected void onPause() {
        super.onPause();
        handler.removeCallbacks(periodicTask); // Остановка задачи при приостановке активности
        JsonDataSaver.SaveChats(SharedViewByChats.getChatList(), this);
        if(login != null && password != null){
            try {
                NetServerController.Register(login, password, this);
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
    }
    @Override
    protected void onDestroy() {
        super.onDestroy();
        handler.removeCallbacks(periodicTask); // Остановка задачи при приостановке активности
        JsonDataSaver.SaveChats(SharedViewByChats.getChatList(), this);
        if(login != null && password != null){
            try {
                NetServerController.Register(login, password, this);
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
    }
    ///






    private ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName className, IBinder service) {
            Log.i("WebSocket", "Session is starting");
            NetServerController.LocalBinder binder = (NetServerController.LocalBinder) service;
            netServerController = binder.getService();
            isBound = true;

            OnCreateNet();
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            Log.i("WebSocket", "Session is closed");
            isBound = false;
        }
    };

    @Override
    public void onBackPressed() {
        FragmentManager fragmentManager = getSupportFragmentManager();
        Fragment currentFragment = fragmentManager.findFragmentById(R.id.main_fragment);

        if (currentFragment instanceof ChatsFragment) {
            OpenLoginFragment(null);
        } else if (currentFragment instanceof SingleChatFragment) {
            OpenChatsFragment();
        } else if (currentFragment instanceof SettingsFragment) {
            OpenChatsFragment();
        } else if (currentFragment instanceof AddChatFragment) {
            OpenChatsFragment();
        } else if (currentFragment instanceof CreateChatFragment) {
            OpenChatsFragment();
        } else if (currentFragment instanceof SettingsChatFragment) {
            OpenChat(SharedViewByChats.getSelectChat());
        } else {
            super.onBackPressed();
        }
    }


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        //Создание Json
        JsonDataSaver.AwakeJson();



        // Реализация создания сервера
        Log.i("WebSocket", "Try bindService");
        Intent intent = new Intent(this, NetServerController.class);
        startService(intent);
        bindService(intent, connection, Context.BIND_AUTO_CREATE);

    }

    protected void OnCreateNet(){
        //netServerController.CreateNewChat("", false);
        //Все для чего нужен сервер
        OpenLoginFragment(null);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.upper_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();

        if (id == R.id.action_setting_profile) {
            Toast.makeText(MainActivity.this, "Профиль", Toast.LENGTH_LONG).show();
            return true;
        } else if (id == R.id.action_setting_theme) {
            Toast.makeText(MainActivity.this, "Тема", Toast.LENGTH_LONG).show();
            OpenSettingsFragment();
            return true;
        } else if (id == R.id.action_setting_chats) {
            Toast.makeText(MainActivity.this, "Чаты", Toast.LENGTH_LONG).show();
            OpenChatsFragment();
            return true;
        } else if (id == R.id.action_setting_add_chat) {
            Toast.makeText(MainActivity.this, "Добавить чат", Toast.LENGTH_LONG).show();
            OpenAddChatFragment();
            return true;
        } else if (id == R.id.action_setting_create_chat) {
            Toast.makeText(MainActivity.this, "Создать чат", Toast.LENGTH_LONG).show();
            OpenCreateChatFragment();
            return true;
        }

        return super.onOptionsItemSelected(item);
    }











    public void LoginLocal(View view){
        EditText login1 = findViewById(R.id.login_login);
        EditText pass1 = findViewById(R.id.login_password);

        String login1Text = login1.getText().toString();
        String pass1Text = pass1.getText().toString();

        if (Objects.equals(login, login1Text) && Objects.equals(password, pass1Text)){
            OpenChatsFragment();
        } else {
            NotificationManager notificationManager = (NotificationManager) this.getSystemService(Context.NOTIFICATION_SERVICE);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "Encryption Progress", NotificationManager.IMPORTANCE_LOW);
                notificationManager.createNotificationChannel(channel);
            }
            String notificationText = "Регистрация не удалась изза некорректных данных";
            Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                    .setContentTitle("Register Stopped")
                    .setContentText(notificationText)
                    .setSmallIcon(R.drawable.ic_encryption)
                    .build();
            notificationManager.notify(NOTIFICATION_ID, notification);
            Log.e("WebSocket", "Reg not alowed");
        }
    }

    public void LoginGlobal(View view){
        EditText login1 = findViewById(R.id.login_login);
        EditText pass1 = findViewById(R.id.login_password);

        String login1Text = login1.getText().toString();
        String pass1Text = pass1.getText().toString();

        try {
            CompletableFuture<String> future = NetServerController.Login(login1Text, pass1Text, this);
            future.thenAccept(goin -> {
                if (goin != null) {
                    try {
                        JsonDataSaver.SaveAll(this, Crypt.DecryptUser(login1Text, pass1Text, goin, this));
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                    ForceCheckSavedChats();
                    OpenChatsFragment();
                } else {
                    NotificationManager notificationManager = (NotificationManager) this.getSystemService(Context.NOTIFICATION_SERVICE);
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "Encryption Progress", NotificationManager.IMPORTANCE_LOW);
                        notificationManager.createNotificationChannel(channel);
                    }
                    String notificationText = "Логин не удалась изза некорректных данных";
                    Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                            .setContentTitle("Login Stopped")
                            .setContentText(notificationText)
                            .setSmallIcon(R.drawable.ic_encryption)
                            .build();
                    notificationManager.notify(NOTIFICATION_ID, notification);
                    Log.e("WebSocket", "Reg not alowed");
                }
            });
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public void LoginGlobal(String login, String password){
        try {
            CompletableFuture<String> future = NetServerController.Login(login, password, this);
            future.thenAccept(goin -> {
                if (goin != null) {
                    try {
                        JsonDataSaver.SaveAll(this, Crypt.DecryptUser(login, password, goin, this));
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                    ForceCheckSavedChats();
                    OpenChatsFragment();
                } else {
                    NotificationManager notificationManager = (NotificationManager) this.getSystemService(Context.NOTIFICATION_SERVICE);
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "Encryption Progress", NotificationManager.IMPORTANCE_LOW);
                        notificationManager.createNotificationChannel(channel);
                    }
                    String notificationText = "Логин не удалась изза некорректных данных";
                    Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                            .setContentTitle("Login Stopped")
                            .setContentText(notificationText)
                            .setSmallIcon(R.drawable.ic_encryption)
                            .build();
                    notificationManager.notify(NOTIFICATION_ID, notification);
                    Log.e("WebSocket", "Reg not alowed");
                }
            });
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public void Register(View view) {
        EditText login1 = findViewById(R.id.registration_login);
        EditText login2 = findViewById(R.id.registration_login_2);
        EditText pass1 = findViewById(R.id.registration_password);
        EditText pass2 = findViewById(R.id.registration_password_2);

        String login1Text = login1.getText().toString();
        String login2Text = login2.getText().toString();
        String pass1Text = pass1.getText().toString();
        String pass2Text = pass2.getText().toString();

        if (Objects.equals(login1Text, login2Text) && Objects.equals(pass1Text, pass2Text)) {
            try {
                login = login1Text;
                password = pass1Text;

                ArrayList<Chat> chats = new ArrayList<>();
                CreateFictChats(chats);
                JsonDataSaver.SaveChats(chats, this);

                CompletableFuture<Boolean> future = netServerController.Register(login, password, this);
                future.thenAccept(goin -> {
                    if (goin) {
                        LoginGlobal(login, password);
                    } else {
                        NotificationManager notificationManager = (NotificationManager) this.getSystemService(Context.NOTIFICATION_SERVICE);
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "Encryption Progress", NotificationManager.IMPORTANCE_LOW);
                            notificationManager.createNotificationChannel(channel);
                        }
                        String notificationText = "Регистрация не удалась изза некорректных данных";
                        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                                .setContentTitle("Register Stopped")
                                .setContentText(notificationText)
                                .setSmallIcon(R.drawable.ic_encryption)
                                .build();
                        notificationManager.notify(NOTIFICATION_ID, notification);
                        Log.e("WebSocket", "Reg not alowed");
                    }
                });
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        } else {
            if (!Objects.equals(login1Text, login2Text)) {
                Toast.makeText(this, "Login fields do not match!", Toast.LENGTH_SHORT).show();
            } else if (!Objects.equals(pass1Text, pass2Text)) {
                Toast.makeText(this, "Password fields do not match!", Toast.LENGTH_SHORT).show();
            }
        }
    }

    public void OpenLoginFragment(View view){
        SharedViewByChats.setListener(null);

        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        LoginFragment loginFragment = new LoginFragment();

        CheckSavedChats();

        fragmentTransaction.replace(R.id.main_fragment, loginFragment);
        fragmentTransaction.commit();
    }

    public void OpenRegistrationFragment(View view){
        SharedViewByChats.setListener(null);

        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        RegistrationFragment registrationFragment = new RegistrationFragment();

        CheckSavedChats();

        fragmentTransaction.replace(R.id.main_fragment, registrationFragment);
        fragmentTransaction.commit();
    }

    private void OpenChatsFragment(){
        SharedViewByChats.setListener(null);

        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        ChatsFragment chatFragment = new ChatsFragment();

        GetMessages();

        fragmentTransaction.replace(R.id.main_fragment, chatFragment);
        fragmentTransaction.commit();
    }

    public void OpenSettingsFragment(){
        SharedViewByChats.setListener(null);

        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        SettingsFragment settingsFragment = new SettingsFragment();


        fragmentTransaction.replace(R.id.main_fragment, settingsFragment);
        fragmentTransaction.commit();
    }

    public void OpenChat(Chat chat){
        SharedViewByChats.setListener(null);

        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        SingleChatFragment singleChatFragment = new SingleChatFragment();

        GetMessages();
        SharedViewByChats.setSelectChat(chat);

        fragmentTransaction.replace(R.id.main_fragment, singleChatFragment);
        fragmentTransaction.commit();
    }

    public void OpenAddChatFragment(){
        SharedViewByChats.setListener(null);

        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        AddChatFragment addChatFragment = new AddChatFragment();


        fragmentTransaction.replace(R.id.main_fragment, addChatFragment);
        fragmentTransaction.commit();
    }

    public void OpenCreateChatFragment(){
        SharedViewByChats.setListener(null);

        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        CreateChatFragment createChatFragment = new CreateChatFragment();


        fragmentTransaction.replace(R.id.main_fragment, createChatFragment);
        fragmentTransaction.commit();
    }

    public void OpenChatSettingsFragment(View view){
        SharedViewByChats.setListener(null);

        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        SettingsChatFragment settingsChatFragment = new SettingsChatFragment();


        fragmentTransaction.replace(R.id.main_fragment, settingsChatFragment);
        fragmentTransaction.commit();
    }








    private String HashPassword(String password) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] encodedHash = digest.digest(password.getBytes(StandardCharsets.UTF_8));

            // Преобразовать байты в строку в формате hex
            StringBuilder hexString = new StringBuilder(2 * encodedHash.length);
            for (byte b : encodedHash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    public void CreateChat(View view) {
        String chatPassword = HashPassword(String.valueOf(((EditText) findViewById(R.id.create_chat_password)).getText()));
        ToggleButton toggleButton = (ToggleButton) findViewById(R.id.create_chat_is_privacy);

        CompletableFuture<String> future = netServerController.CreateNewChat(chatPassword, toggleButton.isChecked());
        future.thenAccept(goin -> {
            if (goin != null) {
                try {
                    AddChat(goin, chatPassword);
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
                Log.i("WebSocket", goin);
            } else {
                Log.e("WebSocket", "Get send msg unsuccessful");
            }
        });
    }

    public void AddChat(View view) throws Exception {
        String chatId = String.valueOf(((EditText) findViewById(R.id.add_chat_login)).getText());
        String chatPassword = HashPassword(String.valueOf(((EditText) findViewById(R.id.add_chat_password)).getText()));

        if(!SharedViewByChats.ChatIsExist(chatId)) {
            User user = new User("You");
            String pk = Crypt.CriptPublicKey(chatId, chatPassword, user.GetPublicKey());

            CompletableFuture<String> future = NetServerController.AddUserToChat(pk, chatId, chatPassword);
            future.thenAccept(goin -> {
                if (goin != null) {
                    LocalAddChat(chatId, chatPassword, user, Integer.valueOf(goin));
                    Log.i("WebSocket", goin);
                } else {
                    Log.e("WebSocket", "Get send msg unsuccessful");
                }
            });
        }
    }

    public void AddChat(String chatId, String chatPassword) throws Exception {

        User user = new User("You");
        String pk = Crypt.CriptPublicKey(chatId, chatPassword, user.GetPublicKey());

        CompletableFuture<String> future = NetServerController.AddUserToChat(pk, chatId, chatPassword);
        future.thenAccept(goin -> {
            if (goin != null) {
                LocalAddChat(chatId, goin, user, Integer.valueOf(goin));
                Log.i("WebSocket", goin);
            } else {
                Log.e("WebSocket", "Get send msg unsuccessful");
            }
        });
    }

    private void LocalAddChat(String idChat, String chatPassword, User user, Integer idUser){
        ArrayList<Chat> chatList = SharedViewByChats.getChatList();
        if (chatList == null){
            chatList = new ArrayList<>();
        }

        HashMap<Integer, User> users = new HashMap<>();
        users.put(idUser, user);
        chatList.add(new Chat(idUser, new ArrayList<>(), users, idChat, chatPassword));

        SharedViewByChats.setChatList(chatList);
    }

    public void SendMessage() {
        EditText editText = ((EditText) findViewById(R.id.message_edit_text));
        byte[] messange = SharedViewByChats.getSelectChat().GetUser(
                SharedViewByChats.getSelectChat().GetYourId()).Encrypt(String.valueOf(editText.getText()));
        Timestamp ts = new Timestamp(System.currentTimeMillis());

        CompletableFuture<String> future = NetServerController.SendMessage(messange, SharedViewByChats.getSelectChat().GetYourId(), ts);
        future.thenAccept(goin -> {
            if (goin != null) {
                editText.setText("");

                if(goin.equals("true")){
                    GetMessages();
                }

                Log.i("WebSocket", goin);
            } else {
                Log.e("WebSocket", "Get send msg unsuccessful");
            }
        });
    }

    public void SendMessageSkrepochka(Uri fileUri) {
        EditText editText = ((EditText) findViewById(R.id.message_edit_text));
        try {
            // Получаем InputStream из URI файла
            InputStream inputStream = getContentResolver().openInputStream(fileUri);

            // Преобразуем InputStream в байтовый массив
            ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            int length;
            while ((length = inputStream.read(buffer)) != -1) {
                byteArrayOutputStream.write(buffer, 0, length);
            }
            byte[] fileBytes = byteArrayOutputStream.toByteArray();

            // Шифруем содержимое файла
            if(fileBytes.length > 1024*1024*2){
                NotificationManager notificationManager = (NotificationManager) this.getSystemService(Context.NOTIFICATION_SERVICE);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "Encryption Progress", NotificationManager.IMPORTANCE_LOW);
                    notificationManager.createNotificationChannel(channel);
                }
                String notificationText = "item more then 2mb";
                Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                        .setContentTitle("Encryption Stopped")
                        .setContentText(notificationText)
                        .setSmallIcon(R.drawable.ic_encryption)
                        .build();
                notificationManager.notify(NOTIFICATION_ID, notification);
                return;
            }
            byte[] encryptedFile = SharedViewByChats.getSelectChat().GetUser(
                    SharedViewByChats.getSelectChat().GetYourId()).EncryptImage(this, fileBytes);

            // Отправляем сообщение
            Timestamp ts = new Timestamp(System.currentTimeMillis());
            CompletableFuture<String> future = NetServerController.SendMessage(encryptedFile, SharedViewByChats.getSelectChat().GetYourId(), ts);
            future.thenAccept(goin -> {
                if (goin != null) {
                    editText.setText("");

                    if (goin.equals("true")) {
                        GetMessages();
                    }

                    Log.i("WebSocket", goin);
                } else {
                    Log.e("WebSocket", "Get send msg unsuccessful");
                }
            });

            inputStream.close();
            byteArrayOutputStream.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }



    // Метод для чтения содержимого файла в байтовый массив
    private byte[] readFileToBytes(String filePath) throws IOException {
        File file = new File(filePath);
        FileInputStream fis = new FileInputStream(file);
        byte[] fileBytes = new byte[(int) file.length()];
        fis.read(fileBytes);
        fis.close();
        return fileBytes;
    }

    // Метод для создания объединенного сообщения, включая тип сообщения и данные
    private byte[] createCombinedMessage(String messageType, byte[] messageData) {
        // Создаем массив, включающий тип сообщения и данные
        byte[] messageTypeBytes = messageType.getBytes(StandardCharsets.UTF_8);
        byte[] combinedMessage = new byte[messageTypeBytes.length + messageData.length];
        System.arraycopy(messageTypeBytes, 0, combinedMessage, 0, messageTypeBytes.length);
        System.arraycopy(messageData, 0, combinedMessage, messageTypeBytes.length, messageData.length);
        return combinedMessage;
    }





    public void EditMessage(Message message, byte[] msg) {
        EditText editText = ((EditText) findViewById(R.id.message_edit_text));
        CompletableFuture<String> future = NetServerController.RefactorMessage(message.messageId, message.author, msg);

        future.thenAccept(goin -> {
            if (goin != null) {
                editText.setText("");

                if(goin.equals("true")){
                    ArrayList<Chat> chatList = new ArrayList<>();
                    chatList.addAll(SharedViewByChats.getChatList());
                    for (Chat chats : chatList) {
                        chats.isChanged = true;
                        if(chats.GetMessangeForId(message.messageId, message.author) != null){
                            chats.RemoveMessage(message.messageId, message.author);
                        }
                    }
                    SharedViewByChats.setChatList(chatList);
                    GetMessages();
                }

                Log.i("WebSocket", goin);
            } else {
                editText.setText("");

                Log.e("WebSocket", "Get send msg unsuccessful");
            }
        });
    }

    public void DeleteMessage(Chat chat, Message message) {
        if (Objects.equals(message.author, chat.GetYourId())) {
            CompletableFuture<String> future = NetServerController.DeleteMessage(message.author, message.messageId);

            future.thenAccept(goin -> {
                if (goin != null) {

                    ArrayList<Chat> chatList = new ArrayList<>();
                    chatList.addAll(SharedViewByChats.getChatList());
                    for (Chat chats : chatList) {
                        chats.isChanged = true;
                        if(chats.GetMessangeForId(message.messageId, message.author) != null){
                            chats.RemoveMessage(message.messageId, message.author);
                        }
                    }
                    SharedViewByChats.setChatList(chatList);
                    GetMessages();


                    Log.i("WebSocket", goin);
                } else {
                    Log.e("WebSocket", "Get send msg unsuccessful");
                }
            });
        }
    }










    private void ForceCheckSavedChats(){
        Log.i("Chats", "Start Check Save");
        ArrayList<Chat> chats = (JsonDataSaver.TryLoadChats(this));
        Log.i("Chats", "End Check Save");
        if(chats == null){
            chats = new ArrayList<>();
            // Это комментировать
            CreateFictChats(chats);
            JsonDataSaver.SaveChats(chats, this);
        }
        Log.i("Chats", "Start sharedViewByChats");
        SharedViewByChats.setChatList(chats);
        Log.i("Chats", "End sharedViewByChats");
    }

    private void CheckSavedChats(){
        if (SharedViewByChats.getChatList() == null){
            Log.i("Chats", "Start Check Save");
            ArrayList<Chat> chats = (JsonDataSaver.TryLoadChats(this));
            Log.i("Chats", "End Check Save");
            if(chats == null){
                chats = new ArrayList<>();
                // Это комментировать
                CreateFictChats(chats);
                JsonDataSaver.SaveChats(chats, this);
            }
            Log.i("Chats", "Start sharedViewByChats");
            SharedViewByChats.setChatList(chats);
            Log.i("Chats", "End sharedViewByChats");
        }
    }

    private String CreateGetMessagesStr(){
        StringBuilder str = new StringBuilder();

        str.append(SharedViewByChats.getChatList().size());

        for (int i = 0; i < SharedViewByChats.getChatList().size(); i++){
            Chat chat = SharedViewByChats.getChatList().get(i);
            HashMap<Integer, ArrayList<Integer>> missMsg;
            missMsg = chat.GetMissingIdsForAllAuthors();
            if(missMsg == null || missMsg.isEmpty()){
                continue;
            }

            str.append(" " + chat.GetChatId() + " " + missMsg.size());

            for(Map.Entry<Integer, ArrayList<Integer>> entry : missMsg.entrySet()){
                int authorId = entry.getKey();
                ArrayList<Integer> messages = entry.getValue();
                int messageCount = messages.size();

                if(chat.GetUser(authorId).GetPublicKey() == null) {
                    str.append(" " + authorId + " " + "false" + " " + messageCount);
                }
                else {
                    str.append(" " + authorId + " " + "true" + " " + messageCount);
                }

                for(Integer msg : messages){
                    str.append(" " + msg);
                }
            }
        }

        return str.toString();
    }

    private void GetMessages(){
        CheckSavedChats();

        String str = CreateGetMessagesStr();

        CompletableFuture<String[]> future = NetServerController.GetMessages(str.toString());
        future.thenAccept(goin -> {
            if (goin != null) {
                UpdateMessages(goin);
                Log.i("WebSocket", String.valueOf(goin.length));
            } else {
                Log.e("WebSocket", "Get send msg unsuccessful");
            }
        });
    }

    public void UpdateMessages(String[] parts){
        Log.i("Chats", "Start Chat Upgrade");
        ArrayList<Chat> chatList = new ArrayList<>();
        chatList.addAll(SharedViewByChats.getChatList());
        int index = 0;

        ArrayList<Integer> erased = new ArrayList<>();
        int chatCount = Integer.valueOf(parts[index++]);
        for(int i = 0; i < chatCount; i++){
            String chatId = parts[index++];
            int authorCount = Integer.valueOf(parts[index++]);

            int messagesAddedToChat = 0; // Counter for messages added to the chat

            for(int j = 0; j < authorCount; j++) {
                int authorId = Integer.parseInt(parts[index++]);
                PublicKey publicKey = null;
                if (Boolean.parseBoolean(parts[index++])){
                    for (Chat chat : chatList) {
                        if (Objects.equals(chat.GetChatId(), chatId)) {
                            try {
                                publicKey = Crypt.DecryptPublicKey(chatId, chat.GetChatPass(), parts[index++]);
                            } catch (Exception e) {
                                throw new RuntimeException(e);
                            }
                        }
                    }
                }
                int msgCount = Integer.valueOf(parts[index++]);

                for(int k = 0; k < msgCount; k++) {

                    int idMsg = Integer.parseInt(parts[index++]);
                    boolean isErase = Boolean.parseBoolean(parts[index++]);

                    if(!isErase) {
                        String timeMillis1 = parts[index++];
                        String timeMillis2 = parts[index++];
                        String timeString = timeMillis1 + " " + timeMillis2;
                        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm:ss");
                        LocalDateTime time = LocalDateTime.parse(timeString, formatter);

                        long timeInSeconds = time.toEpochSecond(ZoneOffset.UTC);

                        byte[] msg = Base64.getDecoder().decode(parts[index++]);

                        for (Chat chat : chatList) {
                            if (Objects.equals(chat.GetChatId(), chatId)) {
                                Message message = new Message(authorId, idMsg, msg, time, false);
                                message.SetTimeInSeconds(timeInSeconds); // Сохраняем время в секундах в сообщении
                                if (chat.GetUser(authorId) == null) {
                                    chat.AddUser(authorId, new User(String.valueOf(authorId), publicKey));
                                }
                                chat.AddChangeMessage(message);
                                messagesAddedToChat++; // Increment the counter
                                break;
                            }
                        }
                    }
                    else{
                        erased.add(idMsg);
                    }
                }
            }

            for (Chat chat : chatList) {
                if (Objects.equals(chat.GetChatId(), chatId)) {
                    chat.CleanErased(erased);
                    chat.SortMessagesByTime();
                    if (messagesAddedToChat > chat.GetWritedUsers()) {
                        chat.isChanged = true;
                    }
                }
            }
        }

        Log.i("Chats", "Start Chat Upd");
        JsonDataSaver.SaveChats(chatList, this);
        SharedViewByChats.setChatList(chatList);
        Log.i("Chats", "End Chat Upd");
    }
}