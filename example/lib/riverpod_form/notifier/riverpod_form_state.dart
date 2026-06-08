import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contact form state managed by Riverpod [AsyncNotifier].
///
/// Uses Riverpod's native [AsyncValue] to represent states:
/// - [AsyncData(null)]  → initial / reset
/// - [AsyncLoading]     → submitting
/// - [AsyncData(Map)]   → success with returned data
/// - [AsyncError]       → failure with error message
typedef RiverpodFormState = AsyncValue<Map<String, dynamic>?>;
