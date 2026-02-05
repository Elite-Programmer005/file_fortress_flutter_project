import 'package:file_fortress/core/constants/app_constants.dart';

String serializePattern(List<int> pattern) {
  return pattern.join('-');
}

bool isPatternValid(List<int> pattern) {
  return pattern.length >= AppConstants.patternMinLength;
}
