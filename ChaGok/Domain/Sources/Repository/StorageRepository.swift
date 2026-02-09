//
//  StorageRepository.swift
//  Domain
//
//  Created by Tom Choi on 2/9/26.
//

import Foundation

/// StorageRepository는 저장소 정보를 조회하고, 녹음 파일을 관리하는 리포지토리 프로토콜입니다.
/// - fetchStorageInfo(): 저장소 정보를 조회합니다.
/// - fetchRecordingFiles(): 녹음 파일을 조회합니다.
/// - deleteFiles(ids:): 녹음 파일을 삭제합니다.
public protocol StorageRepository {
    func fetchStorageInfo() async throws -> StorageInfo
    func fetchRecordingFiles() async throws -> [RecordingFile]
    func deleteFiles(ids: [UUID]) async throws -> Int
}
