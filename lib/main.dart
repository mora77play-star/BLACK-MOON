// ============================================================
// إدارة السنتر - المطور: عمر ✘
// ملف واحد كامل. الصق كل اللي تحت في lib/main.dart
//
// مهم: المكتبات دي لازم تتحط في pubspec.yaml تحت dependencies:
//   flutter_localizations:
//     sdk: flutter
//   shared_preferences: ^2.2.2
//   printing: ^5.12.0
//   pdf: ^3.10.8
//   url_launcher: ^6.2.5
// ============================================================

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show Printing;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const kBase = Color(0xFF0B1020);
const kCard = Color(0xFF141A30);
const kSm = TextStyle(color: Colors.white60, fontSize: 12);
const kB = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
const sp = SizedBox(height: 10);
const sp8 = SizedBox(height: 8);
const monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const daysAr = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

// ===================== التخزين (حفظ تلقائي) =====================
class Store {
  static late SharedPreferences sp;
  static Map<String, dynamic> d = {};

  static Map<String, dynamic> def() {
    final cl = <Map<String, dynamic>>[];
    var i = 0;
    for (final r in [
      ['الصف الأول الابتدائي', 300, 'p'], ['الصف الثاني الابتدائي', 300, 'p'], ['الصف الثالث الابتدائي', 300, 'p'],
      ['الصف الرابع الابتدائي', 350, 'p'], ['الصف الخامس الابتدائي', 350, 'p'], ['الصف السادس الابتدائي', 350, 'p'],
      ['الصف الأول الإعدادي', 400, 'e'], ['الصف الأول الإعدادي (أزهر)', 450, 'e'], ['الصف الثاني الإعدادي', 400, 'e'],
      ['الصف الثاني الإعدادي (أزهر)', 450, 'e'], ['الصف الثالث الإعدادي', 450, 'e'], ['الصف الثالث الإعدادي (أزهر)', 500, 'e'],
      ['الصف الأول الثانوي', 500, 's'], ['الصف الثاني الثانوي', 500, 's'], ['الصف الثالث الثانوي', 600, 's'],
    ]) {
      i++;
      cl.add({'id': i, 'name': r[0], 'price': r[1], 'stage': r[2]});
    }
    return {
      'v': 2, 'pass': '123456', 'center': 'إدارة السنتر',
      'stages': [{'id': 'p', 'name': 'الابتدائية'}, {'id': 'e', 'name': 'الإعدادية'}, {'id': 's', 'name': 'الثانوية'}],
      'classes': cl,
      'halls': [{'id': 1, 'name': 'قاعة 1'}, {'id': 2, 'name': 'قاعة 2'}, {'id': 3, 'name': 'قاعة 3'}],
      'students': [], 'teachers': [], 'pays': [], 'sessions': [], 'exams': [], 'day': {}, 'seq': 100,
    };
  }

