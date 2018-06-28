import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatMessage extends StatelessWidget {
  String username;
  String photoUrl;
  String message;
  String imageUrl;
  Animation animation;
  TextDirection textDirection = TextDirection.ltr;

  ChatMessage({this.username, this.photoUrl, this.message, this.imageUrl});

  ChatMessage.fromSnapshot(DataSnapshot snapshot, Animation animation,
      TextDirection textDirection, String username)
      : photoUrl = snapshot.value['photoUrl'],
        message = snapshot.value['message'],
        imageUrl = snapshot.value['imageUrl'],
        this.animation = animation,
        this.textDirection = textDirection,
        this.username = username;

  toJson() {
    return {
      'username': username,
      'photoUrl': photoUrl,
      'message': message,
      'imageUrl': imageUrl
    };
  }

  @override
  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(parent: animation, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: new Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: new Directionality(
            textDirection: textDirection,
            child: new ListTile(
              leading: new CircleAvatar(
                backgroundImage: new NetworkImage(photoUrl),
              ),
              title: new Text(username),
              subtitle: imageUrl != null
                  ? new Image.network(
                      imageUrl,
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.fill,
                    )
                  : Text(message),
            ),
          )),
    );
  }
}
