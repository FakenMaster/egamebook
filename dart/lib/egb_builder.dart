library egb_builder;

import 'dart:async';
import 'dart:io';
import 'package:graphml/dart_graphml.dart';

import 'src/egb_page.dart';

/**
 * Exception thrown when the input .egb file is badly formatted.
 **/
class EgbFormatException implements Exception {
  String msg;
  int line;
  File file;

  EgbFormatException(String this.msg, {this.line, this.file}) {
  }

  String toString() {
    StringBuffer strBuf = new StringBuffer();
    strBuf.add("Format exception");
    if (line != null) {
      strBuf.add(" on line [$line]");
    }
    if (file != null) {
      strBuf.add(" in file ${file.name}");
    }
    strBuf.add(": ");
    strBuf.add(msg);
    return strBuf.toString();
  }
}

/**
 * Abstract class defining a "line selection".
 */
abstract class BuilderLineRange {
  int lineStart;
  int lineEnd;
}

/**
 * BuilderLineSpan is a "selection" in the input file. In a complete form
 * (`[isClosed] == true`), it has a `lineStart` and a `lineEnd`.
 **/
class BuilderLineSpan implements BuilderLineRange { // XXX: this should be super-class of the below, but Dart is broken here
  int lineStart;
  int lineEnd;

  BuilderLineSpan({this.lineStart});

  get isClosed => lineStart != null && lineEnd != null && lineStart <= lineEnd;
}

/**
 * BuilderMetadata is a key-value pair of metadata associated with
 * the gamebook.
 *
 * An example can be:
 *
 * - key: authors
 * - value: ["Filip Hracek", "John Doe"]
 **/
class BuilderMetadata {
  String key;
  List<String> values;

  BuilderMetadata(this.key, {String firstValue}) {
    values = new List<String>();
    if (firstValue != null) {
      values.add(firstValue);
    }
  }
}

/**
 * BuilderPage defines a page as it is represented in the input .egb file.
 * A BuilderPage has its [name] and also [BuilderBlock]s.
 *
 * BuilderPage also has [options], like `visitOnce`.
 **/
class BuilderPage extends EgbPage implements BuilderLineRange {
  int index;
  int lineStart;
  int lineEnd;

  /**
   * List of options, such as [:visitOnce:].
   */
  Set<String> options;

  bool get visitOnce => options.contains("visitOnce");
  bool get showOnce => options.contains("showOnce");

  /**
   * List of linked page names. Builder makes sure they are specified in
   * their full version (i.e. "Group 1: Something").
   */
  List<String> gotoPageNames;

  List<BuilderBlock> blocks;
  BuilderPageGroup group;

  BuilderPage(String name, this.index, [this.lineStart]) :
      super(name: name) {
    blocks = new List<BuilderBlock>();
    options = new Set<String>();
    gotoPageNames = new List<String>();

    group = new BuilderPageGroup.fromPage(this);
  }

  String toString() {
    return "BuilderPage <$name> [$lineStart:$lineEnd]";
  }

  /**
   * To be commented out – for example when the page is deleted in yEd.
   */
  bool commentOut = false;
}

/**
 * BuilderPageGroup is a form of grouping of the pages. Every time a page's
 * name starts with "Something: ", then "Something" is a pageGroup.
 * Calling goto("xyz") from a page named "Something: abc" when there is
 * a page named "Something: xyz" goes to that page.
 **/
class BuilderPageGroup {
  String name;
  List<BuilderPage> pages;

  static final Map<String, BuilderPageGroup> _cache
                  = new Map<String, BuilderPageGroup>();

  /**
   * Creates group from page. If page has no group, returns null. If group
   * already exists, returns existing group. Also adds the input page
   * to the group.
   */
  factory BuilderPageGroup.fromPage(BuilderPage page) {
    String name = page.groupName;
    if (name == null) {
      return null;
    } else if (_cache.containsKey(name)) {
      _cache[name].pages.add(page);
      return _cache[name];
    } else {
      final group = new BuilderPageGroup._internal(name);
      group.pages.add(page);
      _cache[name] = group;
      return group;
    }
  }

  BuilderPageGroup._internal(this.name) {
    pages = new List<BuilderPage>();
  }

  static List<BuilderPageGroup> get allGroups {
    List<BuilderPageGroup> list = _cache.values.toList();
    list.sort((a,b) => a.pages[0].index - b.pages[0].index); // TODO: check for empty groups
    return list;
  }
}

/**
 * BuilderBlock is a class that defines a "line selection" in the input
 * .egb file. The selection has a type (e.g. BLK_TEXT or BLK_SCRIPT).
 **/
class BuilderBlock implements BuilderLineRange {
  int lineStart;
  int lineEnd;
  int type = 0;
  Map<String,dynamic> options;
  List<BuilderBlock> subBlocks;

  static final int BLK_TEXT = 1;
  static final int BLK_TEXT_WITH_VAR = 8;

  /// Returns [:true:] if block is a text block (no matter if with variable
  /// or without.
  bool get isTextBlock => type == BLK_TEXT || type == BLK_TEXT_WITH_VAR;

  static final int BLK_SCRIPT = 2;
  static final int BLK_SCRIPT_ECHO = 64;

  static final int BLK_CHOICE_LIST = 128;
  static final int BLK_CHOICE_QUESTION = 16; // TODO deprecate
  static final int BLK_CHOICE = 4;
  static final int BLK_CHOICE_WITH_SCRIPT = 32;

  BuilderBlock({this.lineStart, this.type: 0}) {
    options = new Map<String,dynamic>();
    subBlocks = new List<BuilderBlock>();
  }
}

/**
 * BuilderInitBlock is a class that defines a "line selection" of either
 * a `<classes>`, a `<functions>` or a `<variables>` block.
 **/
class BuilderInitBlock implements BuilderLineRange {
  int lineStart;
  int lineEnd;
  int type;

  static const int BLK_CLASSES = 1;
  static const int BLK_FUNCTIONS = 2;
  static const int BLK_VARIABLES = 4;

  static const String BLK_CLASSES_STRING = "classes";
  static const String BLK_FUNCTIONS_STRING = "functions";
  static const String BLK_VARIABLES_STRING = "variables";

  BuilderInitBlock({this.lineStart, this.type, String typeStr}) {
    if (typeStr != null) {
      type = typeFromString(typeStr);
    }
  }

  static int typeFromString(String s) {
    switch (s) {
      case BLK_CLASSES_STRING:
        return BLK_CLASSES;
      case BLK_FUNCTIONS_STRING:
        return BLK_FUNCTIONS;
      case BLK_VARIABLES_STRING:
        return BLK_VARIABLES;
      default:
        throw "Tag <$s> was not recognized as a valid init block tag.";
    }
  }

  static int modeFromString(String s) {
    if (s == BLK_CLASSES_STRING) {
      return Builder.MODE_INSIDE_CLASSES;
    } else if (s == BLK_FUNCTIONS_STRING) {
      return Builder.MODE_INSIDE_FUNCTIONS;
    } else if (s == BLK_VARIABLES_STRING) {
      return Builder.MODE_INSIDE_VARIABLES;
    } else {
      throw "Tag <$s> was not recognized as a valid init block tag.";
    }
  }
}

/**
 * Class that represents a full egamebook. Call [:readEgbFile:] to get
 * data from an existing .egb file. Call [:writeEgbFile:] to output the data
 * into a new .egb file.
 *
 * After it's been created, you can call [:writeDartFiles:] to create
 * the source files (scripter implementation + 2 user interfaces).
 *
 * You can also export the page structure to a GraphML file using
 * [:writeGraphMLFile:] or update existing structure by
 * [:updateFromGraphMLFile:].
 **/
class Builder {
  /**
   * Default constructor. This will allocate memory for members and nothing
   * else. The structure is still empty after calling this.
   **/
  Builder() {
    metadata = new List<BuilderMetadata>();
    synopsisLineNumbers = new List<int>();
    pages = new List<BuilderPage>();
    pageHandles = new Map<String,int>();
    initBlocks = new List<BuilderInitBlock>();
    importEgbFiles = new List<File>();
    importEgbFilesFullPaths = new Set<String>();

    warningLines = new List<String>();
  }

