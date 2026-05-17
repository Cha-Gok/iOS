import Foundation

public enum DownloadStatus: Equatable, Sendable {
    case checking                               // 다운로드 모델 확인
    case idle                                   // 준비
    case downloading(progress: Double)          // 진행 중
    case completed                              // 완료
    case notFoundModel                          // 모델을 다운로드 받을 수 없는 경우 ex) 4GB
    case failed(error: String)                  // 다운로드 실패

    public var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }

    public var progress: Double {
        if case let .downloading(progress) = self { return progress }
        if case .completed = self { return 1.0 }
        return 0.0
    }
    
    public var message: String {
        switch self {
        case .checking:
            return "사용자님의 기기 환경을 확인 중이에요"
        case .idle:
            return "문법 교정과 요약을 기기 안에서 처리하기 위해,\n모델을 다운로드 해요.\nWi-Fi연결을 권장하며 몇 분 정도 걸려요."
        case .downloading:
            return "다운로드 진행 중입니다.."
        case .completed:
            return "다운로드가 완료되었습니다"
        case .notFoundModel:
            return "적용 가능한 모델이 없습니다.."
        case .failed(let error):
            return "다운로드 실패: \(error)"
        }
    }
}
