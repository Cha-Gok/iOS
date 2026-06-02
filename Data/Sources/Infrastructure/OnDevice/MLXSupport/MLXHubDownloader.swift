import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLMCommon

/// Hugging Face Hub에서 모델 파일을 다운로드하기 위한 Downloader 구현체.
/// 컴파일 타임 매크로(#hubDownloader) 대신 사용되는 수동 구현체입니다.
public struct MLXHubDownloader: MLXLMCommon.Downloader {
    private let upstream: HuggingFace.HubClient

    public init(hubClient: HuggingFace.HubClient = HuggingFace.HubClient()) {
        upstream = hubClient
    }

    public func download(
        id: String,
        revision: String?,
        matching patterns: [String],
        useLatest: Bool,
        progressHandler: @Sendable @escaping (Foundation.Progress) -> Void
    ) async throws -> URL {
        guard let repoID = HuggingFace.Repo.ID(rawValue: id) else {
            throw HuggingFaceDownloaderError.invalidRepositoryID(id)
        }
        let revision = revision ?? "main"

        return try await upstream.downloadSnapshot(
            of: repoID,
            revision: revision,
            matching: patterns,
            progressHandler: { @MainActor progress in
                progressHandler(progress)
            }
        )
    }
}