  static Future<void> init() async {
    sp = await SharedPreferences.getInstance();
    final raw = sp.getString('db');
    if (raw != null) {
      try {
        d = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    def().forEach((k, v) => d.putIfAbsent(k, () => v));
    if (d['v'] != 2) {
      if (!classes.any((c) => c['stage'] == 's')) {
        for (final c in def()['classes']) {
          if (c['stage'] == 's') classes.add({'id': nid(), 'name': c['name'], 'price': c['price'], 'stage': 's'});
        }
      }
      d['v'] = 2;
      await save();
    }
  }

  static Future<void> save() => sp.setString('db', jsonEncode(d));
  static List get stages => d['stages'];
  static List get classes => d['classes'];
  static List get halls => d['halls'];
  static List get students => d['students'];
  static List get teachers => d['teachers'];
  static List get pays => d['pays'];
  static List get sessions => d['sessions'];
  static List get exams => d['exams'];
  static Map get day => d['day'];
  static int nid() {
    d['seq'] = (d['seq'] as int) + 1;
    return d['seq'];
  }
}

// ===================== دوال مساعدة =====================
String two(int n) => n.toString().padLeft(2, '0');
String fmt(DateTime n) => '${n.year}-${two(n.month)}-${two(n.day)}';
String today() => fmt(DateTime.now());
String monthOf(DateTime n) => '${n.year}-${two(n.month)}';
String monthLabel(String m) {
  final p = m.split('-');
  return '${monthsAr[int.parse(p[1]) - 1]} ${p[0]}';
}

String money(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '$b ج.م';
}

String n2(num n) => n == n.roundToDouble() ? n.round().toString() : n.toStringAsFixed(1);

Map cls(dynamic id) {
  for (final c in Store.classes) {
    if (c['id'] == id) return c as Map;
  }
  return {'id': 0, 'name': '—', 'price': 0, 'stage': ''};
}

String hallName(dynamic id) {
  for (final h in Store.halls) {
    if (h['id'] == id) return '${h['name']}';
  }
  return 'بدون قاعة';
}

String stageName(dynamic id) {
  for (final s in Store.stages) {
    if (s['id'] == id) return '${s['name']}';
  }
  return '—';
}

String codeOf(Map s) => '${s['code'] ?? ''}';
Map? stuById(dynamic id) {
  for (final s in Store.students) {
    if (s['id'] == id) return s as Map;
  }
  return null;
}

Map? byCode(String c) {
  final t = c.trim();
  if (t.isEmpty) return null;
  for (final s in Store.students) {
    if (codeOf(s as Map) == t) return s;
  }
  return null;
}

bool match(Map s, String q) {
  final t = q.trim();
  if (t.isEmpty) return true;
  return '${s['name']}'.contains(t) || codeOf(s).contains(t) || '${s['parent'] ?? ''}'.contains(t) || '${s['phone'] ?? ''}'.contains(t);
}

String nextCode() {
  var m = 1000;
  for (final s in Store.students) {
    final v = int.tryParse(codeOf(s as Map));
    if (v != null && v > m) m = v;
  }
  return '${m + 1}';
}

Map? paidOf(dynamic sid, String m) {
  for (final p in Store.pays) {
    if (p['sid'] == sid && p['month'] == m) return p as Map;
  }
  return null;
}

Map dayRec(String date, dynamic sid, [bool create = false]) {
  if (!Store.day.containsKey(date)) {
    if (!create) return {};
    Store.day[date] = <String, dynamic>{};
  }
  final m = Store.day[date] as Map;
  final k = '$sid';
  if (!m.containsKey(k)) {
    if (!create) return {};
    m[k] = <String, dynamic>{};
  }
  return m[k] as Map;
}

void deleteStudent(dynamic id) {
  Store.students.removeWhere((s) => s['id'] == id);
  Store.pays.removeWhere((p) => p['sid'] == id);
  Store.exams.removeWhere((e) => e['sid'] == id);
  Store.day.forEach((k, v) => (v as Map).remove('$id'));
  Store.save();
}

String waNum(String p) {
  final d = p.replaceAll(RegExp(r'\D'), '');
  return d.startsWith('0') ? '2$d' : d;
}

void call(BuildContext c, String p) {
  if (p.trim().isEmpty) {
    toast(c, 'مفيش رقم ولي أمر');
    return;
  }
  launchUrl(Uri.parse('tel:${p.trim()}'));
}

void wapp(BuildContext c, String p, [String msg = '']) {
  if (p.trim().isEmpty) {
    toast(c, 'مفيش رقم ولي أمر');
    return;
  }
  launchUrl(Uri.parse('https://wa.me/${waNum(p)}${msg.isEmpty ? '' : '?text=${Uri.encodeComponent(msg)}'}'), mode: LaunchMode.externalApplication);
}

Color hc(num i, [double s = .6, double v = .95]) => HSVColor.fromAHSV(1, ((i * 47) % 360).toDouble(), s, v).toColor();
Color shift(Color c, double d) {
  final h = HSVColor.fromColor(c);
  return h.withHue((h.hue + d) % 360).toColor();
}

LinearGradient pg(BuildContext c, [double d = 0]) {
  final cs = Theme.of(c).colorScheme;
  return LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [shift(cs.primary, d), shift(cs.secondary, d)]);
}

void toast(BuildContext c, String m) {
  final s = ScaffoldMessenger.of(c);
  s.hideCurrentSnackBar();
  s.showSnackBar(SnackBar(content: Text(m, textAlign: TextAlign.center), behavior: SnackBarBehavior.floating, backgroundColor: kCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))));
}

Future<bool> ask(BuildContext c, String t) async =>
    (await showDialog<bool>(
        context: c,
        builder: (x) => AlertDialog(backgroundColor: kCard, title: Text(t), actions: [
              TextButton(onPressed: () => Navigator.pop(x, false), child: const Text('لأ')),
              ElevatedButton(onPressed: () => Navigator.pop(x, true), child: const Text('أيوه')),
            ]))) ??
    false;

Future<void> sheet(BuildContext c, Widget Function(BuildContext) b) => showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    backgroundColor: kCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (x) => Padding(padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(x).viewInsets.bottom + 18), child: SingleChildScrollView(child: b(x))));

InputDecoration deco(String l, IconData i) => InputDecoration(
    labelText: l,
    prefixIcon: Icon(i),
    filled: true,
    fillColor: Colors.white.withOpacity(.07),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));

Widget pop(int i, Widget child) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 450 + min(i, 10) * 70),
    curve: Curves.easeOutBack,
    builder: (_, v, ch) => Opacity(opacity: v.clamp(0.0, 1.0).toDouble(), child: Transform.translate(offset: Offset(0, 30 * (1 - v)), child: ch)),
    child: child);

Widget gbtn(BuildContext c, String t, IconData ic, VoidCallback f) => Material(
    color: Colors.transparent,
    child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: f,
        child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(gradient: pg(c), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Theme.of(c).colorScheme.primary.withOpacity(.4), blurRadius: 14, offset: const Offset(0, 5))]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(ic, color: kBase),
              const SizedBox(width: 8),
              Text(t, style: const TextStyle(color: kBase, fontWeight: FontWeight.bold, fontSize: 16)),
            ]))));

Widget seg(List<List<String>> o, String sel, void Function(String) f) => Row(children: [
      for (final e in o)
        Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(label: SizedBox(width: double.infinity, child: Text(e[1], textAlign: TextAlign.center)), selected: sel == e[0], onSelected: (_) => f(e[0])))),
    ]);

Widget lab(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Align(alignment: AlignmentDirectional.centerStart, child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 13))));
Widget chip(IconData ic, String t, [Color? col]) => Chip(avatar: Icon(ic, size: 18, color: col), label: Text(t));
Widget kv(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$k: ', style: const TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Text(v))]));

Widget foot() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 22),
    child: Text('جميع الحقوق محفوظة لـ عمر ✘ ©\nالمطور: عمر ✘', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.7)));

