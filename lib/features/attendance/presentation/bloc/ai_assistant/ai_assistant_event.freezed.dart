// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_assistant_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AIAssistantEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String groupId, String question) getGroupInsight,
    required TResult Function(String query, Map<String, dynamic>? contextData)
    sendQuery,
    required TResult Function() clearChat,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String groupId, String question)? getGroupInsight,
    TResult? Function(String query, Map<String, dynamic>? contextData)?
    sendQuery,
    TResult? Function()? clearChat,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String groupId, String question)? getGroupInsight,
    TResult Function(String query, Map<String, dynamic>? contextData)?
    sendQuery,
    TResult Function()? clearChat,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GetGroupInsight value) getGroupInsight,
    required TResult Function(SendQuery value) sendQuery,
    required TResult Function(ClearChat value) clearChat,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GetGroupInsight value)? getGroupInsight,
    TResult? Function(SendQuery value)? sendQuery,
    TResult? Function(ClearChat value)? clearChat,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GetGroupInsight value)? getGroupInsight,
    TResult Function(SendQuery value)? sendQuery,
    TResult Function(ClearChat value)? clearChat,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIAssistantEventCopyWith<$Res> {
  factory $AIAssistantEventCopyWith(
    AIAssistantEvent value,
    $Res Function(AIAssistantEvent) then,
  ) = _$AIAssistantEventCopyWithImpl<$Res, AIAssistantEvent>;
}

/// @nodoc
class _$AIAssistantEventCopyWithImpl<$Res, $Val extends AIAssistantEvent>
    implements $AIAssistantEventCopyWith<$Res> {
  _$AIAssistantEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$GetGroupInsightImplCopyWith<$Res> {
  factory _$$GetGroupInsightImplCopyWith(
    _$GetGroupInsightImpl value,
    $Res Function(_$GetGroupInsightImpl) then,
  ) = __$$GetGroupInsightImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String groupId, String question});
}

/// @nodoc
class __$$GetGroupInsightImplCopyWithImpl<$Res>
    extends _$AIAssistantEventCopyWithImpl<$Res, _$GetGroupInsightImpl>
    implements _$$GetGroupInsightImplCopyWith<$Res> {
  __$$GetGroupInsightImplCopyWithImpl(
    _$GetGroupInsightImpl _value,
    $Res Function(_$GetGroupInsightImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? groupId = null, Object? question = null}) {
    return _then(
      _$GetGroupInsightImpl(
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        question: null == question
            ? _value.question
            : question // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$GetGroupInsightImpl implements GetGroupInsight {
  const _$GetGroupInsightImpl({required this.groupId, required this.question});

  @override
  final String groupId;
  @override
  final String question;

  @override
  String toString() {
    return 'AIAssistantEvent.getGroupInsight(groupId: $groupId, question: $question)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GetGroupInsightImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.question, question) ||
                other.question == question));
  }

  @override
  int get hashCode => Object.hash(runtimeType, groupId, question);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GetGroupInsightImplCopyWith<_$GetGroupInsightImpl> get copyWith =>
      __$$GetGroupInsightImplCopyWithImpl<_$GetGroupInsightImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String groupId, String question) getGroupInsight,
    required TResult Function(String query, Map<String, dynamic>? contextData)
    sendQuery,
    required TResult Function() clearChat,
  }) {
    return getGroupInsight(groupId, question);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String groupId, String question)? getGroupInsight,
    TResult? Function(String query, Map<String, dynamic>? contextData)?
    sendQuery,
    TResult? Function()? clearChat,
  }) {
    return getGroupInsight?.call(groupId, question);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String groupId, String question)? getGroupInsight,
    TResult Function(String query, Map<String, dynamic>? contextData)?
    sendQuery,
    TResult Function()? clearChat,
    required TResult orElse(),
  }) {
    if (getGroupInsight != null) {
      return getGroupInsight(groupId, question);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GetGroupInsight value) getGroupInsight,
    required TResult Function(SendQuery value) sendQuery,
    required TResult Function(ClearChat value) clearChat,
  }) {
    return getGroupInsight(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GetGroupInsight value)? getGroupInsight,
    TResult? Function(SendQuery value)? sendQuery,
    TResult? Function(ClearChat value)? clearChat,
  }) {
    return getGroupInsight?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GetGroupInsight value)? getGroupInsight,
    TResult Function(SendQuery value)? sendQuery,
    TResult Function(ClearChat value)? clearChat,
    required TResult orElse(),
  }) {
    if (getGroupInsight != null) {
      return getGroupInsight(this);
    }
    return orElse();
  }
}

abstract class GetGroupInsight implements AIAssistantEvent {
  const factory GetGroupInsight({
    required final String groupId,
    required final String question,
  }) = _$GetGroupInsightImpl;

  String get groupId;
  String get question;
  @JsonKey(ignore: true)
  _$$GetGroupInsightImplCopyWith<_$GetGroupInsightImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SendQueryImplCopyWith<$Res> {
  factory _$$SendQueryImplCopyWith(
    _$SendQueryImpl value,
    $Res Function(_$SendQueryImpl) then,
  ) = __$$SendQueryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String query, Map<String, dynamic>? contextData});
}

