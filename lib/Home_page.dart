
import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini=Gemini.instance;

  List<ChatMessage> messages_list = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1",
      firstName: "Gemini",
      profileImage:"https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Gemini Chat",

        ),


      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(trailing:[ IconButton(
        onPressed:_sendMediaMessage ,
        icon: Icon(Icons.image
        ),
      )
      ]),
      currentUser: currentUser, onSend: _sendMessage, messages: messages_list,);
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages_list=[chatMessage,...messages_list ];
    });
    try{
      String question=chatMessage.text;
      List<Uint8List>? images;

      if(chatMessage.medias?.isNotEmpty??false){
        images=[
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];

      }
      gemini.streamGenerateContent(question,images: images,).listen((event) {
        ChatMessage?lastMessage=messages_list.firstOrNull;
        if(lastMessage!=null&&lastMessage.user==geminiUser){
          lastMessage=messages_list.removeAt(0);
          String response=event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}")??"";
          lastMessage.text +=response;
          setState(() {
            messages_list=[lastMessage!,...messages_list];
          });
        }
        else{
          String response=event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}")??"";
          ChatMessage message=ChatMessage(user: geminiUser, createdAt: DateTime.now(),text:response );
          setState(() {
            messages_list=[message,...messages_list];
          });

        }
      });
    }
    catch(e){
      print(e);
    }

  }
  void _sendMediaMessage() async{
    ImagePicker picker=ImagePicker();
    XFile? file=await picker.pickImage(source: ImageSource.gallery);
    if(file!=null){
      ChatMessage chatMessage=ChatMessage(user: currentUser, createdAt: DateTime.now(),text:"Describe this picture?",medias:[
        ChatMedia(
          url: file.path,
          fileName: file.path.split('/').last, // Extracting file name from path
          type: MediaType.image,


        )
      ], );
      _sendMessage(chatMessage);
    }
  }
}