import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.images
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property var list

    readonly property bool isPinned: root.modelData?.isPinned ?? false
    readonly property bool isImage: root.modelData?.isImage ?? false
    property bool isExpanded: false
    property string fullText: ""
    property bool isTextLoaded: false

    function toggleExpand() {
        root.isExpanded = !root.isExpanded;
        if (root.isExpanded && !root.isImage && !root.isTextLoaded) {
            decodeProc.running = true;
        }
    }

    Process {
        id: decodeProc

        command: root.isPinned
            ? ["sh", "-c", "cat ~/.local/share/caelestia/clipboard/pins/\"$1\".bin 2>/dev/null", "--", String(root.modelData?.pinId ?? "")]
            : ["cliphist", "decode", String(root.modelData?.id ?? "")]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.fullText = text.trim();
                root.isTextLoaded = true;
            }
        }
    }

    function clicked() {
        if (!root.modelData)
            return;
        root.list.visibilities.launcher = false;
        const preview = root.modelData.preview.length > 30 ? root.modelData.preview.slice(0, 30) + "..." : root.modelData.preview;

        // A pinned entry may have rotated out of cliphist, so `cliphist decode`
        // can no longer produce it — the stored bytes are the source of truth.
        if (root.isPinned)
            Clipboard.copyPinned(root.modelData.pinId);
        else
            Quickshell.execDetached(["sh", "-c", "cliphist decode " + root.modelData.id + " | wl-copy"]);

        if (GlobalConfig.utilities.toasts.clipboardChanged)
            Toaster.toast(qsTr("Copied to clipboard"), preview, "content_paste");
    }

    function updateImage(): void {
        if (!root.modelData?.isImage) {
            imagePreview.imagePath = "";
            return;
        }

        // A pinned image has its own stored copy; nothing pre-warms it and no
        // imageReady will ever arrive for it.
        if (root.isPinned) {
            imagePreview.imagePath = root.modelData.imagePath ?? "";
            return;
        }

        // If already cached on disk, display immediately; otherwise wait for imageReady
        if (Clipboard.isImageCached(root.modelData.id)) {
            imagePreview.imagePath = Clipboard.getImagePath(root.modelData.id);
        } else {
            imagePreview.imagePath = "";
        }
    }

    onModelDataChanged: updateImage()
    Component.onCompleted: updateImage()

    /// Listen for the imageReady signal from the C++ backend (forwarded via Clipboard singleton).
    Connections {
        target: Clipboard

        function onImageReady(id: int, path: string): void {
            if (root.isImage && id === root.modelData?.id) {
                imagePreview.imagePath = path;
                imagePreview.reloadToken++;
            }
        }
    }

    implicitHeight: {
        if (root.isExpanded) {
            return root.isImage ? 300 : Math.min(280, Tokens.sizes.launcher.itemHeight + (root.isTextLoaded && root.fullText.length > 80 ? 180 : 120));
        }
        return root.isImage ? Tokens.sizes.launcher.itemHeight * 2 : Tokens.sizes.launcher.itemHeight;
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        id: stateLayer

        anchors.fill: parent
        radius: Tokens.rounding.large
        onClicked: root.clicked()
    }

    Column {
        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.small

        // Top Row (Header)
        Item {
            id: headerRow

            width: parent.width
            height: root.isImage && !root.isExpanded ? Tokens.sizes.launcher.itemHeight * 2 - Tokens.padding.small * 2 : Tokens.sizes.launcher.itemHeight - Tokens.padding.small * 2

            MaterialIcon {
                id: icon

                text: root.isImage ? "image" : "content_paste"
                fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                color: root.isExpanded ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            Item {
                id: imagePreview

                property string imagePath: ""
                property int reloadToken: 0

                width: root.isImage && !root.isExpanded ? 120 : 0
                height: root.isImage && !root.isExpanded ? 80 : 0
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: icon.right
                anchors.leftMargin: root.isImage && !root.isExpanded ? Tokens.spacing.medium : 0
                visible: root.isImage && !root.isExpanded

                Image {
                    anchors.fill: parent
                    asynchronous: true
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    source: imagePreview.imagePath.length > 0 
                        ? ("file://" + imagePreview.imagePath + (imagePreview.reloadToken > 0 ? "?t=" + imagePreview.reloadToken : "")) 
                        : ""
                }
            }

            StyledText {
                id: previewText

                anchors.left: (root.isImage && !root.isExpanded) ? imagePreview.right : icon.right
                anchors.leftMargin: Tokens.spacing.medium
                anchors.right: actionsContainer.left
                anchors.rightMargin: Tokens.spacing.small
                anchors.verticalCenter: parent.verticalCenter
                text: root.isImage ? (root.modelData?.preview ?? "Image") : (root.modelData?.preview ?? "")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
                visible: !(root.isImage && !root.isExpanded)
            }

            // Hover action icons container
            Item {
                id: actionsContainer

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                width: detailBtn.width + pinBtn.width + deleteBtn.width + Tokens.padding.small * 2
                height: 32

                readonly property bool isHovered: stateLayer.containsMouse 
                    || detailBtn.containsMouse 
                    || pinBtn.containsMouse
                    || deleteBtn.containsMouse

                opacity: isHovered || root.isExpanded ? 1.0 : 0.0
                visible: opacity > 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                MouseArea {
                    id: detailBtn

                    width: 32
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: pinBtn.left
                    anchors.rightMargin: Tokens.padding.small
                    hoverEnabled: true
                    onClicked: root.toggleExpand()

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.isExpanded ? "unfold_less" : "unfold_more"
                        color: detailBtn.containsMouse || root.isExpanded ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }
                }

                MouseArea {
                    id: pinBtn

                    width: 32
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: deleteBtn.left
                    anchors.rightMargin: Tokens.padding.small
                    hoverEnabled: true
                    onClicked: {
                        if (!root.modelData)
                            return;
                        if (root.isPinned)
                            Clipboard.unpin(root.modelData.pinId);
                        else
                            Clipboard.pin(root.modelData.id);
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.isPinned ? "keep" : "keep_off"
                        fill: root.isPinned ? 1 : 0
                        color: pinBtn.containsMouse || root.isPinned ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }
                }

                MouseArea {
                    id: deleteBtn

                    width: 32
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    hoverEnabled: true
                    onClicked: {
                        if (!root.modelData)
                            return;
                        if (root.isPinned) {
                            Clipboard.unpin(root.modelData.pinId);
                        } else {
                            Clipboard.deleteEntry(root.modelData.id, root.modelData.preview);
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "delete"
                        color: deleteBtn.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        // Expanded Details Card (for Text)
        StyledRect {
            id: textDetailsCard

            width: parent.width
            height: parent.height - headerRow.height - Tokens.spacing.small
            visible: root.isExpanded && !root.isImage
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerHigh

            StyledFlickable {
                id: textFlickable

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                contentWidth: width
                contentHeight: fullTextDisplay.implicitHeight
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: textFlickable
                }

                StyledText {
                    id: fullTextDisplay

                    width: textFlickable.width
                    text: root.isTextLoaded ? root.fullText : (root.modelData?.preview ?? "")
                    wrapMode: Text.Wrap
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurface
                }
            }
        }

        // Expanded Details Card (for Image)
        StyledRect {
            id: imageDetailsCard

            width: parent.width
            height: parent.height - headerRow.height - Tokens.spacing.small
            visible: root.isExpanded && root.isImage
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerHigh

            CachingImage {
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                path: imagePreview.imagePath
            }
        }
    }
}
