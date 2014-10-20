part of superc4_lib;

class Client {

  var onPlay;
  var onLeave;

  void play(x, y) {
    wait();
  }

  void wait() {
    // Result:
    // Cancel ?
    leave();
    // Remote play ?
    onPlay(0,0);
    // Victory ?
  }

  void joinHuman() {

  }

  void leave() {

    onLeave();
  }
}