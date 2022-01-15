//
//  iPhoneKeyboardLayoutProvider.swift
//  KeyboardKit
//
//  Created by Daniel Saidi on 2021-02-02.
//  Copyright © 2021 Daniel Saidi. All rights reserved.
//

import SwiftUI

/**
 This class provides a keyboard layout that correspond to an
 iPhone with either a home button or notch.
 
 You can inherit this class and override any open properties
 and functions to customize the standard behavior.
 
 `TODO` The layout specifics are pretty nasty below, but the
 internal functionality can be extracted to the new keyboard
 layout configuration type or expressed outside this class.
 */
open class iPhoneKeyboardLayoutProvider: SystemKeyboardLayoutProvider {
    
    
    // MARK: - Overrides
    
    /**
     Get keyboard actions for the provided `context` and the
     provided keyboard `inputs`.
     
     Note that `inputs` is an input set and does not contain
     the bottommost space key row, which we therefore add in
     this function.
     */
    open override func actions(for context: KeyboardContext, inputs: InputSetRows) -> KeyboardActionRows {
        var rows = super.actions(for: context, inputs: inputs)
        guard rows.count > 0 else { return rows }
        let lastRow = rows.last ?? []
        rows.removeLast()
        rows.append(lowerLeadingActions(for: context) + lastRow + lowerTrailingActions(for: context))
        rows.append(bottomActions(for: context))
        return rows
    }
    
    /**
     Get the keyboard layout item width of a certain `action`
     for the provided `context`, `row` and row `index`.
     */
    open override func itemSizeWidth(for context: KeyboardContext, action: KeyboardAction, row: Int, index: Int) -> KeyboardLayoutItemWidth {
        if action.isPrimaryAction { return bottomRowPrimaryButtonWidth(for: context) }
        switch action {
        case dictationReplacement: return bottomRowSystemButtonWidth(for: context)
        case .character:
            if isGreekAlphabetic(context) { return .percentage(0.1) }
            return isLastNumericInputRow(row, for: context) ? lastSymbolicInputWidth(for: context) : .input
        case .backspace: return thirdRowSystemButtonWidth(for: context)
        case .keyboardType: return bottomRowSystemButtonWidth(for: context)
        case .newLine: return bottomRowPrimaryButtonWidth(for: context)
        case .nextKeyboard: return bottomRowSystemButtonWidth(for: context)
        case .return: return bottomRowPrimaryButtonWidth(for: context)
        case .shift: return thirdRowSystemButtonWidth(for: context)
        default: return .available
        }
    }
    
    
    // MARK: - iPhone Specific
    
    /**
     Get the actions of the bottommost space key row.
     
     You can override this function to adjust or replace the
     actions on the bottommost row.
     */
    open func bottomActions(for context: KeyboardContext) -> KeyboardActions {
        var result = KeyboardActions()
        let portrait = context.screenOrientation.isPortrait
        let needsInputSwitch = context.needsInputModeSwitchKey
        let needsDictation = context.needsInputModeSwitchKey
        if let action = keyboardSwitchActionForBottomRow(for: context) { result.append(action) }
        if needsInputSwitch { result.append(.nextKeyboard) }
        if !needsInputSwitch { result.append(.keyboardType(.emojis)) }
        if portrait, needsDictation, let action = dictationReplacement { result.append(action) }
        result.append(.space)
        if isPersianAlphabetic(context) { result.append(.character(.zeroWidthSpace)) }
        result.append(keyboardReturnAction(for: context))
        if !portrait, needsDictation, let action = dictationReplacement { result.append(action) }
        return result
    }
    
    /**
     Get the leading actions to add to the lower input row.
     
     You can override this function to adjust or replace the
     leading actions on the lower input row.
     */
    open func lowerLeadingActions(for context: KeyboardContext) -> KeyboardActions {
        guard let action = keyboardSwitchActionForBottomInputRow(for: context) else { return [] }
        if isCzechAlphabetic(context) { return [action] }
        if isArabicAlphabetic(context) { return [] }
        if isBelarusianAlphabetic(context) { return [action] }
        if isPersianAlphabetic(context) { return [] }
        if isRussianAlphabetic(context) { return [action] }
        return [action, .none]
    }
    
    /**
     Get the trailing actions to add to the lower input row.
     
     You can override this function to adjust or replace the
     trailing actions on the lower input row.
     */
    open func lowerTrailingActions(for context: KeyboardContext) -> KeyboardActions {
        if isCzechAlphabetic(context) { return [.backspace] }
        if isBelarusianAlphabetic(context) { return [.backspace] }
        if isPersianAlphabetic(context) { return [.backspace] }
        if isRussianAlphabetic(context) { return [.backspace] }
        return [.none, .backspace]
    }
}

private extension iPhoneKeyboardLayoutProvider {
    
    func isPortrait(_ context: KeyboardContext) -> Bool {
        context.screenOrientation.isPortrait
    }
    
    /**
     The width of the last numeric/symbolic row input button.
     */
    func lastSymbolicInputWidth(for context: KeyboardContext) -> KeyboardLayoutItemWidth {
        .percentage(0.14)
    }
    
    /**
     The width of the bottom-right primary (return) button.
     */
    func bottomRowPrimaryButtonWidth(for context: KeyboardContext) -> KeyboardLayoutItemWidth {
        .percentage(isPortrait(context) ? 0.25 : 0.195)
    }
    