  /**
    * Main workhorse, reads and parses file to intermediary structure.
    * When the returning Future is ready, use can call [writeDartFiles()],
    * for example.
    * @param  f A well-formed .egb file.
    * @return   A Future. On completion, the future returns `this` for
    *           convenience.
    */
  Future<Builder> readEgbFile(File f) {
    var completer = new Completer();

    inputEgbFile = f;

    f.exists()
    .then((exists) {
      if (!exists) {
        completer.completeError(new FileIOException("File ${f.name} doesn't exist."));
      } else {
        f.fullPath().then((String fullPath) {
          inputEgbFileFullPath = fullPath;
          print("Reading input file ${f.name}.");

          var inputStream = f.openInputStream();
          readInputStream(inputStream).then((b) => completer.complete(b));
        });
      }
    });

    return completer.future;
  }

  Future<Builder> readInputStream(InputStream inputStream) {
    var completer = new Completer();

    var strInputStream = new StringInputStream(inputStream);

    // The top of the file can be metadata. This will be changed to
    // MODE_NORMAL in [_checkMetadataLine()] when there is no metadata.
    _mode = MODE_METADATA;

    _lineNumber = 0;
    _pageNumber = 0;
    _blockNumber = 0;

    strInputStream.onLine = () {
      _lineNumber++;
      var line = strInputStream.readLine();

      _check(_lineNumber, line).then((_) {
        //stdout.writeString(".");
      });
    };

    strInputStream.onClosed = () {
      //print("\nReading input file has finished.");

      if (!pages.isEmpty) {
        // end the last page
        pages.last.lineEnd = _lineNumber;
        if (pages.last.blocks != null && !pages.last.blocks.isEmpty
            && pages.last.blocks.last.lineEnd == null) {
          pages.last.blocks.last.lineEnd = _lineNumber;
        }

        // fully specify gotoPageNames of every page
        for (var page in pages) {
          for (int i = 0; i < page.gotoPageNames.length; i++) {
            var gotoPageName = page.gotoPageNames[i];
            if (pageHandles.containsKey(
                                        "${page.groupName}: $gotoPageName")) {
              page.gotoPageNames[i] =
                  "${page.groupName}: $gotoPageName";
            } else if (pageHandles.containsKey(gotoPageName)) {
              // great, already done
            } else {
              WARNING("Page ${page.name} specifies a choice that goes "
              "to a non-existing page ($gotoPageName).",
              line:null);
            }
          }
        }
      } else {
        WARNING("There are no pages in this egb. If you want it to be playable, "
            "you will need to include page starts in the form of a line "
            "containing exclusively dashes (`-`, three or more) and "
            "an immediately following line with the name of the page.",
            line:null);
      }

      if (_mode != MODE_NORMAL) {
        completer.completeError(
            newFormatException("Corrupt file, didn't close a tag (_mode = ${_mode})."));
      } else {
        _checkForDoubleImports().then((bool passed) {
          if (passed) {
            completer.complete(this);
          }
        });
      }
    };

    return completer.future;
  }

  /**
   * This method takes care of checking each new line, trying to find
   * patterns (like a new page).
   *
   * @return    Future of bool. Always true on completion.
   **/
  Future<bool> _check(int number, String line) {
    var completer = new Completer();

    // start finding patterns in the line
    // try every pattern at once, in a non-blocking way, using futures
    Future.wait([
        _checkBlankLine(number, line),
        _checkNewPage(number, line),
        _checkPageOptions(number, line),
        _checkChoiceList(number, line),
        _checkInitBlockTags(number, line),
        _checkScriptTags(number, line),
        _checkGotoInsideScript(number, line),
        _checkMetadataLine(number, line),
        _checkImportTag(number, line)
    ]).then((List<bool> checkValues) {
      if (checkValues.every((value) => value == false)) {
        // normal paragraph
        _checkNormalParagraph(number, line)
        .then((_) => completer.complete(true));
      } else {
        completer.complete(true);
      }
    });

    return completer.future;
  }


  /*
  Checkers.
  */

  /**
   * Checks if current line is a blank line. Acts accordingly.
   *
   * @return    Future of bool, indicating the result of the check.
   **/
  Future<bool> _checkBlankLine(int number, String line) {
    if (_mode != MODE_NORMAL) {
      return new Future.immediate(false);
    }

    if (line == null || line == "" || blankLine.hasMatch(line)) {
      // close previous unfinished block or choiceList if any
      if (!pages.isEmpty) {
        var lastpage = pages.last;
        if (!lastpage.blocks.isEmpty) {
          var lastblock = lastpage.blocks.last;
          if (lastblock.type == BuilderBlock.BLK_TEXT ||
              lastblock.type == BuilderBlock.BLK_TEXT_WITH_VAR ||
              lastblock.type == BuilderBlock.BLK_CHOICE_LIST) {
            if (lastblock.lineEnd == null) {
              lastblock.lineEnd = number - 1;
            }
          }
        }
      } else {
        synopsisLineNumbers.add(number);
      }
      return new Future.immediate(true);
    } else {
      return new Future.immediate(false);
    }
  }

  /**
   * Checks if current line is a metadata line. Acts accordingly.
   *
   * @return    Future of bool, indicating the result of the check.
   **/
  Future<bool> _checkMetadataLine(int number, String line) {
    if (_mode != MODE_METADATA || line == null) {
      return new Future.immediate(false);
    }

    Match m = metadataLine.firstMatch(line);

    if (m != null) {
      // first line of a metadata record
      var key = m.group(1).trim();
      var value = m.group(2).trim();
      metadata.add(new BuilderMetadata(key, firstValue:value));
      return new Future.immediate(true);
    } else {
      m = metadataLineAdd.firstMatch(line);

      if (m != null && !metadata.isEmpty) {
        // we have a multi-value key and this is a following value
        var value = m.group(1).trim();
        metadata.last.values.add(value);
        return new Future.immediate(true);
      } else {
        // we have hit the first non-metadata line. Quit metadata mode.
        _mode = MODE_NORMAL;
        return new Future.immediate(false);  // let it be checked by _checkNormalParagraph, too
      }
    }
  }

  /**
   * Checks if current line is a beginning of a new page. Acts accordingly.
   *
   * @return    Future of bool, indicating the result of the check.
   **/
  Future<bool> _checkNewPage(int number, String line) {
    // TODO: check inside echo tags, throw error if true
    if ((_mode != MODE_METADATA && _mode != MODE_NORMAL) || line == null) {
      return new Future.immediate(false);
    }

    if (_newPageCandidate && validPageName.hasMatch(line)) {
      // discard the "---" from any previous blocks
      if (pages.isEmpty && !synopsisLineNumbers.isEmpty) {
        synopsisLineNumbers.removeLast();
      } else {
        var lastpage = pages.last;
        if (!lastpage.blocks.isEmpty) {
          var lastblock = lastpage.blocks.last;
          // also close block
          if (lastblock.lineEnd == null) {
            lastblock.lineEnd = number - 2;
            if (lastblock.lineEnd < lastblock.lineStart) {
              // a faux text block with only "---" inside
              lastpage.blocks.removeLast();
            }
          }
        }
      }

      // close last page
      if (!pages.isEmpty) {
        pages.last.lineEnd = number - 2;
      }

      // add the new page
      var name = validPageName.firstMatch(line).group(1);
      pageHandles[name] = _pageNumber;
      pages.add(new BuilderPage(name, _pageNumber++, number));
      _mode = MODE_NORMAL;
      _newPageCandidate = false;
      return new Future.immediate(true);

    } else {
      // no page, but let's check if this line isn't a "---" (next line could confirm a new page)
      if (hr.hasMatch(line)) {
        _newPageCandidate = true;
        return new Future.immediate(false);  // let it be checked by _checkNormalParagraph, too
      } else {
        _newPageCandidate = false;
        return new Future.immediate(false);
      }
    }
  }

  /**
   * Checks if current line is an options line below new page line.
   * Acts accordingly.
   *
   * @return    Future of bool, indicating the result of the check.
   **/
  Future<bool> _checkPageOptions(int number, String line) {
    if (_mode != MODE_NORMAL || line == null) {
      return new Future.immediate(false);
    }

    if (!pages.isEmpty && pages.last.lineStart == number - 1
        && pageOptions.hasMatch(line)) {
      Match m = pageOptions.firstMatch(line);
      var lastpage = pages.last;
      for (var i = 1; i <= m.groupCount; i += 2) {
        var opt = m.group(i);
        if (opt != null) {
          lastpage.options.add(opt);
        }
      }
      return new Future.immediate(true);
    } else {
      return new Future.immediate(false);
    }
  }

