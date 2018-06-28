import 'dart:async';
import 'dart:io';

import 'package:building_beautiful_apps/chat_message.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';

final GoogleSignIn _googleSignIn = new GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;
FirebaseUser _currentUser;

final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
DatabaseReference _databaseReference;
final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
StorageReference _storageReference;

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _databaseReference = _firebaseDatabase.reference().child("messages");
    _gSignIn();
  }

  void _gSignIn() async {
    if (_currentUser == null) {
      GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      FirebaseUser user = await _auth.signInWithGoogle(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<Null> _handleSignOut() async {
    await _googleSignIn.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          centerTitle: true,
          actions: <Widget>[
            new IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: () => _showExitMessage(context))
          ],
          title: new Text("Friendly Chat App"),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        ),
        body: new Container(
          child: new Column(
            children: <Widget>[
              new Flexible(
                child: FirebaseAnimatedList(
                    reverse: true,
                    sort: (a, b) => b.key.compareTo(a.key),
                    query: _databaseReference,
                    itemBuilder: (_, DataSnapshot data,
                        Animation<double> animation, int index) {
                      String name = data.value['username'];
                      if (data.value['username'] == _currentUser.displayName) {
                        name = "You";
                      }
                      ChatMessage message = new ChatMessage.fromSnapshot(
                          data,
                          animation,
                          data.value['username'] == _currentUser.displayName
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          name);
                      return message;
                    }),
              ),
              new Divider(
                height: 1.0,
              ),
              new Container(
                decoration:
                    new BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
                  border: new Border(
                    top: new BorderSide(color: Colors.grey[200]),
                  ),
                )
              : null,
        ));
  }

  Widget _buildTextComposer() {
    return new IconTheme(
        data: new IconThemeData(color: Theme.of(context).accentColor),
        child: new Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: new Row(
              children: <Widget>[
                new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 4.0),
                  child: new IconButton(
                      icon: new Icon(
                        Icons.photo_camera,
                        color: Theme.of(context).accentColor,
                      ),
                      onPressed: () async {
                        File image = await ImagePicker.pickImage(
                            source: ImageSource.camera);
                        int timestamp =
                            new DateTime.now().millisecondsSinceEpoch;
                        _storageReference = _firebaseStorage
                            .ref()
                            .child("images")
                            .child("img_${timestamp.toString()}.jpg");
                        StorageUploadTask uploadTask =
                            _storageReference.putFile(
                                image,
                                new StorageMetadata(
                                    contentLanguage: 'en',
                                    customMetadata: <String, String>{
                                      'activity': 'test'
                                    }));
                        Uri downloadUrl = (await uploadTask.future).downloadUrl;
                        _handleSendImage(downloadUrl.toString());
                      }),
                ),
                new Flexible(
                  child: new TextField(
                    controller: _textController,
                    onSubmitted: _handleSubmitted,
                    decoration: new InputDecoration.collapsed(
                      hintText: "Send a message",
                    ),
                    onChanged: (String text) {
                      if (_currentUser != null) {
                        setState(() {
                          _isComposing = text.length > 0;
                        });
                      } else {
                        _gSignIn();
                      }
                    },
                  ),
                ),
                new Container(
                    margin: new EdgeInsets.symmetric(horizontal: 4.0),
                    child: Theme.of(context).platform == TargetPlatform.iOS
                        ? //modified
                        new CupertinoButton(
                            child: new Text("Send"),
                            onPressed: _isComposing
                                ? () => _handleSubmitted(_textController.text)
                                : null,
                          )
                        : new IconButton(
                            //modified
                            icon: new Icon(Icons.send),
                            onPressed: _isComposing
                                ? () => _handleSubmitted(_textController.text)
                                : null,
                          )),
              ],
            )));
  }

  void _handleSubmitted(String text) async {
    await _gSignIn();
    if (_currentUser != null) {
      _textController.clear();
      setState(() {
        _isComposing = false;
      });

      ChatMessage chatMessage = new ChatMessage(
        username: _currentUser.displayName,
        photoUrl: _currentUser.photoUrl,
        message: text,
        imageUrl: null,
      );
      _databaseReference.push().set(chatMessage.toJson());
    }
  }

  void _handleSendImage(String imageUrl) async {
    await _gSignIn();
    if (_currentUser != null) {
      ChatMessage chatMessage = new ChatMessage(
        username: _currentUser.displayName,
        photoUrl: _currentUser.photoUrl,
        message: null,
        imageUrl: imageUrl,
      );
      _databaseReference.push().set(chatMessage.toJson());
    }
  }

  void _showExitMessage(BuildContext context) {
    var alert = new AlertDialog(
      title: Text("Alert"),
      content: new Text("Hey ! do you really want to leave from the app ?"),
      actions: <Widget>[
        new FlatButton(
          onPressed: () async {
            await _handleSignOut();
            exit(0);
          },
          child: new Text("Yes"),
        ),
        new FlatButton(
          onPressed: () => Navigator.pop(context),
          child: new Text("Cancel"),
        ),
      ],
    );
    showDialog(context: context, builder: (context) => alert);
  }
}
