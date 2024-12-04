

import '../domain/truth_or_dare.dart';
import '../shared/theme/images.dart';

extension ViewRepresentation on TruthOrDare {
  String get nameImage {
    switch(this) {
      case TruthOrDare.truth:
        return Images.truth;
      case TruthOrDare.dare:
        return Images.dare;
      default:
        throw StateError("Unhandled case");
    }
  }

  String get image {
    switch(this) {
      case TruthOrDare.truth:
        return Images.questionMark;
      case TruthOrDare.dare:
        return Images.exclamationMark;
      default:
        throw StateError("Unhandled case");
    }
  }
}