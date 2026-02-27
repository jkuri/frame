import CoreGraphics
import Foundation

struct ProjectMetadata: Codable, Sendable {
  var version: Int = 1
  var name: String?
  var createdAt: Date
  var fps: Int
  var screenSize: CodableSize
  var webcamSize: CodableSize?
  var hasSystemAudio: Bool
  var hasMicrophoneAudio: Bool
  var hasCursorMetadata: Bool = false
  var hasWebcam: Bool = false
  var captureMode: CaptureMode?
  var captureQuality: String? = nil
  var editorState: EditorStateData?
}

struct CursorSettingsData: Codable, Sendable, Equatable {
  var showCursor: Bool
  var cursorStyleRaw: Int
  var cursorSize: CGFloat
  var cursorFillColor: CodableColor?
  var cursorStrokeColor: CodableColor?
  var showClickHighlights: Bool = true
  var clickHighlightColor: CodableColor? = nil
  var clickHighlightSize: CGFloat = 36
}

struct ZoomSettingsData: Codable, Sendable, Equatable {
  var zoomEnabled: Bool = false
  var autoZoomEnabled: Bool
  var zoomFollowCursor: Bool = true
  var zoomLevel: Double
  var transitionDuration: Double
  var dwellThreshold: Double
  var keyframes: [ZoomKeyframe]
}

struct AnimationSettingsData: Codable, Sendable, Equatable {
  var cursorMovementEnabled: Bool = false
  var cursorMovementSpeed: CursorMovementSpeed = .medium
}

struct AudioSettingsData: Codable, Sendable, Equatable {
  var systemAudioVolume: Float = 1.0
  var micAudioVolume: Float = 1.0
  var systemAudioMuted: Bool = false
  var micAudioMuted: Bool = false
  var micNoiseReductionEnabled: Bool = false
  var micNoiseReductionIntensity: Float = 0.5
  var cachedNoiseReductionIntensity: Float?
}

struct AudioRegionData: Codable, Sendable, Identifiable, Equatable {
  var id: UUID = UUID()
  var startSeconds: Double
  var endSeconds: Double
}

enum RegionTransitionType: String, Codable, Sendable, CaseIterable, Identifiable {
  case none, fade, scale, slide

  var id: String { rawValue }

  var label: String {
    switch self {
    case .none: "None"
    case .fade: "Fade"
    case .scale: "Scale"
    case .slide: "Slide"
    }
  }
}

enum CameraRegionType: String, Codable, Sendable, CaseIterable, Identifiable {
  case fullscreen
  case hidden
  case custom

  var id: String { rawValue }

  var label: String {
    switch self {
    case .fullscreen: "Fullscreen"
    case .hidden: "Hidden"
    case .custom: "Custom"
    }
  }

  var icon: String {
    switch self {
    case .fullscreen: "arrow.up.left.and.arrow.down.right"
    case .hidden: "eye.slash"
    case .custom: "pip"
    }
  }
}

struct CameraRegionData: Codable, Sendable, Identifiable, Equatable {
  var id: UUID = UUID()
  var startSeconds: Double
  var endSeconds: Double
  var type: CameraRegionType = .fullscreen
  var customLayout: CameraLayout?
  var customCameraAspect: CameraAspect?
  var customCornerRadius: CGFloat?
  var customShadow: CGFloat?
  var customBorderWidth: CGFloat?
  var customBorderColor: CodableColor?
  var customMirrored: Bool?
  var entryTransition: RegionTransitionType?
  var entryTransitionDuration: Double?
  var exitTransition: RegionTransitionType?
  var exitTransitionDuration: Double?
}

struct VideoRegionData: Codable, Sendable, Identifiable, Equatable {
  var id: UUID = UUID()
  var startSeconds: Double
  var endSeconds: Double
  var entryTransition: RegionTransitionType?
  var entryTransitionDuration: Double?
  var exitTransition: RegionTransitionType?
  var exitTransitionDuration: Double?
}

