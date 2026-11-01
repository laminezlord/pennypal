import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core_lessons.dart';
import 'notification_service.dart';
import 'offline_queue.dart';
import 'gemini_service.dart';

class PennyPalService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static User? get currentUser => auth.currentUser;
  static Future<bool> isLoggedIn() async => auth.currentUser != null;

  static const categories = <String>[
    'Food', 'Transport', 'Education', 'Shopping', 'Entertainment', 'Bills', 'Savings', 'Miscellaneous'
  ];

  /// Income is recorded against its source (SRS: "source, amount, date and
  /// description") instead of an expense category.
  static const incomeSources = <String>[
    'Allowance', 'Scholarship', 'Part-time job', 'Internship', 'Gift', 'Other income'
  ];

  static String dateKey(DateTime d) => _dateKey(d);

  /// Cloud Storage needs the Firebase Blaze plan, which this project is not
  /// on, so receipt photos and lesson videos are hidden. Set to true after
  /// enabling Storage in the Firebase Console.
  static const storageEnabled = false;

  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _initialized = false;
  static bool _syncing = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await OfflineQueue.init();
    try {
      await PennyPalNotificationService.instance.initialize().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Notifications are optional; connectivity/offline sync must still start.
    }
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncPendingTransactions();
      }
    });
    // Best effort. Authentication may not be restored yet during app startup.
    unawaited(syncPendingTransactions());
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final email = '${data['email'] ?? ''}'.trim();
    final password = '${data['password'] ?? ''}';
    final first = '${data['first_name'] ?? ''}'.trim();
    final last = '${data['last_name'] ?? ''}'.trim();
    final mobile = '${data['mobile_number'] ?? ''}'.trim();
    if (first.isEmpty || last.isEmpty || email.isEmpty || mobile.isEmpty) throw Exception('Please complete all required fields.');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) throw Exception('Enter a valid email address.');
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(mobile.replaceAll(RegExp(r'[\s-]'), ''))) {
      throw Exception('Enter a valid mobile number (10 to 15 digits, optionally starting with +).');
    }
    if (password.length < 8) throw Exception('Password must contain at least 8 characters.');
    if (!RegExp(r'[A-Za-z]').hasMatch(password) || !RegExp(r'[0-9]').hasMatch(password)) {
      throw Exception('Password must include at least one letter and one number.');
    }
    final UserCredential credential;
    try {
      credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(friendlyAuthError(e));
    }
    final user = credential.user!;
    final fullName = '$first $last';
    await user.updateDisplayName(fullName);
    try {
      await db.collection('Users').doc(user.uid).set({
        'UserId': user.uid, 'FullName': fullName, 'Email': email, 'MobileNumber': mobile,
        'Role': 'student', 'CreatedAt': FieldValue.serverTimestamp(), 'LastLogin': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 4));
      await db.collection('UserProfiles').doc(user.uid).set({
        'ProfileId': user.uid, 'UserId': user.uid, 'StudentStatus': 'active',
        'CurrencyPreference': 'NGN', 'NotificationPreference': true, 'ProfileImage': null,
      }).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Authentication has already succeeded. Do not leave the user staring at
      // a spinner because Firestore is temporarily unavailable.
    }
    PennyPalGeminiService.resetConversation();
    unawaited(syncPendingTransactions());
    return {'uid': user.uid, 'user': user};
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final UserCredential credential;
    try {
      credential = await auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(friendlyAuthError(e));
    }
    final user = credential.user!;
    try {
      await db.collection('Users').doc(user.uid).set({'LastLogin': FieldValue.serverTimestamp()}, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Login should not depend on a non-critical LastLogin write.
    }
    PennyPalGeminiService.resetConversation();
    unawaited(syncPendingTransactions());
    return {'uid': user.uid, 'user': user};
  }

  /// Plain-language messages for Firebase Authentication error codes.
  static String friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Sign in instead.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static Future<void> logout() async {
    PennyPalGeminiService.resetConversation();
    await auth.signOut();
  }
  static Future<void> saveAuth(Map<String, dynamic> data) async {}

  static Map<String, dynamic> emptyDashboard() => {
    'income': 0,
    'expenses': 0,
    'balance': 0,
    'month_expenses': 0,
    'budget_total': 0,
    'budget_remaining': 0,
    'budget_percent': 0,
    'recent_transactions': <dynamic>[],
    'pending_sync_count': 0,
  };

  static Future<Map<String, dynamic>> dashboard() async {
    final results = await Future.wait<List<dynamic>>([
      transactions(),
      _allBudgets(),
    ]);
    final tx = results[0];
    final budgets = results[1];
    num income = 0, expenses = 0, monthExpenses = 0;
    final now = DateTime.now();
    for (final x in tx) {
      final amount = _num(x['amount']);
      if (x['type'] == 'INCOME') {
        income += amount;
      } else {
        expenses += amount;
        final d = DateTime.tryParse('${x['date']}');
        if (d != null && d.year == now.year && d.month == now.month) monthExpenses += amount;
      }
    }
    final month = _monthKey(now);
    num budget = 0;
    for (final b in budgets.where((x) => x['month'] == month)) {
      if ((b['category_id'] ?? 'TOTAL') == 'TOTAL') budget = _num(b['limit_amount']);
    }
    final percent = budget <= 0 ? 0 : (monthExpenses / budget * 100);
    return {
      'income': income, 'expenses': expenses, 'balance': income - expenses,
      'month_expenses': monthExpenses, 'budget_total': budget,
      'budget_remaining': budget - monthExpenses, 'budget_percent': percent.clamp(0, 999).round(),
      'recent_transactions': tx.take(5).toList(),
      'pending_sync_count': await OfflineQueue.pendingCount(),
    };
  }

  static Future<List<dynamic>> transactions() async {
    final query = db.collection('Transactions').where('UserId', isEqualTo: _uid);
    final snap = await _safeQuery(query);
    final cloud = snap?.docs.map(_withId).toList() ?? <dynamic>[];
    final pending = await OfflineQueue.pendingTransactions();
    final local = pending.map((x) => {
      'id': x['local_id'],
      'type': x['type'] ?? 'EXPENSE',
      'amount': _num(x['amount']),
      'category_detail': {'name': x['category_name'] ?? 'Miscellaneous'},
      'description': x['description'] ?? '',
      'date': x['date'] ?? '',
      'payment_mode': x['payment_mode'] ?? 'Cash',
      'pending_sync': true,
    }).toList();
    // A write can reach Firestore even though the client timed out and queued
    // it, so skip queued copies that already exist in the cloud.
    final cloudIds = cloud.map((x) => '${x['id']}').toSet();
    final list = <dynamic>[...local.where((x) => !cloudIds.contains('${x['id']}')), ...cloud];
    list.sort((a, b) => '${b['date']}'.compareTo('${a['date']}'));
    return list;
  }

  static Future<QuerySnapshot<Map<String, dynamic>>?> _safeQuery(
    Query<Map<String, dynamic>> query,
  ) async {
    // Server first: the local cache may only hold the few documents written in
    // this session, so returning it whenever it is non-empty hides older
    // records. The cache is used only when offline or when the server is slow.
    if (!await hasNetwork()) {
      try {
        return await query.get(const GetOptions(source: Source.cache));
      } catch (_) {
        return null;
      }
    }

    try {
      return await query.get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 8));
    } catch (_) {
      try {
        return await query.get(const GetOptions(source: Source.cache));
      } catch (_) {
        return null;
      }
    }
  }

  static Future<bool> hasNetwork() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  static Future<String?> uploadReceipt(XFile image) async {
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) return null;
    final ref = FirebaseStorage.instance.ref('receipts/$_uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  static Map<String, dynamic> _transactionPayload(Map<String, dynamic> d, String id) => {
    'TransactionId': id,
    'UserId': _uid,
    'Type': d['type'] ?? 'EXPENSE',
    'Amount': _num(d['amount']),
    'CategoryId': '${d['category_name'] ?? 'Miscellaneous'}',
    'CategoryName': '${d['category_name'] ?? 'Miscellaneous'}',
    'Description': '${d['description'] ?? ''}',
    'Date': '${d['date'] ?? _dateKey(DateTime.now())}',
    'PaymentMode': '${d['payment_mode'] ?? 'Cash'}',
    'ReceiptImageUrl': d['receipt_image_url'],
    'CreatedAt': FieldValue.serverTimestamp(),
  };

  static Future<Map<String, dynamic>> addTransaction(Map<String, dynamic> d) async {
    final type = d['type'] ?? 'EXPENSE';
    final category = '${d['category_name'] ?? 'Miscellaneous'}';
    final localId = 'offline_${DateTime.now().microsecondsSinceEpoch}';
    final localData = <String, dynamic>{
      'local_id': localId,
      'type': type,
      'amount': _num(d['amount']),
      'category_name': category,
      'description': '${d['description'] ?? ''}',
      'date': '${d['date'] ?? _dateKey(DateTime.now())}',
      'payment_mode': '${d['payment_mode'] ?? 'Cash'}',
      'receipt_image_url': d['receipt_image_url'],
    };

    if (!await hasNetwork()) {
      await OfflineQueue.queueTransaction(localData);
      return {'id': localId, ...d, 'pending_sync': true};
    }

    try {
      // Use the same deterministic id for the first write and any retry.
      // If a network timeout happens after Firestore accepted the write, the
      // offline retry becomes an idempotent set instead of a duplicate record.
      final ref = db.collection('Transactions').doc(localId);
      await ref.set(_transactionPayload(d, ref.id)).timeout(const Duration(seconds: 4));
      String? alert;
      if (type == 'EXPENSE') {
        try {
          alert = await budgetAlert(category).timeout(const Duration(seconds: 3));
        } catch (_) {}
      }
      if (alert != null && await _shouldNotifyBudget(category, alert)) {
        unawaited(PennyPalNotificationService.instance.showBudgetAlert(alert));
      }
      return {'id': ref.id, ...d, if (alert != null) 'budget_alert': alert};
    } catch (_) {
      // A connection can disappear after the connectivity check. Persist the
      // entry locally and let the connectivity listener retry it automatically.
      await OfflineQueue.queueTransaction(localData);
      return {'id': localId, ...d, 'pending_sync': true};
    }
  }

  static Future<int> syncPendingTransactions() async {
    if (_syncing || auth.currentUser == null || !await hasNetwork()) return 0;
    _syncing = true;
    try {
      final pending = await OfflineQueue.pendingTransactions();
      if (pending.isEmpty) return 0;

      final remaining = <Map<String, dynamic>>[];
      final syncedExpenseCategories = <String>{};
      var synced = 0;
      for (final item in pending) {
        try {
          final id = '${item['local_id']}';
          await db.collection('Transactions').doc(id).set({
            'TransactionId': id,
            'UserId': _uid,
            'Type': item['type'] ?? 'EXPENSE',
            'Amount': _num(item['amount']),
            'CategoryId': item['category_name'] ?? 'Miscellaneous',
            'CategoryName': item['category_name'] ?? 'Miscellaneous',
            'Description': item['description'] ?? '',
            'Date': item['date'] ?? _dateKey(DateTime.now()),
            'PaymentMode': item['payment_mode'] ?? 'Cash',
            'ReceiptImageUrl': item['receipt_image_url'],
            'CreatedAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 4));
          synced++;
          if ('${item['type']}' == 'EXPENSE') {
            syncedExpenseCategories.add('${item['category_name'] ?? 'Miscellaneous'}');
          }
        } catch (_) {
          remaining.add(item);
        }
      }

      // Preserve any transaction added while this sync pass was running.
      final currentQueue = await OfflineQueue.pendingTransactions();
      final remainingIds = remaining.map((x) => '${x['local_id']}').toSet();
      for (final item in currentQueue) {
        final id = '${item['local_id']}';
        if (remainingIds.add(id)) remaining.add(item);
      }
      await OfflineQueue.replacePending(remaining);
      for (final category in syncedExpenseCategories) {
        try {
          final alert = await budgetAlert(category).timeout(const Duration(seconds: 2));
          if (alert != null && await _shouldNotifyBudget(category, alert)) {
            unawaited(PennyPalNotificationService.instance.showBudgetAlert(alert));
          }
        } catch (_) {}
      }
      return synced;
    } finally {
      _syncing = false;
    }
  }

  static Future<bool> _shouldNotifyBudget(String category, String alert) async {
    final prefs = await SharedPreferences.getInstance();
    final month = _monthKey(DateTime.now());
    final key = 'budget_alert_${month}_${category.replaceAll(' ', '_').toLowerCase()}';
    final last = prefs.getInt(key) ?? 0;
    final match = RegExp(r'(\d+)%').firstMatch(alert);
    final current = int.tryParse(match?.group(1) ?? '0') ?? 0;
    final threshold = current >= 100 ? 100 : 80;
    if (current < threshold || current < last) return false;
    if (last >= threshold) return false;
    await prefs.setInt(key, threshold);
    return true;
  }

  static Future<void> updateTransaction(String id, Map<String, dynamic> d) => db.collection('Transactions').doc(id).update({
        if (d['type'] != null) 'Type': d['type'],
        if (d['amount'] != null) 'Amount': _num(d['amount']),
        if (d['category_name'] != null) 'CategoryId': d['category_name'],
        if (d['category_name'] != null) 'CategoryName': d['category_name'],
        if (d['description'] != null) 'Description': d['description'],
        if (d['date'] != null) 'Date': d['date'],
        if (d['payment_mode'] != null) 'PaymentMode': d['payment_mode'],
      }).timeout(const Duration(seconds: 5));

  static Future<void> deleteTransaction(String id) async {
    // Every transaction uses its offline_ id as the Firestore document id too
    // (see addTransaction), so the prefix does not mean "local only". Remove
    // any queued copy first so it cannot be re-uploaded, then delete the cloud
    // document as well.
    final items = await OfflineQueue.pendingTransactions();
    final wasQueued = items.any((x) => '${x['local_id']}' == id);
    if (wasQueued) {
      await OfflineQueue.replacePending(items.where((x) => '${x['local_id']}' != id).toList());
    }
    try {
      await db.collection('Transactions').doc(id).delete().timeout(const Duration(seconds: 5));
    } catch (_) {
      // A queued entry may never have reached the cloud; that is fine.
      if (!wasQueued) rethrow;
    }
  }

  static Future<String?> budgetAlert(String category) async {
    final month = _monthKey(DateTime.now());
    final all = await _allBudgets();
    Map<String, dynamic>? selected;
    for (final item in all) {
      if ('${item['month']}' == month && '${item['category_id']}' == category) {
        selected = item;
        break;
      }
    }
    if (selected == null) {
      for (final item in all) {
        if ('${item['month']}' == month && '${item['category_id']}' == 'TOTAL') {
          selected = item;
          break;
        }
      }
    }
    if (selected == null) return null;

    final limit = _num(selected['limit_amount']);
    if (limit <= 0) return null;
    final threshold = _num(selected['alert_threshold']);
    final isTotal = '${selected['category_id']}' == 'TOTAL';
    final categorySpent = (await transactions())
        .where((x) => x['type'] == 'EXPENSE' && '${x['date']}'.startsWith(month) &&
            (isTotal || '${x['category_detail']?['name'] ?? ''}' == category))
        .fold<num>(0, (total, x) => total + _num(x['amount']));
    if (categorySpent < limit * threshold / 100) return null;

    final percentage = (categorySpent / limit * 100).round();
    return '${isTotal ? 'Monthly budget' : category} is at $percentage% of its limit. Consider slowing spending or reviewing your plan.';
  }

  static Future<List<dynamic>> budgets() async => _allBudgets();
  static Future<List<dynamic>> _allBudgets() async {
    final snap = await _safeQuery(db.collection('Budgets').where('UserId', isEqualTo: _uid));
    final list = (snap?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
        .map(_withBudgetId).toList();
    list.sort((a, b) => '${b['month']}'.compareTo('${a['month']}'));
    return list;
  }

  static Future<Map<String, dynamic>> addBudget(Map<String, dynamic> d) async {
    final month = '${d['month'] ?? _monthKey(DateTime.now())}';
    final category = '${d['category_id'] ?? 'TOTAL'}';
    final snap = await db.collection('Budgets').where('UserId', isEqualTo: _uid).get().timeout(const Duration(seconds: 4));
    DocumentReference<Map<String, dynamic>>? existing;
    for (final doc in snap.docs) {
      final x = doc.data();
      if ('${x['Month']}' == month && '${x['CategoryId'] ?? 'TOTAL'}' == category) existing = doc.reference;
    }
    final ref = existing ?? db.collection('Budgets').doc();
    await ref.set({
      'BudgetId': ref.id, 'UserId': _uid, 'Month': month, 'CategoryId': category,
      'LimitAmount': _num(d['limit_amount']), 'AlertThreshold': _num(d['alert_threshold'] ?? 80),
      'CreatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
    return {'id': ref.id, ...d};
  }
  static Future<void> deleteBudget(String id) => db.collection('Budgets').doc(id).delete().timeout(const Duration(seconds: 5));

  static Future<List<dynamic>> goals() async {
    final snap = await _safeQuery(db.collection('SavingsGoals').where('UserId', isEqualTo: _uid));
    final docs = snap?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final list = docs.map((d) => _goalMap(d.id, d.data())).toList();
    list.sort((a, b) => '${a['target_date']}'.compareTo('${b['target_date']}'));
    return list;
  }

  static Map<String, dynamic> _goalMap(String id, Map<String, dynamic> x) {
    final target = _num(x['TargetAmount']);
    final current = _num(x['CurrentAmount']);
    final monthly = _num(x['MonthlyContribution']);
    final progress = target <= 0 ? 0 : (current / target * 100).clamp(0, 100);
    final remaining = (target - current).clamp(0, double.infinity);
    final estimatedMonths = monthly > 0 && remaining > 0 ? (remaining / monthly).ceil() : 0;
    final targetDate = DateTime.tryParse('${x['TargetDate']}');
    final daysRemaining = targetDate == null ? 0 : targetDate.difference(DateTime.now()).inDays;
    final milestone = progress >= 100 ? 100 : progress >= 75 ? 75 : progress >= 50 ? 50 : progress >= 25 ? 25 : 0;
    final badge = progress >= 100 ? 'Goal achieved' : progress >= 75 ? 'Almost there' : progress >= 50 ? 'Halfway hero' : progress >= 25 ? 'Great start' : 'Getting started';
    return {
      ...x,
      'id': id,
      'goal_name': x['GoalName'] ?? '',
      'target_amount': target,
      'current_amount': current,
      'target_date': x['TargetDate'],
      'monthly_contribution': monthly,
      'remaining': remaining,
      'progress': progress.round(),
      'status': x['Status'] ?? 'active',
      'estimated_months': estimatedMonths,
      'days_remaining': daysRemaining,
      'milestone': milestone,
      'badge': badge,
    };
  }

  static Future<Map<String, dynamic>> addGoal(Map<String, dynamic> d) async {
    final ref = db.collection('SavingsGoals').doc();
    await ref.set({'GoalId': ref.id, 'UserId': _uid, 'GoalName': d['goal_name'], 'TargetAmount': _num(d['target_amount']),
      'CurrentAmount': _num(d['current_amount'] ?? 0), 'TargetDate': d['target_date'],
      'MonthlyContribution': _num(d['monthly_contribution']), 'Status': 'active', 'CreatedAt': FieldValue.serverTimestamp()}).timeout(const Duration(seconds: 5));
    return {'id': ref.id, ...d};
  }

  static Future<void> contributeToGoal(String id, num amount) async {
    final doc = await db.collection('SavingsGoals').doc(id).get();
    if (!doc.exists) throw Exception('Savings goal not found.');
    final data = doc.data()!;
    final current = _num(data['CurrentAmount']);
    final target = _num(data['TargetAmount']);
    final next = (current + amount).clamp(0, target);
    await db.collection('SavingsGoals').doc(id).update({
      'CurrentAmount': next,
      'Status': next >= target ? 'completed' : 'active',
      'UpdatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 5));
  }

  static Future<void> archiveGoal(String id) => db.collection('SavingsGoals').doc(id).update({'Status': 'archived', 'UpdatedAt': FieldValue.serverTimestamp()}).timeout(const Duration(seconds: 5));
  static Future<void> restoreGoal(String id) => db.collection('SavingsGoals').doc(id).update({'Status': 'active', 'UpdatedAt': FieldValue.serverTimestamp()}).timeout(const Duration(seconds: 5));
  static Future<void> deleteGoal(String id) => db.collection('SavingsGoals').doc(id).delete().timeout(const Duration(seconds: 5));
  static Future<void> updateGoal(String id, Map<String, dynamic> d) => db.collection('SavingsGoals').doc(id).update({
        if (d['goal_name'] != null) 'GoalName': d['goal_name'],
        if (d['target_amount'] != null) 'TargetAmount': _num(d['target_amount']),
        if (d['current_amount'] != null) 'CurrentAmount': _num(d['current_amount']),
        if (d['target_date'] != null) 'TargetDate': d['target_date'],
        if (d['monthly_contribution'] != null) 'MonthlyContribution': _num(d['monthly_contribution']),
        if (d['status'] != null) 'Status': d['status'],
        'UpdatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));

  static Future<List<dynamic>> lessons() async {
    final snap = await _safeQuery(db.collection('LearningContent').where('IsActive', isEqualTo: true));
    final list = (snap?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]).map((d) {
      final x = d.data();
      return {...x, 'id': d.id, 'title': x['Title'] ?? '', 'topic': x['Topic'] ?? '', 'body': x['Body'] ?? '', 'difficulty': x['DifficultyLevel'] ?? 'Beginner', 'video_url': x['VideoUrl'] ?? ''};
    }).toList();
    list.sort((a, b) => '${a['title']}'.compareTo('${b['title']}'));
    // Built-in lessons come first so the Learn section is never empty.
    return [...coreLessons, ...list];
  }

  static Future<Map<String, dynamic>> report() async {
    final tx = await transactions();
    final byCategory = <String, num>{};
    final byMonth = <String, num>{};
    final monthlyIncome = <String, num>{};
    final monthlyExpense = <String, num>{};
    num totalIncome = 0;
    num totalExpense = 0;
    for (final x in tx) {
      final amount = _num(x['amount']);
      final date = '${x['date']}';
      final month = date.length >= 7 ? date.substring(0, 7) : 'Unknown';
      if (x['type'] == 'INCOME') {
        totalIncome += amount;
        monthlyIncome[month] = (monthlyIncome[month] ?? 0) + amount;
      } else {
        totalExpense += amount;
        final category = '${x['category_detail']?['name'] ?? 'Miscellaneous'}';
        byCategory[category] = (byCategory[category] ?? 0) + amount;
        byMonth[month] = (byMonth[month] ?? 0) + amount;
        monthlyExpense[month] = (monthlyExpense[month] ?? 0) + amount;
      }
    }
    final sortedCategories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {
      'by_category': byCategory,
      'by_month': byMonth,
      'monthly_income': monthlyIncome,
      'monthly_expense': monthlyExpense,
      'transactions': tx,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'balance': totalIncome - totalExpense,
      'top_category': sortedCategories.isEmpty ? null : sortedCategories.first.key,
    };
  }

  static Future<Map<String, dynamic>> assistant(String q) async {
    final question = q.trim();
    if (question.isEmpty) throw ArgumentError('Ask PennyPal a question.');

    Map<String, dynamic> context = emptyDashboard();
    try {
      context = await dashboard();
      final month = _monthKey(DateTime.now());
      final monthByCategory = <String, num>{};
      for (final x in await transactions()) {
        if (x['type'] != 'EXPENSE' || !'${x['date']}'.startsWith(month)) continue;
        final category = '${x['category_detail']?['name'] ?? 'Miscellaneous'}';
        monthByCategory[category] = (monthByCategory[category] ?? 0) + _num(x['amount']);
      }
      context['month_by_category'] = monthByCategory;
      context['goals'] = (await goals())
          .where((g) => g['status'] == 'active')
          .map((g) => '${g['goal_name']}: ${g['current_amount']} of ${g['target_amount']} saved (${g['progress']}%)')
          .toList();
    } catch (_) {
      // Gemini can still answer general educational questions when cloud data is unavailable.
    }

    try {
      final answer = await PennyPalGeminiService.ask(
        question: question,
        financialContext: context,
      );
      return {
        'answer': answer,
        'source': 'ai',
      };
    } catch (_) {
      // SRS requires a graceful fallback when the AI request times out/fails.
      final lower = question.toLowerCase();
      final answer = lower.contains('budget')
          ? 'Start with your income, separate needs from wants, set a realistic monthly limit, and review your progress before you reach the limit.'
          : lower.contains('save')
              ? 'Choose a clear savings goal, set a target date, and turn the remaining amount into a manageable monthly contribution.'
              : lower.contains('want') || lower.contains('need')
                  ? 'Needs are essential for daily life or study. Wants are optional purchases. Comparing both helps you make deliberate spending choices.'
                  : 'I can help with budgeting, saving, needs versus wants, spending limits, and the financial-learning topics inside PennyPal.';
      return {'answer': answer, 'source': 'educational-fallback'};
    }
  }

  static Future<void> support(String subject, String message) async => db.collection('SupportQueries').add({
        'UserId': _uid, 'Subject': subject.trim(), 'Message': message.trim(), 'Status': 'open', 'AdminResponse': null, 'SubmittedOn': FieldValue.serverTimestamp()
      }).timeout(const Duration(seconds: 5));
  static Future<void> feedback(String name, String email, int rating, String comments) async => db.collection('Feedback').add({
        'UserId': _uid, 'Name': name.trim(), 'Email': email.trim(), 'Rating': rating, 'Comments': comments.trim(), 'SubmittedOn': FieldValue.serverTimestamp()
      }).timeout(const Duration(seconds: 5));

  static Future<String> role() async {
    final doc = await db.collection('Users').doc(_uid).get().timeout(const Duration(seconds: 4));
    final data = doc.data() ?? <String, dynamic>{};
    // Accept both field spellings so manually provisioned admin accounts
    // remain compatible while the canonical field stays `Role`.
    return '${data['Role'] ?? data['role'] ?? 'student'}'.toLowerCase();
  }

  static Future<List<Map<String, dynamic>>> adminUsers() async {
    final snap = await db.collection('Users').get().timeout(const Duration(seconds: 5));
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  static Future<List<Map<String, dynamic>>> adminSupport() async {
    final snap = await db.collection('SupportQueries').get().timeout(const Duration(seconds: 5));
    final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    list.sort((a, b) => '${b['SubmittedOn']}'.compareTo('${a['SubmittedOn']}'));
    return list;
  }

  static Future<void> adminAddLesson({
    required String title,
    required String topic,
    required String body,
    required String difficulty,
    XFile? video,
  }) async {
    String? videoUrl;
    if (video != null) {
      final safeName = video.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final ref = FirebaseStorage.instance.ref('learning_videos/$_uid/${DateTime.now().millisecondsSinceEpoch}_$safeName');
      final bytes = await video.readAsBytes();
      if (bytes.length > 100 * 1024 * 1024) {
        throw Exception('Lesson videos must be 100 MB or smaller.');
      }
      final lower = safeName.toLowerCase();
      final contentType = lower.endsWith('.mov') ? 'video/quicktime' : lower.endsWith('.webm') ? 'video/webm' : 'video/mp4';
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      videoUrl = await ref.getDownloadURL();
    }
    await db.collection('LearningContent').add({
      'Title': title.trim(),
      'Topic': topic.trim(),
      'Body': body.trim(),
      'DifficultyLevel': difficulty,
      'VideoUrl': videoUrl,
      'IsActive': true,
      'CreatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 5));
  }

  static String get _uid => auth.currentUser?.uid ?? (throw Exception('Please sign in again.'));
  static Map<String, dynamic> _withId(DocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data() ?? {};
    return {'id': d.id, 'type': x['Type'] ?? 'EXPENSE', 'amount': _num(x['Amount']),
      'category_detail': {'name': x['CategoryName'] ?? x['CategoryId'] ?? 'Miscellaneous'},
      'description': x['Description'] ?? '', 'date': x['Date'] ?? '', 'payment_mode': x['PaymentMode'] ?? 'Cash'};
  }
  static Map<String, dynamic> _withBudgetId(DocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data() ?? {};
    return {'id': d.id, 'month': x['Month'] ?? '', 'limit_amount': _num(x['LimitAmount']), 'alert_threshold': _num(x['AlertThreshold']), 'category_id': x['CategoryId'] ?? 'TOTAL'};
  }
  static num _num(dynamic value) => num.tryParse('$value') ?? 0;
  static String _dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String _monthKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
}
