import Foundation
import ScreenSaver

private extension String {
    static let lastQuote = "lastQuote"
    static let htmlRegex = "<a href=\"/\" rel=\"nofollow\" style=\"text-decoration: none; color: #333;\">(.+)</a>"
}

private extension URL {
    static let websiteUrl = URL(string: "http://developerexcuses.com")!
}

private extension UserDefaults {
    static var lastQuote: String? {
        get {
            return UserDefaults.standard.string(forKey: .lastQuote)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: .lastQuote)
            UserDefaults.standard.synchronize()
        }
    }
}

class DeveloperExcusesView: ScreenSaverView {
    let fetchQueue = DispatchQueue(label: "io.kida.DeveloperExcuses.fetchQueue")
    let mainQueue = DispatchQueue.main
    
    var quoteLabel: NSTextField!
    var clockLabel: NSTextField!
    var timer: Timer!
    var ticker = 0
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        quoteLabel = .quoteLabel(isPreview, bounds: frame)
        clockLabel = .clockLabel(isPreview, bounds: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        quoteLabel = .quoteLabel(isPreview, bounds: bounds)
        clockLabel = .clockLabel(isPreview, bounds: bounds)
        initialize()
    }
    
    override func configureSheet() -> NSWindow? {
        return nil
    }
    
    override func hasConfigureSheet() -> Bool {
        return false
    }
    
    override func draw(_ rect: NSRect) {
        super.draw(rect)
        
        var newFrame = quoteLabel.frame
        newFrame.origin.x = 0
        newFrame.origin.y = rect.size.height * 0.5
        newFrame.size.width = rect.size.width
        newFrame.size.height = (quoteLabel.stringValue as NSString).size(withAttributes: [NSFontAttributeName: quoteLabel.font!]).height
        quoteLabel.frame = newFrame
        
        var newClockFrame = clockLabel.frame
        newClockFrame.origin.x = 0
        newClockFrame.origin.y = rect.size.height * 0.03
        newClockFrame.size.width = rect.size.width
        newClockFrame.size.height = (clockLabel.stringValue as NSString).size(withAttributes: [NSFontAttributeName: clockLabel.font!]).height
        clockLabel.frame = newClockFrame
        
        NSColor.black.setFill()
        // NSColor.init(red:0.129, green:0.125, blue:0.141, alpha:1).setFill()
        NSRectFill(rect)
    }
    
    func initialize() {
        animationTimeInterval = 1
        addSubview(quoteLabel)
        addSubview(clockLabel)
        tick()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
    }
    
    func tick() {
        clockLabel.stringValue = NSDate.init().description(with: NSLocale.current)
        ticker += 1
        if ticker == 10 || quoteLabel.stringValue == "Loading…" {
            quoteLabel.stringValue = UserDefaults.lastQuote!
            fetchNext()
            ticker = 0
        }
        setNeedsDisplay(frame)
    }
    
    func setLastQuote(quote: String?) {
        if let q = quote {
            UserDefaults.lastQuote = q
        }
    }
    
    func fetchNext() {
        fetchQueue.async { [weak self] in
            guard let data = try? Data(contentsOf: .websiteUrl), let string = String(data: data, encoding: .utf8) else {
                return
            }

            guard let regex = try? NSRegularExpression(pattern: .htmlRegex, options: NSRegularExpression.Options(rawValue: 0)) else {
                return
            }

            let quotes = regex.matches(in: string, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: string.characters.count)).map { result in
                return (string as NSString).substring(with: result.rangeAt(1))
            }
            
            self?.mainQueue.async { [weak self] in
                self?.setLastQuote(quote: quotes.first)
            }
        }
    }
}

private extension NSTextField {
    static func quoteLabel(_ isPreview: Bool, bounds: CGRect) -> NSTextField {
        let label = NSTextField(frame: bounds)
        label.autoresizingMask = .viewWidthSizable
        label.alignment = .center
        label.stringValue = "Loading…"
        label.textColor = .white
        label.font = NSFont(name: "Menlo Regular", size: (isPreview ? 12.0 : 24.0))
        label.backgroundColor = .clear
        label.isEditable = false
        label.isBezeled = false
        return label
    }
    
    static func clockLabel(_ isPreview: Bool, bounds: CGRect) -> NSTextField {
        let label = NSTextField(frame: bounds)
        label.autoresizingMask = .viewWidthSizable
        label.alignment = .center
        label.stringValue = NSDate.init().description(with: NSLocale.current)
        label.textColor = NSColor.init(white: 1, alpha: 0.6)
        label.font = NSFont(name: "Menlo Regular", size: (isPreview ? 8.0 : 16.0))
        label.backgroundColor = .clear
        label.isEditable = false
        label.isBezeled = false
        return label
    }
}
