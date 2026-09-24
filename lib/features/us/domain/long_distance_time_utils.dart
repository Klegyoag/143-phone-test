class LongDistanceTimeUtils {
  const LongDistanceTimeUtils._();

  static int? utcOffsetMinutesFromIso(String iso) {
    final match = RegExp(r'([+-])(\d{2}):(\d{2})$').firstMatch(iso.trim());
    if (match == null) return null;
    final sign = match.group(1) == '-' ? -1 : 1;
    final hours = int.tryParse(match.group(2) ?? '');
    final minutes = int.tryParse(match.group(3) ?? '');
    if (hours == null || minutes == null) return null;
    return sign * (hours * 60 + minutes);
  }

  static String timezoneDifferenceLabel({required String partnerIso, required Duration localOffset}) {
    final partnerMinutes = utcOffsetMinutesFromIso(partnerIso);
    if (partnerMinutes == null) return 'Partner timezone';
    final difference = partnerMinutes - localOffset.inMinutes;
    if (difference == 0) return 'Same UTC offset as you';
    final absolute = difference.abs();
    final hours = absolute ~/ 60;
    final minutes = absolute % 60;
    final amount = [if (hours > 0) '${hours}h', if (minutes > 0) '${minutes}m'].join(' ');
    return 'Partner is $amount ${difference > 0 ? 'ahead' : 'behind'}';
  }

  static String countdown(DateTime now, DateTime? target) {
    if (target == null) return 'No date set';
    final difference = target.difference(now);
    if (difference.isNegative) return 'Started / passed';
    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    final minutes = difference.inMinutes.remainder(60);
    if (days > 0) return '${days}d ${hours}h';
    return '${hours}h ${minutes}m';
  }
}