/// @nodoc
class __$$SendQueryImplCopyWithImpl<$Res>
    extends _$AIAssistantEventCopyWithImpl<$Res, _$SendQueryImpl>
    implements _$$SendQueryImplCopyWith<$Res> {
  __$$SendQueryImplCopyWithImpl(
    _$SendQueryImpl _value,
    $Res Function(_$SendQueryImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null, Object? contextData = freezed}) {
    return _then(
      _$SendQueryImpl(
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        contextData: freezed == contextData
            ? _value._contextData
            : contextData // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc

class _$SendQueryImpl implements SendQuery {
  const _$SendQueryImpl({
    required this.query,
    final Map<String, dynamic>? contextData,
  }) : _contextData = contextData;

  @override
  final String query;
  final Map<String, dynamic>? _contextData;
  @override
  Map<String, dynamic>? get contextData {
    final value = _contextData;
    if (value == null) return null;
    if (_contextData is EqualUnmodifiableMapView) return _contextData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'AIAssistantEvent.sendQuery(query: $query, contextData: $contextData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SendQueryImpl &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(
              other._contextData,
              _contextData,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    query,
    const DeepCollectionEquality().hash(_contextData),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SendQueryImplCopyWith<_$SendQueryImpl> get copyWith =>
      __$$SendQueryImplCopyWithImpl<_$SendQueryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String groupId, String question) getGroupInsight,
    required TResult Function(String query, Map<String, dynamic>? contextData)
    sendQuery,
    required TResult Function() clearChat,
  }) {
    return sendQuery(query, contextData);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String groupId, String question)? getGroupInsight,
    TResult? Function(String query, Map<String, dynamic>? contextData)?
    sendQuery,
    TResult? Function()? clearChat,
  }) {
    return sendQuery?.call(query, contextData);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String groupId, String question)? getGroupInsight,
    TResult Function(String query, Map<String, dynamic>? contextData)?
    sendQuery,
    TResult Function()? clearChat,
    required TResult orElse(),
  }) {
    if (sendQuery != null) {
      return sendQuery(query, contextData);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GetGroupInsight value) getGroupInsight,
    required TResult Function(SendQuery value) sendQuery,
    required TResult Function(ClearChat value) clearChat,
  }) {
    return sendQuery(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GetGroupInsight value)? getGroupInsight,
    TResult? Function(SendQuery value)? sendQuery,
    TResult? Function(ClearChat value)? clearChat,
  }) {
    return sendQuery?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GetGroupInsight value)? getGroupInsight,
    TResult Function(SendQuery value)? sendQuery,
    TResult Function(ClearChat value)? clearChat,
    required TResult orElse(),
  }) {
    if (sendQuery != null) {
      return sendQuery(this);
    }
    return orElse();
  }
}

abstract class SendQuery implements AIAssistantEvent {
  const factory SendQuery({
    required final String query,
    final Map<String, dynamic>? contextData,
  }) = _$SendQueryImpl;

  String get query;
  Map<String, dynamic>? get contextData;
  @JsonKey(ignore: true)
  _$$SendQueryImplCopyWith<_$SendQueryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ClearChatImplCopyWith<$Res> {
  factory _$$ClearChatImplCopyWith(
    _$ClearChatImpl value,
    $Res Function(_$ClearChatImpl) then,
  ) = __$$ClearChatImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ClearChatImplCopyWithImpl<$Res>
    extends _$AIAssistantEventCopyWithImpl<$Res, _$ClearChatImpl>
    implements _$$ClearChatImplCopyWith<$Res> {
  __$$ClearChatImplCopyWithImpl(
    _$ClearChatImpl _value,
    $Res Function(_$ClearChatImpl) _then,
  ) : super(_value, _then);
}

/// @nodoc

class _$ClearChatImpl implements ClearChat {
  const _$ClearChatImpl();

  @override
  String toString() {
    return 'AIAssistantEvent.clearChat()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ClearChatImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String groupId, String question) getGroupInsight,
    required TResult Function(String query, Map<String, dynamic>? contextData)
    sendQuery,
    required TResult Function() clearChat,
  }) {
    return clearChat();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String groupId, String question)? getGroupInsight,
    TResult? Function(String query, Map<String, dynamic>? contextData)?
    sendQuery,
    TResult? Function()? clearChat,
  }) {
    return clearChat?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String groupId, String question)? getGroupInsight,
    TResult Function(String query, Map<String, dynamic>? contextData)?
    sendQuery,
    TResult Function()? clearChat,
    required TResult orElse(),
  }) {
    if (clearChat != null) {
      return clearChat();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GetGroupInsight value) getGroupInsight,
    required TResult Function(SendQuery value) sendQuery,
    required TResult Function(ClearChat value) clearChat,
  }) {
    return clearChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GetGroupInsight value)? getGroupInsight,
    TResult? Function(SendQuery value)? sendQuery,
    TResult? Function(ClearChat value)? clearChat,
  }) {
    return clearChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GetGroupInsight value)? getGroupInsight,
    TResult Function(SendQuery value)? sendQuery,
    TResult Function(ClearChat value)? clearChat,
    required TResult orElse(),
  }) {
    if (clearChat != null) {
      return clearChat(this);
    }
    return orElse();
  }
}

abstract class ClearChat implements AIAssistantEvent {
  const factory ClearChat() = _$ClearChatImpl;
}
