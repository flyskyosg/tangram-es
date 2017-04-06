#include "data/networkDataSource.h"

#include "log.h"
#include "platform.h"

namespace Tangram {

NetworkDataSource::NetworkDataSource(std::shared_ptr<Platform> _platform, const std::string& _urlTemplate) :
    m_platform(_platform),
    m_urlTemplate(_urlTemplate) {}

void NetworkDataSource::constructURL(const TileID& _tileCoord, std::string& _url) const {
    _url.assign(m_urlTemplate);

    try {
        size_t xpos = _url.find("{x}");
        _url.replace(xpos, 3, std::to_string(_tileCoord.x));
        size_t ypos = _url.find("{y}");
        _url.replace(ypos, 3, std::to_string(_tileCoord.y));
        size_t zpos = _url.find("{z}");
        _url.replace(zpos, 3, std::to_string(_tileCoord.z));
    } catch(...) {
        LOGE("Bad URL template!");
    }
}

bool NetworkDataSource::loadTileData(std::shared_ptr<TileTask> _task, TileTaskCb _cb) {

    if (_task->rawSource != this->level) {
        LOGE("NetworkDataSource must be last!");
        return false;
    }

    auto tileId = _task->tileId();

    Url url(constructURL(_task->tileId()));

    UrlCallback onRequestFinish = [this, cb = _cb, task = _task, url](UrlResponse response) mutable {

        removePending(task->tileId(), false);

        if (task->isCanceled()) {
            return;
        }

        if (response.error) {
            LOGE("Error for URL request '%s': %s", url.string().c_str(), response.error);
            return;
        }

        if (!response.content.empty()) {
            auto& dlTask = static_cast<BinaryTileTask&>(*task);
            dlTask.rawTileData = std::make_shared<std::vector<char>>(std::move(response.content));
        }
        cb.func(task);
    };

    // Only start the request if we don't have a pending request for the same tile already.
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        if (getPendingRequest(tileId) != m_pending.end()) {
            return false;
        } else {
            auto requestHandle = m_platform->startUrlRequest(url, onRequestFinish);
            m_pending.push_back({ tileId, requestHandle });
        }
    }

    return true;
}

void NetworkDataSource::removePending(const TileID& _tileId, bool cancelRequest) {
    std::unique_lock<std::mutex> lock(m_mutex);
    auto it = getPendingRequest(_tileId);
    if (it != m_pending.end()) {
        if (cancelRequest) {
            m_platform->cancelUrlRequest(it->request);
        }
        m_pending.erase(it);
    }
}

void NetworkDataSource::cancelLoadingTile(const TileID& _tileId) {
    removePending(_tileId, true);
}

auto NetworkDataSource::getPendingRequest(const Tangram::TileID& tile) -> decltype(m_pending)::iterator {
    auto it = m_pending.begin();
    for (; it != m_pending.end(); ++it) {
        if (it->tile == tile) {
            break;
        }
    }
    return it;
}

}
