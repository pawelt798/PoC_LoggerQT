// ActionDropdownButton.qml
import QtQuick

Item {
    id: root
    width: 170
    height: 42

    property string text: "Start Logging"
    signal mainClicked()
    signal dropdownClicked()

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 8

        // Zmiana odcienia zieleni w zależności od stanu akcji głównej
        color: mainTap.pressed
               ? "#007a41"
               : (mainHover.hovered ? "#00bd64" : "#00a859")

        Behavior on color { ColorAnimation { duration: 100 } }

        // --- LEWA STRONA: IKONA AKCJI + TEKST ---
        Item {
            id: mainArea
            anchors.left: parent.left
            anchors.right: separator.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Row {
                anchors.centerIn: parent
                spacing: 8

                // Ikona "Play"
                Text {
                    text: "▶"
                    color: "white"
                    font.pixelSize: 13
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

            HoverHandler {
                id: mainHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                id: mainTap
                onTapped: root.mainClicked()
            }
        }

        // --- PIONOWY SEPARATOR ---
        Rectangle {
            id: separator
            width: 1
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            anchors.right: dropdownArea.left
            color: Qt.rgba(1, 1, 1, 0.18) // Subtelna półprzezroczysta linia
        }

        // --- PRAWA STRONA: STRZAŁKA DROPDOWN ---
        Item {
            id: dropdownArea
            width: 36
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // Nakładka tła dla strzałki po najechaniu/kliknięciu
            Rectangle {
                anchors.fill: parent
                // Zaokrąglenie tylko po prawej stronie
                radius: bg.radius
                color: dropTap.pressed
                       ? Qt.rgba(0, 0, 0, 0.25)
                       : (dropHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
            }

            Text {
                anchors.centerIn: parent
                text: "∨"
                color: "white"
                font.pixelSize: 12
                font.bold: true
            }

            HoverHandler {
                id: dropHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                id: dropTap
                onTapped: root.dropdownClicked()
            }
        }
    }
}