Future<DateTime?> pickDate(BuildContext c, DateTime d) => showDatePicker(context: c, initialDate: d, firstDate: DateTime(2020), lastDate: DateTime(2100));

Widget navBar(String title, String sub, VoidCallback prev, VoidCallback next, VoidCallback tap) => Glass(
    pad: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.chevron_right_rounded, size: 32), onPressed: prev),
      Expanded(
          child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: tap,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.calendar_month_rounded, size: 20),
                      const SizedBox(width: 6),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ]),
                    Text(sub, style: kSm),
                  ])))),
      IconButton(icon: const Icon(Icons.chevron_left_rounded, size: 32), onPressed: next),
    ]));

Widget dateBar(BuildContext c, DateTime d, void Function(DateTime) set) => navBar(
    fmt(d),
    daysAr[d.weekday - 1] + (fmt(d) == today() ? ' • اليوم' : ' • اضغط لفتح التقويم'),
    () => set(d.subtract(const Duration(days: 1))),
    () => set(d.add(const Duration(days: 1))),
    () async {
      final r = await pickDate(c, d);
      if (r != null) set(r);
    });

Widget monthBar(BuildContext c, String m, void Function(String) set) {
  final d = DateTime.parse('$m-01');
  return navBar(
      monthLabel(m),
      m == monthOf(DateTime.now()) ? 'الشهر الحالي' : 'اضغط لاختيار شهر من التقويم',
      () => set(monthOf(DateTime(d.year, d.month - 1, 1))),
      () => set(monthOf(DateTime(d.year, d.month + 1, 1))),
      () async {
        final r = await pickDate(c, d);
        if (r != null) set(monthOf(r));
      });
}

// ===================== فلتر المرحلة / الصف / القاعة =====================
class Flt {
  String st;
  int kl = 0, ha = 0;
  Flt([this.st = '']);
  bool ok(Map s) {
    if (kl != 0 && s['cls'] != kl) return false;
    if (st.isNotEmpty && cls(s['cls'])['stage'] != st) return false;
    if (ha != 0 && s['hall'] != ha) return false;
    return true;
  }
}

Widget fltBar(Flt f, VoidCallback ch) {
  final cl = Store.classes.where((c) => f.st.isEmpty || c['stage'] == f.st).toList();
  if (f.kl != 0 && !cl.any((c) => c['id'] == f.kl)) f.kl = 0;
  if (f.ha != 0 && !Store.halls.any((h) => h['id'] == f.ha)) f.ha = 0;
  if (f.st.isNotEmpty && !Store.stages.any((s) => s['id'] == f.st)) f.st = '';
  return Glass(
      pad: const EdgeInsets.all(12),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: DropdownButtonFormField<String>(
                  value: f.st,
                  isExpanded: true,
                  dropdownColor: kCard,
                  decoration: deco('المرحلة', Icons.layers_rounded),
                  items: [const DropdownMenuItem<String>(value: '', child: Text('كل المراحل')), for (final s in Store.stages) DropdownMenuItem<String>(value: '${s['id']}', child: Text('${s['name']}'))],
                  onChanged: (v) {
                    f.st = v ?? '';
                    ch();
                  })),
          const SizedBox(width: 8),
          Expanded(
              child: DropdownButtonFormField<int>(
                  value: f.ha,
                  isExpanded: true,
                  dropdownColor: kCard,
                  decoration: deco('القاعة', Icons.meeting_room_rounded),
                  items: [const DropdownMenuItem<int>(value: 0, child: Text('كل القاعات')), for (final h in Store.halls) DropdownMenuItem<int>(value: h['id'], child: Text('${h['name']}'))],
                  onChanged: (v) {
                    f.ha = v ?? 0;
                    ch();
                  })),
        ]),
        sp8,
        DropdownButtonFormField<int>(
            value: f.kl,
            isExpanded: true,
            dropdownColor: kCard,
            decoration: deco('الصف', Icons.class_rounded),
            items: [const DropdownMenuItem<int>(value: 0, child: Text('كل الصفوف')), for (final k in cl) DropdownMenuItem<int>(value: k['id'], child: Text('${k['name']}'))],
            onChanged: (v) {
              f.kl = v ?? 0;
              ch();
            }),
      ]));
}

