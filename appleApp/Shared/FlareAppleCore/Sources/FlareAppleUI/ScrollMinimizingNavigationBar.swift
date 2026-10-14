import SwiftUI

public struct ScrollMinimizingNavigationBar: ViewModifier {
    public init() {}

    @ViewBuilder
    public func body(content: Content) -> some View {
        // toolbarMinimizationBehavior 属于 iOS 27 SDK，Xcode 26.6 的 SDK 里尚不存在，直接透传。
        content
    }
}
