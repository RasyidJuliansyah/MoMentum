import CoreGraphics

/// Token jarak (pt). Padding layar 20, jarak antarkartu 12 sampai 14.
enum MSpace {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let screen: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

/// Token radius sudut (pt). Tombol, chip, badge, dan tab bar memakai `Capsule`.
enum MRadius {
    static let sm: CGFloat = 10 // sel kecil (grid segmen)
    static let md: CGFloat = 16 // input, banner info
    static let lg: CGFloat = 24 // kartu glass
    static let xl: CGFloat = 36 // bottom sheet
}
