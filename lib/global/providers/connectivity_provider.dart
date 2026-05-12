import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref){
  final controller = StreamController<List<ConnectivityResult>>();

  Connectivity().checkConnectivity().then((statusList){
    if(!controller.isClosed){
      print("connection result is${statusList[0]}");
     controller.add(statusList);
    }
  });

  final subscriptions = Connectivity().onConnectivityChanged.listen((statusList){
    controller.add(statusList);
  });
  
  ref.onDispose((){
    subscriptions.cancel();
    controller.close();
  });

  return controller.stream;
});