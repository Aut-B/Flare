// iOS 15 回退：把 iOS 16/17 专属的 SwiftUI API 用兼容写法包一层。
// 放在 FlareAppleCore 模块（FlareAppleUI 依赖它），ios/ 与 Shared/ 内的文件均可使用。
import Combine
import SwiftUI

// MARK: - onChange 回退
// 不用 SwiftUI 的 onChange：iOS 17 SDK 里它同时存在单参旧版与双参新版（initial 有默认值），
// 在部署目标 iOS 15 下重载解析容易歧义。改用 onReceive(Just(...))，iOS 13+ 通用且语义一致。
private struct BackportChangeObserver<V: Equatable>: ViewModifier {
    let value: V
    let initial: Bool
    let action: (V, V) -> Void
    @State private var oldValue: V?

    func body(content: Content) -> some View {
        content
            .onReceive(Just(value)) { newValue in
                guard let old = oldValue else {
                    oldValue = newValue
                    if initial {
                        action(newValue, newValue)
                    }
                    return
                }
                guard old != newValue else { return }
                oldValue = newValue
                action(old, newValue)
            }
    }
}

extension View {
    public func backportOnChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        perform: @escaping (V) -> Void
    ) -> some View {
        modifier(
            BackportChangeObserver(value: value, initial: initial) { _, newValue in
                perform(newValue)
            }
        )
    }

    public func backportOnChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        perform: @escaping (V, V) -> Void
    ) -> some View {
        modifier(BackportChangeObserver(value: value, initial: initial, action: perform))
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