  /**
   * Checks if line is a valid choice. If not, returns [:null:].
   * If it is a valid choice, returns the corresponding [BuilderBlock] (without
   * the lineStart or lineEnd).
   */
  BuilderBlock parseChoiceBlock(String line) {
    if (!choice.hasMatch(line)) return null;

    var choiceBlock = new BuilderBlock(type: BuilderBlock.BLK_CHOICE);

    Match m = choice.firstMatch(line);
    /*for (int i = 1; i <= m.groupCount; i++) {*/
      /*print("$i - \"${m.group(i)}\"");*/
    /*}*/
    choiceBlock.options["string"] = m.group(1);
    choiceBlock.options["script"] = m.group(2);
    choiceBlock.options["goto"] = m.group(3);

    if (choiceBlock.options["script"] != null) {
      choiceBlock.type = BuilderBlock.BLK_CHOICE_WITH_SCRIPT;
    }

    // trim the strings
    choiceBlock.options.forEach((var k, var v) {
      if (v != null) {
        choiceBlock.options[k] = choiceBlock.options[k].trim();
      }
    });


    if (choiceBlock.options["script"] == null && choiceBlock.options["goto"] == null) {
      WARNING("Choice in the form of `- something []` is illegal. There must be "
            "a script and/or a goto specified.");
      return null;
    }

    if (choiceBlock.options["script"] != null
        && (new RegExp(r"^[^{]*}").hasMatch(choiceBlock.options["script"])
            || new RegExp(r"{[^}]*$").hasMatch(choiceBlock.options["script"]))) {
      WARNING("Inline script `${choiceBlock.options['script']}` in choice appears to have "
            "an unmatched bracket. This could be an error. Actual format used: `$line`.");
    }

    return choiceBlock;
  }



  /**
   * Checks if current line is choice. Acts accordingly.
   *
   * @return    Future of bool, indicating the result of the check.
   **/
  Future<bool> _checkChoiceList(int number, String line) {
    // TODO: allow choices in synopsis?
    // TODO: check even inside ECHO tags, add to script
    if (line == null || pages.isEmpty
        || (_mode != MODE_NORMAL && _mode != MODE_INSIDE_SCRIPT_ECHO)) {
      return new Future.immediate(false);
    }

    var choiceBlock = parseChoiceBlock(line);
    if (choiceBlock == null) return new Future.immediate(false);
    choiceBlock.lineStart = number;

    BuilderBlock choiceList;
    var lastpage = pages.last;
    if (!lastpage.blocks.isEmpty) {
      var lastblock = lastpage.blocks.last;

      // If there was a choiceList preceding this one, just continue
      // with the preceding choiceList.
      if (lastblock.type == BuilderBlock.BLK_CHOICE_LIST) {
        choiceList = lastblock;
        // Even if there was a space after the choiceList and therefore
        // lineEnd was added. Just join the two lists. TODO: is that clever?
        choiceList.lineEnd = null;
      } else {
        choiceList = new BuilderBlock(
            lineStart: number, type: BuilderBlock.BLK_CHOICE_LIST);

        // If the previous line is a text block, then that textblock needs to be
        // added to this choiceList.
        if (lastblock.isTextBlock && lastblock.lineEnd == null) {
          choiceList.lineStart = lastblock.lineStart;
          lastpage.blocks.removeLast();
        }
      }
    } else {
      choiceList = new BuilderBlock(
          lineStart: number, type: BuilderBlock.BLK_CHOICE_LIST);
    }

    lastpage.blocks.add(choiceList);

    bool hasVarInString = (choiceBlock.options["string"] != null
        && variableInText.hasMatch(choiceBlock.options["string"]));

    if (_mode == MODE_INSIDE_SCRIPT_ECHO) {
      // TODO: just add a _choiceToScript(block) to the current script flow
    } else if (_mode == MODE_NORMAL && choiceBlock.options["script"] == null &&
               !hasVarInString) {
      // we have a simple choice (i.e. no scripts needed)
      choiceBlock.type = BuilderBlock.BLK_CHOICE;
    } else {
      // the choice will need to be rewritten into a standalone script (closure)
      choiceBlock.type = BuilderBlock.BLK_CHOICE_WITH_SCRIPT;
    }

    choiceBlock.lineEnd = number;  // TODO: fix for multiline choices (indented lines)
    if (choiceBlock.options["goto"] != null) {
      lastpage.gotoPageNames.add(choiceBlock.options["goto"]);
    }
    choiceList.subBlocks.add(choiceBlock);

    return new Future.immediate(true);
  }

  /**
   * Checks if current line is one of `<classes>`, `<functions>` or
   * `<variables>` (or their closing tags). Acts accordingly.
   *
   * @return    Future of bool, indicating the result of the check.
   **/
  Future<bool> _checkInitBlockTags(int number, String line) {
    if (_mode == MODE_INSIDE_SCRIPT_TAG || line == null) {
      return new Future.immediate(false);
    }

    var completer = new Completer();

    Match m = initBlockTag.firstMatch(line);

    if (m != null) {
      bool closing =  m.group(1) == "/";
      var blocktype = m.group(2).toLowerCase();

      if (!closing) {  // opening a new tag
        if (_mode == MODE_NORMAL || _mode == MODE_METADATA) {
          _mode = BuilderInitBlock.modeFromString(blocktype);
          initBlocks.add(new BuilderInitBlock(lineStart:number, typeStr:blocktype));
          _closeLastBlock(number - 1);
          completer.complete(true);
        } else {
          completer.completeError(
            newFormatException("Invalid appearance of of an init "
                  "opening tag `<$blocktype>`. We are already inside "
                  "another tag (mode = $_mode)."));
        }
      } else {  // closing a tag
        if (_mode == MODE_INSIDE_CLASSES || _mode == MODE_INSIDE_FUNCTIONS
            || _mode == MODE_INSIDE_VARIABLES) {
          _mode = MODE_NORMAL;
          initBlocks.last.lineEnd = number;
          completer.complete(true);
        } else {
          completer.completeError(
            newFormatException("Invalid appearance of of an init "
                  "closing tag `</$blocktype>`. We are not inside any "
                  "other tag (mode = $_mode)."));
        }
      }
    } else {
      completer.complete(false);
    }

    return completer.future;
  }

  /**
   * Checks if current line is one of `<script>` or `</script>`.
   * Acts accordingly.
   *
   * @return    Future of bool, indicating the result of the check.
   **/
  Future<bool> _checkScriptTags(int number, String line) {
    if (_mode == MODE_INSIDE_CLASSES || _mode == MODE_INSIDE_VARIABLES
        || _mode == MODE_INSIDE_FUNCTIONS || line == null) {
      return new Future.immediate(false);
    }

    var completer = new Completer();

    Match m = scriptOrEchoTag.firstMatch(line);

    if (pages.isEmpty) {
      if (m != null) {
        WARNING("No <script> or <echo> blocks will be recognized as such "
                "in the synopsis (i.e. outside a page). Ignoring.");
      }
      return new Future.immediate(false);
    }
    var lastpage = pages.last;

    if (m != null) {
      bool closing =  m.group(1) == "/";
      var type = m.group(2).toLowerCase();
      bool tagIsEcho = type == "echo";
      bool tagIsScript = type == "script";

      if (!closing) {  // opening a new tag
        if (_mode == MODE_NORMAL && tagIsScript) {
          _closeLastBlock(number - 1);
          _mode = MODE_INSIDE_SCRIPT_TAG;
          var block = new BuilderBlock(lineStart:number);
          block.type = BuilderBlock.BLK_SCRIPT;
          lastpage.blocks.add(block);
          completer.complete(true);
        } else if (_mode == MODE_INSIDE_SCRIPT_TAG && tagIsEcho) {
          _mode = MODE_INSIDE_SCRIPT_ECHO;
          if (!lastpage.blocks.isEmpty
              && lastpage.blocks.last.type == BuilderBlock.BLK_SCRIPT) {
            lastpage.blocks.last.subBlocks.add(
                new BuilderBlock(lineStart: number,
                                 type: BuilderBlock.BLK_SCRIPT_ECHO));
            completer.complete(true);
          } else {
            completer.completeError(
              newFormatException("Echo tags must be inside <script> tags."));
          }
        } else {
          completer.completeError(
            newFormatException("Starting a <$type> tag outside NORMAL is illegal. "
                  "We are now in mode=$_mode."));
        }
      } else {  // closing a tag
        if (_mode == MODE_INSIDE_SCRIPT_TAG && !tagIsEcho && !lastpage.blocks.isEmpty) {
          _mode = MODE_NORMAL;
          lastpage.blocks.last.lineEnd = number;
          completer.complete(true);
        } else if (_mode == MODE_INSIDE_SCRIPT_ECHO && !lastpage.blocks.isEmpty
              && lastpage.blocks.last.type == BuilderBlock.BLK_SCRIPT
              && !lastpage.blocks.last.subBlocks.isEmpty) {
          _mode = MODE_INSIDE_SCRIPT_TAG;
          lastpage.blocks.last.subBlocks.last.lineEnd = number;
          completer.complete(true);
        } else {
          completer.completeError(
            newFormatException("Invalid appearance of of a `</$type>` "
                  "closing tag. We are not inside any $type tag to be"
                  "closed (mode = $_mode)."));
        }
      }
    } else {
      completer.complete(false);
    }

    return completer.future;
  }

