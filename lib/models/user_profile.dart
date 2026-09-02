/// A user's profile information shown on the Profile page.
///
/// Plain, immutable value type for the current UI-mockup phase — no real
/// authentication exists yet ("Authentication (Profile - optional)" per
/// the module plan), so this is seeded with dummy data rather than loaded
/// from a real account.
class UserProfile {
  /// Creates a [UserProfile].
  const UserProfile({
    required this.name,
    required this.email,
    required this.joinDate,
    this.avatarUrl,
  });

  /// Display name.
  final String name;

  /// Account email.
  final String email;

  /// When the account was created.
  final DateTime joinDate;

  /// Optional profile photo URL.
  ///
  /// Always `null` in this mockup phase (no image upload/auth exists yet),
  /// so the UI always falls back to [initials] — the field is kept here so
  /// [ProfileHeaderCard] doesn't need reworking once real photos exist.
  final String? avatarUrl;

  /// Up to two initials derived from [name], used as the avatar when
  /// [avatarUrl] is null.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Returns a copy of this profile with the given fields replaced.
  UserProfile copyWith({String? name, String? email}) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      joinDate: joinDate,
      avatarUrl: avatarUrl,
    );
  }
}