// ===================== نموذج الطالب =====================
void studentForm(BuildContext ctx, VoidCallback done, {Map? st, String stage = ''}) {
  final n = TextEditingController(text: st == null ? '' : '${st['name']}');
  final cd = TextEditingController(text: st == null ? nextCode() : codeOf(st));
  final pa = TextEditingController(text: st == null ? '' : '${st['parent'] ?? ''}');
  final ph = TextEditingController(text: st == null ? '' : '${st['phone'] ?? ''}');
  String g = st == null ? 'm' : '${st['gender']}';
  String stg = st != null ? '${cls(st['cls'])['stage']}' : (stage.isNotEmpty ? stage : '${Store.stages.first['id']}');
  int cid = st != null ? st['cls'] : 0;
  int hid = st != null ? (st['hall'] ?? 0) : 0;
  if (!Store.halls.any((h) => h['id'] == hid)) hid = 0;
  sheet(
      ctx,
      (x) => StatefulBuilder(builder: (x, ss) {
            final cl = Store.classes.where((c) => c['stage'] == stg).toList();
            if (!cl.any((c) => c['id'] == cid)) cid = cl.isEmpty ? 0 : cl.first['id'];
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Text(st == null ? 'إضافة طالب' : 'تعديل بيانات الطالب', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(controller: n, decoration: deco('اسم الطالب', Icons.person_rounded)),
              sp,
              TextField(controller: cd, decoration: deco('كود الطالب (تكتبه بنفسك)', Icons.qr_code_rounded)),
              sp,
              TextField(controller: pa, keyboardType: TextInputType.phone, decoration: deco('رقم ولي الأمر', Icons.family_restroom_rounded)),
              sp,
              TextField(controller: ph, keyboardType: TextInputType.phone, decoration: deco('رقم الطالب (اختياري)', Icons.phone_rounded)),
              sp,
              lab('النوع'),
              seg([['m', 'ولد'], ['f', 'بنت']], g, (v) => ss(() => g = v)),
              sp,
              DropdownButtonFormField<String>(
                  value: stg,
                  dropdownColor: kCard,
                  decoration: deco('المرحلة', Icons.layers_rounded),
                  items: [for (final s in Store.stages) DropdownMenuItem<String>(value: '${s['id']}', child: Text('${s['name']}'))],
                  onChanged: (v) => ss(() => stg = v!)),
              sp,
              DropdownButtonFormField<int>(
                  value: cid == 0 ? null : cid,
                  dropdownColor: kCard,
                  decoration: deco('الصف', Icons.class_rounded),
                  items: [for (final k in cl) DropdownMenuItem<int>(value: k['id'], child: Text('${k['name']}'))],
                  onChanged: (v) => ss(() => cid = v!)),
              sp,
              DropdownButtonFormField<int>(
                  value: hid == 0 ? null : hid,
                  dropdownColor: kCard,
                  decoration: deco('القاعة', Icons.meeting_room_rounded),
                  items: [for (final h in Store.halls) DropdownMenuItem<int>(value: h['id'], child: Text('${h['name']}'))],
                  onChanged: (v) => ss(() => hid = v ?? 0)),
              const SizedBox(height: 14),
              gbtn(x, 'حفظ', Icons.check_rounded, () {
                final code = cd.text.trim();
                if (n.text.trim().isEmpty || code.isEmpty) {
                  toast(x, 'اكتب الاسم والكود');
                  return;
                }
                if (cid == 0) {
                  toast(x, 'اختار الصف الأول');
                  return;
                }
                final o = byCode(code);
                if (o != null && (st == null || o['id'] != st['id'])) {
                  toast(x, 'الكود ده مستخدم قبل كده');
                  return;
                }
                final data = <String, dynamic>{'name': n.text.trim(), 'code': code, 'parent': pa.text.trim(), 'phone': ph.text.trim(), 'gender': g, 'cls': cid, 'hall': hid};
                if (st == null) {
                  Store.students.add({'id': Store.nid(), ...data, 'date': today()});
                } else {
                  st.addAll(data);
                }
                Store.save();
                Navigator.pop(x);
                done();
                toast(ctx, 'تم الحفظ');
              }),
            ]);
          }));
}

// ===================== الدفع والإيصال =====================
void payDialog(BuildContext ctx, Map s, String month, void Function(int) done) {
  final t = TextEditingController(text: n2(cls(s['cls'])['price']));
  showDialog(
      context: ctx,
      builder: (x) => AlertDialog(
              backgroundColor: kCard,
              title: Text('دفع ${s['name']}'),
              content: TextField(controller: t, keyboardType: TextInputType.number, decoration: deco('المبلغ', Icons.payments_rounded)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(x), child: const Text('إلغاء')),
                ElevatedButton(
                    onPressed: () {
                      final a = double.tryParse(t.text);
                      if (a == null || a < 0) return;
                      final id = Store.nid();
                      Store.pays.add({'id': id, 'sid': s['id'], 'month': month, 'amount': a, 'date': today()});
                      Store.save();
                      Navigator.pop(x);
                      done(id);
                    },
                    child: const Text('تأكيد الدفع')),
              ]));
}

Widget receiptBody(Map p) {
  final s = stuById(p['sid']) ?? {'name': '—', 'cls': 0, 'code': ''};
  return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('${Store.d['center']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    Text('إيصال دفع رقم ${p['id']}', textAlign: TextAlign.center),
    const Divider(),
    kv('الطالب', '${s['name']}'),
    kv('الكود', codeOf(s)),
    kv('الصف', '${cls(s['cls'])['name']}'),
    kv('الشهر', monthLabel('${p['month']}')),
    kv('المبلغ', money(p['amount'])),
    kv('التاريخ', '${p['date']}'),
  ]);
}

void receiptDialog(BuildContext c, int id) {
  final p = Store.pays.firstWhere((x) => x['id'] == id) as Map;
  showDialog(
      context: c,
      builder: (x) => AlertDialog(backgroundColor: kCard, content: SingleChildScrollView(child: receiptBody(p)), actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(x);
                  openPrint(c, 'إيصال دفع', receiptBody(p));
                },
                child: const Text('طباعة')),
            ElevatedButton(onPressed: () => Navigator.pop(x), child: const Text('تمام')),
          ]));
}

// ===================== الطباعة الحقيقية =====================
class PrintPage extends StatefulWidget {
  final String title;
  final Widget child;
  const PrintPage({super.key, required this.title, required this.child});
  @override
  State<PrintPage> createState() => _PrintS();
}

class _PrintS extends State<PrintPage> {
  final key = GlobalKey();
  bool busy = false;

