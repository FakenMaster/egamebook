library stranded.history;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:edgehead/fractal_stories/actor.dart';
import 'package:edgehead/fractal_stories/room.dart';
import 'package:meta/meta.dart';

part 'history.g.dart';

/// The result of querying a history.
abstract class QueryResult<T extends Record> {
  /// Whether or not this query found at least one event.
  bool get hasHappened;

  /// The latest event matching the query.
  T get latest;
}

/// A base interface to all records.
abstract class Record {
  /// The time at which the event occurred. Must be in UTC.
  DateTime get time;
}

abstract class RuleHistory implements Built<RuleHistory, RuleHistoryBuilder> {
  factory RuleHistory([void updates(RuleHistoryBuilder b)]) = _$RuleHistory;

  RuleHistory._();

  BuiltMap<int, RuleRecord> get records;

  SingleQueryResult<RuleRecord> query(int ruleId) {
    return new SingleQueryResult(records[ruleId]);
  }
}

class RuleRecord implements Record {
  int ruleId;

  @override
  DateTime time;

  RuleRecord(this.ruleId, this.time);
}

/// A history result that could have happened several times.
///
/// For example, visiting San Francisco can happen several times during
/// a lifetime, and we might want to track all occurrences.
///
/// The counterpart class is [SingleQueryResult].
class SerialQueryResult<T extends Record> implements QueryResult<T> {
  Iterable<T> _records;

  bool _walked = false;

  SerialQueryResult(this._records);

  @override
  bool get hasHappened {
    _checkUnwalked();

    for (final _ in _records) {
      return true;
    }

    return false;
  }

  @override
  T get latest {
    _checkUnwalked();

    for (final record in _records) {
      return record;
    }

    return null;
  }

  /// Ensures that the [_records] iterable isn't walked more than once. This
  /// means that [QueryResult] can only be used once.
  void _checkUnwalked() {
    if (_walked) throw new StateError("Trying to walk query twice.");
    _walked = true;
  }
}

/// A history result that can meaningfully happen only once.
///
/// For example, being born is often a once-in-a-lifetime event. But even events
/// like "drink coffee", which can happen many times in real life, could
/// be modelled as [SingleQueryResult] if the game really only cares about
/// the _last_ time the player did something, and previous instances are
/// irrelevant.
///
/// The counterpart class is [SerialQueryResult].
class SingleQueryResult<T extends Record> implements QueryResult<T> {
  T _record;

  SingleQueryResult(this._record);

  @override
  bool get hasHappened => _record != null;

  @override
  T get latest => _record;
}

/// A record of all visits made to any room by any actor.
abstract class VisitHistory
    implements Built<VisitHistory, VisitHistoryBuilder> {
  static Serializer<VisitHistory> get serializer => _$visitHistorySerializer;

  factory VisitHistory([void updates(VisitHistoryBuilder b)]) = _$VisitHistory;

  VisitHistory._();

  /// A map from keys (as defined by [VisitHistory.getKey]) to iterables
  /// of stored [VisitRecord]s.
  ///
  /// The records are grouped for faster access.
  BuiltListMultimap<String, VisitRecord> get records;

  /// Returns the record for the particular [actor] and the [room].
  ///
  /// By default, this only asks for record of the particular variant of the
  /// room. If you don't care what state the room was in when the actor
  /// visited it, set [includeVariants] to `true`.
  SerialQueryResult<VisitRecord> query(Actor actor, Room room,
      {bool includeVariants: false}) {
    assert(actor != null);
    assert(room != null);
    final key = getKey(room);
    return new SerialQueryResult(records[key].where((rec) {
      if (rec.roomName == room.name) return true;
      if (includeVariants && rec.parentRoomName == room.name) return true;
      return false;
    }));
  }

  /// Returns the latest visit performed by [actor].
  VisitRecord getLatestOnly(Actor actor) {
    final visited = records.values.where((rec) => rec.actorId == actor.id);
    VisitRecord latest;
    for (final rec in visited) {
      if (latest == null) {
        latest = rec;
        continue;
      }
      if (rec.time.isAfter(latest.time)) {
        latest = rec;
      }
    }
    return latest;
  }

  /// Visits are grouped by rooms. More specifically, they are grouped by
  /// names of rooms, or names of parent rooms if applicable.
  ///
  /// We can't go more specific, because for visits of variants, it's
  /// not clear whether to index by variant room name, or parent room name.
  /// So we always go with parent room name.
  static String getKey(Room room) => room.parent ?? room.name;
}

abstract class VisitRecord
    implements Record, Built<VisitRecord, VisitRecordBuilder> {
  static Serializer<VisitRecord> get serializer => _$visitRecordSerializer;

  factory VisitRecord(
      {@required DateTime time,
      @required int actorId,
      @required String roomName,
      String parentRoomName}) = _$VisitRecord._;

  VisitRecord._();

  int get actorId;

  @nullable
  String get parentRoomName;

  String get roomName;

  @override
  DateTime get time;
}