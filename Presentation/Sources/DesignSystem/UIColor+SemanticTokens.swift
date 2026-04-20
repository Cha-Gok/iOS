import UIKit

public extension UIColor {
    /// 재생 중인 스크립트 셀 강조 배경
    static var scriptCellHighlight: UIColor {
        .point600.withAlphaComponent(0.3)
    }

    /// 음성 메모 메타데이터(폴더·날짜·재생시간) 표시 색상
    static var metadataLabel: UIColor {
        .gray750
    }
}
