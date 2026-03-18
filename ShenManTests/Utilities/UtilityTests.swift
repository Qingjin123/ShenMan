import XCTest
@testable import ShenMan

// MARK: - TimeFormatter 测试

final class TimeFormatterTests: XCTestCase {
    
    // MARK: - formatTime 测试
    
    func testFormatTimeZero() {
        XCTAssertEqual(TimeFormatter.formatTime(0), "00:00")
    }
    
    func testFormatTimeFiveSeconds() {
        XCTAssertEqual(TimeFormatter.formatTime(5), "00:05")
    }
    
    func testFormatTimeOneMinute() {
        XCTAssertEqual(TimeFormatter.formatTime(65), "01:05")
    }
    
    func testFormatTimeOneHour() {
        XCTAssertEqual(TimeFormatter.formatTime(3665), "01:01:05")
    }
    
    func testFormatTimeNegative() {
        XCTAssertEqual(TimeFormatter.formatTime(-1), "00:00")
    }
    
    // MARK: - formatTimeWithMilliseconds 测试
    
    func testFormatTimeWithMillisecondsZero() {
        XCTAssertEqual(TimeFormatter.formatTimeWithMilliseconds(0), "00:00.000")
    }
    
    func testFormatTimeWithMilliseconds() {
        XCTAssertEqual(TimeFormatter.formatTimeWithMilliseconds(1.5), "00:01.500")
    }
    
    func testFormatTimeWithMillisecondsComplex() {
        XCTAssertEqual(TimeFormatter.formatTimeWithMilliseconds(65.123), "01:05.123")
    }
    
    func testFormatTimeWithMillisecondsHour() {
        XCTAssertEqual(TimeFormatter.formatTimeWithMilliseconds(3665.999), "01:01:05.999")
    }
    
    // MARK: - formatSRTTime 测试
    
    func testFormatSRTTimeZero() {
        XCTAssertEqual(TimeFormatter.formatSRTTime(0), "00:00:00,000")
    }
    
    func testFormatSRTTimeOneSecond() {
        XCTAssertEqual(TimeFormatter.formatSRTTime(1.5), "00:00:01,500")
    }
    
    func testFormatSRTTimeOneMinute() {
        XCTAssertEqual(TimeFormatter.formatSRTTime(65.123), "00:01:05,123")
    }
    
    // MARK: - formatTimestamp 测试
    
    func testFormatTimestampSeconds() {
        let options = ExportOptions(timestampPrecision: .seconds)
        let result = TimeFormatter.formatTimestamp(65.123, options: options)
        XCTAssertEqual(result, "[00:02]")
    }
    
    func testFormatTimestampMilliseconds() {
        let options = ExportOptions(timestampPrecision: .milliseconds)
        let result = TimeFormatter.formatTimestamp(65.123, options: options)
        XCTAssertEqual(result, "[00:01.123]")
    }
    
    // MARK: - formatRemainingTime 测试
    
    func testFormatRemainingTimeSeconds() {
        XCTAssertEqual(TimeFormatter.formatRemainingTime(30), "30 秒")
    }
    
    func testFormatRemainingTimeMinutes() {
        XCTAssertEqual(TimeFormatter.formatRemainingTime(150), "2 分 30 秒")
    }
    
    func testFormatRemainingTimeHours() {
        XCTAssertEqual(TimeFormatter.formatRemainingTime(7350), "2 小时 2 分")
    }
}

// MARK: - Constants 测试

final class ConstantsTests: XCTestCase {
    
    // MARK: - 应用信息测试
    
    func testAppName() {
        XCTAssertEqual(Constants.appName, "声声慢")
    }
    
    func testAppVersion() {
        XCTAssertEqual(Constants.appVersion, "1.0.0")
    }
    
    // MARK: - 格式列表测试
    
    func testSupportedAudioFormats() {
        XCTAssertTrue(Constants.supportedAudioFormats.contains("mp3"))
        XCTAssertTrue(Constants.supportedAudioFormats.contains("wav"))
        XCTAssertTrue(Constants.supportedAudioFormats.contains("m4a"))
        XCTAssertTrue(Constants.supportedAudioFormats.contains("flac"))
        XCTAssertTrue(Constants.supportedAudioFormats.contains("aac"))
    }
    
    func testSupportedVideoFormats() {
        XCTAssertTrue(Constants.supportedVideoFormats.contains("mp4"))
        XCTAssertTrue(Constants.supportedVideoFormats.contains("mov"))
        XCTAssertTrue(Constants.supportedVideoFormats.contains("avi"))
        XCTAssertTrue(Constants.supportedVideoFormats.contains("mkv"))
    }
    
    // MARK: - 默认模型测试
    
    func testDefaultASRModel() {
        XCTAssertEqual(Constants.defaultASRModel, .qwen3ASR06B8bit)
    }
    
    func testAvailableASRModels() {
        XCTAssertEqual(Constants.availableASRModels.count, 3)
        XCTAssertTrue(Constants.availableASRModels.contains(.qwen3ASR06B8bit))
        XCTAssertTrue(Constants.availableASRModels.contains(.qwen3ASR17B8bit))
        XCTAssertTrue(Constants.availableASRModels.contains(.glmASRNano4bit))
    }
    
    // MARK: - UI 常量测试
    
    func testMinWindowWidth() {
        XCTAssertEqual(Constants.minWindowWidth, 900)
    }
    
    func testMinWindowHeight() {
        XCTAssertEqual(Constants.minWindowHeight, 600)
    }
    
    // MARK: - Spacing 测试
    
