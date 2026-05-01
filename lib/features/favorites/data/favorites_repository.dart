import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FavoriteType { flight, airline, airport }

class FavoriteItem {
  final String id; // callsign, airline ICAO, or airport ICAO
  final FavoriteType type;
  final String label;
  final String? subtitle;
  final DateTime addedAt;

  /// Pinned items float to the top of every favorites list. Mirrors the
  /// web frontend's `togglePin` / `pinned` shape so a user who pinned a
  /// flight in the web app sees it first when they open the mobile
  /// favorites screen too (after future state-sync work).
  final bool pinned;

  FavoriteItem({
    required this.id,
    required this.type,
    required this.label,
    this.subtitle,
    this.pinned = false,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Build a copy with one or more fields overridden. Used internally
  /// by [FavoritesNotifier.togglePin] without breaking the immutable
  /// model semantics expected by Riverpod.
  FavoriteItem copyWith({bool? pinned}) => FavoriteItem(
        id: id,
        type: type,
        label: label,
        subtitle: subtitle,
        pinned: pinned ?? this.pinned,
        addedAt: addedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'label': label,
        'subtitle': subtitle,
        'addedAt': addedAt.toIso8601String(),
        'pinned': pinned,
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        id: json['id'] as String,
        type: FavoriteType.values[json['type'] as int],
        label: json['label'] as String,
        subtitle: json['subtitle'] as String?,
        // `pinned` was added in v2 of the favourites schema. Older
        // serialised payloads silently default to `false`, no migration
        // needed.
        pinned: (json['pinned'] as bool?) ?? false,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}

class FavoritesNotifier extends Notifier<List<FavoriteItem>> {
  static const _key = 'favorites_v1';

  @override
  List<FavoriteItem> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => FavoriteItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  bool isFavorite(String id) => state.any((f) => f.id == id);

  /// Whether the given id is currently pinned. Returns false for items
  /// that aren't favourited at all — callers can safely use this to
  /// decide whether to render a "filled pin" icon.
  bool isPinned(String id) =>
      state.firstWhere(
        (f) => f.id == id,
        orElse: () => FavoriteItem(
          id: '',
          type: FavoriteType.flight,
          label: '',
        ),
      ).pinned;

  void toggle(FavoriteItem item) {
    if (isFavorite(item.id)) {
      state = state.where((f) => f.id != item.id).toList();
    } else {
      state = [...state, item];
    }
    _save();
  }

  /// Flip the `pinned` flag on a single favourite. Idempotent across
  /// re-pins — no error if the id doesn't exist (matches web behaviour
  /// of `togglePin` which silently no-ops on missing ids).
  void togglePin(String id) {
    state = state
        .map((f) => f.id == id ? f.copyWith(pinned: !f.pinned) : f)
        .toList();
    _save();
  }

  void remove(String id) {
    state = state.where((f) => f.id != id).toList();
    _save();
  }

  /// Return the favourites of `type`, with pinned items floating to the
  /// top. Within each section (pinned / unpinned) entries keep their
  /// original `addedAt`-descending order so the list doesn't shuffle on
  /// every render. Mirrors the sort behaviour the web's
  /// `useSavedGroups` hook applies before render.
  List<FavoriteItem> byType(FavoriteType type) {
    final items = state.where((f) => f.type == type).toList();
    items.sort((a, b) {
      // Pinned first.
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      // Then most-recently-added first.
      return b.addedAt.compareTo(a.addedAt);
    });
    return items;
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<FavoriteItem>>(
        FavoritesNotifier.new);
