import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Popup {
    id: root

    property var pluginApi: null
    property var mainInstance: null

    property string deleteUuid: ""
    property string deleteDescription: ""

    function openForTask(uuid, description) {
        root.deleteUuid = uuid;
        root.deleteDescription = description;
        root.open();
    }

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 400 * Style.uiScaleRatio
    height: 180 * Style.uiScaleRatio
    modal: true
    focus: true
    padding: 0

    background: Rectangle {
        color: Color.mSurface
        radius: Style.radiusL
        border.color: Color.mOutline
        border.width: 1
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("panel.delete-confirm-title") || "Delete Task?"
            font.pointSize: Style.fontSizeM
            font.weight: Font.Bold
            color: Color.mOnSurface
        }

        NText {
            Layout.fillWidth: true
            text: root.deleteDescription
            font.pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Style.marginS

            NButton {
                text: pluginApi?.tr("panel.delete-cancel") || "Cancel"
                onClicked: root.close()
            }

            NButton {
                text: pluginApi?.tr("panel.delete-confirm") || "Delete"
                textColor: Color.mOnError
                backgroundColor: Color.mError
                onClicked: {
                    if (root.mainInstance)
                        root.mainInstance.deleteTask(root.deleteUuid);
                    root.close();
                }
            }
        }
    }
}
