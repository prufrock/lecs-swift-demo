//
// Created by David Kanenwisher on 1/3/23.
//

import Foundation

/**
 Constructs services on demand from the config.
 */
class AppCoreServiceFactory {
    private let config: AppCoreConfig.Services

    init(_ config: AppCoreConfig.Services) {
        self.config = config
    }

    public func createRenderService() -> RenderService {
        RenderService(config.renderService)
    }

    public func createFileService() -> FileService {
        FileService(config.fileService)
    }
}
