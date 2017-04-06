#pragma once

#include "data/tileSource.h"
#include "platform.h"

#include <unordered_map>

namespace Tangram {

class Platform;

class NetworkDataSource : public TileSource::DataSource {
public:

    NetworkDataSource(std::shared_ptr<Platform> _platform, const std::string& _urlTemplate);

    bool loadTileData(std::shared_ptr<TileTask> _task, TileTaskCb _cb) override;

    void cancelLoadingTile(const TileID& _tile) override;

private:
    /* Constructs the URL of a tile using <m_urlTemplate> */
    void constructURL(const TileID& _tileCoord, std::string& _url) const;

    std::string constructURL(const TileID& _tileCoord) const {
        std::string url;
        constructURL(_tileCoord, url);
        return url;
    }

    // Each pending tile request is stored as a pair of TileID and UrlRequestHandle.
    struct TileRequest {
        TileID tile;
        UrlRequestHandle request;
    };

    std::vector<TileRequest> m_pending;

    // Return an iterator to a pending list item with the given TileID, or the item past the end.
    // This is not mutex-locked.
    decltype(m_pending)::iterator getPendingRequest(const TileID& tile);

    // Remove a pending list item with the given TileID if present, and if cancelRequest is true
    // also cancels the corresponding URL request.
    void removePending(const TileID& _tileId, bool cancelRequest);

    std::shared_ptr<Platform> m_platform;

    // URL template for requesting tiles from a network or filesystem
    std::string m_urlTemplate;

    std::mutex m_mutex;

};

}