  /**
   * Checks if there is a goto("") statement inside a script. Acts accordingly.
   *
   * @return    Future of bool, indicating the result of the check.
   **/
  Future<bool> _checkGotoInsideScript(int number, String line) {
    if (line == null) {
      return new Future.immediate(false);
    }

    if (_mode == MODE_INSIDE_SCRIPT_TAG) {
      Match m = gotoInsideScript.firstMatch(line);

      if (m != null) {
        pages.last.gotoPageNames.add(m.group(2));
        return new Future.immediate(true);
      }
    }

    return new Future.immediate(false);
  }

  /**
   * Checks if current line is an `<import>` tag. Acts accordingly.
   *
   * @return    Future of bool, indicating the result of the check.
   **/
  Future<bool> _checkImportTag(int number, String line) {
    if (_mode == MODE_INSIDE_SCRIPT_TAG || line == null) {
      return new Future.immediate(false);
    }

    var completer = new Completer();

    Match m = importTag.firstMatch(line);

    if (m != null) {
      _closeLastBlock(number - 1);
      var importFilePath = m.group(1);
      importFilePath = importFilePath.substring(1, importFilePath.length - 1); //get rid of "" / ''

      var inputFilePath = new Path(inputEgbFileFullPath);
      var pathToImport = inputFilePath.directoryPath
            .join(new Path(importFilePath));

      importEgbFiles.add(new File.fromPath(pathToImport));
      completer.complete(true);
    } else {
      completer.complete(false);
    }

    return completer.future;
  }

  /**
   * When all above checks fails, this is probably a line in a normal paragraph.
   * (Unless it's above the first page, in which case it's a line
   * in the synopsis.)
   *
   * @return    Future of bool, indicating the result of the check.
   **/
  Future<bool> _checkNormalParagraph(int number, String line) {
    // TODO: check also inside echo tags, add to script block
    if (_mode != MODE_NORMAL || line == null) {
      return new Future.immediate(false);
    }

    if (pages.isEmpty) {
      synopsisLineNumbers.add(number);
    } else {
      // we have a new block inside a page!
      var lastpage = pages.last;
      bool appending = false;

      if (!lastpage.blocks.isEmpty) {
        var lastblock = lastpage.blocks.last;
        if (lastblock.lineEnd == null
            && (lastblock.type == BuilderBlock.BLK_TEXT
            || lastblock.type == BuilderBlock.BLK_TEXT_WITH_VAR)) {
          // we have an unfinished text block that we can append to
          appending = true;
          //lastblock.lines.add(_thisLine);
          if (variableInText.hasMatch(line)) {
            lastblock.type = BuilderBlock.BLK_TEXT_WITH_VAR;
          }
        }
      }

      if (!appending) {
        // we create a new block
        var block = new BuilderBlock(lineStart:number);
        if (variableInText.hasMatch(line)) {
          block.type = BuilderBlock.BLK_TEXT_WITH_VAR;
        } else {
          block.type = BuilderBlock.BLK_TEXT;
        }
        //block.lines.add(_thisLine);
        lastpage.blocks.add(block);
      }
    }

    return new Future.immediate(true);
  }

  /**
   * Goes out and checks if the imported files exist. The method finds out
   * if two imports are of the same file, in which case it removes the redundant
   * [importFiles].
   *
   * @return    Future of bool, always true.
   **/
  Future<bool> _checkForDoubleImports() {
    var completer = new Completer();

    var inputFilePath = new Path(inputEgbFileFullPath);

    List<Future<bool>> existsFutures = new List<Future<bool>>();
    List<Future<String>> fullPathFutures = new List<Future<String>>();

    for (File f in importEgbFiles) {
      existsFutures.add(f.exists());
      fullPathFutures.add(f.fullPath());
    }

    Future.wait(existsFutures)
    .then((List<bool> existsBools) {
      assert(existsBools.length == importEgbFiles.length);

      for (int i = 0; i < existsBools.length; i++) {
        if (existsBools[i] == false) {
          completer.completeError(
              new FileIOException("Source file tries to import a file that "
                    "doesn't exist (${importEgbFiles[i].name})."));
        }
      }

      Future.wait(fullPathFutures)
      .then((List<String> fullPaths) {
        assert(fullPaths.length == importEgbFiles.length);

        for (int i = 0; i < fullPaths.length; i++) {
          for (int j = 0; j < i; j++) {
            if (fullPaths[i] == fullPaths[j]) {
              WARNING("File '${fullPaths[i]}' has already been imported. Ignoring "
                      "the redundant <import> tag.");
              importEgbFiles[i] = null;
            }
          }
        }

        // delete the nulls
        importEgbFiles = importEgbFiles.where((f) => f != null).toList();
        completer.complete(true);
      });
    });

    return completer.future;
  }

  /**
   * Helper function. Finds the previous block and closes it with either
   * the given [lineEnd] param, or the previous line.
   **/
  void _closeLastBlock(int lineEnd) {
    if (!pages.isEmpty && !pages.last.blocks.isEmpty) {
      var lastblock = pages.last.blocks.last;
      if (lastblock.lineEnd == null) {
        lastblock.lineEnd = lineEnd;
      }
    }
  }

  EgbFormatException newFormatException(String msg) {
    return new EgbFormatException(msg, line:_lineNumber, file:inputEgbFile);
  }

  // input file given by readFile()
  File inputEgbFile;
  String inputEgbFileFullPath;
  List<File> importEgbFiles;
  Set<String> importEgbFilesFullPaths;

  List<BuilderMetadata> metadata;
  bool _newPageCandidate = false;  // when last page was "---", there's a chance of a newpage

  List<int> synopsisLineNumbers;

  /**
   * List of pages.
   */
  List<BuilderPage> pages;

  List<BuilderPageGroup> get pageGroups => BuilderPageGroup.allGroups;

  /**
   * A map of pageHandles -> pageIndex. For use of the `goto("something")`
   * funtion.
   */
  Map<String, int> pageHandles;

  /**
   * List of init blocks, such as `<classes>` or `<variables>` blocks.
   */
  List<BuilderInitBlock> initBlocks;

  /**
   * GraphML representation of the page flow.
   **/
  GraphML graphML;

