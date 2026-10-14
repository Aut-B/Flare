// iOS 15 回退：把 iOS 16/17 专属的 SwiftUI API 用兼容写法包一层。
// 这些扩展放在 FlareAppleUI 模块，ios/ 与 FlareAppleUI 内的文件均可使用。
import SwiftUI

// MARK: - onChange 回退（iOS 15 只支持单参闭包；iOS 17 支持双参 + initial）
extension View {
    @ViewBuilder
    public func backportOnChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        perform: @escaping (V) -> Void
    ) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.onChange(of: value, initial: initial) { _ in perform(value) }
        } else {
            self.onChange(of: value) { perform($0) }
        }
    }

    @ViewBuilder
    public func backportOnChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        perform: @escaping (V, V) -> Void
    ) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.onChange(of: value, initial: initial) { old, new in perform(old, new) }
        } else {
            self.onChange(of: value) { new in perform(new, new) }
        }
    }
}

// MARK: - ContentUnavailableView 回退（iOS 17 专属）
public struct BackportContentUnavailableView<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension BackportContentUnavailableView where Content == AnyView {
    public init(_ titleKey: LocalizedStringKey, systemImage: String) {
        self.init {
            AnyView(
                VStack(spacing: 16) {
                    Image(systemName: systemImage)
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(titleKey)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            )
        }
    }
}

// MARK: - scrollPosition 回退（iOS 17 专属，iOS 15 下直接透传不生效）
extension View {
    @ViewBuilder
    public func backportScrollPosition<ID: Hashable>(
        id: Binding<ID?>,
        anchor: UnitPoint? = nil
    ) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.scrollPosition(id: id, anchor: anchor)
        } else {
            self
        }
    }
}
