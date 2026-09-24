import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/providers.dart';
import '../../../core/realtime/realtime_events.dart';
import '../../../core/theme/app_colors.dart';

/// Production call lifecycle wired to the current Laravel signaling contract.
///
/// Backend responsibilities:
/// - create/accept/decline/end call lifecycle
/// - authenticated ICE server discovery
/// - authenticated SDP offer/answer/ICE candidate publication
/// - private couple-channel signaling events
///
/// Flutter responsibilities:
/// - microphone/camera capture
/// - RTCPeerConnection negotiation
/// - remote/local rendering and controls
class CallSessionScreen extends ConsumerStatefulWidget {
  const CallSessionScreen({super.key, required this.callId, required this.type, this.incoming = false});
  final String callId;
  final String type;
  final bool incoming;

  @override
  ConsumerState<CallSessionScreen> createState() => _CallSessionScreenState();
}

class _CallSessionScreenState extends ConsumerState<CallSessionScreen> {
  StreamSubscription? realtimeSub;
  Timer? fallbackPoll;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peer;
  String status = 'ringing';
  String myUserId = '';
  bool muted = false;
  bool speaker = false;
  bool camera = true;
  bool mediaStarting = false;
  bool peerConnected = false;
  bool offerSent = false;
  bool answerSent = false;
  String? mediaError;
  Map<String, dynamic>? pendingOffer;
  final List<Map<String, dynamic>> pendingIce = [];
  final Set<String> appliedIce = <String>{};