  static final RegExp blankLine = new RegExp(r"^\s*$");
  static final RegExp hr = new RegExp(r"^\s{0,3}\-\-\-+\s*$"); // ----
  static final RegExp validPageName = new RegExp(r"^\s{0,3}(.+)\s*$");
  static final RegExp pageOptions = new RegExp(r"^\s{0,3}\[\[\s*(\w+)([\s,]+(\w+))*\s*]\]\s*$");
  static final RegExp metadataLine = new RegExp(r"^(\w.+):\s*(\w.*)\s*$");
  static final RegExp metadataLineAdd = new RegExp(r"^\s+(\w.*)\s*$");
  /*static final RegExp scriptTag = new RegExp(@"^\s{0,3}<\s*(/?)\s*script\s*>\s*$", ignoreCase:true);*/
  static final RegExp scriptOrEchoTag = new RegExp(r"^\s{0,}<\s*(/?)\s*((?:script)|(?:echo))\s*>\s*$", caseSensitive: false);
  static final RegExp gotoInsideScript = new RegExp(r"""goto\s*\(\s*(\"|\'|\"\"\")(.+?)\1\s*\)\s*;""");
  /*static final RegExp scriptTagStart = new RegExp(@"^\s{0,3}<script>\s*$");*/
  /*static final RegExp scriptTagEnd = new RegExp(@"^\s{0,3}</script>\s*$");*/
  /*static final RegExp initTagStart = new RegExp(@"^\s{0,3}<init>\s*$");*/
  /*static final RegExp initTagEnd = new RegExp(@"^\s{0,3}</init>\s*$");*/
  /*static final RegExp libraryTagStart = new RegExp(@"^\s{0,3}<library>\s*$");*/
  /*static final RegExp libraryTagEnd = new RegExp(@"^\s{0,3}</library>\s*$");*/
  /*static final RegExp classesTagStart = new RegExp(@"^\s{0,3}<classes>\s*$");*/
  /*static final RegExp classesTagEnd = new RegExp(@"^\s{0,3}</classes>\s*$");*/
  static final RegExp initBlockTag = new RegExp(r"^\s{0,3}<\s*(/?)\s*((?:classes)|(?:functions)|(?:variables))\s*>\s*$", caseSensitive: false);
  static final RegExp importTag = new RegExp(r"""^\s{0,3}<\s*import\s+((?:\"(?:.+)\")|(?:\'(?:.+)\'))\s*/?>\s*$""", caseSensitive: false);
  static final RegExp choice = new RegExp(r"^\s{0,3}\-\s+(?:(.+)\s+)?\[\s*(?:\{\s*(.+)\s*\})?[\s,]*([^\{].+)?\s*\]\s*$");
  static final RegExp variableInText = new RegExp(r"[^\\]\$[a-zA-Z_][a-zA-Z0-9_]*|[^\\]\${[^}]+}");

  /**
   * Writes following Dart files to disk:
   *
   * - xyz.dart (The Scripter implementation)
   * - xyz.cmdline.dart (The command line interface)
   * - xyz.html.dart (The html interface)
   **/
  Future<bool> writeDartFiles() {
    var completer = new Completer();

    Future.wait([
        writeScripterFile(),
        writeInterfaceFiles()
    ]).then((_) {
      completer.complete(true);
    });

    return completer.future;
  }

  /**
   * Creates the scripter implementation file. This file includes the
   * whole egamebooks content.
   */
  Future<bool> writeScripterFile() {
    var completer = new Completer();

    var pathToOutputDart = getPathFor("dart");

    // TODO: use .chain instead of .then

    // write the .dart file
    File dartFile = new File.fromPath(pathToOutputDart);
    OutputStream dartOutStream = dartFile.openOutputStream();
    dartOutStream.writeString(implStartFile); // TODO: fix path to #import('../egb_library.dart');
    writeInitBlocks(dartOutStream, BuilderInitBlock.BLK_CLASSES, indent:0)
    .then((_) {
      dartOutStream.writeString(implStartClass);
      writeInitBlocks(dartOutStream, BuilderInitBlock.BLK_FUNCTIONS, indent:2)
      .then((_) {
        dartOutStream.writeString(implStartCtor);
        dartOutStream.writeString(implStartPages);
        writePagesToScripter(dartOutStream)
        .then((_) {
          dartOutStream.writeString(implEndPages);
          dartOutStream.writeString(implEndCtor);
          dartOutStream.writeString(implStartInit);
          writeInitBlocks(dartOutStream, BuilderInitBlock.BLK_VARIABLES, indent:4)
          .then((_) {
            dartOutStream.writeString(implEndInit);
            dartOutStream.writeString(implEndClass);
            dartOutStream.writeString(implEndFile);

            // Close and complete
            dartOutStream.close();
            dartOutStream.onClosed = () {
              completer.complete(true);
            };
            dartOutStream.onError = (var e) {
              completer.completeError(e);
            };
          });
        });
      });
    });

    return completer.future;
  }

  /**
   * Creates the interface files. These files are the ones that run
   * the egamebook. They import the scripter file as an Isolate.
   *
   * There are two interfaces: the command line interface, and the HTML
   * interface.
   */
  Future<bool> writeInterfaceFiles() {
    var completer = new Completer();

    var scriptFilePath = new Path(new Options().script);
    var pathToOutputDart = getPathFor("dart");
    var pathToOutputCmd = getPathFor("cmdline.dart");
    var pathToInputTemplateCmd = scriptFilePath.directoryPath
          .join(new Path("../lib/src/egb_cmdline_template.dart"));
    var pathToOutputHtml =getPathFor("html.dart");
    var pathToInputTemplateHtml = scriptFilePath.directoryPath
          .join(new Path("../lib/src/egb_html_template.dart"));

    File cmdLineOutputFile = new File.fromPath(pathToOutputCmd);
    File cmdLineTemplateFile = new File.fromPath(pathToInputTemplateCmd);
    File htmlOutputFile = new File.fromPath(pathToOutputHtml);
    File htmlTemplateFile = new File.fromPath(pathToInputTemplateHtml);

    var substitutions = {
      // TODO: make this directory independent
      "import 'egb_library.dart';" :
          "import '../../lib/src/egb_library.dart';\n",
      "import 'egb_runner.dart';" :
          "import '../../lib/src/egb_runner.dart';\n",
      "import 'egb_interface.dart';" :
          "import '../../lib/src/egb_interface.dart';\n",
      "import 'egb_interface_cmdline.dart';" :
          "import '../../lib/src/egb_interface_cmdline.dart';\n",
      "import 'egb_interface_html.dart';" :
          "import '../../lib/src/egb_interface_html.dart';\n",
      "import 'egb_storage.dart';" :
        "import '../../lib/src/egb_storage.dart';\n",
      "import 'egb_player_profile.dart';" :
        "import '../../lib/src/egb_player_profile.dart';\n",
      "import 'reference_scripter_impl.dart';" :
          "import '$pathToOutputDart';\n", // TODO!!
    };

    Future.wait([
        _fileFromTemplate(cmdLineTemplateFile, cmdLineOutputFile, substitutions),
        _fileFromTemplate(htmlTemplateFile, htmlOutputFile, substitutions),
    ]).then((List<bool> bools) => completer.complete(bools.every((b) => b)));

    return completer.future;
  }

  /**
   * Helper function copies contents of the template to a new file,
   * substituting strings as specified by [substitutions].
   *
   * @param inFile  The template file.
   * @param outFile File to be created.
   * @param substitutions A map of String->String substitutions.
   */
  Future<bool> _fileFromTemplate(File inFile, File outFile,
      [Map<String,String> substitutions]) {
    if (substitutions == null) {
      substitutions = new Map();
    }
    Completer completer = new Completer();

    inFile.exists()
    .then((bool exists) {
      if (!exists) {
        WARNING("Cmd line template ${inFile.name} doesn't exist in current directory. Skipping.");
        completer.complete(false);
      } else {
        OutputStream outStream = outFile.openOutputStream();
        StringInputStream inStream = new StringInputStream(inFile.openInputStream());

        inStream.onLine = () {
          String line = inStream.readLine();
          if (substitutions.containsKey(line)) {
            outStream.writeString("${substitutions[line]}\n");
          } else {
            outStream.writeString("$line\n");
          }
        };
        inStream.onClosed = () {
          outStream.close();
          completer.complete(true);
        };
        inStream.onError = (e) => completer.completeError(e);
      }
    });

    return completer.future;
  }

  /**
   * Writes the specified initBlockType from the .egb file
   * (and its imports TODO) to the OutputStream.
   *
   * @param dartOutStream Stream to be written to.
   * @param initBlockType The type of blocks whose contents we want to copy.
   * @param indent  Whitespace indent.
   * @return    Always true.
   */
  Future<bool> writeInitBlocks(OutputStream dartOutStream, int initBlockType,
                         {int indent: 0}) {
    var completer = new Completer();

    // TODO: copy <import> classes first

    copyLineRanges(
        initBlocks.where((block) => block.type == initBlockType).toList(),
        new StringInputStream(inputEgbFile.openInputStream()),
        dartOutStream,
        inclusive:false, indentLength:indent)
    .then((_) {
      completer.complete(true);
    });

    return completer.future;
  }

