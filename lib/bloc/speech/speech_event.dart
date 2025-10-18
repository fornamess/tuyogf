import 'package:equatable/equatable.dart';

abstract class SpeechEvent extends Equatable {
  const SpeechEvent();

  @override
  List<Object?> get props => [];
}

class SpeechInitialize extends SpeechEvent {}

class SpeechStartOneTimeListening extends SpeechEvent {}

class SpeechStopListening extends SpeechEvent {}

class SpeechRecognized extends SpeechEvent {
  final String text;
  final bool isFinal;

  const SpeechRecognized({
    required this.text,
    required this.isFinal,
  });

  @override
  List<Object?> get props => [text, isFinal];
}
