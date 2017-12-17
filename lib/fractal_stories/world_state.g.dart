// GENERATED CODE - DO NOT MODIFY BY HAND

part of stranded.world_state;

// **************************************************************************
// Generator: BuiltValueGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line
// ignore_for_file: annotate_overrides
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: avoid_returning_this
// ignore_for_file: omit_local_variable_types
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: sort_constructors_first

class _$WorldState extends WorldState {
  @override
  final BuiltList<ActionRecord> actionRecords;
  @override
  final BuiltSet<Actor> actors;
  @override
  final Object global;
  @override
  final BuiltList<Situation> situations;
  @override
  final int time;

  factory _$WorldState([void updates(WorldStateBuilder b)]) =>
      (new WorldStateBuilder()..update(updates)).build() as _$WorldState;

  _$WorldState._(
      {this.actionRecords,
      this.actors,
      this.global,
      this.situations,
      this.time})
      : super._() {
    if (actionRecords == null) throw new ArgumentError.notNull('actionRecords');
    if (actors == null) throw new ArgumentError.notNull('actors');
    if (global == null) throw new ArgumentError.notNull('global');
    if (situations == null) throw new ArgumentError.notNull('situations');
    if (time == null) throw new ArgumentError.notNull('time');
  }

  @override
  WorldState rebuild(void updates(WorldStateBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  _$WorldStateBuilder toBuilder() => new _$WorldStateBuilder()..replace(this);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! WorldState) return false;
    return actionRecords == other.actionRecords &&
        actors == other.actors &&
        global == other.global &&
        situations == other.situations &&
        time == other.time;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc(0, actionRecords.hashCode), actors.hashCode),
                global.hashCode),
            situations.hashCode),
        time.hashCode));
  }
}

class _$WorldStateBuilder extends WorldStateBuilder {
  _$WorldState _$v;

  @override
  ListBuilder<ActionRecord> get actionRecords {
    _$this;
    return super.actionRecords ??= new ListBuilder<ActionRecord>();
  }

  @override
  set actionRecords(ListBuilder<ActionRecord> actionRecords) {
    _$this;
    super.actionRecords = actionRecords;
  }

  @override
  SetBuilder<Actor> get actors {
    _$this;
    return super.actors ??= new SetBuilder<Actor>();
  }

  @override
  set actors(SetBuilder<Actor> actors) {
    _$this;
    super.actors = actors;
  }

  @override
  Object get global {
    _$this;
    return super.global;
  }

  @override
  set global(Object global) {
    _$this;
    super.global = global;
  }

  @override
  ListBuilder<Situation> get situations {
    _$this;
    return super.situations ??= new ListBuilder<Situation>();
  }

  @override
  set situations(ListBuilder<Situation> situations) {
    _$this;
    super.situations = situations;
  }

  @override
  int get time {
    _$this;
    return super.time;
  }

  @override
  set time(int time) {
    _$this;
    super.time = time;
  }

  _$WorldStateBuilder() : super._();

  WorldStateBuilder get _$this {
    if (_$v != null) {
      super.actionRecords = _$v.actionRecords?.toBuilder();
      super.actors = _$v.actors?.toBuilder();
      super.global = _$v.global;
      super.situations = _$v.situations?.toBuilder();
      super.time = _$v.time;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WorldState other) {
    if (other == null) throw new ArgumentError.notNull('other');
    _$v = other as _$WorldState;
  }

  @override
  void update(void updates(WorldStateBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$WorldState build() {
    final _$result = _$v ??
        new _$WorldState._(
            actionRecords: actionRecords?.build(),
            actors: actors?.build(),
            global: global,
            situations: situations?.build(),
            time: time);
    replace(_$result);
    return _$result;
  }
}