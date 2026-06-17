abstract class BugReportState {}

class BugReportInitial extends BugReportState {}

class BugReportLoading extends BugReportState {}

class BugReportSuccess extends BugReportState {}

class BugReportFailure extends BugReportState {
  final String message;
  BugReportFailure(this.message);
}
