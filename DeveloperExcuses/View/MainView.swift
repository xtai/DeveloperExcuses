//
//  ExcuseView.swift
//  DeveloperExcuses
//
//  Created by Marcus Kida on 31/03/2016.
//  Copyright © 2016 Marcus Kida. All rights reserved.
//

import Cocoa
import ScreenSaver
import Alamofire
import Fuzi

extension Selector {
    static let animateOneFrame = #selector(MainView.animateOneFrame)
}

class MainView: ScreenSaverView {
    
    var textField: NSTextField?
    var locked: Bool? = false
    
    func activeScreenRects() -> [NSRect]? {
        return NSScreen.screens()?.map { $0.visibleFrame }
    }
    
    // MARK: - Initializers
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override func drawRect(rect: NSRect) {
        super.drawRect(rect)
        
        if let textField = textField, font = textField.font {
            let string = textField.stringValue as NSString
            let size = string.sizeWithAttributes(
                [NSFontAttributeName: font]
            )
            var textRect = textField.frame
            textRect.size.height = size.height
            if let height = activeScreenRects()?.first?.size.height {
                textRect.origin.y = height / 2.0
            }
            textField.frame = textRect
            textField.textColor = NSColor.blackColor()
        }
        
        NSColor.whiteColor().setFill()
        NSRectFill(rect)
    }
    
    override func animateOneFrame() {
        guard let locked = locked where locked == false else {
            return
        }
        self.locked = true
        self.getRandomQuote()
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(10 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
            self.locked = false
        }
    }
    
    private func initialize() {
        animationTimeInterval = 1/30.0

        textField = NSTextField(frame: NSRect(x: 0, y: 0, width: bounds.size.width, height: 100))
        
        textField!.autoresizingMask = .ViewWidthSizable
        textField!.alignment = .Center
        textField!.backgroundColor = NSColor.clearColor()
        textField!.editable = false
        textField!.bezeled = false
        textField!.textColor = NSColor.blackColor()
        textField!.font = NSFont(name: "Courier", size: 24.0)
        textField!.stringValue = "Loading…"
        addSubview(self.textField!)
        getRandomQuote()
    }
    
    override func hasConfigureSheet() -> Bool {
        return false
    }
    
    override func configureSheet() -> NSWindow? {
        return nil
    }
    
    func getRandomQuote() {
        guard let textField = textField else { return assertionFailure() }
        Alamofire.request(.GET, "http://developerexcuses.com").responseString { response in
            guard let string = response.result.value else { return }
            guard let doc = try? XMLDocument(string: string) else { return }
            let elements = doc.xpath("//div[@class='wrapper']/center/a")
            guard let quote = elements.first?.stringValue else { return }
            dispatch_async(dispatch_get_main_queue()) {
                textField.stringValue = quote
            }
        }
    }
}