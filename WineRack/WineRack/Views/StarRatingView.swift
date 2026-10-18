import SwiftUI

// Vijf tikbare sterren. Tik je op de huidige ster, dan gaat de score naar 0.
struct StarRatingView: View {
    @Binding var rating: Int
    var maximum = 5

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(1...maximum), id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundStyle(star <= rating ? Color.yellow : Color.secondary)
                    .contentShape(Rectangle())
                    .onTapGesture { rating = (rating == star) ? 0 : star }
                    .accessibilityLabel("\(star) van \(maximum) sterren")
                    .accessibilityAddTraits(.isButton)
            }
        }
    }
}

#Preview {
    StarRatingView(rating: .constant(3))
}