  Future<void> doPrint() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 3);
      final w = img.width.toDouble(), h = img.height.toDouble();
      final sliceH = w * (770 / 539);
      final pages = <Uint8List>[];
      for (double y = 0; y < h; y += sliceH) {
        final hh = min(sliceH, h - y);
        final rec = ui.PictureRecorder();
        final cv = Canvas(rec);
        cv.drawImageRect(img, Rect.fromLTWH(0, y, w, hh), Rect.fromLTWH(0, 0, w, hh), Paint());
        final part = await rec.endRecording().toImage(w.toInt(), hh.ceil());
        final bd = await part.toByteData(format: ui.ImageByteFormat.png);
        pages.add(bd!.buffer.asUint8List());
      }
      final doc = pw.Document();
      for (final p in pages) {
        final im = pw.MemoryImage(p);
        doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(28), build: (_) => pw.Align(alignment: pw.Alignment.topCenter, child: pw.Image(im, width: 539))));
      }
      final bytes = await doc.save();
      await Printing.layoutPdf(name: widget.title, onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) toast(context, 'تعذرت الطباعة: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext c) => Bg(
      child: Scaffold(
          appBar: AppBar(title: Text(widget.title), actions: [IconButton(icon: const Icon(Icons.print_rounded), onPressed: doPrint)]),
          floatingActionButton: FloatingActionButton.extended(
              onPressed: doPrint,
              icon: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.print_rounded),
              label: const Text('طباعة')),
          body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
              child: Center(
                  child: RepaintBoundary(
                      key: key,
                      child: Container(
                          width: 380,
                          color: Colors.white,
                          padding: const EdgeInsets.all(18),
                          child: Theme(data: ThemeData.light(), child: DefaultTextStyle(style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.5), child: widget.child))))))));
}

void openPrint(BuildContext c, String title, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => PrintPage(title: title, child: w)));

Widget tbl(List<String> head, List<List<String>> rows) {
  Widget cell(String t, {bool b = false}) => Padding(padding: const EdgeInsets.all(5), child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: b ? FontWeight.bold : FontWeight.normal)));
  return Table(border: TableBorder.all(color: Colors.black26), children: [
    TableRow(decoration: const BoxDecoration(color: Color(0xFFE3EAF8)), children: [for (final h in head) cell(h, b: true)]),
    for (final r in rows) TableRow(children: [for (final v in r) cell(v)]),
  ]);
}

Widget reportHead(String title, String sub) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${Store.d['center']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      const Divider(),
    ]);

Widget tableReport(String title, String sub, List<String> head, List<List<String>> rows) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      reportHead(title, sub),
      tbl(head, rows),
      const SizedBox(height: 8),
      Text('العدد: ${rows.length} • ${today()}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
    ]);

// ===================== بيانات الطالب الشهرية =====================
Map monthData(Map st, String m) {
  final rows = <List>[];
  Store.day.forEach((k, v) {
    if ('$k'.startsWith(m)) {
      final r = (v as Map)['${st['id']}'];
      if (r != null) rows.add(['$k', r as Map]);
    }
  });
  rows.sort((a, b) => '${a[0]}'.compareTo('${b[0]}'));
  int cnt(String key, int val) => rows.where((r) => (r[1] as Map)[key] == val).length;
  return {
    'rows': rows,
    'pay': paidOf(st['id'], m),
    'exams': Store.exams.where((e) => e['sid'] == st['id'] && e['month'] == m).toList(),
    'pr': cnt('a', 1), 'ab': cnt('a', 0), 'rc': cnt('r', 1), 'nrc': cnt('r', 0), 'hw': cnt('h', 1), 'nhw': cnt('h', 0),
  };
}

String yn(dynamic v) => v == 1 ? 'نعم' : v == 0 ? 'لا' : '-';

Widget studentReport(Map st, String m) {
  final d = monthData(st, m);
  final rows = d['rows'] as List, ex = d['exams'] as List;
  final pay = d['pay'] as Map?;
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    reportHead('تقرير الطالب الشهري', monthLabel(m)),
    kv('الاسم', '${st['name']}'),
    kv('الكود', codeOf(st)),
    kv('الصف', '${cls(st['cls'])['name']}'),
    kv('القاعة', hallName(st['hall'])),
    kv('المصروفات', pay == null ? 'غير مدفوع' : 'مدفوع ${money(pay['amount'])} بتاريخ ${pay['date']}'),
    const SizedBox(height: 6),
    Text('حضور ${d['pr']} • غياب ${d['ab']} • تسميع ${d['rc']} • لم يسمّع ${d['nrc']} • واجب ${d['hw']} • بدون واجب ${d['nhw']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    const SizedBox(height: 8),
    if (rows.isNotEmpty) tbl(['التاريخ', 'الحضور', 'التسميع', 'الواجب'], [for (final r in rows) ['${r[0]}', yn((r[1] as Map)['a']), yn((r[1] as Map)['r']), yn((r[1] as Map)['h'])]]),
    if (ex.isNotEmpty) ...[
      const SizedBox(height: 10),
      const Text('الامتحانات', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      tbl(['المادة', 'الدرجة', 'النسبة'], [for (final e in ex) ['${e['subject']}', '${n2(e['score'])} / ${n2(e['max'])}', '${((e['score'] as num) / (e['max'] as num) * 100).round()}%']]),
    ],
  ]);
}

