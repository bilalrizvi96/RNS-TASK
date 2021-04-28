import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'RNS TASK'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();

}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  String _verificationId;
  final SmsAutoFill _autoFill = SmsAutoFill();
  void showSnackbar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }
  void verifyPhoneNumber() async {
    PhoneVerificationCompleted verificationCompleted =
        (PhoneAuthCredential phoneAuthCredential) async {
      await _auth.signInWithCredential(phoneAuthCredential);
      showSnackbar("Phone number automatically verified and user signed in: ${_auth.currentUser.uid}");
    };
    PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {
      showSnackbar('Phone number verification failed. Code: ${authException.code}. Message: ${authException.message}');
    };
    PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      showSnackbar('Please check your phone for the verification code.');
      _verificationId = verificationId;
    };
    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      showSnackbar("verification code: " + verificationId);
      _verificationId = verificationId;
    };
    try {
      await _auth.verifyPhoneNumber(
          phoneNumber: _phoneNumberController.text,
          timeout: const Duration(seconds: 60),
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
    } catch (e) {
      showSnackbar("Failed to Verify Phone Number: ${e}");
    }
  }
  void signInWithPhoneNumber() async {
      try {
        final AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: _smsController.text,
        );

        final User user = (await _auth.signInWithCredential(credential)).user;

        showSnackbar("Successfully signed in UID: ${user.uid}");
      } catch (e) {
        showSnackbar("Failed to sign in: " + e.toString());
      }
    }
@override
  void initState() {
    // TODO: implement initState
    super.initState();
    listenOTp();
  }
  void listenOTp()async
  {
    await SmsAutoFill().listenForCode;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        key: _scaffoldKey,
        resizeToAvoidBottomPadding: false,
        body: Padding(padding: const EdgeInsets.all(8),
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: const InputDecoration(labelText: 'Phone number (+92 xxx xxxxxxx)'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    alignment: Alignment.center,
                    child: RaisedButton(child: Text("Get current number",style: TextStyle(color: Colors.white)),
                        onPressed: () async => {
                          _phoneNumberController.text = await _autoFill.hint
                        },
                        color: Colors.red[700]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    alignment: Alignment.center,
                    child: RaisedButton(
                      color: Colors.red[800],
                      child: Text("Verify Number",style: TextStyle(color: Colors.white),),
                      onPressed: () async {
                        verifyPhoneNumber();
                        final signed = await SmsAutoFill().getAppSignature;
                      },
                    ),
                  ),
                  Container(
                    child: PinFieldAutoFill(
                      codeLength: 6,
                      onCodeChanged: (val)
                      {
                        print(val);
                      },
                    ),
                  )
                  // TextFormField(
                  //   controller: _smsController,
                  //   onChanged: (){
                  //     _autoFill.code.length.toString()
                  //   },
                  //   decoration: const InputDecoration(labelText: 'Verification code'),
                  // ),
                  ,Container(
                    padding: const EdgeInsets.only(top: 16.0),
                    alignment: Alignment.center,
                    child: RaisedButton(
                        color: Colors.red[400],
                        onPressed: () async {
                          signInWithPhoneNumber();
                        },
                        child: Text("Sign in",style: TextStyle(color: Colors.white))),
                  ),
                ],
              )
          ),
        )
    );
  }
}