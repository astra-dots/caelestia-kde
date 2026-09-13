#pragma once

#include <qqmlintegration.h>
#include <qtimer.h>

#include "service.hpp"

namespace caelestia::services {

class AudioProcessor : public QObject {
    Q_OBJECT

public:
    explicit AudioProcessor(QObject* parent = nullptr);
    virtual ~AudioProcessor();

    void init();

public slots:
    virtual void start();
    virtual void stop();

protected:
    virtual void process() = 0;

private:
    QTimer* m_timer = nullptr;
};

class AudioProvider : public Service {
    Q_OBJECT

public:
    explicit AudioProvider(QObject* parent = nullptr);
    ~AudioProvider();

protected:
    AudioProcessor* m_processor;

    void init();
    void start() override;
    void stop() override;

private:
    QThread* m_thread;
};

} // namespace caelestia::services
