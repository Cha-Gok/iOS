//
//  StorageInfo.swift
//  Domain
//
//  Created by Tom Choi on 2/9/26.
//

import Foundation

/// StorageInfo는 기기의 저장소 정보를 담고 있는 구조체입니다.
/// - totalBytes: 저장소의 전체 바이트 수.
/// - freeBytes: 저장소의 남은(여유) 바이트 수.
/// - appUsedBytes: 앱이 사용한 바이트 수.
/// - usageRatio: 앱 사용량 비율.
public struct StorageInfo {
    public let totalBytes: Int64
    public let freeBytes: Int64
    public let appUsedBytes: Int64

    public var usageRatio: Double {
        Double(appUsedBytes) / Double(totalBytes)
    }

    public init(totalBytes: Int64, freeBytes: Int64, appUsedBytes: Int64) {
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
        self.appUsedBytes = appUsedBytes
    }
}
