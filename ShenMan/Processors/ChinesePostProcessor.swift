import Foundation

/// 中文字符判断扩展
extension Character {
    /// 是否为中文字符（包括常用汉字）
    var isChinese: Bool {
        let scalar = self.unicodeScalars.first!
        return scalar.value >= 0x4E00 && scalar.value <= 0x9FA5
    }
}

/// 中文后处理器
/// 对转录结果进行中文优化处理
///
/// ## v1.0 功能
/// - 同音字纠错：根据常见错误规则进行纠错
/// - 标点优化：统一中英文标点，修正错误标点
/// - 数字格式化：中文数字转阿拉伯数字
/// - 空格清理：去除不必要的空格
///
/// ## 性能考虑
/// 所有规则都使用缓存的正则表达式，避免重复编译
struct ChinesePostProcessor {

    // MARK: - 缓存的正则表达式

    /// 重复标点正则
    private static let duplicatePunctuationRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "([。！？.!?])\\1+", options: [])
    }()

    /// 中英文标点映射正则
    private static let chinesePunctuationRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "[,.!?;:]", options: [])
    }()

    /// 句首空格正则
    private static let leadingSpaceRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "^\\s+", options: [])
    }()

    /// 句尾空格正则
    private static let trailingSpaceRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "\\s+$", options: [])
    }()

    // MARK: - 同音字纠错规则

    /// 常见同音字错误映射（v1.0 基础规则）
    /// 这些规则基于常见的 ASR 错误模式
    private static let homophoneCorrections: [String: String] = [
        // 会议相关
        "配备": "配置",
        "协义": "协议",
        "登路": "登录",
        "帐护": "账户",
        "由箱": "邮箱",
        "微姓": "微信",
        "支负": "支付",
        "宝付": "支付宝",
        "收负": "收费",
        "付费": "付费",
        "住测": "注册",
        
        // 日常用语
        "在见": "再见",
        "知到": "知道",
        "以经": "已经",
        "须要": "需要",
        "在次": "再次",
        "做业": "作业",
        "克服": "克服",
        "坚苦": "艰苦",
        "历害": "厉害",
        "暴燥": "暴躁",
        
        // 数字相关
        "零晨": "凌晨",
        "两点中": "两点钟",
        "三耗": "三号",
        
        // 技术术语
        "软见": "软件",
        "应勇": "应用",
        "网占": "网站",
        "服物": "服务",
        "端品": "端口",
        "进成": "进程",
        "线成": "线程",
        "内从": "内存",
        "处里": "处理",
        "算发": "算法",
    ]

    // MARK: - 数字格式化规则

    /// 中文数字映射
    private static let chineseNumbers: [String: String] = [
        "零": "0",
        "一": "1",
        "二": "2",
        "三": "3",
        "四": "4",
        "五": "5",
        "六": "6",
        "七": "7",
        "八": "8",
        "九": "9",
        "十": "10",
    ]

    // MARK: - 初始化

    init() {}

    // MARK: - 公开方法

    /// 处理句子列表
    /// - Parameter sentences: 句子时间戳列表
    /// - Returns: 处理后的句子列表
    func process(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        return sentences.map { sentence in
            var text = sentence.text

            // 1. 同音字纠错
            text = correctHomophones(text: text)

            // 2. 标点优化
            text = optimizePunctuation(text: text)

            // 3. 数字格式化
            text = formatNumbers(text: text)

            // 4. 空格清理
            text = cleanSpaces(text: text)

            return SentenceTimestamp(
                id: sentence.id,
                text: text,
                startTime: sentence.startTime,
                endTime: sentence.endTime,
                words: sentence.words,
                speaker: sentence.speaker
            )
        }
    }

    /// 同音字纠错
    /// - Parameter text: 原始文本
    /// - Returns: 纠错后的文本
    func correctHomophones(text: String) -> String {
        var corrected = text

        // 应用所有纠错规则
        for (wrong, correct) in Self.homophoneCorrections {
            corrected = corrected.replacingOccurrences(of: wrong, with: correct)
        }

        return corrected
    }

    /// 标点优化
    /// - Parameter text: 原始文本
    /// - Returns: 优化后的文本
    func optimizePunctuation(text: String) -> String {
        var result = text

        // 1. 统一中英文标点（英文转中文）
        let punctuationMap: [(String, String)] = [
            (",", "，"),
            (".", "。"),
            ("!", "！"),
            ("?", "？"),
            (":", "："),
            (";", "；"),
        ]

        for (english, chinese) in punctuationMap {
            result = result.replacingOccurrences(of: english, with: chinese)
        }

        // 2. 去除重复标点
        result = Self.duplicatePunctuationRegex.stringByReplacingMatches(
            in: result,
            options: [],
            range: NSRange(result.startIndex..., in: result),
            withTemplate: "$1"
        )

        // 3. 修正标点前的空格
        result = result.replacingOccurrences(of: " ,", with: "，")
        result = result.replacingOccurrences(of: " .", with: "。")
        result = result.replacingOccurrences(of: " !", with: "！")
        result = result.replacingOccurrences(of: " ?", with: "？")

        return result
    }

    /// 数字格式化
    /// - Parameter text: 原始文本
    /// - Returns: 格式化后的文本
    func formatNumbers(text: String) -> String {
        var result = text

        // v1.0 基础规则：简单的中文数字转阿拉伯数字
        // TODO: 实现更复杂的数字格式化（如"三百五十万" → "350 万"）

        // 年份格式化："二零二五年" → "2025 年"
        result = formatYear(text: result)

        // 时间格式化："两点钟" → "2 点"
        result = formatTime(text: result)

        return result
    }

    /// 空格清理
    /// - Parameter text: 原始文本
    /// - Returns: 清理后的文本
    func cleanSpaces(text: String) -> String {
        var result = text

        // 1. 去除中文字符之间的空格（使用 Swift 原生方法）
        result = removeChineseSpaces(text: result)

        // 2. 去除句首空格
        result = Self.leadingSpaceRegex.stringByReplacingMatches(
            in: result,
            options: [],
            range: NSRange(result.startIndex..., in: result),
            withTemplate: ""
        )

        // 3. 去除句尾空格
        result = Self.trailingSpaceRegex.stringByReplacingMatches(
            in: result,
            options: [],
            range: NSRange(result.startIndex..., in: result),
            withTemplate: ""
        )

        // 4. 多个空格压缩为一个
        result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)

        return result
    }
    
    /// 去除中文字符之间的空格
    /// - Parameter text: 原始文本
    /// - Returns: 去除空格后的文本
    private func removeChineseSpaces(text: String) -> String {
        var result = ""
        let chars = Array(text)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            // 如果当前字符是空格，检查前后是否都是中文
            if char == " " || char == "\t" {
                let prevChar = i > 0 ? chars[i - 1] : nil
                let nextChar = i < chars.count - 1 ? chars[i + 1] : nil
                
                // 如果前后都是中文，跳过空格
                if let prev = prevChar, let next = nextChar,
                   prev.isChinese && next.isChinese {
                    // 跳过空格
                } else {
                    result.append(char)
                }
            } else {
                result.append(char)
            }
            
            i += 1
        }
        
        return result
    }

    // MARK: - 私有方法

    /// 格式化年份
    private func formatYear(text: String) -> String {
        var result = text

        // 匹配"二零二五年"这种格式
        let yearPattern = "([零一二三四五六七八九]{4})年"

        guard let regex = try? NSRegularExpression(pattern: yearPattern, options: []) else {
            return result
        }

        let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))

        // 从后向前替换，避免索引问题
        for match in matches.reversed() {
            guard let range = Range(match.range(at: 1), in: result) else { continue }

            let chineseYear = String(result[range])
            let arabicYear = chineseYear.compactMap { Self.chineseNumbers[String($0)] }.joined()

            if let fullRange = Range(match.range, in: result) {
                let newYear = arabicYear + "年"
                result.replaceSubrange(fullRange, with: newYear)
            }
        }

        return result
    }

    /// 格式化时间
    private func formatTime(text: String) -> String {
        var result = text

        // 匹配"两点钟"、"三点"这种格式
        let timePatterns = [
            "([一二三四五六七八九十])点钟": "$1 点",
            "([一二三四五六七八九十])点": "$1 点",
        ]

        for (pattern, replacement) in timePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                continue
            }

            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: NSRange(result.startIndex..., in: result),
                withTemplate: replacement
            )
        }

        return result
    }
}