// ===================== الامتحانات (إضافة وصف) =====================
void addExam(BuildContext ctx, String month, VoidCallback done, {Map? student}) {
  final cd = TextEditingController(text: student == null ? '' : codeOf(student));
  final sb = TextEditingController(), sc = TextEditingController(), mx = TextEditingController(text: '100');
  sheet(
      ctx,
      (x) => StatefulBuilder(builder: (x, ss) {
            final f = byCode(cd.text);
            return Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('إضافة امتحان', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(controller: cd, onChanged: (_) => ss(() {}), decoration: deco('كود الطالب', Icons.qr_code_rounded)),
              Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(f == null ? (cd.text.isEmpty ? '' : 'مفيش طالب بالكود ده') : 'الطالب: ${f['name']} • ${cls(f['cls'])['name']}', style: TextStyle(color: f == null ? Colors.redAccent : Colors.greenAccent))),
              sp,
              TextField(controller: sb, decoration: deco('المادة', Icons.menu_book_rounded)),
              sp,
              Row(children: [
                Expanded(child: TextField(controller: sc, keyboardType: TextInputType.number, decoration: deco('الدرجة', Icons.grade_rounded))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: mx, keyboardType: TextInputType.number, decoration: deco('من', Icons.flag_rounded))),
              ]),
              const SizedBox(height: 14),
              gbtn(x, 'حفظ الامتحان', Icons.check_rounded, () {
                final s = byCode(cd.text), a = double.tryParse(sc.text), m = double.tryParse(mx.text);
                if (s == null || sb.text.trim().isEmpty || a == null || m == null || m <= 0) {
                  toast(x, 'اكتب كود صحيح والمادة والدرجة');
                  return;
                }
                Store.exams.add({'id': Store.nid(), 'sid': s['id'], 'subject': sb.text.trim(), 'score': a, 'max': m, 'date': today(), 'month': month});
                Store.save();
                Navigator.pop(x);
                done();
                toast(ctx, 'تم حفظ الامتحان');
              }),
            ]);
          }));
}

Widget examRow(BuildContext c, int i, Map e, VoidCallback changed, {bool who = true}) {
  final st = stuById(e['sid']);
  final p = (e['score'] as num) / (e['max'] as num) * 100;
  final col = p >= 85 ? Colors.greenAccent : p >= 50 ? Colors.amberAccent : Colors.redAccent;
  return pop(
      i,
      Glass(
          onTap: who && st != null ? () => Navigator.push(c, MaterialPageRoute(builder: (_) => StudentPage(id: st['id']))).then((_) => changed()) : null,
          child: Row(children: [
            Container(width: 56, height: 56, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: col, width: 3)), child: Text('${p.round()}%', style: TextStyle(fontWeight: FontWeight.w900, color: col, fontSize: 14))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e['subject']}', style: kB),
              Text('${n2(e['score'])} / ${n2(e['max'])}${who && st != null ? ' • ${st['name']} • كود ${codeOf(st)}' : ''}', style: kSm),
            ])),
            IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                onPressed: () async {
                  if (!await ask(c, 'حذف الامتحان؟')) return;
                  Store.exams.removeWhere((x) => x['id'] == e['id']);
                  Store.save();
                  changed();
                }),
          ])));
}


// ===================== عناصر الواجهة =====================
class Bg extends StatefulWidget {
  final Widget child;
  const Bg({super.key, required this.child});
  @override
  State<Bg> createState() => _BgS();
}

class _BgS extends State<Bg> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(fit: StackFit.expand, children: [
      Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [
        Color.alphaBlend(cs.primary.withOpacity(.30), kBase),
        kBase,
        Color.alphaBlend(cs.secondary.withOpacity(.30), kBase),
      ]))),
      AnimatedBuilder(animation: c, builder: (_, __) => CustomPaint(painter: _Dots(c.value, cs.primary, cs.secondary))),
      widget.child,
    ]);
  }
}

class _Dots extends CustomPainter {
  final double t;
  final Color a, b;
  _Dots(this.t, this.a, this.b);
  @override
  void paint(Canvas cv, Size s) {
    for (var i = 0; i < 14; i++) {
      final k1 = 1 + i % 3, k2 = 1 + (i + 1) % 3;
      final x = (sin(t * 2 * pi * k1 + i * 1.7) * .45 + .5) * s.width;
      final y = (cos(t * 2 * pi * k2 + i * 2.3) * .45 + .5) * s.height;
      final pt = Paint()
        ..color = (i.isEven ? a : b).withOpacity(.10 + .04 * (i % 3))
        ..style = i % 4 == 0 ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = 2.5;
      cv.drawCircle(Offset(x, y), 14.0 + (i % 5) * 9, pt);
    }
  }

  @override
  bool shouldRepaint(covariant _Dots o) => true;
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets pad;
  final Gradient? g;
  final VoidCallback? onTap;
  const Glass({super.key, required this.child, this.pad = const EdgeInsets.all(14), this.g, this.onTap});
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Ink(
                  padding: pad,
                  decoration: BoxDecoration(
                      gradient: g ?? LinearGradient(colors: [Colors.white.withOpacity(.11), Colors.white.withOpacity(.04)]),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(.12))),
                  child: child))));
}

class SpinLogo extends StatefulWidget {
  final double size;
  const SpinLogo({super.key, this.size = 150});
  @override
  State<SpinLogo> createState() => _SpinLogoS();
}

