import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/journal_card.dart';

class CoupleSetupScreen extends ConsumerStatefulWidget {
  const CoupleSetupScreen({super.key});
  @override ConsumerState<CoupleSetupScreen> createState() => _CoupleSetupScreenState();
}
class _CoupleSetupScreenState extends ConsumerState<CoupleSetupScreen> {
  bool loading=false;
  Future<void> _create() async {
    final c=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(x)=>AlertDialog(title:const Text('Name your little world'),content:TextField(controller:c,decoration:const InputDecoration(hintText:'Optional couple name')),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('Create'))]));
    if(ok!=true)return; setState(()=>loading=true);
    try { await ref.read(coupleRepositoryProvider).create(name:c.text.trim().isEmpty?null:c.text.trim()); final invite=await ref.read(coupleRepositoryProvider).createInvite(); if(!mounted)return; await showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>_InviteSheet(invite:invite)); if(mounted) context.go('/app'); }
    on ApiException catch(e){if(mounted)_error(e.message);} finally {if(mounted)setState(()=>loading=false);}
  }
  Future<void> _join() async {
    final c=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(x)=>AlertDialog(title:const Text('Join your partner'),content:TextField(controller:c,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'Invite code or token')),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('Continue'))]));
    if(ok!=true||c.text.trim().isEmpty)return; setState(()=>loading=true);
    try { final v=c.text.trim(); if(v.length<=12) await ref.read(coupleRepositoryProvider).joinCode(v); else {final preview=await ref.read(coupleRepositoryProvider).preview(v); if(!mounted)return; final space=(preview['couple_space'] as Map?)?.cast<String,dynamic>(); final yes=await showDialog<bool>(context:context,builder:(x)=>AlertDialog(title:const Text('Join this couple space?'),content:Text(space?['name']?.toString() ?? 'Your partner invited you to their private space.'),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('Not now')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('Join'))])); if(yes==true) await ref.read(coupleRepositoryProvider).acceptToken(v);} if(mounted)context.go('/app'); }
    on ApiException catch(e){if(mounted)_error(e.message);} finally {if(mounted)setState(()=>loading=false);}
  }
  void _error(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const SizedBox(height:22),Text('Create your space',style:Theme.of(context).textTheme.displaySmall),const SizedBox(height:10),Text('One space. Two people. Your little world.',style:Theme.of(context).textTheme.bodyLarge?.copyWith(color:AppColors.muted)),const SizedBox(height:30),if(loading) const LinearProgressIndicator(),JournalCard(color:AppColors.blush,onTap:loading?null:_create,child:const ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:Colors.white,child:Icon(Icons.favorite_rounded,color:AppColors.rose)),title:Text('Invite my partner',style:TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('Create our private couple space'),trailing:Icon(Icons.arrow_forward_ios_rounded,size:16))),const SizedBox(height:14),JournalCard(onTap:loading?null:_join,child:const ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:AppColors.peach,child:Icon(Icons.link_rounded,color:AppColors.wine)),title:Text('I have an invite',style:TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('Join my partner’s space'),trailing:Icon(Icons.arrow_forward_ios_rounded,size:16))),const SizedBox(height:14),JournalCard(onTap:loading?null:()=>context.go('/invite-scan'),child:const ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:AppColors.blush,child:Icon(Icons.qr_code_scanner_rounded,color:AppColors.rose)),title:Text('Scan invite QR',style:TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('Open the camera and preview the invite first'),trailing:Icon(Icons.arrow_forward_ios_rounded,size:16)))]))));
}

class _InviteSheet extends StatelessWidget {
 const _InviteSheet({required this.invite}); final Map<String,dynamic> invite;
 @override Widget build(BuildContext context){final token='${invite['token']??''}',code='${invite['join_code']??''}';return SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(24,18,24,28),child:Column(mainAxisSize:MainAxisSize.min,children:[Container(width:42,height:4,decoration:BoxDecoration(color:AppColors.divider,borderRadius:BorderRadius.circular(4))),const SizedBox(height:20),Text('Invite your person ♡',style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:8),const Text('They can scan this QR or enter the code.'),const SizedBox(height:22),Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24)),child:QrImageView(data:'143://invite/$token',size:190)),const SizedBox(height:18),Text(code,style:Theme.of(context).textTheme.headlineMedium?.copyWith(color:AppColors.rose,letterSpacing:3,fontWeight:FontWeight.w700)),const SizedBox(height:6),Text('Expires ${invite['expires_at']??''}',style:const TextStyle(color:AppColors.muted,fontSize:12)),const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Done')))])));}
}
