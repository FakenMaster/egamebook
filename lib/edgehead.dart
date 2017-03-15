library Scripter_Implementation;

import 'package:egamebook/scripter.dart';
import 'dart:isolate';

import 'package:edgehead/edgehead_lib.dart';

class ScripterImpl extends Scripter {
  @override
  String uid = "net.filiph.edgehead.0.0.1";

  /* LIBRARY */

      EdgeheadGame game;
  
      Stat<double> hitpoints = new Stat<double>("Health", (double value) {
      if (value == 0.0) {
        return "💀"; // dead, skull
      }
      if (value <= 0.5) {
        return "😣"; // bleeding, persevering face
      }
      if (value < 1.0) {
        return "😧"; // cut, anguished face
      }
      return "😐"; // fine, neutral face
      }, description: "Your physical state", initialValue: 100.0, show: true);
      Stat<int> stamina = new Stat<int>("Stamina", (int value) => "$value S",
        description: "Spare physical energy", show: true);

  @override
  void populateVarsFromState() {
    vars["game"] = game;
    vars["hitpoints"] = hitpoints;
    vars["stamina"] = stamina;
  }
  @override
  void extractStateFromVars() {
    game = vars["game"] as EdgeheadGame;
    hitpoints = vars["hitpoints"] as Stat<double>;
    stamina = vars["stamina"] as Stat<int>;
  }
  ScripterImpl() : super() {
    /* PAGES & BLOCKS */
    pageMap[r"""start"""] = new ScripterPage(
      [
          """<p class='meta'>Debug version from Wed, March 15, 2017.</p>""",
          [
            null,
          {
            "goto": r"""gameLoop"""          }
        ]
        ]
    );
    pageMap[r"""gameLoop"""] = new ScripterPage(
      [
          () async {
  await game.run();
        },
          [
            null,
          {
            "goto": r"""gameLoop"""          }
        ]
        ]
    );
    pageMap[r"""endGame"""] = new ScripterPage(
      [
          """<p class="meta">
  Hit <strong>Restart</strong> (top left) to play again. It will be different.
</p>"""
]
    );
        firstPage = pageMap[r"""start"""];
  }
  /* INIT */
  @override
  void initBlock() {
    game = null;
    hitpoints = new Stat<double>("Health", (double value) {if (value == 0.0) {return "💀";} if (value <= 0.5) {return "😣";} if (value < 1.0) {return "😧";} return "😐";}, description: "Your physical state", initialValue: 100.0, show: true);
    stamina = new Stat<int>("Stamina", (int value) => "$value S", description: "Spare physical energy", show: true);

        game = new EdgeheadGame(echo, goto, choices, choice, showSlotMachine,
                                hitpoints, stamina);
        game.onFinishedGoto = "endGame";
        points.add(0);

  }
}

// The entry point of the isolate.
void main(List<String> args, SendPort mainIsolatePort) {
  PresenterProxy presenter = new IsolatePresenterProxy(mainIsolatePort);
  Scripter book = new ScripterImpl();
  presenter.setScripter(book);
}