class _SpinLogoS extends State<SpinLogo> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return AnimatedBuilder(
        animation: c,
        builder: (_, __) => Transform.translate(
            offset: Offset(0, sin(c.value * 2 * pi * 2) * 6),
            child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(painter: _LogoP(cs.primary, cs.secondary, c.value)))));
  }
}

class _LogoP extends CustomPainter {
  final Color a, b;
  final double t;
  _LogoP(this.a, this.b, this.t);
  @override
  void paint(Canvas cv, Size s) {
    final r = s.width / 2, cx = r, cy = r;
    cv.drawCircle(Offset(cx, cy), r * .88,
        Paint()..color = a.withOpacity(.35 + .15 * sin(t * 2 * pi * 3))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
    cv.drawCircle(Offset(cx, cy), r * .9, Paint()..color = const Color(0xFF0A1630));
    cv.save();
    cv.translate(cx, cy);
    cv.rotate(t * 2 * pi);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r * .9);
    cv.drawArc(rect, 0, 2 * pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .07
          ..shader = SweepGradient(colors: [a, b, a.withOpacity(.1), a]).createShader(rect));
    cv.restore();
    cv.drawCircle(Offset(cx, cy), r * .78,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .015
          ..color = b.withOpacity(.5));
    final white = Paint()..color = Colors.white;
    final blue = Paint()..color = const Color(0xFF5AA9FF);
    for (final d in [-1.0, 1.0]) {
      cv.drawCircle(Offset(cx + d * r * .3, cy - r * .02), r * .1, blue);
      cv.drawArc(Rect.fromCenter(center: Offset(cx + d * r * .3, cy + r * .3), width: r * .4, height: r * .45), pi, pi, true, blue);
    }
    cv.drawCircle(Offset(cx, cy - r * .08), r * .17, Paint()..color = const Color(0xFFDCE9FF));
    cv.drawArc(Rect.fromCenter(center: Offset(cx, cy + r * .34), width: r * .62, height: r * .6), pi, pi, true, white);
    final cap = Path()
      ..moveTo(cx - r * .34, cy - r * .26)
      ..lineTo(cx, cy - r * .42)
      ..lineTo(cx + r * .34, cy - r * .26)
      ..lineTo(cx, cy - r * .12)
      ..close();
    cv.drawPath(cap, white);
    final gold = Paint()
      ..color = const Color(0xFFFFC857)
      ..strokeWidth = r * .02;
    cv.drawLine(Offset(cx + r * .34, cy - r * .26), Offset(cx + r * .34, cy - r * .1), gold);
    cv.drawCircle(Offset(cx + r * .34, cy - r * .08), r * .03, gold);
    final cols = [const Color(0xFF2F6BFF), const Color(0xFF4A8BFF), const Color(0xFF7FB0FF)];
    for (var i = 0; i < 3; i++) {
      cv.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(cx + r * .38 + i * r * .02, cy + r * .06 + i * r * .1, r * .3, r * .08), Radius.circular(r * .02)),
          Paint()..color = cols[i]);
    }
    cv.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - r * .72, cy + r * .02, r * .3, r * .22), Radius.circular(r * .025)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .025
          ..color = const Color(0xFF9CC4FF));
    final ln = Paint()
      ..color = b
      ..strokeWidth = r * .02;
    cv.drawLine(Offset(cx - r * .66, cy + r * .1), Offset(cx - r * .5, cy + r * .1), ln);
    cv.drawLine(Offset(cx - r * .66, cy + r * .16), Offset(cx - r * .54, cy + r * .16), ln);
  }

  @override
  bool shouldRepaint(covariant _LogoP o) => true;
}

class Teachers extends StatefulWidget {
  const Teachers({super.key});
  @override
  State<Teachers> createState() => _TeachersS();
}

