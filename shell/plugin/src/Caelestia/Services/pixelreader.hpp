// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <QColor>
#include <QImage>
#include <QObject>
#include <QQmlEngine>
#include <QString>

namespace caelestia::services {

class PixelReader : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool loaded READ isLoaded NOTIFY loadedChanged)
    Q_PROPERTY(int imageWidth READ imageWidth NOTIFY loadedChanged)
    Q_PROPERTY(int imageHeight READ imageHeight NOTIFY loadedChanged)
    Q_PROPERTY(QString imagePath READ imagePath NOTIFY loadedChanged)

public:
    explicit PixelReader(QObject* parent = nullptr);

    [[nodiscard]] bool isLoaded() const;
    [[nodiscard]] int imageWidth() const;
    [[nodiscard]] int imageHeight() const;
    [[nodiscard]] QString imagePath() const;

    Q_INVOKABLE bool load(const QString& path);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QColor pixel(int x, int y) const;
    Q_INVOKABLE QString hex(int x, int y) const;
    Q_INVOKABLE QString rgb(int x, int y) const;
    Q_INVOKABLE QString hsl(int x, int y) const;

signals:
    void loadedChanged();

private:
    QImage m_image;
    QString m_path;
};

} // namespace caelestia::services
