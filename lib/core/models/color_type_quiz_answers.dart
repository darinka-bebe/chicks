/// User selections from the color type onboarding quiz.
class ColorTypeQuizAnswers {
  const ColorTypeQuizAnswers({
    required this.eyeColorId,
    required this.hairColorId,
    required this.skinUndertoneId,
    required this.contrastLevelId,
    required this.skinDepthId,
  });

  final String eyeColorId;
  final String hairColorId;
  final String skinUndertoneId;
  final String contrastLevelId;
  final String skinDepthId;

  bool get isComplete =>
      eyeColorId.isNotEmpty &&
      hairColorId.isNotEmpty &&
      skinUndertoneId.isNotEmpty &&
      contrastLevelId.isNotEmpty &&
      skinDepthId.isNotEmpty;
}
