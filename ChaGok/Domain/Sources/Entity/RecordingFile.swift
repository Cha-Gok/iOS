//
//  RecordingFile.swift
//  Domain
//
//  Created by Tom Choi on 2/9/26.
//

import Foundation

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
    public let isFavorite: Bool

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
        isFavorite: Bool
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
        self.isFavorite = isFavorite
    }
}

public enum FileFormat {
    case mp3
    case wav
    case aac
    case m4a
    case other(String)
}
