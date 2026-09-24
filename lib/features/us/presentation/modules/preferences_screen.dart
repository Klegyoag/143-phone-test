import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});
  @override ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}
class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  bool loading=true,saving=false; Map<String,dynamic> mine={},partner={},love={};
  final keys=['favorite_food','favorite_color','favorite_flower','favorite_movie','favorite_music','favorite_places','important_dates','gift_preferences','cheer_me_up'];
  final Map<String,TextEditingController> c={};
  final loveOptions=['words_of_affirmation','quality_time','acts_of_service','physical_touch','receiving_gifts'];
  String primary='quality_time',secondary='words_of_affirmation';
  @override void initState(){super.initState();for(final k in keys)c[k]=TextEditingController();_load();}
  @override void dispose(){for(final x in c.values)x.dispose();super.dispose();}
  Future<void> _load()async{setState(()=>loading=true);final r=ref.read(relationshipToolsRepositoryProvider);try{final a=await Future.wait([r.preferences(),r.partnerPreferences(),r.loveLanguage()]);mine=a[0];partner=a[1];love=a[2];for(final k in keys)c[k]!.text='${mine[k]??''}';primary='${love['primary']??primary}';secondary='${love['secondary']??secondary}';}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> _save()async{setState(()=>saving=true);final r=ref.read(relationshipToolsRepositoryProvider);try{await r.savePreferences({for(final k in keys)k:c[k]!.text.trim()});await r.saveLoveLanguage({'primary':primary,'secondary':secondary});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Preferences saved ♡')));}finally{if(mounted)setState(()=>saving=false);}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Love & Preferences')),body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.fromLTRB(20,8,20,120),children:[
    _hero(context),const SizedBox(height:18),Text('My love language',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:8),DropdownButtonFormField(value:primary,items:loveOptions.map((x)=>DropdownMenuItem(value:x,child:Text(_label(x)))).toList(),onChanged:(v)=>setState(()=>primary=v!),decoration:const InputDecoration(labelText:'Primary')),const SizedBox(height:10),DropdownButtonFormField(value:secondary,items:loveOptions.map((x)=>DropdownMenuItem(value:x,child:Text(_label(x)))).toList(),onChanged:(v)=>setState(()=>secondary=v!),decoration:const InputDecoration(labelText:'Secondary')),const SizedBox(height:20),
    Text('Little things about me',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:8),...keys.map((k)=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c[k],decoration:InputDecoration(labelText:_label(k),prefixIcon:Icon(_icon(k),color:AppColors.rose))))),
    FilledButton.icon(onPressed:saving?null:_save,icon:saving?const SizedBox.square(dimension:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.favorite),label:const Text('Save my preferences')),const SizedBox(height:22),
    Text('Partner preferences',style:Theme.of(context).textTheme.titleMedium),const Text('Shared only according to your partner’s privacy choices.',style:TextStyle(color:AppColors.muted)),const SizedBox(height:10),if(partner.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('Nothing shared yet ♡')))else ...partner.entries.where((e)=>e.value!=null&&'$e'.isNotEmpty).map((e)=>Card(child:ListTile(leading:Icon(_icon(e.key),color:AppColors.rose),title:Text(_label(e.key)),subtitle:Text('${e.value}'))))]));
  Widget _hero(BuildContext c)=>Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.blush,AppColors.peach]),borderRadius:BorderRadius.circular(28)),child:const Column(children:[Icon(Icons.favorite_rounded,color:AppColors.rose,size:38),SizedBox(height:8),Text('The little things matter',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),Text('Help your person love you in ways that feel like you.',textAlign:TextAlign.center,style:TextStyle(color:AppColors.muted))]));
  String _label(String s)=>s.replaceAll('_',' ').split(' ').map((e)=>e.isEmpty?e:'${e[0].toUpperCase()}${e.substring(1)}').join(' ');
  IconData _icon(String k)=>k.contains('food')?Icons.restaurant:k.contains('color')?Icons.palette:k.contains('flower')?Icons.local_florist:k.contains('movie')?Icons.movie:k.contains('music')?Icons.music_note:k.contains('place')?Icons.place:k.contains('date')?Icons.calendar_month:k.contains('gift')?Icons.card_giftcard:Icons.sentiment_satisfied_alt;
}
