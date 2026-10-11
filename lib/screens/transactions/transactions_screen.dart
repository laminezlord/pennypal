import 'package:flutter/material.dart';
import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';

class TransactionsScreen extends StatefulWidget { const TransactionsScreen({super.key}); @override State<TransactionsScreen> createState() => _TransactionsScreenState(); }
class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> data = []; bool loading = true; String type = 'ALL'; String category = 'ALL'; String search = '';
  final searchCtrl = TextEditingController();
  @override void initState(){super.initState(); load();}
  @override void dispose(){searchCtrl.dispose(); super.dispose();}
  Future<void> load() async { try { final x = await PennyPalService.transactions(); if(mounted) setState(()=>data=x); } catch(_){} finally{if(mounted)setState(()=>loading=false);} }
  @override Widget build(BuildContext context){
    final q=search.trim().toLowerCase();
    final list=data.where((x){ final okType=type=='ALL'||x['type']==type; final cat='${x['category_detail']?['name']??''}'; final okCat=category=='ALL'||cat==category; final text='${x['description']} $cat ${x['date']}'.toLowerCase(); return okType&&okCat&&(q.isEmpty||text.contains(q)); }).toList();
    return Scaffold(appBar: AppBar(title: const Text('Activity',style: TextStyle(fontWeight: FontWeight.w900)),actions:[IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),body: RefreshIndicator(onRefresh: load,child: ListView(padding: const EdgeInsets.fromLTRB(18,8,18,110),children:[
      TextField(controller: searchCtrl,onChanged:(_)=>setState((){}),decoration: const InputDecoration(hintText:'Search transactions',prefixIcon:Icon(Icons.search),suffixIcon:Icon(Icons.tune))),
      const SizedBox(height:12),
      SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[_Chip('All',type=='ALL',()=>setState(()=>type='ALL')),_Chip('Income',type=='INCOME',()=>setState(()=>type='INCOME')),_Chip('Expenses',type=='EXPENSE',()=>setState(()=>type='EXPENSE')), ...PennyPalService.categories.map((c)=>_Chip(c,category==c,()=>setState(()=>category=category==c?'ALL':c)))])),
      const SizedBox(height:16),
      if(loading) const LoadingCard() else if(list.isEmpty) const EmptyState(icon:Icons.search_off_rounded,title:'Nothing found',message:'Try another search or filter, or add a new transaction.') else ...list.asMap().entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:10),child:MotionReveal(delay:Duration(milliseconds: 70 + e.key * 55),child:_TransactionCard(e.value,onChanged:load)))),
    ])));
  }
  Widget _Chip(String label,bool selected,VoidCallback onTap)=>Padding(padding:const EdgeInsets.only(right:8),child:FilterChip(label:Text(label),selected:selected,onSelected:(_)=>onTap(),showCheckmark:false));
}

class _TransactionCard extends StatelessWidget { final dynamic x; final Future<void> Function() onChanged; const _TransactionCard(this.x,{required this.onChanged});
  @override Widget build(BuildContext context){final income=x['type']=='INCOME'; final amount=num.tryParse('${x['amount']}')??0; final color=income?PennyPalTheme.mint:PennyPalTheme.sky; return Dismissible(key:ValueKey(x['id']),direction:DismissDirection.endToStart,background:Container(decoration:BoxDecoration(color:PennyPalTheme.danger,borderRadius:BorderRadius.circular(20)),alignment:Alignment.centerRight,padding:const EdgeInsets.only(right:24),child:const Icon(Icons.delete_outline,color:Colors.white)),confirmDismiss:(_)=>_confirmDelete(context),onDismissed:(_){
      PennyPalService.deleteTransaction(x['id']).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) onChanged();
        });
      }).catchError((_) {});
    },child:InkWell(onTap:()=>_edit(context),borderRadius:BorderRadius.circular(20),child:AppCard(child:Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:color.withValues(alpha: .10),borderRadius:BorderRadius.circular(13)),child:Icon(income?Icons.south_west_rounded:Icons.north_east_rounded,color:color)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${x['description']}'.isEmpty?'Untitled transaction':'${x['description']}',style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:3),Text('${x['category_detail']?['name']??'Miscellaneous'} • ${x['date']}',style:const TextStyle(color:PennyPalTheme.muted,fontSize:12))])),const SizedBox(width:8),Text('${income?'+':'-'}${money(amount)}',style:TextStyle(fontWeight:FontWeight.w900,color:income?PennyPalTheme.mint:PennyPalTheme.danger))]))));}
  Future<bool> _confirmDelete(BuildContext context) async {final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Delete transaction?'),content:const Text('This removes the record from your PennyPal history.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete'))])); return ok??false;}
  Future<void> _edit(BuildContext context) async {final amount=TextEditingController(text:'${x['amount']}');final desc=TextEditingController(text:'${x['description']}');String cat='${x['category_detail']?['name']??'Miscellaneous'}';await showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('Edit transaction'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount',prefixText:'₦ ')),const SizedBox(height:12),DropdownButtonFormField<String>(initialValue:PennyPalService.categories.contains(cat)?cat:'Miscellaneous',items:PennyPalService.categories.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>cat=v??cat,decoration:const InputDecoration(labelText:'Category')),const SizedBox(height:12),TextField(controller:desc,decoration:const InputDecoration(labelText:'Description'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()async{final a=double.tryParse(amount.text.replaceAll(',',''));if(a==null||a<=0)return;try {
              await PennyPalService.updateTransaction(x['id'],{'amount':a,'category_name':cat,'description':desc.text.trim()});
              if (!c.mounted) return;
              Navigator.pop(c);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) onChanged();
              });
            } catch (e) {
              if (c.mounted) {
                ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Could not update transaction: $e')));
              }
            }},child:const Text('Save'))]));amount.dispose();desc.dispose();}
}
