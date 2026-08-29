// SPDX-License-Identifier: GPL-3.0-only
#include "pixelreader.hpp"

#include <QFile>
#include <QFileInfo>

namespace caelestia::services {

PixelReader::PixelReader(QObject* parent)
    : QObject(parent) {}

bool PixelReader::isLoaded() const {
    return !m_image.isNull();
}

int PixelReader::imageWidth() const {
    return m_image.width();
}

int PixelReader::imageHeight() const {
    return m_image.height();
}

QString PixelReader::imagePath() const {
    return m_path;
}

bool PixelReader::load(const QString& path) {
    if (path.isEmpty()) {
        clear();
        return false;
    }

    QString localPath = path;
    if (localPath.startsWith(QLatin1String("file://"))) {
        localPath = localPath.mid(7);
    }

    QImage img;
    if (!img.load(localPath)) {
        clear();
        return false;
    }

    m_image = img.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    m_path = localPath;
    emit loadedChanged();
    return true;
}

void PixelReader::clear() {
    m_image = QImage();
    m_path.clear();
    emit loadedChanged();
}

QColor PixelReader::pixel(int x, int y) const {
    if (m_image.isNull() || x < 0 || y < 0 || x >= m_image.width() || y >= m_image.height()) {
        return QColor(0, 0, 0, 0);
    }
    return m_image.pixelColor(x, y);
}

QString PixelReader::hex(int x, int y) const {
    const QColor c = pixel(x, y);
    if (!c.isValid() || c.alpha() == 0) {
        return QStringLiteral("#000000");
    }
    return c.name(QColor::HexRgb).toUpper();
}

QString PixelReader::rgb(int x, int y) const {
    const QColor c = pixel(x, y);
    if (!c.isValid()) {
        return QStringLiteral("rgb(0, 0, 0)");
    }
    return QStringLiteral("rgb(%1, %2, %3)").arg(c.red()).arg(c.green()).arg(c.blue());
}

QString PixelReader::hsl(int x, int y) const {
    const QColor c = pixel(x, y);
    if (!c.isValid()) {
        return QStringLiteral("hsl(0, 0%, 0%)");
    }
    int h = qRound(c.hslHueF() * 360.0);
    if (h < 0) h = 0;
    int s = qRound(c.hslSaturationF() * 100.0);
    int l = qRound(c.lightnessF() * 100.0);
    return QStringLiteral("hsl(%1, %2%, %3%)").arg(h).arg(s).arg(l);
}

} // namespace caelestia::services
