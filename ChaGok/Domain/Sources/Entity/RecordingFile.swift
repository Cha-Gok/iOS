//
//  RecordingFile.swift
//  Domain
//
//  Created by Tom Choi on 2/9/26.
//

import Foundation

/// RecordingFile은 녹음 파일을 나타내는 엔티티입니다.
/// - id: 녹음 파일의 고유 식별자.
/// - fileURL: 녹음 파일의 URL.
/// - createdAt: 녹음 파일의 생성 시간.
/// - updatedAt: 녹음 파일의 업데이트 시간.
/// - duration: 녹음 파일의 재생 시간.
/// - fileFormat: 녹음 파일의 파일 형식.
/// - fileSize: 녹음 파일의 파일 크기.
/// - fileName: 녹음 파일의 파일 이름.
/// - title: 녹음 파일의 제목.
/// - description: 녹음 파일의 설명.
/// - tags: 녹음 파일의 태그.
public struct RecordingFile {
    public let id: UUID
    public let fileURL: URL
    public let createdAt: Date
    public let updatedAt: Date
    public let duration: TimeInterval
    public let fileFormat: FileFormat
    public let fileSize: Int64
    public let fileName: String
    public let title: String
    public let description: String
    public let tags: [String]

    public init(
        id: UUID,
        fileURL: URL,
        createdAt: Date,
        updatedAt: Date,
        duration: TimeInterval,
        fileFormat: FileFormat,
        fileSize: Int64,
        fileName: String,
        title: String,
        description: String,
        tags: [String],
    ) {
        self.id = id
        self.fileURL = fileURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.duration = duration
        self.fileFormat = fileFormat
        self.fileSize = fileSize
        self.fileName = fileName
        self.title = title
        self.description = description
        self.tags = tags
    }
}
