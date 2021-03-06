/*
 *   Copyright 2020 Evgeni B<evgeni.biryuk.tail@gofree.club>
 *   Copyright 2020 Dan Leinir Turthra Jensen <admin@leinir.dk>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 3, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public License
 *   along with this program; if not, see <https://www.gnu.org/licenses/>
 */

import QtQuick 2.11
import QtQuick.Controls 2.11
import QtQuick.Layouts 1.11
import org.kde.kirigami 2.13 as Kirigami
import org.thetailcompany.digitail 1.0 as Digitail

Kirigami.ScrollablePage {
    id: component;
    objectName: "gearGestures";
    title: i18nc("Title for the page for selecting a pose for the Gear", "Gear Gestures");
    actions {
        main: Kirigami.Action {
            text: i18nc("Button for returning Gear to the home position, on the page for selecting a pose for the Gear", "Home Position");
            icon.name: "go-home";
            onTriggered: {
                BTConnectionManager.sendMessage("TAILHM", []);
            }
        }
    }
    property QtObject enabledGestures: Digitail.FilterProxyModel {
        sourceModel: GestureDetectorModel;
        filterRole: 261; // the sensorEnabledRole role
        filterBoolean: true;
    }

    ColumnLayout {
        width: component.width - Kirigami.Units.largeSpacing * 4
        InfoCard {
            text: i18nc("Info card for the page for selecting a pose for the Gear", "Turn on one of the sensors below to make your gear react to gestures performed on this device, if there is nothing else going on (that is, no current commands, and an empty command queue). For example, make your ears perk up when the device recognises that is has been picked up, or start wagging when it detects that you have taken a step.");
        }
        Repeater {
            model: GestureDetectorModel;
            ColumnLayout {
                ColumnLayout {
                    visible: model.firstInSensor === undefined ? false : model.firstInSensor;
                    Layout.fillWidth: true;
                    Rectangle {
                        Layout.fillWidth: true;
                        height: 1;
                        color: Kirigami.Theme.textColor;
                        visible: model.index > 0
                    }
                    Kirigami.BasicListItem {
                        visible: model.firstInSensor === undefined ? false : model.firstInSensor;
                        Layout.fillWidth: true;
                        separatorVisible: false;
                        bold: true;
                        icon: model.sensorEnabled > 0 ? ":/icons/breeze-internal/emblems/16/checkbox-checked" : ":/icons/breeze-internal/emblems/16/checkbox-unchecked";
                        label: model.sensorName === undefined ? "" : model.sensorName;
                        onClicked: {
                            if(!model.sensorEnabled && enabledGestures.count > 0) {
                                applicationWindow().showMessageBox(i18nc("Title for the warning for having enabled multiple gestures at the same time, on the page for selecting a pose for the Gear","Multiple Gestures"),
                                    i18nc("Description for the warning for having enabled multiple gestures at the same time, on the page for selecting a pose for the Gear", "You are attempting to turn on more than one gesture at the same time. This will occasionally cause problems, primarily by being confusing to manage (for example, turning on both Walking and Shake is likely to cause both to be detected). If you are sure you want to do this, tap OK, or tap Cancel to not enable this gesture."),
                                    function() {GestureController.setGestureSensorEnabled(model.index, !model.sensorEnabled)});
                            } else {
                                GestureController.setGestureSensorEnabled(model.index, !model.sensorEnabled);
                            }
                        }
                    }
                    CheckBox {
                        Layout.fillWidth: true;
                        text: i18nc("Description for the checkbox for showing a gesture on the Welcome Page, on the page for selecting a pose for the Gear", "Show On Welcome Page")
                        checked: model.sensorPinned === undefined ? false : model.sensorPinned
                        onClicked: GestureController.setGestureSensorPinned(model.index, !model.sensorPinned)
                    }
                }
                RowLayout {
                    id: gestureDelegate;
                    Layout.fillWidth: true;
                    Text {
                        Layout.fillWidth: true;
                        text: model.name === undefined ? "" : model.name;
                    }
                    Button {
                        text: model.command === "" ? i18nc("Default text for the button for picking a command, for when no command has been selected, on the page for selecting a pose for the Gear", "(no command)"): model.command;
                        onClicked: {
                            pickACommand.gestureIndex = model.index;
                            pickACommand.pickCommand();
                        }
                    }
                    ToolButton {
                        Layout.alignment: Qt.AlignVCenter
                        height: parent.height - Kirigami.Units.smallSpacing * 2;
                        width: height;
                        icon.name: "edit-clear"
                        visible: model.command !== "";
                        onClicked: {
                            GestureController.setGestureDetails(model.index, "", "");
                        }
                    }
                    ToolButton {
                        Layout.alignment: Qt.AlignVCenter
                        height: parent.height - Kirigami.Units.smallSpacing * 2;
                        width: height;
                        icon.name: "document-revert"
                        visible: model.command === "" && model.defaultCommand !== "";
                        onClicked: {
                            GestureController.setGestureDetails(model.index, model.defaultCommand, "");
                        }
                    }
                }
            }
        }
    }

    PickACommandSheet {
        id: pickACommand;

        property int gestureIndex;

        onCommandPicked: {
            GestureController.setGestureDetails(pickACommand.gestureIndex, command, destinations);
            pickACommand.close();
        }
    }
}
