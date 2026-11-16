// CustomButton.qml
import QtQuick

Item {
    id: root
    width: 140
    height: 44

    // Właściwości udostępnione na zewnątrz
    property string text: "Button"
    property string iconText: "⚙" // Domyślna ikona Unicode
    signal clicked()

    // Tło przycisku
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 8

        // Kolory dobrane z obrazka
        color: tapHandler.pressed
               ? "#5d5d5d"
               : (hoverHandler.hovered ? "#2d2d2d" : "#3d3d3d")

        border.color: hoverHandler.hovered ? "#2d2d2d" : "#3d3d3d"
        border.width: 1

        // Płynne przejścia kolorów
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Zawartość przycisku (Ikona + Etykieta)
        Row {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: root.iconText
                color: "white"
                font.pixelSize: 18
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.text
                color: "white"
                font.pixelSize: 14
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Obsługa najechania myszą w Qt6
    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    // Obsługa kliknięcia w Qt6
    TapHandler {
        id: tapHandler
        onTapped: root.clicked()
    }
}