  bool get isVideo => widget.type == 'video';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([_localRenderer.initialize(), _remoteRenderer.initialize()]);
    try {
      final me = await ref.read(profileRepositoryProvider).me();
      myUserId = '${me['id'] ?? ''}';
    } catch (_) {}
    await _load();
    realtimeSub = ref.read(realtimeCoordinatorProvider).events.listen(_handleRealtime);
    if (!widget.incoming) {
      await _startLocalMedia();
      await _ensurePeer();
      await _ensureOffer();
    }
    fallbackPoll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (status != 'ended' && status != 'declined') _load();
    });
  }

  Future<void> _handleRealtime(dynamic event) async {
    if ('${event.payload['call_id'] ?? ''}' != widget.callId) return;
    if (!mounted) return;
    if (event.name == RealtimeEvents.callAccepted) {
      setState(() => status = 'active');
      await _startLocalMedia();
      await _ensurePeer();
      if (!widget.incoming) await _ensureOffer();
    } else if (event.name == RealtimeEvents.callDeclined) {
      setState(() => status = 'declined');
    } else if (event.name == RealtimeEvents.callEnded) {
      setState(() => status = 'ended');
    } else if (event.name == RealtimeEvents.callOffer) {
      if ('${event.payload['from_user_id'] ?? ''}' == myUserId) return;
      pendingOffer = Map<String, dynamic>.from(event.payload);
      if (status == 'active') await _applyOffer(pendingOffer!);
    } else if (event.name == RealtimeEvents.callAnswer) {
      if ('${event.payload['from_user_id'] ?? ''}' == myUserId) return;
      await _applyAnswer(Map<String, dynamic>.from(event.payload));
    } else if (event.name == RealtimeEvents.callIceCandidate) {
      if ('${event.payload['from_user_id'] ?? ''}' == myUserId) return;
      await _applyOrQueueIce(Map<String, dynamic>.from(event.payload));
    }
  }

  Future<void> _load() async {
    try {
      final call = await ref.read(advancedRepositoryProvider).call(widget.callId);
      if (mounted) setState(() => status = '${call['status'] ?? status}');
      final data = call['data'];
      final signaling = data is Map ? data['signaling'] : null;
      if (signaling is Map) {
        final offer = signaling['offer'];
        final answer = signaling['answer'];
        final ice = signaling['ice_candidates'];
        if (offer is Map && '${offer['from_user_id'] ?? ''}' != myUserId) {
          pendingOffer = offer.cast<String, dynamic>();
          if (status == 'active') await _applyOffer(pendingOffer!);
        }
        if (answer is Map && '${answer['from_user_id'] ?? ''}' != myUserId) {
          await _applyAnswer(answer.cast<String, dynamic>());
        }
        if (ice is List) {
          for (final item in ice.whereType<Map>()) {
            final candidate = item.cast<String, dynamic>();
            if ('${candidate['from_user_id'] ?? ''}' != myUserId) await _applyOrQueueIce(candidate);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _startLocalMedia() async {
    if (_localStream != null || mediaStarting || status == 'ended' || status == 'declined') return;
    setState(() {
      mediaStarting = true;
      mediaError = null;
    });
    try {
      final permissionService = ref.read(nativePermissionServiceProvider);
      final mic = await permissionService.requestMicrophone();
      if (!mic.isGranted) throw StateError('Microphone permission is required for calls.');
      if (isVideo) {
        final cam = await permissionService.requestCamera();
        if (!cam.isGranted) throw StateError('Camera permission is required for video calls.');
      }
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      });
      _localStream = stream;
      _localRenderer.srcObject = stream;
      for (final track in stream.getAudioTracks()) {
        track.enabled = !muted;
      }
      for (final track in stream.getVideoTracks()) {
        track.enabled = camera;
      }
      await Helper.setSpeakerphoneOn(speaker);
      await _ensurePeer();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => mediaError = '$e'.replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => mediaStarting = false);
    }
  }

  Future<void> _ensurePeer() async {
    if (_peer != null || _localStream == null) return;
    final servers = await ref.read(advancedRepositoryProvider).iceServers();
    final peer = await createPeerConnection({'iceServers': servers}, {'mandatory': {}, 'optional': []});
    for (final track in _localStream!.getTracks()) {
      await peer.addTrack(track, _localStream!);
    }
    peer.onIceCandidate = (candidate) async {
      final raw = candidate.candidate;
      if (raw == null || raw.isEmpty) return;
      try {
        await ref.read(advancedRepositoryProvider).publishIceCandidate(
              widget.callId,
              candidate: raw,
              sdpMid: candidate.sdpMid,
              sdpMLineIndex: candidate.sdpMLineIndex,
            );
      } catch (_) {}
    };
    peer.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        if (mounted) setState(() {});
      }
    };
    peer.onConnectionState = (state) {
      if (!mounted) return;
      setState(() => peerConnected = state == RTCPeerConnectionState.RTCPeerConnectionStateConnected);
    };
    _peer = peer;
  }

  Future<void> _ensureOffer() async {
    if (widget.incoming || offerSent || _peer == null || _localStream == null) return;
    final offer = await _peer!.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': isVideo});
    await _peer!.setLocalDescription(offer);
    await ref.read(advancedRepositoryProvider).publishCallOffer(widget.callId, sdp: offer.sdp ?? '');
    offerSent = true;
  }

  Future<void> _applyOffer(Map<String, dynamic> signal) async {
    if (!widget.incoming || status != 'active') return;
    await _startLocalMedia();
    await _ensurePeer();
    if (_peer == null) return;
    final sdp = '${signal['sdp'] ?? ''}';
    if (sdp.isEmpty) return;
    final remote = await _peer!.getRemoteDescription();
    if (remote?.sdp != sdp) await _peer!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    await _flushIce();
    if (!answerSent) {
      final answer = await _peer!.createAnswer({'offerToReceiveAudio': true, 'offerToReceiveVideo': isVideo});
      await _peer!.setLocalDescription(answer);
      await ref.read(advancedRepositoryProvider).publishCallAnswer(widget.callId, sdp: answer.sdp ?? '');
      answerSent = true;
    }
  }

  Future<void> _applyAnswer(Map<String, dynamic> signal) async {
    if (widget.incoming) return;
    await _ensurePeer();
    if (_peer == null) return;
    final sdp = '${signal['sdp'] ?? ''}';
    if (sdp.isEmpty) return;
    final remote = await _peer!.getRemoteDescription();
    if (remote?.sdp != sdp) await _peer!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    await _flushIce();
  }

  Future<void> _applyOrQueueIce(Map<String, dynamic> signal) async {
    final raw = '${signal['candidate'] ?? ''}';
    if (raw.isEmpty) return;
    final key = '$raw|${signal['sdp_mid']}|${signal['sdp_mline_index']}';
    if (appliedIce.contains(key)) return;
    await _ensurePeer();
    final remote = await _peer?.getRemoteDescription();
    if (_peer == null || remote == null) {
      pendingIce.add(signal);
      return;
    }
    await _peer!.addCandidate(RTCIceCandidate(raw, signal['sdp_mid']?.toString(), signal['sdp_mline_index'] is int ? signal['sdp_mline_index'] as int : int.tryParse('${signal['sdp_mline_index'] ?? ''}')));
    appliedIce.add(key);
  }

  Future<void> _flushIce() async {
    final copy = List<Map<String, dynamic>>.from(pendingIce);
    pendingIce.clear();
    for (final item in copy) {
      await _applyOrQueueIce(item);
    }
  }

  @override
  void dispose() {
    realtimeSub?.cancel();
    fallbackPoll?.cancel();
    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      stream.dispose();
    }
    _peer?.close();
    _peer?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ended = status == 'ended' || status == 'declined';
    return Scaffold(
      backgroundColor: const Color(0xFF3B2530),
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, title: Text(isVideo ? 'Video call' : 'Audio call')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (isVideo && (_localStream != null || _remoteRenderer.srcObject != null))
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_remoteRenderer.srcObject != null)
                          RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                        else
                          const ColoredBox(color: Color(0xFF2A1B22), child: Center(child: Icon(Icons.favorite_rounded, color: AppColors.rose, size: 48))),
                        if (_localStream != null)
                          Positioned(
                            right: 12,
                            top: 12,
                            width: 112,
                            height: 160,
                            child: ClipRRect(borderRadius: BorderRadius.circular(18), child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
                          ),
                      ],
                    ),
                  ),
                )
              else ...[
                const Spacer(),
                const CircleAvatar(radius: 58, backgroundColor: AppColors.blushStrong, child: Icon(Icons.favorite_rounded, color: AppColors.rose, size: 46)),
                const SizedBox(height: 22),
              ],
              Text('Your person ♡', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_statusText(), style: const TextStyle(color: Colors.white70)),
              if (mediaStarting) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
              if (mediaError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: .18), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(mediaError!, style: const TextStyle(color: Colors.white))), TextButton(onPressed: _startLocalMedia, child: const Text('Retry'))]),
                ),
              ],
              const SizedBox(height: 12),
              Text(peerConnected ? 'Secure WebRTC peer connected' : 'Encrypted WebRTC media · authenticated 143 signaling', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const Spacer(),
              if (!ended)
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _round(muted ? Icons.mic_off_rounded : Icons.mic_rounded, muted, _toggleMute, 'Microphone'),
                  _round(speaker ? Icons.volume_up_rounded : Icons.hearing_rounded, speaker, _toggleSpeaker, 'Speaker'),
                  if (isVideo) _round(camera ? Icons.videocam_rounded : Icons.videocam_off_rounded, !camera, _toggleCamera, 'Camera'),
                  if (isVideo) _round(Icons.cameraswitch_rounded, false, _switchCamera, 'Switch camera'),
                ]),
              const SizedBox(height: 26),
              if (widget.incoming && status == 'ringing')
                Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: _decline, icon: const Icon(Icons.call_end_rounded), label: const Text('Decline'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton.icon(onPressed: _accept, icon: const Icon(Icons.call_rounded), label: const Text('Accept'))),
                ])
              else if (!ended)
                FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(180, 54)), onPressed: _end, icon: const Icon(Icons.call_end_rounded), label: const Text('End call'))
              else
                FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _round(IconData icon, bool active, VoidCallback tap, String label) => Semantics(
        button: true,
        label: label,
        child: Tooltip(message: label, child: InkWell(onTap: tap, customBorder: const CircleBorder(), child: CircleAvatar(radius: 27, backgroundColor: active ? AppColors.rose : Colors.white.withValues(alpha: .14), child: Icon(icon, color: Colors.white)))),
      );

  String _statusText() => switch (status) {
        'active' => peerConnected ? 'Connected' : 'Connecting securely…',
        'declined' => 'Call declined',
        'ended' => 'Call ended',
        _ => widget.incoming ? 'Incoming ${widget.type} call…' : 'Calling…',
      };

  void _toggleMute() {
    muted = !muted;
    for (final track in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) track.enabled = !muted;
    setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    speaker = !speaker;
    await Helper.setSpeakerphoneOn(speaker);
    if (mounted) setState(() {});
  }

  void _toggleCamera() {
    camera = !camera;
    for (final track in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) track.enabled = camera;
    setState(() {});
  }

  Future<void> _switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? <MediaStreamTrack>[];
    if (tracks.isNotEmpty) await Helper.switchCamera(tracks.first);
  }

  Future<void> _accept() async {
    await ref.read(advancedRepositoryProvider).acceptCall(widget.callId);
    if (mounted) setState(() => status = 'active');
    await _startLocalMedia();
    await _ensurePeer();
    await _load();
    if (pendingOffer != null) await _applyOffer(pendingOffer!);
  }

  Future<void> _decline() async {
    await ref.read(advancedRepositoryProvider).declineCall(widget.callId);
    if (mounted) setState(() => status = 'declined');
  }

  Future<void> _end() async {
    try {
      await ref.read(advancedRepositoryProvider).endCall(widget.callId);
    } finally {
      if (mounted) setState(() => status = 'ended');
    }
  }
}
