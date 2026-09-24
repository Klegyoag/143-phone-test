import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../location/data/location_repository.dart';
import '../../../location/domain/arrival_detector.dart';
import '../../domain/long_distance_time_utils.dart';
import 'journeys_screen.dart';
import 'scheduled_love_screen.dart';

class LongDistanceScreen extends ConsumerStatefulWidget {
  const LongDistanceScreen({super.key});

  @override
  ConsumerState<LongDistanceScreen> createState() => _LongDistanceState();
}

class _LongDistanceState extends ConsumerState<LongDistanceScreen> {
  bool loading = true;
  Map<String, dynamic> settings = {};
  Map<String, dynamic> partnerTime = {};
  Map<String, dynamic> distance = {};
  dynamic nextMeet;
  List<Map<String, dynamic>> trips = [];
  SharedLocation? activeShare;
  ArrivalDestination? _arrivalDestination;
  Timer? _locationTimer;
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      final repository = ref.read(coupleLifeRepositoryProvider);
      final result = await Future.wait<dynamic>([
        repository.longDistance(),
        repository.partnerTime(),
        repository.distance(),
        repository.nextMeet(),
        repository.travelItineraries(),
      ]);
      settings = result[0];
      partnerTime = result[1];
      distance = result[2];
      nextMeet = result[3];
      trips = result[4];
    } catch (e) {
      _toast('$e');
    }
    if (mounted) setState(() => loading = false);
  }

  void _toast(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setNextMeet() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      await ref.read(coupleLifeRepositoryProvider).setNextMeet(date);
      await _load();
    }
  }

  Future<void> _trip([Map<String, dynamic>? existing]) async {
    final oldData = existing?['data'] is Map ? (existing!['data'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final title = TextEditingController(text: '${existing?['title'] ?? ''}');
    final flight = TextEditingController(text: '${oldData['flight'] ?? ''}');
    final destination = TextEditingController(text: '${oldData['destination'] ?? ''}');
    DateTime date = DateTime.tryParse('${existing?['starts_at'] ?? ''}')?.toLocal() ?? DateTime.now().add(const Duration(days: 7));

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Share a trip' : 'Edit trip'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Trip title')),
              TextField(controller: destination, decoration: const InputDecoration(labelText: 'Destination')),
              TextField(controller: flight, decoration: const InputDecoration(labelText: 'Flight / transport')),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(MaterialLocalizations.of(dialogContext).formatFullDate(date)),
                subtitle: Text(TimeOfDay.fromDateTime(date).format(dialogContext)),
                leading: const Icon(Icons.flight, color: AppColors.rose),
                onTap: () async {
                  final selectedDate = await showDatePicker(context: dialogContext, initialDate: date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650)));
                  if (selectedDate == null) return;
                  final selectedTime = await showTimePicker(context: dialogContext, initialTime: TimeOfDay.fromDateTime(date));
                  if (selectedTime != null) setDialogState(() => date = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute));
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(existing == null ? 'Share' : 'Save')),
          ],
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;

    final repository = ref.read(coupleLifeRepositoryProvider);
    if (existing == null) {
      await repository.createTravelItinerary(title: title.text.trim(), startsAt: date, flight: flight.text, destination: destination.text);
    } else {
      await repository.updateTravelItinerary('${existing['id']}', {
        'title': title.text.trim(),
        'starts_at': date.toUtc().toIso8601String(),
        'data': {
          if (flight.text.trim().isNotEmpty) 'flight': flight.text.trim(),
          if (destination.text.trim().isNotEmpty) 'destination': destination.text.trim(),
        },
      });
    }
    await _load();
  }

  Future<void> _deleteTrip(Map<String, dynamic> trip) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Remove this trip?'), content: const Text('This removes the shared itinerary from 143. It does not cancel any airline or transport booking.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove'))])) ?? false;
    if (!ok) return;
    await ref.read(coupleLifeRepositoryProvider).deleteTravelItinerary('${trip['id']}');
    await _load();
  }

  Future<ArrivalDestination?> _chooseArrivalDestination() async {
    final label = TextEditingController();
    final latitude = TextEditingController();
    final longitude = TextEditingController();
    final result = await showDialog<ArrivalDestination>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arrival destination'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('143 can stop an until-arrival share while the app is active when you enter the chosen radius. Background geofencing still requires native device QA.'),
            const SizedBox(height: 12),
            TextField(controller: label, decoration: const InputDecoration(labelText: 'Place name (optional)')),
            TextField(controller: latitude, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Destination latitude')),
            TextField(controller: longitude, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Destination longitude')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final lat = double.tryParse(latitude.text.trim());
              final lng = double.tryParse(longitude.text.trim());
              if (lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) return;
              Navigator.pop(dialogContext, ArrivalDestination(latitude: lat, longitude: lng, label: label.text.trim(), radiusMeters: 120));
            },
            child: const Text('Use destination'),
          ),
        ],
      ),
    );
    latitude.dispose(); longitude.dispose(); label.dispose();
    return result;
  }

  Future<void> _startLocationShare(int? minutes) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _toast('Location permission is required only while you choose to share.');
      return;
    }
    final destination = minutes == null ? await _chooseArrivalDestination() : null;
    if (minutes == null && destination == null) return;
    final position = await Geolocator.getCurrentPosition();
    final expires = minutes == null ? null : DateTime.now().add(Duration(minutes: minutes));
    final share = await ref.read(locationRepositoryProvider).create(latitude: position.latitude, longitude: position.longitude, mode: minutes == null ? 'until_arrival' : 'live', expiresAt: expires, destination: destination?.toJson());
    if (!mounted) return;
    setState(() { activeShare = share; _arrivalDestination = destination; });
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted || activeShare == null) {
        timer.cancel();
        return;
      }
      if (activeShare!.expiresAt != null && DateTime.now().isAfter(activeShare!.expiresAt!)) {
        await _stopLocationShare();
        return;
      }
      try {
        final current = await Geolocator.getCurrentPosition();
        await ref.read(locationRepositoryProvider).update(activeShare!.id, current.latitude, current.longitude);
        final destination = _arrivalDestination;
        if (activeShare?.mode == 'until_arrival' && destination != null && ArrivalDetector.hasArrived(latitude: current.latitude, longitude: current.longitude, destination: destination)) {
          await _stopLocationShare(arrived: true);
          return;
        }
      } catch (_) {}
    });
    _toast(minutes == null ? 'Until-arrival sharing started. Arrival detection works while 143 is active; background geofencing still needs device QA.' : 'Live location sharing started for $minutes minutes.');
  }

  Future<void> _stopLocationShare({bool arrived = false}) async {
    final share = activeShare;
    _locationTimer?.cancel();
    if (share != null) {
      try {
        await ref.read(locationRepositoryProvider).stop(share.id);
      } catch (_) {}
    }
    if (mounted) { setState(() { activeShare = null; _arrivalDestination = null; }); if (arrived) _toast('You arrived ♡ Location sharing stopped.'); }
  }

  Future<void> _locationSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Temporary live location', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Only starts after you choose a duration. Updates run while 143 is active. Until-arrival can detect the chosen destination while 143 is active. Reliable background geofencing still requires native device QA.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            if (activeShare != null)
              ListTile(leading: const Icon(Icons.stop_circle_outlined, color: AppColors.rose), title: const Text('Stop sharing now'), subtitle: Text('Share ${activeShare!.id}'), onTap: () { Navigator.pop(context); _stopLocationShare(); })
            else ...[
              ListTile(leading: const Icon(Icons.timer_outlined), title: const Text('15 minutes'), onTap: () { Navigator.pop(context); _startLocationShare(15); }),
              ListTile(leading: const Icon(Icons.schedule), title: const Text('1 hour'), onTap: () { Navigator.pop(context); _startLocationShare(60); }),
              ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Until arrival'), subtitle: const Text('Choose a destination. 143 can stop sharing on arrival while the app is active; Stop Sharing remains available at all times.'), onTap: () { Navigator.pop(context); _startLocationShare(null); }),
            ],
          ]),
        ),
      ),
    );
  }

  Future<void> _virtualDate() async {
    final title = TextEditingController(text: 'Virtual date');
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Virtual Date Mode'), content: TextField(controller: title, decoration: const InputDecoration(labelText: 'Date name')), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create'))]));
    if (ok == true) {
      final created = await ref.read(coupleLifeRepositoryProvider).createVirtualDate(title: title.text.trim());
      _toast('Virtual date ready • ${created['id'] ?? 'created'}');
    }
  }

  Future<void> _openLongDistanceChallenge() async {
    try {
      final repository = ref.read(advancedRepositoryProvider);
      final catalog = await repository.journeys();
      Map<String, dynamic>? journey;
      for (final item in catalog) {
        final haystack = '${item['title'] ?? ''} ${item['slug'] ?? ''} ${item['key'] ?? ''}'.toLowerCase();
        if (haystack.contains('long-distance') || haystack.contains('long distance')) {
          journey = item;
          break;
        }
      }
      if (journey == null) {
        _toast('The backend did not return the Long-Distance journey catalog item.');
        return;
      }
      final session = await repository.startJourney('${journey['id']}');
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => JourneyDetailScreen(journey: journey!, session: session)));
    } catch (e) {
      _toast('Could not start the Long-Distance challenge: $e');
    }
  }

  String _timezoneDifferenceText() => LongDistanceTimeUtils.timezoneDifferenceLabel(
        partnerIso: '${partnerTime['local_time'] ?? ''}',
        localOffset: DateTime.now().timeZoneOffset,
      );

  String _countdown(DateTime? target) => LongDistanceTimeUtils.countdown(_now, target);

  DateTime? _tripStart(Map<String, dynamic> trip) => DateTime.tryParse('${trip['starts_at'] ?? ''}')?.toLocal();

  @override
  Widget build(BuildContext context) {
    final data = settings['data'] is Map ? (settings['data'] as Map).cast<String, dynamic>() : settings;
    final enabled = data['enabled'] == true;
    final partnerLocal = DateTime.tryParse('${partnerTime['local_time'] ?? ''}')?.toLocal();
    final nextMeetDate = nextMeet is String ? DateTime.tryParse('$nextMeet')?.toLocal() : (nextMeet is Map ? DateTime.tryParse('${nextMeet['next_meet'] ?? ''}')?.toLocal() : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Long-Distance Mode')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(28)),
                    child: Column(children: [
                      const Icon(Icons.public_rounded, color: AppColors.rose, size: 42),
                      const SizedBox(height: 8),
                      const Text('Far apart, still in the same little world ♡', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
                      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Long-Distance Mode'), value: enabled, onChanged: (value) async { await ref.read(coupleLifeRepositoryProvider).setLongDistanceEnabled(value); await _load(); }),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    _stat(Icons.schedule, 'Partner time', partnerLocal == null ? '${partnerTime['local_time'] ?? '—'}' : TimeOfDay.fromDateTime(partnerLocal).format(context)),
                    const SizedBox(width: 10),
                    _stat(Icons.straighten, 'Distance', '${distance['distance_km'] ?? '—'} km'),
                  ]),
                  const SizedBox(height: 10),
                  Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)), child: Row(children: [const Icon(Icons.language_outlined, color: AppColors.rose), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${partnerTime['timezone'] ?? 'Partner timezone'}', style: const TextStyle(fontWeight: FontWeight.w800)), Text(_timezoneDifferenceText(), style: const TextStyle(color: AppColors.muted, fontSize: 12))]))])),
                  const SizedBox(height: 12),
                  _tile(Icons.favorite_border, 'Next time together', nextMeetDate == null ? 'Tap to set countdown' : '${MaterialLocalizations.of(context).formatMediumDate(nextMeetDate)} • ${_countdown(nextMeetDate)}', _setNextMeet),
                  _tile(Icons.wb_sunny_outlined, 'Good Morning', 'Schedule from Scheduled Love using your partner’s local time', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduledLoveScreen()))),
                  _tile(Icons.nightlight_outlined, 'Good Night', 'Schedule a gentle message across time zones', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduledLoveScreen()))),
                  _tile(Icons.location_on_outlined, 'Temporary location', activeShare == null ? '15 min • 1 hour • until arrival' : 'Sharing now • tap to stop', _locationSheet),
                  _tile(Icons.emoji_events_outlined, 'Long-Distance Challenge', 'Open the guided Long-Distance journey', _openLongDistanceChallenge),
                  _tile(Icons.video_call_outlined, 'Virtual Date Mode', 'Create a shared virtual date session', _virtualDate),
                  const SizedBox(height: 18),
                  Row(children: [const Expanded(child: Text('Travel itineraries', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), TextButton.icon(onPressed: () => _trip(), icon: const Icon(Icons.add), label: const Text('Add'))]),
                  if (trips.isEmpty)
                    const Text('No trips shared yet.', style: TextStyle(color: AppColors.muted))
                  else
                    ...trips.map((trip) {
                      final tripData = trip['data'] is Map ? trip['data'] as Map : const {};
                      final start = _tripStart(trip);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: ListTile(
                            leading: const Icon(Icons.flight_takeoff, color: AppColors.rose),
                            title: Text('${trip['title'] ?? 'Our trip'}'),
                            subtitle: Text('${tripData['destination'] ?? ''}${'${tripData['flight'] ?? ''}'.isEmpty ? '' : ' • ${tripData['flight']}'}\n${start == null ? trip['starts_at'] ?? '' : MaterialLocalizations.of(context).formatFullDate(start)}\nFlight countdown: ${_countdown(start)}'),
                            isThreeLine: false,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) { if (value == 'edit') _trip(trip); if (value == 'delete') _deleteTrip(trip); },
                              itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit itinerary')), PopupMenuItem(value: 'delete', child: Text('Remove itinerary'))],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  const Card(child: ListTile(leading: Icon(Icons.location_disabled_outlined, color: AppColors.rose), title: Text('Arrival detection boundary'), subtitle: Text('The backend accepts destination metadata for until-arrival sessions. 143 now performs foreground arrival-radius detection and stops the share when you arrive. Reliable background geofencing and OS-level arrival delivery remain PARTIAL until physical-device QA is complete.'))),
                ],
              ),
            ),
    );
  }

  Widget _stat(IconData icon, String label, String value) => Expanded(
        child: Semantics(
          label: '$label, $value',
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
            child: Column(children: [Icon(icon, color: AppColors.rose), const SizedBox(height: 7), Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted))]),
          ),
        ),
      );

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Semantics(
          button: true,
          label: '$title. $subtitle',
          child: ListTile(
            onTap: onTap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.divider)),
            tileColor: Colors.white,
            leading: Icon(icon, color: AppColors.rose),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      );
}
