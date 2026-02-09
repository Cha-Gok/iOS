//
//  StorageInfo.swift
//  Domain
//
//  Created by Tom Choi on 2/9/26.
//

import Foundation

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
