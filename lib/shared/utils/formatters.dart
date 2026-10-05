String dateLabel(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return day + '/' + month + '/' + local.year.toString();
}

String durationLabel(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) {
    return hours.toString() + 'h ' +
        minutes.toString().padLeft(2, '0') +
        'm';
  }
  return minutes.toString() + 'm';
}
