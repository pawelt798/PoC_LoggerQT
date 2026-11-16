#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <SystemStatus.h>



int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("untitled", "Main");

    SystemStatus statusProvider;
    engine.rootContext()->setContextProperty("statusProvider", &statusProvider);

    statusProvider.setBatteryStatus("OK");



    return QGuiApplication::exec();
}