    func testSpacingCases() {
        XCTAssertEqual(Constants.Spacing.xs.rawValue, 4)
        XCTAssertEqual(Constants.Spacing.sm.rawValue, 8)
        XCTAssertEqual(Constants.Spacing.md.rawValue, 12)
        XCTAssertEqual(Constants.Spacing.lg.rawValue, 16)
        XCTAssertEqual(Constants.Spacing.xl.rawValue, 20)
        XCTAssertEqual(Constants.Spacing.xxl.rawValue, 24)
    }
    
    // MARK: - 转录常量测试
    
    func testDefaultSampleRate() {
        XCTAssertEqual(Constants.defaultSampleRate, 16000)
    }
    
    func testPauseThreshold() {
        XCTAssertEqual(Constants.pauseThreshold, 0.5)
    }
    
    func testMaxFileSize() {
        XCTAssertEqual(Constants.maxFileSize, 2 * 1024 * 1024 * 1024) // 2GB
    }
    
    // MARK: - ModelIdentifier 测试
    
    func testModelIdentifierAllCases() {
        let allCases = ModelIdentifier.allCases
        XCTAssertEqual(allCases.count, 3)
    }
    
    func testModelIdentifierRawValues() {
        XCTAssertEqual(ModelIdentifier.qwen3ASR06B8bit.rawValue, "mlx-community/Qwen3-ASR-0.6B-8bit")
        XCTAssertEqual(ModelIdentifier.qwen3ASR17B8bit.rawValue, "mlx-community/Qwen3-ASR-1.7B-8bit")
        XCTAssertEqual(ModelIdentifier.glmASRNano4bit.rawValue, "mlx-community/GLM-ASR-Nano-2512-4bit")
    }
    
    func testModelIdentifierDisplayNames() {
        XCTAssertEqual(ModelIdentifier.qwen3ASR06B8bit.displayName, "Qwen3-ASR 0.6B (8bit)")
        XCTAssertEqual(ModelIdentifier.qwen3ASR17B8bit.displayName, "Qwen3-ASR 1.7B (8bit)")
        XCTAssertEqual(ModelIdentifier.glmASRNano4bit.displayName, "GLM-ASR Nano (4bit)")
    }
    
    func testModelIdentifierSizes() {
        XCTAssertEqual(ModelIdentifier.qwen3ASR06B8bit.sizeGB, 0.6)
        XCTAssertEqual(ModelIdentifier.qwen3ASR17B8bit.sizeGB, 1.7)
        XCTAssertEqual(ModelIdentifier.glmASRNano4bit.sizeGB, 0.3)
    }
    
    func testModelIdentifierSupportedLanguages() {
        let model = ModelIdentifier.qwen3ASR06B8bit
        XCTAssertTrue(model.supportedLanguages.contains(.auto))
        XCTAssertTrue(model.supportedLanguages.contains(.chinese))
    }
    
    func testModelIdentifierIsGLM() {
        XCTAssertTrue(ModelIdentifier.glmASRNano4bit.isGLM)
        XCTAssertFalse(ModelIdentifier.qwen3ASR06B8bit.isGLM)
    }
    
    func testModelIdentifierIsQwen() {
        XCTAssertTrue(ModelIdentifier.qwen3ASR06B8bit.isQwen)
        XCTAssertFalse(ModelIdentifier.glmASRNano4bit.isQwen)
    }
}

// MARK: - AudioMetadataReader 测试

final class AudioMetadataReaderTests: XCTestCase {
    
    // MARK: - validateFormat 测试
    
    func testValidateFormatSupported() {
        XCTAssertTrue(AudioMetadataReader.validateFormat(extension: "mp3"))
        XCTAssertTrue(AudioMetadataReader.validateFormat(extension: "wav"))
        XCTAssertTrue(AudioMetadataReader.validateFormat(extension: "m4a"))
        XCTAssertTrue(AudioMetadataReader.validateFormat(extension: "mp4"))
    }
    
    func testValidateFormatUnsupported() {
        XCTAssertFalse(AudioMetadataReader.validateFormat(extension: "txt"))
        XCTAssertFalse(AudioMetadataReader.validateFormat(extension: "pdf"))
        XCTAssertFalse(AudioMetadataReader.validateFormat(extension: "exe"))
    }
    
    func testValidateFormatCaseInsensitive() {
        XCTAssertTrue(AudioMetadataReader.validateFormat(extension: "MP3"))
        XCTAssertTrue(AudioMetadataReader.validateFormat(extension: "Wav"))
        XCTAssertTrue(AudioMetadataReader.validateFormat(extension: "M4A"))
    }
}

// MARK: - FileSizeFormatter 测试

final class FileSizeFormatterTests: XCTestCase {
    
    func testFormatBytes() {
        XCTAssertEqual(FileSizeFormatter.format(0), "0 B")
        XCTAssertEqual(FileSizeFormatter.format(1), "1 B")
        XCTAssertEqual(FileSizeFormatter.format(1023), "1023 B")
    }
    
    func testFormatKilobytes() {
        XCTAssertEqual(FileSizeFormatter.format(1024), "1 KB")
        XCTAssertEqual(FileSizeFormatter.format(1536), "1.5 KB")
        XCTAssertEqual(FileSizeFormatter.format(1024 * 1024 - 1), "1024 KB")
    }
    
    func testFormatMegabytes() {
        XCTAssertEqual(FileSizeFormatter.format(1024 * 1024), "1 MB")
        XCTAssertEqual(FileSizeFormatter.format(1.5 * 1024 * 1024), "1.5 MB")
        XCTAssertEqual(FileSizeFormatter.format(1024 * 1024 * 1024 - 1), "1024 MB")
    }
    
    func testFormatGigabytes() {
        XCTAssertEqual(FileSizeFormatter.format(1024 * 1024 * 1024), "1 GB")
        XCTAssertEqual(FileSizeFormatter.format(1.5 * 1024 * 1024 * 1024), "1.5 GB")
    }
}
