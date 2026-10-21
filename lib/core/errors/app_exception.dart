/// Custom exceptions for Rabit_doku.
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class StageNotFoundException extends AppException {
  StageNotFoundException(int stageId)
      : super('Stage $stageId not found.');
}

class StageLockedException extends AppException {
  StageLockedException(int stageId)
      : super('Stage $stageId is locked. Complete previous stage first.');
}

class InvalidPlacementException extends AppException {
  InvalidPlacementException(String reason)
      : super('Invalid placement: $reason.');
}

class InsufficientHeartsException extends AppException {
  InsufficientHeartsException()
      : super('Not enough hearts. Use a booster or watch an ad.');
}

class InsufficientBoostersException extends AppException {
  InsufficientBoostersException(String boosterType)
      : super('No $boosterType boosters available. Buy or watch an ad.');
}

class PurchaseFailedException extends AppException {
  PurchaseFailedException(String reason)
      : super('Purchase failed: $reason.');
}

class AdNotLoadedException extends AppException {
  AdNotLoadedException(String adType)
      : super('$adType ad is not loaded yet.');
}
