library egb_form;

/**
 * A container of a 'form' - a specialized type of choice when you need more
 * than simple choice ([EgbChoice]).
 * 
 * Forms materialize as something very similar to a standard HTML Form, with
 * input fields (such as text fields, sliders, multiple-choice, checkboxes),
 * labels, other arbitrary HTML elements (such as visualizations) and one or
 * more submit buttons.
 * 
 * The whole structure is sent as JsonML, so everything can be nested, and
 * HTML(-like) interfaces have very easy ways to materialize the [Form].
 * 
 * ## Live updates
 * 
 * It is possible for the form's elements to be updated automatically after
 * user's input. For instance, when player has allocated all of his resources,
 * all resource sliders should be locked at their current maximum. If two
 * checkboxes are mutually exclusive and one of them has been checked, the other
 * one should be disabled.
 * 
 * The logic of the updating can be quite complex and gamebook-dependent, so it
 * is executed in the Scripter. 
 * 
 * When presented to the user, and after each user input, the form is 
 * temporarily disabled (no user input allowed) and a callback is fired. This
 * callback goes from [EgbInterface] to [EgbScripter] (therefore, sometimes it
 * has to go into another Isolate or even to a server).
 * 
 * Each node of the Form structure is given a unique ID. This makes it easy
 * to identify the element to be updated.
 * 
 * ## Example use
 * 
 * All this happens in a `<script>` element, not in `<variables>` (of course, 
 * the variables like `name` can be defined in `<variables>`, but the form
 * itself should not be persistent between sessions).
 * 
 *     String name;
 *     int age;
 *     String sex;
 *     var form = new Form();
 *     form.add(new TextInput("Name", (value) => name = value,
 *                            validate: (value) => value != "");
 *     form.add(new RangeInput("Age", (value) => age = value,
 *                             min: 20, max: 100, value: 30, step: 1,
 *                             maxEnabled: 40));
 *     form.add(new RadioChoice("Sex", 
 *                              {"m": "Male [+1 STR]", "f": "Female [+1 INT]"}, 
 *                              (value) => sex = m));
 *     ask(form)
 *     .then((_) {});
 *
 * Another, more complex example:
 * 
 *     int energyAvailable = 15;
 *     int energyReserve = 4;
 *     int energyToManeuvres = 0;
 *     int energyToShield = 0;
 *     int energyToRepair = 0;
 *     int energyToHyperdrive = 0;
 *     int energyToWeapons = 0;
 * 
 *     var form = new Form();
 *     var energySection = new FormSection("Energy");
 *     var energyAvailableEl = new RangeOutput("Available", max: 15, 
 *                                             value: energyAvailable);
 *     energySection.add(energyAvailableEl);
 *     var energyReserveEl = new RangeOutput("Reserves", max: 6, 
 *                                           value: energyReserve);
 *     energySection.add(energyReserveEl);
 *     var energyToManeuvresEl = new RangeInput("Maneuvres", max: 6, value: 0);
 *     energySection.add(energyToManeuvresEl);
 *     form.add(energySection);
 *     form.onInputListener = (_) {
 *       energyAvailableEl.value = energyAvailable - energyToManeuvresEl.value;
 *       // ...
 *       form.update();  // Sends the new setup to interface.
 *     };
 * 
 *     ask(form);
 *   
 */

import "package:html5lib/dom.dart" as html5lib;
import "package:jsonml/html5lib2jsonml.dart";
import 'dart:math';

class FormElement extends html5lib.Element {
  FormElement(String elementClass) : super.tag(elementClass);

  //  /**
  //   * The [id] is unique in any form and is assigned by the top-level [Form]
  //   * element. (This allows for [Form.update] payloads to only carry the updated
  //   * data.
  //   */
  //  int id;

  //  /// The parent element. Should be [:null:] only when this element is the
  //  /// [Form].
  //  FormElement parent;

  /// Every form element can have a help button that shows a text message.
  String get helpMessage => attributes["helpMessage"];
  set helpMessage(String value) => attributes["helpMessage"] = value;

  /// Sets the visibility of the element. This works like CSS [:display:],
  /// meaning that when set to [:false:], the element will not occupy its
  /// space (there will be no 'white rectange' in the place of a hidden element
  /// like with CSS [:visibility:]).
  bool get hidden => attributes["hidden"] == "true";
  set hidden(bool value) => attributes["hidden"] = value ? "true" : "false";
  
  /// Utility function that walks through the whole structure recursively and
  /// adds all [FormElement] children to the [set].
  void _addFormChildrenToSet(FormElement element, Set<FormElement> set) {
    for (html5lib.Element child in element.children) {
      if (child is FormElement) {
        set.add(child);
        _addFormChildrenToSet(child, set);
      }
    }
  }
  
