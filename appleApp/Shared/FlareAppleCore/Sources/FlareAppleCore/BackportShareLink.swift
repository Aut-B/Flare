// iOS 15 回退：SwiftUI 的 ShareLink 是 iOS 16+，这里用 UIActivityViewController 包一层。
import SwiftUI

private struct BackportActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

public struct BackportShareLink<Label: View>: View {
    private let items: [Any]
    private let label: Label
    @State private var isPresented = false

    public init(item: URL, @ViewBuilder label: () -> Label) {
        self.items = [item]
        self.label = label()
    }

    public init(item: UIImage, @ViewBuilder label: () -> Label) {
        self.items = [item]
        self.label = label()
    }

    public init(item: URL, subject: Text? = nil, message: Text? = nil, @ViewBuilder label: () -> Label) {
        // iOS 15 的 UIActivityViewController 不支持逐条 subject/message（那是 iOS 16 的
        // UIActivityItemSource 能力），这里退化为分享链接本身。
        self.items = [item]
        self.label = label()
    }

    public var body: some View {
        Button {
            isPresented = true
        } label: {
            label
        }
        .sheet(isPresented: $isPresented) {
            BackportActivityView(items: items)
        }
    }
}
