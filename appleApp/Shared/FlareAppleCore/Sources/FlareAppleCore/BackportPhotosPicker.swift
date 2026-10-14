// iOS 15 回退：SwiftUI 的 PhotosPicker 是 iOS 16+，这里用 iOS 14 就有的
// PHPickerViewController（PhotosUI 框架）包一层，对外 API 尽量贴近 PhotosPicker。
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

public final class BackportPhotosPickerItem: Hashable {
    public static func == (lhs: BackportPhotosPickerItem, rhs: BackportPhotosPickerItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let provider: NSItemProvider
    public let id: String

    public var itemIdentifier: String? { id }

    public var supportedContentTypes: [UTType] {
        provider.registeredTypeIdentifiers.compactMap { UTType($0) }
    }

    init(provider: NSItemProvider, id: String) {
        self.provider = provider
        self.id = id
    }

    /// 以文件副本的形式交付原始数据，保留 GIF / 视频的原有编码。
    /// 回调里的 URL 仅在该回调执行期间有效，需要立即复制。
    public func loadFile(completion: @escaping (Result<URL?, Error>) -> Void) {
        let typeIdentifier = provider.registeredTypeIdentifiers.first ?? UTType.data.identifier
        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(url))
            }
        }
    }

    public func loadTransferable(type: Data.Type) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            loadFile { result in
                switch result {
                case .success(let url):
                    guard let url, let data = try? Data(contentsOf: url) else {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private struct BackportPickerHost: UIViewControllerRepresentable {
    let filter: PHPickerFilter?
    let selectionLimit: Int
    let onPick: ([BackportPhotosPickerItem]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = selectionLimit
        if let filter {
            configuration.filter = filter
        }
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: ([BackportPhotosPickerItem]) -> Void

        init(onPick: @escaping ([BackportPhotosPickerItem]) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else { return }
            onPick(
                results.map {
                    BackportPhotosPickerItem(
                        provider: $0.itemProvider,
                        id: $0.assetIdentifier ?? UUID().uuidString
                    )
                }
            )
        }
    }
}

public struct BackportPhotosPicker<Label: View>: View {
    @Binding private var multiple: [BackportPhotosPickerItem]
    @Binding private var single: BackportPhotosPickerItem?
    private let isMultiple: Bool
    private let maxSelectionCount: Int
    private let filter: PHPickerFilter?
    private let label: Label
    @State private var isPresented = false

    public init(
        selection: Binding<[BackportPhotosPickerItem]>,
        maxSelectionCount: Int = 1,
        matching filter: PHPickerFilter? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self._multiple = selection
        self._single = .constant(nil)
        self.isMultiple = true
        self.maxSelectionCount = maxSelectionCount
        self.filter = filter
        self.label = label()
    }

    public init(
        selection: Binding<BackportPhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self._multiple = .constant([])
        self._single = selection
        self.isMultiple = false
        self.maxSelectionCount = 1
        self.filter = filter
        self.label = label()
    }

    public var body: some View {
        Button {
            isPresented = true
        } label: {
            label
        }
        .sheet(isPresented: $isPresented) {
            BackportPickerHost(
                filter: filter,
                selectionLimit: isMultiple ? maxSelectionCount : 1
            ) { picked in
                if isMultiple {
                    multiple = picked
                } else {
                    single = picked.first
                }
            }
            .ignoresSafeArea()
        }
    }
}