  Set<FormElement> get allFormElements {
    Set<FormElement> set = new Set<FormElement>();
    _addFormChildrenToSet(this, set);
    return set;
  }
}

abstract class UpdatableByMap {
  Map<String,Object> toMap();
  void updateFromMap(Map<String,Object> map);
}

class FormBase extends FormElement {
  FormBase() : super("Form");

  /// The text to be on the submit button. Defaults to [:null:], in which case
  /// the button will just have a generic graphic (such as an arrow or a check
  /// mark).
  String get submitText => attributes["submitText"];
  set submitText(String value) => attributes["submitText"] = value;
}

/**
 * The top level element of a form, containing all other elements. 
 * Author-facing.
 */
class Form extends FormBase {
  String formUid;
  Random _random = new Random();
  
  Form({String submitText}) {
    this.submitText = submitText;
    formUid = "${_random.nextInt((1<<16))}";  // Assuming this is enough.
  }

  receiveUserInput(Map newValues) {
    // TODO: go to each element, if element has onInputListener, then fire that,
    // otherwise, change value directly. Also, walk up the parent chain to
    // see if there are other onInputListeners to fire.
    // Returns Future?
  }
  
  bool _uniqueIdsGiven = false;
  void _giveChildrenUniqueIds() {
    int id = 0;
    allFormElements.forEach((FormElement element) {
      element.id = "$formUid::${id++}";
    });
    _uniqueIdsGiven = true;
  }

  Map<String,Object> toMap() {
    if (!_uniqueIdsGiven) {
      // Set all children with a unique ID here or before here.
      _giveChildrenUniqueIds();
    }
    Map<String,Object> map = new Map<String,Object>();
    map["jsonml"] = encodeToJsonML(this);
    Map<String,Object> valuesMap = new Map<String,Object>(); 
    map["values"] = valuesMap;
    for (UpdatableByMap element 
        in allFormElements.where((element) => element is UpdatableByMap)) {
      valuesMap[(element as FormElement).id] = element.toMap(); 
    }
    return map;
  }
}

class FormSection extends FormElement {
  final String name;
  FormSection(this.name) : super("FormSection");
}

class _ValueCallback<T> {
  /**
   * The function to be called when the element has a new value. The value is
   * given as the only argument to the callback.
   */
  InputCallback onInput;
}

typedef void InputCallback(value);

/**
 * Base class of [RangeInput] and [InterfaceRangeInput].
 */
class BaseRangeInput extends FormElement implements UpdatableByMap {
  String get name => attributes["name"];
  set name(String value) => attributes["name"] = value;
  
  static const String elementClass = "RangeInput";

  BaseRangeInput(String name) : super(elementClass) {
    this.name = name;
  }
  BaseRangeInput.withConstraints(String name, this.current, this.min, this.max, 
      this.step, this.minEnabled, this.maxEnabled) : super(elementClass) {
    this.name = name;
  }

  /// Current (or predefined) value selected on the range input. Defaults to
  /// [:0:]. We use `current` because `value` is the [String] value of any
  /// HTML5 element (although it's deprecated in html5lib).
  int current = 0;
  /// Minimal value on the range input. Defaults to [:0:].
  int min = 0;
  /// Maximal value on the range input. Defaults to [:10:].
  int max = 10;
  /// Allows for the range values to be in steps larger than [:1:] (the
  /// default).
  int step = 1;
  /// Numbers below this value will be visible to player, but disabled for
  /// choosing. This can communicate to the player that those values could be
  /// possible to choose in other circumstances. When set to [:null:] (default),
  /// all numbers are possible.
  int minEnabled;
  /// Same as [minEnabled], but for values _above_ this number.
  int maxEnabled;

  @override
  Map<String, Object> toMap() => {
    "current": current,
    "min": min,
    "max": max,
    "step": step,
    "minEnabled": minEnabled,
    "maxEnabled": maxEnabled
  };

  @override
  void updateFromMap(Map<String, Object> map) {
    current = map["current"];
    min = map["min"];
    max = map["max"];
    step = map["step"];
    minEnabled = map["minEnabled"];
    maxEnabled = map["maxEnabled"];
  }
}

/**
 * The author-facing class of the range input element. It works only with
 * integers
 */
class RangeInput extends BaseRangeInput with _ValueCallback<int> {
  RangeInput(String name, InputCallback onInput, {int value: 0, int min: 0, int
      max: 10, int step: 1, int minEnabled, int maxEnabled}) : super.withConstraints(
      name, value, min, max, step, minEnabled, maxEnabled) {
    this.onInput = onInput;
  }
}