import SwiftUI

struct BubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            Text(message.content)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(bubbleBackground)
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: message.role == .assistant ? 1 : 0)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                .frame(maxWidth: 320, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }

    private var bubbleBackground: some ShapeStyle {
        if message.role == .user {
            return AnyShapeStyle(Color.accentColor)
        }
        return AnyShapeStyle(Color(.secondarySystemBackground))
    }
}
