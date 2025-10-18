import 'package:equatable/equatable.dart';

abstract class SpeechState extends Equatable {
  const SpeechState();

  @override
  List<Object?> get props => [];
}

class SpeechIdle extends SpeechState {}

class SpeechLoading extends SpeechState {}

class SpeechListening extends SpeechState {}

class SpeechProcessing extends SpeechState {}

class SpeechSuccess extends SpeechState {
  final String command;

  const SpeechSuccess({required this.command});

  @override
  List<Object?> get props => [command];
}

class SpeechError extends SpeechState {
  final String message;

  const SpeechError({required this.message});

  @override
  List<Object?> get props => [message];
}