struct CaptionSegment: Codable, Sendable, Identifiable, Equatable {
  var id: UUID = UUID()
  var startSeconds: Double
  var endSeconds: Double
  var text: String
  var words: [CaptionWord]?
}

struct CaptionWord: Codable, Sendable, Equatable {
  var word: String
  var startSeconds: Double
  var endSeconds: Double
}

enum CaptionPosition: String, Codable, Sendable, CaseIterable, Identifiable {
  case bottom, top, center

  var id: String { rawValue }

  var label: String {
    switch self {
    case .bottom: "Bottom"
    case .top: "Top"
    case .center: "Center"
    }
  }
}

enum CaptionFontWeight: String, Codable, Sendable, CaseIterable, Identifiable {
  case regular, medium, semibold, bold

  var id: String { rawValue }

  var label: String {
    switch self {
    case .regular: "Regular"
    case .medium: "Medium"
    case .semibold: "Semibold"
    case .bold: "Bold"
    }
  }
}

enum CaptionLanguage: String, Codable, Sendable, CaseIterable, Identifiable {
  case auto
  case en, zh, de, es, ru, ko, fr, ja, pt, tr, pl, ca, nl, ar, sv, it, id, hi, fi, vi, he, uk, el
  case ms, cs, ro, da, hu, ta, no, th, ur, hr, bg, lt, la, mi, ml, cy, sk, te, fa, lv, bn, sr, az
  case sl, kn, et, mk, br, eu, `is`, hy, ne, mn, bs, kk, sq, sw, gl, mr, pa, si, km, sn, yo, so
  case af, oc, ka, be, tg, sd, gu, am, yi, lo, uz, fo, ht, ps, tk, nn, mt, sa, lb, my, bo, tl
  case mg, `as`, tt, haw, ln, ha, ba, jw, su, yue

  var id: String { rawValue }

  var label: String {
    switch self {
    case .auto: "Auto-detect"
    case .en: "English"
    case .zh: "Chinese"
    case .de: "German"
    case .es: "Spanish"
    case .ru: "Russian"
    case .ko: "Korean"
    case .fr: "French"
    case .ja: "Japanese"
    case .pt: "Portuguese"
    case .tr: "Turkish"
    case .pl: "Polish"
    case .ca: "Catalan"
    case .nl: "Dutch"
    case .ar: "Arabic"
    case .sv: "Swedish"
    case .it: "Italian"
    case .id: "Indonesian"
    case .hi: "Hindi"
    case .fi: "Finnish"
    case .vi: "Vietnamese"
    case .he: "Hebrew"
    case .uk: "Ukrainian"
    case .el: "Greek"
    case .ms: "Malay"
    case .cs: "Czech"
    case .ro: "Romanian"
    case .da: "Danish"
    case .hu: "Hungarian"
    case .ta: "Tamil"
    case .no: "Norwegian"
    case .th: "Thai"
    case .ur: "Urdu"
    case .hr: "Croatian"
    case .bg: "Bulgarian"
    case .lt: "Lithuanian"
    case .la: "Latin"
    case .mi: "Maori"
    case .ml: "Malayalam"
    case .cy: "Welsh"
    case .sk: "Slovak"
    case .te: "Telugu"
    case .fa: "Persian"
    case .lv: "Latvian"
    case .bn: "Bengali"
    case .sr: "Serbian"
    case .az: "Azerbaijani"
    case .sl: "Slovenian"
    case .kn: "Kannada"
    case .et: "Estonian"
    case .mk: "Macedonian"
    case .br: "Breton"
    case .eu: "Basque"
    case .is: "Icelandic"
    case .hy: "Armenian"
    case .ne: "Nepali"
    case .mn: "Mongolian"
    case .bs: "Bosnian"
    case .kk: "Kazakh"
    case .sq: "Albanian"
    case .sw: "Swahili"
    case .gl: "Galician"
    case .mr: "Marathi"
    case .pa: "Punjabi"
    case .si: "Sinhala"
    case .km: "Khmer"
    case .sn: "Shona"
    case .yo: "Yoruba"
    case .so: "Somali"
    case .af: "Afrikaans"
    case .oc: "Occitan"
    case .ka: "Georgian"
    case .be: "Belarusian"
    case .tg: "Tajik"
    case .sd: "Sindhi"
    case .gu: "Gujarati"
    case .am: "Amharic"
    case .yi: "Yiddish"
    case .lo: "Lao"
    case .uz: "Uzbek"
    case .fo: "Faroese"
    case .ht: "Haitian Creole"
    case .ps: "Pashto"
    case .tk: "Turkmen"
    case .nn: "Nynorsk"
    case .mt: "Maltese"
    case .sa: "Sanskrit"
    case .lb: "Luxembourgish"
    case .my: "Myanmar"
    case .bo: "Tibetan"
    case .tl: "Tagalog"
    case .mg: "Malagasy"
    case .as: "Assamese"
    case .tt: "Tatar"
    case .haw: "Hawaiian"
    case .ln: "Lingala"
    case .ha: "Hausa"
    case .ba: "Bashkir"
    case .jw: "Javanese"
    case .su: "Sundanese"
    case .yue: "Cantonese"
    }
  }

