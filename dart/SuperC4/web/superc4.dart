import 'dart:html';

import 'lib/superc4_lib.dart' as s4lib;

void joinHuman(var next) {
  // Hide the "join" buttons, show the wait & abort button, then call next().

  next();
}

void onJoin() {
  // Hide the "waiting" screen and show the "playing" one.
}

void main() {
  var drawer = new s4lib.Drawer(querySelector("#superc4_canvas"));
  var client = new s4lib.Client();
  var game = new s4lib.Game();

  querySelector("#play_human").onClick.listen((_) => joinHuman(client.joinHuman));
  querySelector("#play_ai_easy").onClick.listen((_) => window.alert("AI Play not implemented yet."));
  querySelector("#play_ai_hard").onClick.listen((_) => window.alert("AI Play not implemented yet."));

  drawer.onPlay = game.play;

  client.onPlay = game.play;

  drawer.start();
}
