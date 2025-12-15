import 'package:flutter_riverpod/legacy.dart';
import '../models/grammar_type.dart';

class GrammarUiState {
  final GrammarType? filter;
  final bool highlightRoot;
  final bool learningMode;

  const GrammarUiState({
    this.filter,
    this.highlightRoot = false,
    this.learningMode = false,
  });

  GrammarUiState copyWith({
    GrammarType? filter,
    bool? highlightRoot,
    bool? learningMode,
  }) {
    return GrammarUiState(
      filter: filter,
      highlightRoot: highlightRoot ?? this.highlightRoot,
      learningMode: learningMode ?? this.learningMode,
    );
  }
}

class GrammarUiNotifier extends StateNotifier<GrammarUiState> {
  GrammarUiNotifier() : super(const GrammarUiState());

  void setFilter(GrammarType? type) {
    state = state.copyWith(filter: type);
  }

  void toggleHighlightRoot() {
    state = state.copyWith(highlightRoot: !state.highlightRoot);
  }

  void toggleLearningMode() {
    state = state.copyWith(learningMode: !state.learningMode);
  }
}

final grammarUiProvider =
    StateNotifierProvider<GrammarUiNotifier, GrammarUiState>(
  (ref) => GrammarUiNotifier(),
);