  var whisperCode: String? {
    self == .auto ? nil : rawValue
  }

  static var sortedCases: [CaptionLanguage] {
    let rest = allCases.filter { $0 != .auto }.sorted { $0.label < $1.label }
    return [.auto] + rest
  }
}

enum CaptionAudioSource: String, Codable, Sendable, CaseIterable, Identifiable, Equatable {
  case microphone
  case system

  var id: String { rawValue }

  var label: String {
    switch self {
    case .microphone: "Microphone"
    case .system: "System Audio"
    }
  }
}

struct CaptionSettingsData: Codable, Sendable, Equatable {
  var enabled: Bool = true
  var fontSize: CGFloat = 48
  var fontWeight: CaptionFontWeight = .bold
  var textColor: CodableColor = CodableColor(r: 1, g: 1, b: 1)
  var backgroundColor: CodableColor = CodableColor(r: 0, g: 0, b: 0, a: 1.0)
  var backgroundOpacity: CGFloat = 0.6
  var showBackground: Bool = true
  var position: CaptionPosition = .bottom
  var maxWordsPerLine: Int = 6
  var model: String = "openai_whisper-base"
  var language: CaptionLanguage = .auto
  var audioSource: CaptionAudioSource = .microphone
}

struct EditorStateData: Codable, Sendable {
  var trimStartSeconds: Double
  var trimEndSeconds: Double
  var backgroundStyle: BackgroundStyle
  var backgroundImageFillMode: BackgroundImageFillMode?
  var canvasAspect: CanvasAspect?
  var padding: CGFloat
  var videoCornerRadius: CGFloat
  var cameraAspect: CameraAspect?
  var cameraCornerRadius: CGFloat
  var cameraBorderWidth: CGFloat
  var cameraBorderColor: CodableColor?
  var videoShadow: CGFloat?
  var cameraShadow: CGFloat?
  var cameraMirrored: Bool?
  var cameraFullscreenFillMode: CameraFullscreenFillMode?
  var cameraFullscreenAspect: CameraFullscreenAspect?
  var cameraLayout: CameraLayout
  var webcamEnabled: Bool?
  var cursorSettings: CursorSettingsData?
  var zoomSettings: ZoomSettingsData?
  var animationSettings: AnimationSettingsData?
  var audioSettings: AudioSettingsData?
  var systemAudioRegions: [AudioRegionData]?
  var micAudioRegions: [AudioRegionData]?
  var cameraRegions: [CameraRegionData]?
  var cameraFullscreenRegions: [AudioRegionData]?
  var videoRegions: [VideoRegionData]?
  var cameraBackgroundStyle: CameraBackgroundStyle?
  var captionSettings: CaptionSettingsData?
  var captionSegments: [CaptionSegment]?
}

struct CodableSize: Codable, Sendable {
  var width: CGFloat
  var height: CGFloat

  init(_ size: CGSize) {
    self.width = size.width
    self.height = size.height
  }

  var cgSize: CGSize {
    CGSize(width: width, height: height)
  }
}
