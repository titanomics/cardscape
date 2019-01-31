import 'dart:async';
import 'dart:convert';

import '../mixins/validators.dart';
import '../models/pack_model.dart';
import '../models/card_model.dart';
import '../models/user_model.dart';

import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:http/http.dart' show get;

import 'package:background_fetch/background_fetch.dart';

class MainState {
  int viewIndex;
  List<PackModel> packs;
  List<CardModel> deck;

  MainState(this.viewIndex, this.packs, this.deck);
}

class MainBloc extends Validators {

  final _navController = BehaviorSubject<int>();
  final _packsController = BehaviorSubject<List<PackModel>>();
  final _deckController = BehaviorSubject<List<CardModel>>();

  Stream<int> get navStream => _navController.stream;
  Stream<List<PackModel>> get packStream => _packsController.stream;
  Stream<List<CardModel>> get deckStream => _deckController.stream;
  Stream<MainState> get stateStream => Observable.combineLatest3(navStream, packStream, deckStream, (n, p, d) => MainState(n, p, d));

  //current state
  int get currentView => _navController.value;
  List<PackModel> get currentPacks => _packsController.value;
  List<CardModel> get currentDeck => _deckController.value;

  // TODO: for combineLatest2 to emit a first event, all derivative streams must emit an event first - so we need a good way to initialize all data streams with defaults
  MainBloc() {
    _navController.sink.add(0);
    _packsController.sink.add([]);
    _deckController.sink.add([]);
    fetchFirestoreDoc();
  }

  Future<void> initBackgroundEvents() async {
    // Configure BackgroundFetch.
    BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: true,
        enableHeadless: false
    ), () async {
      // This is the fetch-event callback.
      print('[BackgroundFetch] Event received');
      addPack();
      // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish();
    }).then((int status) {
      print('[BackgroundFetch] SUCCESS: $status');
    }).catchError((e) {
      print('[BackgroundFetch] ERROR: $e');
    });

    BackgroundFetch.start().then((int status) {
      print('[BackgroundFetch] start success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] start FAILURE: $e');
    });
  }

  fetchFirestoreDoc() async {
    var doc = await Firestore.instance.collection('users').document('0').get();

    var user = UserModel.fromUserDocument(doc.data);

    _packsController.sink.add(currentPacks..addAll(user.packThumbs));
    _deckController.sink.add(currentDeck..addAll(user.cardThumbs));

  }

  // called by main_screen navigation bar
  Function(int) get changeView => _navController.sink.add;

  addPack() async {
    var doc = await Firestore.instance.collection('packs').document('1').get();

    var pack = PackModel.fromPackDocument(doc.data);

    _packsController.sink.add(currentPacks..add(pack));

    saveUserData();
  }

  openPack(int index) {
    var packs = currentPacks;
    var deck = currentDeck;
    deck.addAll(packs.removeAt(index).cards);
    _packsController.sink.add(packs);
    _deckController.sink.add(deck);

    saveUserData();
  }

  saveUserData() async {
    Firestore.instance.runTransaction((transaction) async {
      final userDocRef = Firestore.instance.collection('users').document('0');
      //final freshSnapshot = await transaction.get(userDocRef);
      //final freshUserData = UserModel.fromUserDocument(freshSnapshot.data);
      final packsMap = currentPacks.map((p) => p.toMapPartial()).toList();
      final deckMap = currentDeck.map((d) => d.toMapPartial()).toList();

      await transaction.update(userDocRef, {
        'packs': packsMap,
        'cards': deckMap
      });

    });
  }

  dispose() {
    _navController.close();
    _packsController.close();
    _deckController.close();
  }

}