  /**
   * Writes all pages from the .egb file to to the OutputStream. Iterates
   * over all included blocks, taking care of the correct "conversion".
   * (E.g. a choice in .egb is written differently than in the resulting
   * Dart file.)
   *
   * @param dartOutStream Stream to be written to.
   * @return    Always true.
   */
  Future writePagesToScripter(OutputStream dartOutStream) {
    var completer = new Completer();

    if (pages.isEmpty) {
      return new Future.immediate(true);
    }  // TODO: unit test this

    String indent = "";
    Function write = (String msg) {
      dartOutStream.writeString("$indent$msg");
    };

    var inStream = new StringInputStream(inputEgbFile.openInputStream());
    int lineNumber = 0;
    BuilderPage curPage;
    int pageIndex = 0;
    BuilderBlock curBlock;
    int blockIndex;
    int subBlockIndex;
    int subBlockIndent;  // echo block indent

    // this is the main looping function
    Function handleLine = (String line) {
      // start page
      if (pageIndex < pages.length
          && lineNumber == pages[pageIndex].lineStart) {
        curPage = pages[pageIndex];
        blockIndex = 0;
        indent = _getIndent(4);
        write("pageMap[r\"\"\"${curPage.name}\"\"\"] = new EgbScripterPage(\n");
        write("  [\n");
      }

      // start of block
      if (curPage != null && !curPage.blocks.isEmpty && blockIndex < curPage.blocks.length
          && lineNumber == curPage.blocks[blockIndex].lineStart) {
        indent = _getIndent(10);
        curBlock = curPage.blocks[blockIndex];
        subBlockIndex = 0;
        String commaOrNot = blockIndex < curPage.blocks.length - 1 ? "," : "";

        if (curBlock.type == BuilderBlock.BLK_TEXT) {
          if (curBlock.lineStart == curBlock.lineEnd) {
            write("\"\"\"${handleTrailingQuotes(line)}\"\"\"$commaOrNot\n");
          } else {
            write("\"\"\"$line\n");
          }
        }

        if (curBlock.type == BuilderBlock.BLK_TEXT_WITH_VAR) {
          write("() {\n");
          if (curBlock.lineStart == curBlock.lineEnd) {
            write("  echo(\"\"\"${handleTrailingQuotes(line)}\"\"\");\n");
            write("}$commaOrNot\n");
          } else {
            write("  echo(\"\"\"$line\n");
          }
        }

        if (curBlock.type == BuilderBlock.BLK_CHOICE_QUESTION) {
          var question = curBlock.options["question"];
          if (curBlock.lineStart == curBlock.lineEnd) {
            write("{\n");
            write("  \"question\": r\"\"\"${handleTrailingQuotes(line)}\"\"\"\n");
            write("}$commaOrNot\n");
          } else {
            write("{\n");
            write("  \"question\": r\"\"\"\"$line\n");
          }
        }

        if (curBlock.type == BuilderBlock.BLK_CHOICE_LIST) {
          write("[\n");

          var questionLineCount =
              curBlock.subBlocks.first.lineStart - curBlock.lineStart;

          if (questionLineCount == 0) {
            write("  null,\n");
          } else if (questionLineCount == 1) {
            write("  () => \"\"\"${handleTrailingQuotes(line)}\"\"\",\n");
          } else {
            write("  () => \"\"\"$line\n");
          }
        }

//        if (curBlock.type == BuilderBlock.BLK_CHOICE) {
//          var string = curBlock.options["string"];
//          var goto = curBlock.options["goto"];
//          write("{\n");
//          write("  \"string\": r\"\"\"${string != null ? string : ''} \"\"\",\n");
//          write("  \"goto\": r\"\"\"$goto\"\"\"\n");
//          write("}$commaOrNot\n");
//        }

//        if (curBlock.type == BuilderBlock.BLK_CHOICE_WITH_SCRIPT) {
//          var string = curBlock.options["string"];
//          var goto = curBlock.options["goto"];
//          var script = curBlock.options["script"];
//
//          write("() {\n");
//
//          if (string == null) {
//            // ex: "- [gotopage]"
//            if (script != null) {
//              write("  $script;\n");
//            }
//            if (goto != null) {
//              write("  goto(r\"\"\"$goto\"\"\");\n");
//            }
//          } else {
//            // ex: "- Go to there [{{time++}} page]"
//            write("  choices.add(new EgbChoice(\n");
//            write("      \"\"\"$string \"\"\",\n");
//            var commaAfterGoto = ( script != null ) ? "," : "";
//            write("      goto:r\"\"\"$goto\"\"\"$commaAfterGoto\n");
//            write("      then:() { $script; }\n");
//            write("  ));\n");
//          }
//
//          write("}$commaOrNot\n");
//        }

        if (curBlock.type == BuilderBlock.BLK_SCRIPT) {
          write("() {\n");
        }

      }

      // block line
      if (curPage != null && !curPage.blocks.isEmpty && blockIndex < curPage.blocks.length
          && _insideLineRange(lineNumber, curPage.blocks[blockIndex])) {
        curBlock = curPage.blocks[blockIndex];

        if ((curBlock.type == BuilderBlock.BLK_TEXT
            || curBlock.type == BuilderBlock.BLK_TEXT_WITH_VAR)
            && _insideLineRange(lineNumber, curBlock, inclusive:false)) {
          indent = _getIndent(0);
          write("$line\n");
        }

        if (curBlock.type == BuilderBlock.BLK_CHOICE_LIST &&
            _insideLineRange(lineNumber, curBlock, inclusive: true)) {

          if (lineNumber < curBlock.subBlocks.first.lineStart) {
            // we are still in Question territory
            if (lineNumber > curBlock.lineStart) {
              write("$line\n");
              if (lineNumber == curBlock.subBlocks.first.lineStart - 1) {
                write("\"\"\",\n");  // end multiline question
              }
            }
          } else {
            var choiceBlock = curBlock.subBlocks.firstMatching((block) =>
                  _insideLineRange(lineNumber, block, inclusive: true),
                  orElse: () => null);

            if (choiceBlock != null) {
              write("{\n");
              var lines = new List<String>();
              if (choiceBlock.options["string"] != null) {
                // TODO: don't use when not needed (no variable)
                lines.add("  \"string\": () => \"\"\"${handleTrailingQuotes(choiceBlock.options["string"])}\"\"\"");
              }
              if (choiceBlock.options["goto"] != null) {
                lines.add("  \"goto\": r\"\"\"${handleTrailingQuotes(choiceBlock.options["goto"])}\"\"\"");
              }
              if (choiceBlock.options["script"] != null) {
                lines.add("  \"script\": () {${choiceBlock.options["script"]};}");
              }
              write(lines.join(",\n"));
              write("}${lineNumber != curBlock.lineEnd ? "," : ""}\n");
            }
          }
        }



        if (curBlock.type == BuilderBlock.BLK_CHOICE_QUESTION
            && _insideLineRange(lineNumber, curBlock, inclusive:false)) {
          indent = _getIndent(0);
          write("$line\n");
        }

        if (curBlock.type == BuilderBlock.BLK_SCRIPT
            && _insideLineRange(lineNumber, curBlock, inclusive:false)) {
          indent = _getIndent(0);

          bool needsToBeHandled = true;
          // check for <echo>
          if (subBlockIndex < curBlock.subBlocks.length) {
            var curSubBlock = curBlock.subBlocks[subBlockIndex];
            if (_insideLineRange(lineNumber, curSubBlock, inclusive:true)) {
              if (lineNumber == curSubBlock.lineStart) {
                // ignore the <echo> line, but get indenting
                subBlockIndent = line.indexOf("<");
                write("echo(\"\"\"");
              } else if (lineNumber < curSubBlock.lineEnd) {
                if (line.startsWith(_getIndent(subBlockIndent + 2))) {
                  // get rid of indenting
                  write("${line.substring(subBlockIndent + 2)}\n");
                } else {
                  write("$line\n");
                }
              } else {
                write("\"\"\");\n");
                subBlockIndex++;
              }
              needsToBeHandled = false;
            }
          }

          // script line, copy
          if (needsToBeHandled) {
            write("$line\n");
          }
        }
      }

      // end of block
      if (curPage != null && !curPage.blocks.isEmpty && blockIndex < curPage.blocks.length
          && lineNumber == curPage.blocks[blockIndex].lineEnd) {
        String commaOrNot = blockIndex < curPage.blocks.length - 1 ? "," : "";

        if (curBlock.type == BuilderBlock.BLK_TEXT) {
          if (curBlock.lineStart != curBlock.lineEnd) {
            indent = _getIndent(0);
            write("${handleTrailingQuotes(line)}\"\"\"$commaOrNot\n");
          }
        }

        if (curBlock.type == BuilderBlock.BLK_TEXT_WITH_VAR) {
          if (curBlock.lineStart != curBlock.lineEnd) {
            indent = _getIndent(0);
            write("${handleTrailingQuotes(line)}\"\"\");\n");
            indent = _getIndent(8);
            write("}$commaOrNot\n");
          }
        }

        if (curBlock.type == BuilderBlock.BLK_CHOICE_LIST) {
          indent = _getIndent(8);
          write("]\n$commaOrNot");
        }

        if (curBlock.type == BuilderBlock.BLK_CHOICE_QUESTION) {
          if (curBlock.lineStart != curBlock.lineEnd) {
            indent = _getIndent(0);
            write("${handleTrailingQuotes(line)}\"\"\"\n");
            indent = _getIndent(8);
            write("}$commaOrNot\n");
          }
        }

        if (curBlock.type == BuilderBlock.BLK_CHOICE) {
        }

        if (curBlock.type == BuilderBlock.BLK_SCRIPT) {
          indent = _getIndent(8);
          write("}$commaOrNot\n");
        }

        blockIndex++;
        curBlock = null;
      }


      // end page
      if (pageIndex < pages.length && lineNumber == pages[pageIndex].lineEnd) {
        // end blocks
        if (curPage.options.isEmpty) {
          write("]\n");
        } else {
          write("],\n");
          write(
              curPage.options.mappedBy((optName) => "$optName: true")
              .join(", ")
          );
        }
        indent = _getIndent(4);
        write(");\n");

        if (pageIndex == pages.length - 1) {
          // that was all of pageMap, now add firstPage and we're done here
          write("");
          write("firstPage = pageMap[r\"\"\"${pages[0].name}\"\"\"];");
        }

        pageIndex++;
        curPage = null;
      }

    };

    inStream.onLine = () {
      lineNumber++;
      var line = inStream.readLine();
      handleLine(line);
    };

    inStream.onClosed = () {
      completer.complete(true);
    };

    inStream.onError = (e) {
      completer.completeError(e);
    };
    return completer.future;
  }