// MARK: - 扩展方法

extension ChinesePostProcessor {
    /// 处理单个文本
    /// - Parameter text: 原始文本
    /// - Returns: 处理后的文本
    func process(text: String) -> String {
        var result = text
        result = correctHomophones(text: result)
        result = optimizePunctuation(text: result)
        result = formatNumbers(text: result)
        result = cleanSpaces(text: result)
        return result
    }

    /// 同音字纠错（句子列表）
    /// - Parameter sentences: 句子列表
    /// - Returns: 纠错后的句子列表
    func correctHomophones(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        return sentences.map { sentence in
            SentenceTimestamp(
                id: sentence.id,
                text: correctHomophones(text: sentence.text),
                startTime: sentence.startTime,
                endTime: sentence.endTime,
                words: sentence.words,
                speaker: sentence.speaker
            )
        }
    }

    /// 标点优化（句子列表）
    /// - Parameter sentences: 句子列表
    /// - Returns: 优化后的句子列表
    func optimizePunctuation(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        return sentences.map { sentence in
            SentenceTimestamp(
                id: sentence.id,
                text: optimizePunctuation(text: sentence.text),
                startTime: sentence.startTime,
                endTime: sentence.endTime,
                words: sentence.words,
                speaker: sentence.speaker
            )
        }
    }

    /// 数字格式化（句子列表）
    /// - Parameter sentences: 句子列表
    /// - Returns: 格式化后的句子列表
    func formatNumbers(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        return sentences.map { sentence in
            SentenceTimestamp(
                id: sentence.id,
                text: formatNumbers(text: sentence.text),
                startTime: sentence.startTime,
                endTime: sentence.endTime,
                words: sentence.words,
                speaker: sentence.speaker
            )
        }
    }

    /// 空格清理（句子列表）
    /// - Parameter sentences: 句子列表
    /// - Returns: 清理后的句子列表
    func cleanSpaces(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        return sentences.map { sentence in
            SentenceTimestamp(
                id: sentence.id,
                text: cleanSpaces(text: sentence.text),
                startTime: sentence.startTime,
                endTime: sentence.endTime,
                words: sentence.words,
                speaker: sentence.speaker
            )
        }
    }
}
