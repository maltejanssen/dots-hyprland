import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property string protectionMessage: ""
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
 
    property int volume: -1
    property int micVolume: -1
    property bool muted: false
    Process {
      running: true
      onRunningChanged: running = true
      command: ["pactl", "subscribe"]
      stdout: SplitParser {
        onRead: data => {
          const [, updatedSink] = data.match(/sink #(\d+)/) ?? []
          if (updatedSink) {
            volumeProcess.running = true
            muteProcess.running = true
            return
          }
          const [, updatedSource] = data.match(/source #(\d+)/) ?? []
          if (updatedSource) {
            micVolumeProcess.running = true
            micMuteProcess.running = true
            return
          }
        }
      }
    }

    Process {
      running: true
      id: volumeProcess
      command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
      stdout: SplitParser {
        splitMarker: ""
        onRead: data => {
          volume = Number(data.match(/(\d+)%/)?.[1] || 0)
          console.log(volume)
        }
      }
    }

    Process {
      running: true
      id: muteProcess
      command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]
      stdout: SplitParser { splitMarker: ""; onRead: data => muted = data == "Mute: yes\n" }
    }

    function triggerOsd() {
        GlobalStates.osdVolumeOpen = true
        osdTimeout.restart()
    }

    Timer {
        id: osdTimeout
        interval: Config.options.osd.timeout
        repeat: false
        running: false
        onTriggered: {
            GlobalStates.osdVolumeOpen = false
            root.protectionMessage = ""
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            GlobalStates.osdVolumeOpen = false
        }
   }

    Connections { // Listen to protection triggers
        target: Audio
        function onSinkProtectionTriggered(reason) {
            root.protectionMessage = reason;
            root.triggerOsd()
        }
    }

    Loader {
        id: osdLoader
        active: GlobalStates.osdVolumeOpen

        sourceComponent: PanelWindow {
            id: osdRoot
            color: "transparent"

            Connections {
                target: root
                function onFocusedScreenChanged() {
                    osdRoot.screen = root.focusedScreen
                }
            }

            WlrLayershell.namespace: "quickshell:onScreenDisplay"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors {
                top: !Config.options.bar.bottom
                bottom: Config.options.bar.bottom
            }
            mask: Region {
                item: osdValuesWrapper
            }

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            margins {
                top: Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
            }

            implicitWidth: columnLayout.implicitWidth
            implicitHeight: columnLayout.implicitHeight
            visible: osdLoader.active

            ColumnLayout {
                id: columnLayout
                anchors.horizontalCenter: parent.horizontalCenter
                Item {
                    id: osdValuesWrapper
                    // Extra space for shadow
                    implicitHeight: contentColumnLayout.implicitHeight + Appearance.sizes.elevationMargin * 2
                    implicitWidth: contentColumnLayout.implicitWidth
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: GlobalStates.osdVolumeOpen = false
                    }

                    ColumnLayout {
                        id: contentColumnLayout
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            leftMargin: Appearance.sizes.elevationMargin
                            rightMargin: Appearance.sizes.elevationMargin
                        }
                        spacing: 0

                        OsdValueIndicator {
                            id: osdValues
                            Layout.fillWidth: true
                            value: volume ?? 0
                            icon: muted ? "volume_off" : "volume_up"
                            name: Translation.tr("Volume")
                        }

                        Item {
                            id: protectionMessageWrapper
                            implicitHeight: protectionMessageBackground.implicitHeight
                            implicitWidth: protectionMessageBackground.implicitWidth
                            Layout.alignment: Qt.AlignHCenter
                            opacity: root.protectionMessage !== "" ? 1 : 0

                            StyledRectangularShadow {
                                target: protectionMessageBackground
                            }
                            Rectangle {
                                id: protectionMessageBackground
                                anchors.centerIn: parent
                                color: Appearance.m3colors.m3error
                                property real padding: 10
                                implicitHeight: protectionMessageRowLayout.implicitHeight + padding * 2
                                implicitWidth: protectionMessageRowLayout.implicitWidth + padding * 2
                                radius: Appearance.rounding.normal

                                RowLayout {
                                    id: protectionMessageRowLayout
                                    anchors.centerIn: parent
                                    MaterialSymbol {
                                        id: protectionMessageIcon
                                        text: "dangerous"
                                        iconSize: Appearance.font.pixelSize.hugeass
                                        color: Appearance.m3colors.m3onError
                                    }
                                    StyledText {
                                        id: protectionMessageTextWidget
                                        horizontalAlignment: Text.AlignHCenter
                                        color: Appearance.m3colors.m3onError
                                        wrapMode: Text.Wrap
                                        text: root.protectionMessage
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
		target: "osdVolume"

		function trigger() {
            root.triggerOsd()
        }

        function hide() {
            GlobalStates.osdVolumeOpen = false
        }

        function toggle() {
            GlobalStates.osdVolumeOpen = !GlobalStates.osdVolumeOpen
        }
	}
    GlobalShortcut {
        name: "osdVolumeTrigger"
        description: "Triggers volume OSD on press"

        onPressed: {
            root.triggerOsd()
        }
    }
    GlobalShortcut {
        name: "osdVolumeHide"
        description: "Hides volume OSD on press"

        onPressed: {
            GlobalStates.osdVolumeOpen = false
        }
    }

}
