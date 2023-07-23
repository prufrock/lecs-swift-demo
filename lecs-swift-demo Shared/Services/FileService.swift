//
// Created by David Kanenwisher on 1/7/23.
//

import Foundation

public class FileService {
    fileprivate let config: AppCoreConfig.Services.FileService

    public init(_ config: AppCoreConfig.Services.FileService) {
        self.config = config
    }

    public func sync(_ command: LoadLevelFileCommand) {
        command.execute(fileService: self)
    }
}

/**
 For now it looks like this is just giving the sync command a unique signature.
 Someday need to spend some time thinking about these services.
 */
public struct LoadLevelFileCommand: ServiceCommand {
    public let block: ([TileMap]) -> ()
    /**
     - Parameter fileService:
     - Returns:
     */
    public func execute(fileService: FileService) {
        let jsonUrl = Bundle.main.url(
            forResource: fileService.config.levelsFile.name,
            withExtension: fileService.config.levelsFile.ext)!
        let jsonData = try! Data(contentsOf: jsonUrl)
        let levels = try! JSONDecoder().decode([MapData].self, from: jsonData)
        block(levels.enumerated().map { index, mapData in
            TileMap(mapData, index: index)
        })
    }
}
