import 'package:edgehead/fractal_stories/action.dart';
import 'package:edgehead/fractal_stories/actor.dart';
import 'package:edgehead/fractal_stories/context.dart';
import 'package:edgehead/fractal_stories/room.dart';
import 'package:edgehead/fractal_stories/room_approach.dart';
import 'package:edgehead/fractal_stories/simulation.dart';
import 'package:edgehead/fractal_stories/world_state.dart';
import 'package:edgehead/src/room_roaming/room_roaming_situation.dart';
import 'package:logging/logging.dart';

class TakeApproachAction extends Action<RoomPath> {
  static const String className = "TakeApproachAction";

  static final TakeApproachAction singleton = TakeApproachAction();

  static final Logger _log = Logger('TakeApproachAction');

  @override
  List<String> get commandPathTemplate =>
      throw UnimplementedError('This action overrides getCommandPath().');

  @override
  String get helpMessage => null;

  @override
  bool get isAggressive => false;

  @override
  bool get isImplicit => false;

  @override
  bool get isProactive => true;

  @override
  String get name => className;

  @override
  bool get rerollable => false;

  @override
  Resource get rerollResource => null;

  @override
  String applyFailure(ActionContext context, RoomPath path) {
    throw UnimplementedError();
  }

  @override
  String applySuccess(ActionContext context, RoomPath path) {
    Actor a = context.actor;
    WorldStateBuilder w = context.outputWorld;
    if (path.approach.description != null) {
      path.approach.description(context);
    }

    (w.currentSituation as RoomRoamingSituation)
        .moveActor(context, path.approach.to);

    return "${a.name} went through approach to ${path.approach.to}";
  }

  @override
  Iterable<RoomPath> generateObjects(ApplicabilityContext context) {
    final situation = context.world.currentSituation as RoomRoamingSituation;
    var room = context.simulation.getRoomByName(situation.currentRoomName);
    _log.finest(() => 'Generating approaches for ${context.actor} from $room');

    return _walkApproaches(context, room);
  }

  /// [TakeApproach] returns the path from the current position to
  /// [Approach.to], as a list of coordinates.
  ///
  /// For example, `[0, 0, 10, 5, 100, 100]` is a path from (0, 0)
  /// through (10, 5) to (100, 100).
  @override
  List<int> getAdditionalData(ApplicabilityContext context, RoomPath path) {
    return path.getPathCoordinates().toList(growable: false);
  }

  /// When the writer specifies a command with " >> " in it, this will
  /// automatically create a command path.
  ///
  /// For example, "go >> upper door".
  @override
  List<String> getCommandPath(ApplicabilityContext context, RoomPath path) =>
      path.approach.command.split(' >> ');

  @override
  String getRollReason(Actor a, Simulation sim, WorldState w, RoomPath path) =>
      "WARNING should not be user-visible";

  @override
  ReasonedSuccessChance getSuccessChance(
          Actor a, Simulation sim, WorldState w, RoomPath path) =>
      ReasonedSuccessChance.sureSuccess;

  @override
  bool isApplicable(ApplicabilityContext c, Actor a, Simulation sim,
      WorldState w, RoomPath path) {
    if (path.approach.isImplicit) {
      // Implicit approaches are covered by TakeImplicitApproachAction.
      return false;
    }

    if ((w.currentSituation as RoomRoamingSituation).monstersAlive) {
      // Don't allow exit taking when monsters in this room are still alive.
      return false;
    }

    if (path.approach.isApplicable != null) {
      return path.approach.isApplicable(c);
    }

    return true;
  }

  /// Returns all approaches that can be accessed from [startingRoom] either
  /// directly, or through a set of already-explored other rooms.
  ///
  /// This lets the player "fast travel" throughout the map.
  static Iterable<RoomPath> _walkApproaches(
      ApplicabilityContext context, Room startingRoom) sync* {
    // The unclosed paths that we yet have to explore.
    final open = {RoomPath.start(startingRoom)};

    // Rooms that have been visited by the walk, and therefore shouldn't be
    // considered again.
    // These are normalized to the parent (no variants here).
    final closed = <Room>{context.simulation.getRoomParent(startingRoom)};

    while (open.isNotEmpty) {
      final current = open.first;
      open.remove(current);
      _log.finest(() => 'Going from sourceRoom=${current.from} '
          '(open.length=${open.length})');

      final approaches = context.simulation
          .getAvailableApproaches(current.destination, context)
          .toList(growable: false);

      assert(approaches.every((a) => !a.isImplicit) || approaches.length == 1,
          "You can have only one implicit approach: $approaches");

      for (final approach in approaches) {
        final destination = context.simulation.getRoomByName(approach.to);
        final destinationParent = context.simulation.getRoomParent(destination);

        if (closed.contains(destinationParent)) {
          // Don't revisit rooms that have already been walked by
          // this algorithm.
          continue;
        }

        closed.add(destination);

        // Construct the new path from the last one, by adding one intermediate
        // room, and changing the destination.
        final newPath = RoomPath(
          startingRoom,
          current.destination,
          destination,
          approach,
          List.from(current.intermediateRooms)..add(current.destination),
        );

        if (approach.isImplicit) {
          // Don't auto-travel through implicit approaches. Just yield it.
          yield newPath;
          continue;
        }

        yield newPath;

        if (context.world.visitHistory
            .query(context.actor, destination)
            .hasHappened) {
          // The actor has been here. They can "fast travel" through.
          open.add(newPath);
        }
      }
    }
  }
}

class RoomPath {
  static final Logger _log = Logger('RoomPath');

  final Approach approach;

  /// The origin of the path.
  final Room origin;

  /// The last room on this path.
  final Room destination;

  /// The second to last room on this path.
  final Room from;

  final List<Room> intermediateRooms;

  const RoomPath(this.origin, this.from, this.destination, this.approach,
      this.intermediateRooms)
      : assert(origin != null),
        assert(from != null),
        assert(destination != null),
        assert(approach != null),
        assert(intermediateRooms != null);

  const RoomPath.start(this.destination)
      : origin = null,
        from = null,
        intermediateRooms = const [],
        approach = null;

  bool get isStart => origin == null;

  /// Constructs the list of coordinates that we can send to the UI as a path.
  Iterable<int> getPathCoordinates() sync* {
    assert(
        !isStart,
        'Trying to construct path for RoomPath.start(). '
        'This should not happen: the starting path is empty, and only used '
        'for the tree search.');

    if (origin.positionX == null || origin.positionY == null) {
      _log.info('$origin in $this has no position. Returning empty path.');
      return;
    }

    if (destination.positionX == null || destination.positionY == null) {
      _log.info('$destination in $this has no position. '
          'Returning empty path.');
      return;
    }

    yield origin.positionX;
    yield origin.positionY;

    for (final room in intermediateRooms) {
      if (room.positionX == null || room.positionY == null) {
        continue;
      }

      yield room.positionX;
      yield room.positionY;
    }

    yield destination.positionX;
    yield destination.positionY;
  }

  @override
  String toString() => 'RoomPath<$origin, $from, $destination, $approach>';
}
