import SwiftUI

struct PLItemPickerDefaultModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        return content
            .background(Color.white)
            .cornersRadius(8)
            .overlay (
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 1)
            )
    }
}

struct PLItemPickerBorderlessModifier: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .background(Color.white)
            .cornersRadius(8)
    }
}
