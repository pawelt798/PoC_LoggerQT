#ifndef SYSTEMSTATUS_H
#define SYSTEMSTATUS_H

#include <QObject>
#include <QString>

class SystemStatus : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString batteryStatus READ batteryStatus NOTIFY batteryStatusChanged)

public:
    QString batteryStatus() const { return m_batteryStatus; }

    void setBatteryStatus(const QString &status) {
        if (m_batteryStatus != status) {
            m_batteryStatus = status;
            emit batteryStatusChanged();
        }
    }

signals:
    void batteryStatusChanged();

private:
    QString m_batteryStatus = "Naładowano: 9999%";
};

#endif // SYSTEMSTATUS_H
