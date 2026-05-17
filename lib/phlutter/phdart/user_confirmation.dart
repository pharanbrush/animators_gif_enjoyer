enum UserConfirmationChoice {
  confirm,
  reject,
  cancel,
}

enum ConfirmedOperationResult {
  success,
  nothingChanged,
  userRejected,
  userCanceled,
  error,
}
