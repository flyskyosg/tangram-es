#pragma once

#include <string>
#include <vector>
#include <memory>
#include <map>

namespace Tangram {

class Platform;
struct ZipHandle;

class Asset {
    public:
        Asset(std::string name, std::string path, std::shared_ptr<ZipHandle> zipHandle = nullptr,
              std::vector<char> zippedData = {});
        ~Asset();

        const std::shared_ptr<ZipHandle> zipHandle() const { return m_zipHandle; }
        const std::string& name() const { return m_name; }
        const std::string& path() const { return m_path; }

        // builds zipHandle (if not already built, from raw Data
        void buildZipHandle(const std::vector<char>& zippedData);

        // returns the string from file (m_path) or from zip archive
        std::string readStringFromAsset(const std::shared_ptr<Platform>& platform);

        // returns the bytes from file (m_path) or from zip archive
        std::vector<char> readBytesFromAsset(const std::shared_ptr<Platform>& platform);

        // returns the string from file (m_path) or from zip archive
        std::string readStringFromAsset(const std::shared_ptr<Platform>& platform, const std::string& filename);

        // returns the bytes from file (m_path) or from zip archive
        std::vector<char> readBytesFromAsset(const std::shared_ptr<Platform>& platform, const std::string& filename);

    private:
        std::string m_name; //resolvedUrl
        std::string m_path; //path within a zip, empty for a non zipped asset
        std::shared_ptr<ZipHandle> m_zipHandle = nullptr;

        bool isBaseYaml(const std::string& filename);
};

}