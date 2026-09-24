import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';

class InviteFlowScreen extends ConsumerStatefulWidget {
  const InviteFlowScreen({super.key, required this.token});
  final String token;
  @override ConsumerState<InviteFlowScreen> createState()=>_InviteFlowScreenState();
}
class _InviteFlowScreenState extends ConsumerState<InviteFlowScreen> {
  Map<String,dynamic>? preview; String? error; bool loading=true, joining=false;
  @override void initState(){super.initState();Future.microtask(load);}
  Future<void> load() async {
    try { final p=await ref.read(coupleRepositoryProvider).preview(widget.token); if(mounted)setState((){preview=p;loading=false;}); }
    on ApiException catch(e){if(mounted)setState((){error=e.message;loading=false;});}
  }
  Future<void> join() async {
    setState(()=>joining=true);
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString('pending_invite_token', widget.token);
    try {
      await ref.read(coupleRepositoryProvider).acceptToken(widget.token);
      await prefs.remove('pending_invite_token');
      if(mounted) context.go('/app');
    } on ApiException catch(e) {
      if(e.statusCode==401){if(mounted)context.go('/login');return;}
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    } finally { if(mounted)setState(()=>joining=false); }
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Partner invite')),
    body:SafeArea(child:Padding(padding:const EdgeInsets.all(24),child:loading?const Center(child:CircularProgressIndicator()):error!=null?Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.link_off_rounded,size:54,color:AppColors.rose),const SizedBox(height:16),Text('This invite is unavailable',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:8),Text(error!,textAlign:TextAlign.center),const SizedBox(height:20),OutlinedButton(onPressed:load,child:const Text('Try again'))]):Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Spacer(), const Center(child:Icon(Icons.favorite_rounded,size:64,color:AppColors.rose)), const SizedBox(height:24),
      Text('You’ve been invited ♡',style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:12),
      Text('${preview?['couple_space'] is Map ? (preview!['couple_space'] as Map)['name'] ?? 'A private couple space' : 'A private couple space'}',style:Theme.of(context).textTheme.titleLarge),
      const SizedBox(height:8),const Text('Preview the space before joining. A 143 couple space can contain at most two people.'),
      if(preview?['expires_at']!=null)...[const SizedBox(height:16),Text('Invite expires: ${preview!['expires_at']}',style:const TextStyle(color:AppColors.muted))],
      const Spacer(),SizedBox(width:double.infinity,child:FilledButton(onPressed:joining?null:join,child:Text(joining?'Joining…':'Join this space'))),
      const SizedBox(height:10),Center(child:TextButton(onPressed:()=>context.go('/welcome'),child:const Text('Not now'))),
    ]))),
  );
}
