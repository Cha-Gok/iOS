import Core
import Foundation

/// 음성 메모 통합 유스케이스 에러.
public enum VoiceNoteUseCaseError: LocalizedError, Sendable {
    // Common
    case cancelled
    case unknown(Error)

    // Create
    case invalidDuration(duration: TimeInterval)
    case emptyFileName
    case unsupportedExtension(String)
    case createFailed(VoiceNoteRepositoryError)

    // Update
    case invalidTitle
    case invalidLengthTitle
    case updateFailed(VoiceNoteRepositoryError)

    // Fetch
    case fetchFailed(VoiceNoteRepositoryError)
    case recordNotFound(UUID)

    /// Audio Analysis (from AudioToSummary)
    case analysisFailed(Error)

    public init(_ error: Error) {
        if let useCaseError = error as? VoiceNoteUseCaseError {
            self = useCaseError
        } else if let repoError = error as? VoiceNoteRepositoryError {
            switch repoError {
            case .cancelled: self = .cancelled
            case .recordNotFound(let id): self = .recordNotFound(id)
            case .createFailed: self = .createFailed(repoError)
            case .updateFailed: self = .updateFailed(repoError)
            default: self = .fetchFailed(repoError)
            }
        } else if (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == NSURLErrorCancelled {
            self = .cancelled
        } else {
            self = .unknown(error)
        }
    }

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .invalidDuration(let duration):
            return "유효하지 않은 녹음 시간입니다: \(duration)"
        case .emptyFileName:
            return "파일 이름이 비어 있습니다."
        case .unsupportedExtension(let ext):
            return "지원하지 않는 파일 형식입니다: \(ext)"
        case .invalidTitle:
            return "제목이 유효하지 않습니다."
        case .invalidLengthTitle:
            return "제목은 \(Policy.maxNameLength)자 이내여야 합니다."
        case .createFailed(let error), .updateFailed(let error), .fetchFailed(let error):
            return error.localizedDescription
        case .recordNotFound:
            return "해당 음성 메모를 찾을 수 없습니다."
        case .analysisFailed(let error):
            return "심성 분석에 실패했습니다: \(error.localizedDescription)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