    /**
     The width of the bottom-right primary (return) button.
     */
    func bottomRowSystemButtonWidth(for context: KeyboardContext) -> KeyboardLayoutItemWidth {
        .percentage(isPortrait(context) ? 0.125 : 0.097)
    }
    
    /**
     The system buttons that are shown to the left and right
     of the third row's input buttons.
     */
    func thirdRowSystemButtonWidth(for context: KeyboardContext) -> KeyboardLayoutItemWidth {
        if hasTwelveElevenNineAlphabeticInput { return .percentage(0.11) }
        if isBelarusianAlphabetic(context) { return .available }
        if isCzechAlphabetic(context) { return .input }
        if isPersianAlphabetic(context) { return .input }
        if isRussianAlphabetic(context) { return .input }
        return .percentage(0.12)
    }
    
    /**
     Whether or not a certain row is the last input row in a
     numeric or symbolic keyboard.
     */
    func isLastNumericInputRow(_ row: Int, for context: KeyboardContext) -> Bool {
        let isNumeric = context.keyboardType == .numeric
        let isSymbolic = context.keyboardType == .symbolic
        guard isNumeric || isSymbolic else { return false }
        return row == 2 // Index 2 is the "wide keys" row
    }
}

/**
 These previews are pretty complex, since we want to be able
 to verify that the returned sizes are correct. We therefore
 add a real screenshot below the generated SwiftUI view.
 
 The real screenshots are not perfectly cropped to fit these
 previews, but they give a great assistance in approximating
 the size, so that it's not way off.
 */
struct iPhoneKeyboardLayoutProvider_Previews: PreviewProvider {
    
    static var overlayOpacity: Double = 1.0
    
    static var proxy = PreviewTextDocumentProxy()
    
    static var context = KeyboardContext(
        controller: KeyboardInputViewController(),
        device: MockDevice(),
        keyboardType: .alphabetic(.lowercased))
    
    static var previewImage: some View {
        Image(context.previewImageName, bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: context.previewWidth)
            .opacity(overlayOpacity)
    }
    
    
    static func input(for locale: KeyboardLocale) -> InputSetProvider {
        StandardInputSetProvider(
            context: context,
            providers: [provider(for: locale)])
    }
    
    static func layout(for locale: KeyboardLocale) -> KeyboardLayoutProvider {
        iPhoneKeyboardLayoutProvider(inputSetProvider: input(for: locale))
    }
    
    static func provider(for locale: KeyboardLocale) -> LocalizedInputSetProvider {
        switch locale {
        case .swedish: return InternalSwedishInputSetProvider(device: MockDevice())
        default: return EnglishInputSetProvider(device: MockDevice())
        }
    }
    
    
    static func preview(for locale: KeyboardLocale, _ type: KeyboardType, _ orientation: UIInterfaceOrientation) -> some View {
        // proxy.returnKeyType = UIReturnKeyType.search
        context.locale = locale.locale
        context.keyboardType = type
        context.screenOrientation = orientation
        context.textDocumentProxy = proxy
        context.needsInputModeSwitchKey = true
        return SystemKeyboard(
            layout: layout(for: locale).keyboardLayout(for: context),
            appearance: StandardKeyboardAppearance(context: context),
            actionHandler: .preview,
            keyboardContext: .preview,
            actionCalloutContext: .preview,
            inputCalloutContext: .preview,
            width: context.previewWidth)
            .background(previewImage, alignment: .bottom)
            .background(Color.gray.opacity(0.4))
            .overlay(Text(context.previewImageName), alignment: .bottom)
    }
    
    static func previews(for locale: KeyboardLocale, _ orientation: UIInterfaceOrientation) -> some View {
        VStack {
            Text(locale.localizedName).font(.title)
            preview(for: locale, .alphabetic(.lowercased), orientation)
            preview(for: locale, .alphabetic(.uppercased), orientation)
            preview(for: locale, .numeric, orientation)
            preview(for: locale, .symbolic, orientation)
            Spacer()
        }.padding()
    }
    
    static var previews: some View {
        HStack {
            previews(for: .english, .portrait)
            previews(for: .swedish, .portrait)
            previews(for: .english, .landscapeLeft)
            previews(for: .swedish, .landscapeLeft)
        }
        .frame(height: 980)
        .previewLayout(.sizeThatFits)
    }
}

private class MockDevice: UIDevice {
    
    override var userInterfaceIdiom: UIUserInterfaceIdiom { .phone }
}

private extension KeyboardContext {
    
    var previewImageName: String {
        let language = locale.languageCode ?? ""
        let type = keyboardType.previewImageSegment
        let orientation = screenOrientation.previewImageSegment
        return "iPhone12_\(language)_\(type)_\(orientation)"
    }
    
    var previewWidth: CGFloat {
        screenOrientation.isPortrait ? 390 : 844
    }
}

private extension KeyboardType {
    
    var previewImageSegment: String {
        switch self {
        case .alphabetic: return "alphabetic"
        case .numeric: return "numeric"
        case .symbolic: return "numeric"
        default: return ""
        }
    }
}

private extension UIInterfaceOrientation {
    
    var previewImageSegment: String {
        isPortrait ? "portrait" : "landscape"
    }
}
