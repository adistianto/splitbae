// SharedPreferences keys shared by UI settings and persistence layers.

/// On-disk SQLCipher vs plain SQLite for the local Drift database.
const kEncryptDatabasePreferenceKey = 'encrypt_database';

/// Cached result of [DynamicColorPlugin.getCorePalette] (Material You availability).
const kDynamicColorSupportedCachedKey = 'dynamic_color_supported_cached';

/// [DateTime] ms when [kDynamicColorSupportedCachedKey] was written.
const kDynamicColorSupportedCachedAtMsKey = 'dynamic_color_supported_cached_at_ms';
