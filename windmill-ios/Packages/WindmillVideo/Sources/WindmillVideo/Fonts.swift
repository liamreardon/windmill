import CoreText
import Foundation

/// Lexend ships in the package (SIL Open Font License, Resources/OFL-Lexend.txt).
public enum Fonts {
    public static let lexendFamily = "Lexend"

    private static let registered: Bool = {
        guard let url = Bundle.module.url(forResource: "Lexend-VariableFont_wght", withExtension: "ttf") else { return false }
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }()

    /// Safe to call any number of times, from any thread.
    public static func registerOnce() {
        _ = registered
    }
}