  /**
   * Checks if string has a trailing [:":] char. If so, it is appended with
   * a space.
   *
   * The reason for this is that the Builder will surround the string with
   * triple quotes ([:""":]). A trailing quote in the (already) quoted string
   * will mean a quadruple quote ([:"""":]) which is interpreted by Dart
   * as the ending triple quote plus a hanging single quote.
   */
  String handleTrailingQuotes(String string) {
    if (string.endsWith('"')) {
      return "$string ";
    } else {
      return string;
    }
  }

  /**
   * Gets lines from inStream and dumps them to outStream.
   *
   * @param lineRanges  A collection of line ranges that need to be copied.
   * @param inStream  The input stream.
   * @param outStream The output stream.
   * @param inclusive Should the starting and ending lines in the lineRanges
   *                  be included?
   * @param indentLength  Whitespace indent.
   * @return  Always true.
   */
  Future<bool> copyLineRanges(Collection<BuilderLineRange> lineRanges,
      StringInputStream inStream, OutputStream outStream,
      {bool inclusive: true, int indentLength: 0}) {
    var completer = new Completer();
    outStream.writeString("\n");
    var indent = _getIndent(indentLength);

    int lineNumber = 0;
    inStream.onLine = () {
      lineNumber++;
      String line = inStream.readLine();

      // if lineNumber is in one of the ranges, write
      if (lineRanges.any((var range) => _insideLineRange(lineNumber, range, inclusive:inclusive))) {
        outStream.writeString("$indent$line\n");
      }
    };

    inStream.onClosed = () {
      outStream.writeString("\n");
      completer.complete(true);
    };
    inStream.onError = (e) {
      completer.completeError(e);
    };
    return completer.future;
  }

  /**
   * Gets path for the file with specified extension. Therefore, calling
   * [:getPathFor('graphml'):] for [:path/to/example.egb:] will return
   * [:path/to/example.graphml:].
   */
  Path getPathFor(String extension) {
    Path inputFilePath = new Path(inputEgbFileFullPath);
    return inputFilePath.directoryPath
          .join(new Path("${inputFilePath.filenameWithoutExtension}"
          ".$extension"));
  }

  /**
   * Writes GraphML file from current Builder object.
   **/
  Future<bool> writeGraphMLFile() {
    var completer = new Completer();

    var pathToOutputGraphML = getPathFor("graphml");
    File graphmlOutputFile = new File.fromPath(pathToOutputGraphML);
    OutputStream graphmlOutStream = graphmlOutputFile.openOutputStream();

    try {
      updateGraphML();
      graphmlOutStream.writeString(graphML.toString());
    } on Exception catch (e) {
      throw e;
    } finally {
      graphmlOutStream.close();
      graphmlOutStream.onClosed = () => completer.complete(true);
    }

    return completer.future;
  }

  /**
   * Builds the [graphML] structure from the current Builder instance.
   **/
  void updateGraphML() {
    graphML = new GraphML();

    // create group nodes
    Map<String,Node> pageGroupNodes = new Map<String,Node>();
    for (int i = 0; i < pageGroups.length; i++) {
      var node = new Node(pageGroups[i].name);
      pageGroupNodes[pageGroups[i].name] = node;
      graphML.addGroupNode(node);
    }

    // create nodes
    Map<String,Node> pageNodes = new Map<String,Node>();
    for (int i = 0; i < pages.length; i++) {
      var node = new Node(pages[i].nameWithoutGroup);
      pageNodes[pages[i].name] = node;
      if (pages[i].group != null) {
        node.parent = pageGroupNodes[pages[i].groupName];
      }
      graphML.addNode(node);
    }

    // create graph edges
    for (int i = 0; i < pages.length; i++) {
      BuilderPage page = pages[i];
      for (int j = 0; j < page.gotoPageNames.length; j++) {
        String gotoHandle = page.gotoPageNames[j];

        if (pageHandles.containsKey("${page.groupName}: $gotoHandle")) {
          graphML.addEdge(
              pageNodes[page.name],
              pageNodes["${page.groupName}: $gotoHandle"]);
        } else if (pageHandles.containsKey(gotoHandle)) {
            graphML.addEdge(
                pageNodes[page.name],
                pageNodes[gotoHandle]);
        } else {
          WARNING( "Choice links to a non-existent page ('$gotoHandle')"
                " in page ${page.name}. Creating new page/node.");

          var newPage = new BuilderPage(gotoHandle, pages.length);
          var node = new Node(newPage.nameWithoutGroup);
          pageNodes[newPage.name] = node;
          if (newPage.group != null) {
            node.parent = pageGroupNodes[newPage.groupName];
          }
          graphML.addNode(node);

          graphML.addEdge(
              pageNodes[page.name],
              pageNodes[newPage.name]);
        }
      }
    }

    graphML.updateXml();
  }

  /**
   * Opens the .graphml file, updates [graphML] from it, then calls
   * [updateFromGraphML()].
   */
  Future<bool> updateFromGraphMLFile() {
//    Completer completer = new Completer();

    var pathToInputGraphML = getPathFor("graphml");
    File graphmlInputFile = new File.fromPath(pathToInputGraphML);

    graphML = new GraphML.fromFile(graphmlInputFile); // TODO: make async!

    updateFromGraphML();
    return new Future.immediate(true);
  }