class _TeachersS extends State<Teachers> {
  void add() {
    final n = TextEditingController(), j = TextEditingController(), p = TextEditingController();
    String st = 'e';
    sheet(context, (x) => StatefulBuilder(builder: (x, ss) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('إضافة مدرس', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(controller: n, decoration: deco('اسم المدرس', Icons.person_rounded)),
          const SizedBox(height: 10),
          TextField(controller: j, decoration: deco('المادة', Icons.menu_book_rounded)),
          const SizedBox(height: 10),
          TextField(controller: p, keyboardType: TextInputType.number, decoration: deco('سعر الحصة (ج.م)', Icons.payments_rounded)),
          const SizedBox(height: 10),
          seg([['p', 'ابتدائية'], ['e', 'إعدادية']], st, (v) => ss(() => st = v)),
          const SizedBox(height: 14),
          gbtn(x, 'حفظ المدرس', Icons.check_rounded, () {
            final pr = double.tryParse(p.text);
            if (n.text.trim().isEmpty || pr == null) {
              toast(x, 'اكتب الاسم وسعر الحصة');
              return;
            }
            Store.teachers.add({'id': Store.nid(), 'name': n.text.trim(), 'subj': j.text.trim(), 'stage': st, 'price': pr});
            Store.save();
            Navigator.pop(x);
            setState(() {});
          }),
        ])));
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      floatingActionButton: FloatingActionButton.extended(
          onPressed: add,
          icon: const Icon(Icons.add_rounded),
          label: const Text('مدرس جديد', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 90), children: [
        const Text('المدرسين والحصص', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (Store.teachers.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('مفيش مدرسين'))),
        for (var i = 0; i < Store.teachers.length; i++) _card(i, Store.teachers[i] as Map),
      ]));

  Widget _card(int i, Map t) {
    final open = Store.sessions.where((x) => x['tid'] == t['id'] && x['done'] != true).toList();
    double due = 0;
    for (final x in open) {
      due += (x['price'] as num).toDouble();
    }
    return pop(
        i,
        Glass(
            child: Column(children: [
          Row(children: [
            CircleAvatar(backgroundColor: hc(t['id']), child: const Icon(Icons.person_pin_rounded, color: kBase)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${t['subj'] == '' ? '—' : t['subj']} • ${t['stage'] == 'p' ? 'ابتدائية' : 'إعدادية'} • الحصة ${money(t['price'])}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 8),
          Text('حصص لم تُصفّى: ${open.length} — المستحق: ${money(due)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ElevatedButton.icon(
                onPressed: () {
                  Store.sessions.add({'id': Store.nid(), 'tid': t['id'], 'price': t['price'], 'date': today(), 'done': false});
                  Store.save();
                  setState(() {});
                  toast(context, 'تم تسجيل حصة');
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('حصة')),
            OutlinedButton.icon(
                onPressed: () async {
                  if (open.isEmpty) {
                    toast(context, 'مفيش مستحقات');
                    return;
                  }
                  if (!await ask(context, 'تصفية ${open.length} حصة بمبلغ ${money(due)}؟')) return;
                  for (final x in open) {
                    x['done'] = true;
                  }
                  Store.save();
                  setState(() {});
                },
                icon: const Icon(Icons.price_check_rounded),
                label: const Text('تصفية')),
            IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                onPressed: () async {
                  if (!await ask(context, 'حذف المدرس؟')) return;
                  Store.teachers.removeWhere((x) => x['id'] == t['id']);
                  Store.sessions.removeWhere((x) => x['tid'] == t['id']);
                  Store.save();
                  setState(() {});
                }),
          ]),
        ])));
  }
}

// ===================== التطبيق =====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppS();
}

class _AppS extends State<App> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final h = c.value * 360;
        final p = HSVColor.fromAHSV(1, h, .62, .98).toColor();
        final s = HSVColor.fromAHSV(1, (h + 70) % 360, .60, .98).toColor();
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'إدارة السنتر',
            locale: const Locale('ar', 'EG'),
            supportedLocales: const [Locale('ar', 'EG')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.dark(primary: p, secondary: s, primaryContainer: p, onPrimaryContainer: kBase, secondaryContainer: s.withOpacity(.30), onSecondaryContainer: Colors.white, surface: kCard, onPrimary: kBase),
                scaffoldBackgroundColor: Colors.transparent,
                appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
                navigationBarTheme: NavigationBarThemeData(backgroundColor: kCard.withOpacity(.96), indicatorColor: p.withOpacity(.35))),
            home: const Login());
      });
}

// ===================== تسجيل الدخول (لوحة أرقام) =====================
class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginS();
}

class _LoginS extends State<Login> with TickerProviderStateMixin {
  String code = '';
  bool ok = false;
  late final AnimationController sh = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController sm = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  int get len => '${Store.d['pass']}'.length;
  @override
  void dispose() {
    sh.dispose();
    sm.dispose();
    super.dispose();
  }

  Future<void> press(String d) async {
    if (ok || code.length >= len) return;
    HapticFeedback.selectionClick();
    setState(() => code += d);
    if (code.length != len) return;
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    if (code == '${Store.d['pass']}') {
      setState(() => ok = true);
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 700),
              pageBuilder: (_, __, ___) => const Shell(),
              transitionsBuilder: (_, a, __, ch) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween<double>(begin: .9, end: 1.0).animate(a), child: ch))));
    } else {
      HapticFeedback.heavyImpact();
      sh.forward(from: 0);
      setState(() => code = '');
      toast(context, 'الباسورد غلط');
    }
  }

  void del() {
    if (code.isNotEmpty && !ok) setState(() => code = code.substring(0, code.length - 1));
  }

  Widget kb(String t, {IconData? ic, VoidCallback? f}) => Padding(
      padding: const EdgeInsets.all(7),
      child: Material(
          color: Colors.white.withOpacity(.08),
          shape: const CircleBorder(side: BorderSide(color: Colors.white12)),
          child: InkWell(
              customBorder: const CircleBorder(),
              onTap: f ?? () => press(t),
              child: SizedBox(width: 68, height: 68, child: Center(child: ic != null ? Icon(ic, size: 26) : Text(t, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)))))));

  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return Bg(
        child: Scaffold(
            body: SafeArea(
                child: Center(
                    child: SingleChildScrollView(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
      pop(0, const SpinLogo(size: 140)),
      pop(
          1,
          AnimatedBuilder(
              animation: sm,
              builder: (_, __) => ShaderMask(
                  shaderCallback: (r) => LinearGradient(begin: Alignment(-1 + 2 * sm.value, -.3), end: Alignment(1 + 2 * sm.value, .3), tileMode: TileMode.mirror, colors: [cs.primary, Colors.white, cs.secondary]).createShader(r),
                  child: const Text('إدارة السنتر', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white))))),
      pop(2, const Text('أدخل الرقم السري للدخول', style: TextStyle(color: Colors.white70, fontSize: 15))),
      const SizedBox(height: 20),
      AnimatedBuilder(
          animation: sh,
          builder: (_, ch) => Transform.translate(offset: Offset(sin(sh.value * pi * 8) * 14 * (1