/// How much media the app is willing to send, in one place.
///
/// These are the *capture* limits, applied where the user picks a file, which
/// is the only point at which size can still be influenced from the client:
/// `image_picker` resizes and re-encodes photos itself, and caps a video by
/// duration. Compression proper happens on the server, where Cloudinary
/// re-encodes on the way into storage.
///
/// The numbers matter because a phone shoots 1080p at roughly 7.7 Mbps — a
/// measured figure, taken from a crash report carrying a tester's real
/// recording format. At that rate a minute of video is about 58 MB, and the
/// picker used to allow five minutes of it: a ~290 MB upload over a mobile
/// connection, past the point where Cloudinary accepts a single upload at all.
/// That is the upload that reached 100% and then failed.
library;

/// Longest video a post or reel may carry.
///
/// Riff's video surface is reels — short-form by design — so a minute is the
/// product limit as much as a technical one. Raising it raises upload failures
/// on slow connections roughly in proportion.
const Duration kMaxPostVideoDuration = Duration(minutes: 1);

/// Longest video that can be sent in a chat. Shorter than a post: a message is
/// a glance, and chat media is never re-encoded as aggressively.
const Duration kMaxChatVideoDuration = Duration(seconds: 45);

/// Longest edge kept for a picked photo, in pixels.
///
/// The feed never renders wider than about 1080 logical pixels; 1600 leaves
/// room for a high-density screen without storing a camera's full sensor size.
const double kMaxImageDimension = 1600;

/// JPEG quality for picked photos, 0–100.
const int kImageQuality = 85;
