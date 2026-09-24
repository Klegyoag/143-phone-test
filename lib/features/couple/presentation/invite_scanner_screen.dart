import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/navigation/deep_link_target.dart';
import '../../../core/theme/app_colors.dart';

class InviteScannerScreen extends StatefulWidget {
  const InviteScannerScreen({super.key});
  @override State<InviteScannerScreen> createState()=>_InviteScannerScreenState();
}
class _InviteScannerScreenState extends State<InviteScannerScreen>{
  bool handled=false;
  void detect(BarcodeCapture capture){
    if(handled)return;
    final raw=capture.barcodes.map((b)=>b.rawValue).whereType<String>().firstOrNull;
    if(raw==null||raw.isEmpty)return;
    final uri=Uri.tryParse(raw);
    if(uri==null){_error();return;}
    final target=DeepLinkTarget.fromUri(uri);
    if(!target.location.startsWith('/invite/')){_error();return;}
    handled=true; context.go(target.location);
  }
  void _error(){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('That QR code is not a 143 partner invite.')));}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Scan partner invite')),
    body:Stack(children:[
      MobileScanner(onDetect:detect),
      Center(child:Container(width:250,height:250,decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),border:Border.all(color:Colors.white,width:3)))),
      Positioned(left:24,right:24,bottom:34,child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.ivory.withValues(alpha:.94),borderRadius:BorderRadius.circular(22)),child:const Text('Place your partner’s 143 invite QR inside the frame. Nothing is joined until you confirm the preview.',textAlign:TextAlign.center))),
    ]),
  );
}

extension _FirstOrNull<T> on Iterable<T>{T? get firstOrNull=>isEmpty?null:first;}