  /**
   * Updates the Builder instance from the current state of [graphML].
   */
  void updateFromGraphML() {
    // populate map of all nodes in graph
    Map<String,Node> nodesToAdd = new Map<String,Node>();
    for (var node in graphML.nodes) {
      nodesToAdd[node.fullText] = node;
    }

    // walk the existing Builder instance
    for (int i = 0; i < pages.length; i++) {
      BuilderPage page = pages[i];
      bool pageStays = nodesToAdd.containsKey(page.name);
      if (pageStays) {
        Node node = nodesToAdd[page.name];

        // populate map of all linked nodes in graphml
        Set<Node> linkedNodesToAdd = new Set<Node>.from(node.linkedNodes);
        Map<String,Node> linkedPageFullNamesToAdd = new Map<String,Node>();
        for (var node in linkedNodesToAdd) {
          linkedPageFullNamesToAdd[node.fullText] = node;
        }

        // create set of gotoPageNames to be deleted
        Set<String> gotoPageNamesToDelete = new Set<String>();

        // walk through goto links in egb
        for (var gotoPageName in page.gotoPageNames) {
          // make sure
          bool linkStays = linkedPageFullNamesToAdd.containsKey(gotoPageName);
          if (linkStays) {
            var linkedNode = linkedPageFullNamesToAdd[gotoPageName];
            linkedNodesToAdd.remove(linkedNode);
          } else {
            gotoPageNamesToDelete.add(gotoPageName);
          }
        }

        // delete excesive gotos
        page.gotoPageNames = page.gotoPageNames
                       .where((name) => !gotoPageNamesToDelete.contains(name)).toList();

        // add remaining linked nodes
        for (var linkedNode in linkedNodesToAdd) {
          page.gotoPageNames.add(linkedNode.fullText);
        }
      } else {
        page.commentOut = true;
      }

      // remove the node from "stack" if it's there
      nodesToAdd.remove(page.name);
    }

    // TODO: add new groupNodes

    // add remaining nodes
    nodesToAdd.forEach((String fullText, Node node) {

      int newIndex = pages.last.index + 1;
      var newPage = new BuilderPage(fullText, newIndex);
      pageHandles[fullText] = newIndex;
      node.linkedNodes.forEach(
          (linkedPage) => newPage.gotoPageNames.add(linkedPage.fullText)); // TODO: no need to fully qualify sometimes
      pages.add(newPage);
    });
  }

  /**
   * Updates the .egb file according to the current state of the Builder
   * instance.
   */
  Future<Builder> updateEgbFile() {
    var completer = new Completer();

    var tempFile = new File.fromPath(getPathFor("egb~"));
    File outputEgbFile;

    var tempInStream = inputEgbFile.openInputStream();
    tempInStream.pipe(tempFile.openOutputStream(FileMode.WRITE));
    tempInStream.onClosed = () {
      outputEgbFile = inputEgbFile;
      inputEgbFile = tempFile;
      var rawInputStream = inputEgbFile.openInputStream();
      var outStream = outputEgbFile.openOutputStream(FileMode.WRITE);

      if (pages.length == 0) {
        // right now, we can only update pages, so a file without pages stays the same
        rawInputStream.pipe(outStream);
      } else {
        var inStream = new StringInputStream(rawInputStream);

        // TODO: rewrite based on logical structure (i.e. insert new pages where they belong)

        int lineNumber = 0;
        BuilderPage page;
        Set<BuilderPage> pagesToAdd = new Set.from(pages);
        Set<String> gotoPageNamesToAdd;
        inStream.onLine = () {
          lineNumber++;
          String line = inStream.readLine();

          if (page != null && page.lineEnd < lineNumber) {
            // add remaining gotos
            bool addingPages = !gotoPageNamesToAdd.isEmpty;
            for (var gotoPageName in gotoPageNamesToAdd) {
              outStream.writeString(
                  "- $gotoPageName (AUTO) [$gotoPageName]\n");
            }
            if (addingPages) outStream.writeString("\n");
            page = null;
            gotoPageNamesToAdd = null;
          }

          if (page == null) {
            for (var candidate in pages) {
              if (_insideLineRange(lineNumber, candidate)) {
                page = candidate;
                pagesToAdd.remove(page);
                gotoPageNamesToAdd = new Set.from(page.gotoPageNames);
                break;
              }
            }
          }

          if (page != null) {
            // find out if this line has a goto, if so, remove from pageNamesToAdd
            String goto;
            Match m = choice.firstMatch(line);
            if (m != null) {
              goto = m.group(3); // TODO: make this into a function, DRY
            } else {
              m = gotoInsideScript.firstMatch(line);
              if (m != null) {
                goto = m.group(2);
              }
            }
            if (goto != null) {
              if (page.gotoPageNames.any((gotoPageName) => gotoPageName == goto)
                  || page.gotoPageNames.any((gotoPageName) => gotoPageName == "${page.groupName}: $goto")) {
                outStream
                  ..writeString(line)
                  ..writeString("\n");
                gotoPageNamesToAdd.remove(goto);
                gotoPageNamesToAdd.remove("${page.groupName}: $goto");
              } else {
                // choiceBlock shouldn't be here, to be deleted => do not copy
              }
            } else {
              // normal line, just copy
              outStream
                ..writeString(line)
                ..writeString("\n");
            }
          } else {
            // outside any page - just copy
            outStream
              ..writeString(line)
              ..writeString("\n");
          }

        };

        inStream.onClosed = () {
          for (var page in pagesToAdd) {
            outStream
              ..writeString("\n---\n")
              ..writeString(page.name)
              ..writeString("\n\n");

            for (var gotoPageName in page.gotoPageNames) {
              outStream.writeString(
                  "- $gotoPageName (AUTO) [$gotoPageName]\n");
            }
          }

          outStream.close();

          // TODO: delete egb~
          inputEgbFile.delete();
          inputEgbFile = outputEgbFile;

          new Builder().readEgbFile(inputEgbFile).then((Builder b) {
            completer.complete(b);;
          });
        };
        inStream.onError = (e) {
          completer.completeError(e);
        };
      }
    };

    return completer.future;
  }

  /**
   * Helper function creates a string of a given number of spaces. Useful
   * for indentation.
   *
   * @param len Number of spaces to return.
   * @return  The string, e.g. `"    "` for [_getIndent(4)].
   */
  String _getIndent(int len) {
    var strBuf = new StringBuffer();
    for (int i = 0; i < len; i++) {
      strBuf.add(" ");
    }
    return strBuf.toString();
  }

  /**
   * Returns true if given [lineNumber] is in given [range] of lines.
   *
   * @param lineNumber  Line number to check.
   * @param range Range of lines in question.
   * @param inclusive Whether or not to include the starting and ending
   *                  lines of the range in the computation.
   * @return True if line is inside range or if range has no lineStart and
   *                  lineEnd.
   */
  bool _insideLineRange(int lineNumber, BuilderLineRange range,
                        {bool inclusive: true}) {
    if (range.lineStart == null && range.lineEnd == null) {
      return false;
    }
    if (range.lineEnd == null) {
      throw "Range with lineStart == ${range.lineStart} has lineEnd == null "
            "in file $inputEgbFileFullPath.";
    }
    if (lineNumber >= range.lineStart
        && lineNumber <= range.lineEnd) {
      if (inclusive) {
        return true;
      } else if (lineNumber != range.lineStart
              && lineNumber != range.lineEnd) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }


  final String implStartFile = """
library Scripter_Implementation;

import '../../lib/src/egb_library.dart';
import 'dart:math';
""";

  final String implStartClass = """
class ScripterImpl extends EgbScripter {

  /* LIBRARY */
""";

  final String implStartCtor = """
  ScripterImpl() : super() {
""";

  final String implStartPages = """
    /* PAGES & BLOCKS */
    pageMap = new EgbScripterPageMap();
""";

  final String implEndPages = """
    
""";

  final String implEndCtor = """
  }
""";

  final String implStartInit = """
  /* INIT */
  void initBlock() {
""";

  final String implEndInit = """
  }
""";

  final String implEndClass = """
}
""";

  final String implEndFile = """
""";


  // These are available modes for the [mode] variable.
  static int MODE_NORMAL = 1;
  static int MODE_INSIDE_CLASSES = 2;
  static int MODE_INSIDE_FUNCTIONS = 4;
  static int MODE_INSIDE_VARIABLES = 8;
  static int MODE_INSIDE_SCRIPT_ECHO = 16;
  static int MODE_INSIDE_SCRIPT_TAG = 32;
  static int MODE_METADATA = 64;
  /// This makes sure the parser remembers where it is during reading the file.
  int _mode;

  /// Public getter for _mode.
  int get mode => _mode;
  /// Public setter for _mode. This is here for unit testing only.
  set mode(int value) => _mode = value;

  int _lineNumber;  // TODO: Because checking is async right now, this
                    // is only an _unreliable_ way of getting actual line number
  int _pageNumber;
  int _blockNumber;

  //String _thisLine;

  /** used to communicate problems to caller */
  List<String> warningLines;

  void WARNING(String msg, {int line}) {
    if (!?line) {
      line = _lineNumber;
    }
    String str = (line == null) ? msg : "$msg (line:$line)";

    print(str);
    warningLines.add(str);
  }
}
