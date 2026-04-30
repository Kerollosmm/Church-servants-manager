// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_assistant_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AIAssistantState {
  List<ChatMessage> get messages => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  AttendanceInsight? get lastInsight => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AIAssistantStateCopyWith<AIAssistantState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIAssistantStateCopyWith<$Res> {
  factory $AIAssistantStateCopyWith(
    AIAssistantState value,
    $Res Function(AIAssistantState) then,
  ) = _$AIAssistantStateCopyWithImpl<$Res, AIAssistantState>;
  @useResult
  $Res call({
    List<ChatMessage> messages,
    bool isLoading,
    String? errorMessage,
    AttendanceInsight? lastInsight,
  });
}

/// @nodoc
class _$AIAssistantStateCopyWithImpl<$Res, $Val extends AIAssistantState>
    implements $AIAssistantStateCopyWith<$Res> {
  _$AIAssistantStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
    Object? lastInsight = freezed,
  }) {
    return _then(
      _value.copyWith(
            messages: null == messages
                ? _value.messages
                : messages // ignore: cast_nullable_to_non_nullable
                      as List<ChatMessage>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastInsight: freezed == lastInsight
                ? _value.lastInsight
                : lastInsight // ignore: cast_nullable_to_non_nullable
                      as AttendanceInsight?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AIAssistantStateImplCopyWith<$Res>
    implements $AIAssistantStateCopyWith<$Res> {
  factory _$$AIAssistantStateImplCopyWith(
    _$AIAssistantStateImpl value,
    $Res Function(_$AIAssistantStateImpl) then,
  ) = __$$AIAssistantStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<ChatMessage> messages,
    bool isLoading,
    String? errorMessage,
    AttendanceInsight? lastInsight,
  });
}

/// @nodoc
class __$$AIAssistantStateImplCopyWithImpl<$Res>
    extends _$AIAssistantStateCopyWithImpl<$Res, _$AIAssistantStateImpl>
    implements _$$AIAssistantStateImplCopyWith<$Res> {
  __$$AIAssistantStateImplCopyWithImpl(
    _$AIAssistantStateImpl _value,
    $Res Function(_$AIAssistantStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
    Object? lastInsight = freezed,
  }) {
    return _then(
      _$AIAssistantStateImpl(
        messages: null == messages
            ? _value._messages
            : messages // ignore: cast_nullable_to_non_nullable
                  as List<ChatMessage>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastInsight: freezed == lastInsight
            ? _value.lastInsight
            : lastInsight // ignore: cast_nullable_to_non_nullable
                  as AttendanceInsight?,
      ),
    );
  }
}

/// @nodoc

class _$AIAssistantStateImpl implements _AIAssistantState {
  const _$AIAssistantStateImpl({
    final List<ChatMessage> messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastInsight,
  }) : _messages = messages;

  final List<ChatMessage> _messages;
  @override
  @JsonKey()
  List<ChatMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? errorMessage;
  @override
  final AttendanceInsight? lastInsight;

  @override
  String toString() {
    return 'AIAssistantState(messages: $messages, isLoading: $isLoading, errorMessage: $errorMessage, lastInsight: $lastInsight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIAssistantStateImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.lastInsight, lastInsight) ||
                other.lastInsight == lastInsight));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_messages),
    isLoading,
    errorMessage,
    lastInsight,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AIAssistantStateImplCopyWith<_$AIAssistantStateImpl> get copyWith =>
      __$$AIAssistantStateImplCopyWithImpl<_$AIAssistantStateImpl>(
        this,
        _$identity,
      );
}

abstract class _AIAssistantState implements AIAssistantState {
  const factory _AIAssistantState({
    final List<ChatMessage> messages,
    final bool isLoading,
    final String? errorMessage,
    final AttendanceInsight? lastInsight,
  }) = _$AIAssistantStateImpl;

  @override
  List<ChatMessage> get messages;
  @override
  bool get isLoading;
  @override
  String? get errorMessage;
  @override
  AttendanceInsight? get lastInsight;
  @override
  @JsonKey(ignore: true)
  _$$AIAssistantStateImplCopyWith<_$AIAssistantStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
