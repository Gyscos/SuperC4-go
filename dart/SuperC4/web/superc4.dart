import 'dart:html';

import 'lib/superc4_lib.dart' as s4lib;

void main() {
  var drawer = new s4lib.Drawer(querySelector("#superc4_canvas"));
  var client = new s4lib.Client();
  var game = new s4lib.Game();

  drawer.onPlay = game.play;

  client.onPlay = game.play;

  drawer.start();
}
