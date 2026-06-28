import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import "TranslationEngine.js" as TranslationEngine
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property bool busy: false
    property string statusText: ""
    property string statusTone: "neutral"
    property string translatedText: ""
    property string lastDetectedSourceLanguage: ""
    property var translationHistory: []
    readonly property url appIconSource: Qt.resolvedUrl("../images/deepl-translator.svg")
    readonly property int historyLimit: 20
    property var sourceLanguages: [{
        "text": i18n("Auto detect"),
        "value": ""
    }, {
        "text": "TR",
        "value": "TR"
    }, {
        "text": "EN",
        "value": "EN"
    }, {
        "text": "DE",
        "value": "DE"
    }, {
        "text": "FR",
        "value": "FR"
    }, {
        "text": "ES",
        "value": "ES"
    }, {
        "text": "IT",
        "value": "IT"
    }, {
        "text": "NL",
        "value": "NL"
    }, {
        "text": "PL",
        "value": "PL"
    }, {
        "text": "PT",
        "value": "PT"
    }, {
        "text": "RU",
        "value": "RU"
    }, {
        "text": "JA",
        "value": "JA"
    }, {
        "text": "ZH",
        "value": "ZH"
    }]
    property var targetLanguages: [{
        "text": "EN-US",
        "value": "EN-US"
    }, {
        "text": "EN-GB",
        "value": "EN-GB"
    }, {
        "text": "TR",
        "value": "TR"
    }, {
        "text": "DE",
        "value": "DE"
    }, {
        "text": "FR",
        "value": "FR"
    }, {
        "text": "ES",
        "value": "ES"
    }, {
        "text": "IT",
        "value": "IT"
    }, {
        "text": "NL",
        "value": "NL"
    }, {
        "text": "PL",
        "value": "PL"
    }, {
        "text": "PT-BR",
        "value": "PT-BR"
    }, {
        "text": "PT-PT",
        "value": "PT-PT"
    }, {
        "text": "RU",
        "value": "RU"
    }, {
        "text": "JA",
        "value": "JA"
    }, {
        "text": "ZH",
        "value": "ZH"
    }]

    function languageValue(languages, index) {
        if (!languages || index < 0 || index >= languages.length)
            return "";

        const language = languages[index];
        return language && language.value !== undefined ? language.value : "";
    }

    function languageIndex(languages, value, fallbackIndex) {
        const selectedValue = value || "";
        for (let i = 0; i < languages.length; i++) {
            if (languages[i].value === selectedValue)
                return i;
        }

        return fallbackIndex;
    }

    function hasLanguage(languages, value) {
        return languageIndex(languages, value, -1) >= 0;
    }

    function firstTargetForLanguageFamily(language) {
        const family = TranslationEngine.languageFamily(language);
        for (let i = 0; i < targetLanguages.length; i++) {
            if (TranslationEngine.languageFamily(targetLanguages[i].value) === family)
                return targetLanguages[i].value;
        }

        return "";
    }

    function setStatus(message, tone) {
        statusText = message;
        statusTone = tone || "neutral";
    }

    function clipboardText() {
        if (clipboard.content === undefined || clipboard.content === null)
            return "";

        return String(clipboard.content);
    }

    function copyToClipboard(text) {
        clipboard.content = text;
    }

    function compactText(text) {
        const singleLine = (text || "").replace(/\s+/g, " ").trim();
        return singleLine.length > 64 ? singleLine.slice(0, 61) + "..." : singleLine;
    }

    function historyLabel(item) {
        const source = item.detectedSourceLanguage || item.sourceLanguage || i18n("Auto");
        const target = item.targetLanguage || "EN-US";
        return source + " -> " + target + ": " + compactText(item.sourceText);
    }

    function loadTranslationHistory() {
        try {
            const parsedHistory = JSON.parse(plasmoid.configuration.translationHistory || "[]");
            translationHistory = Array.isArray(parsedHistory) ? parsedHistory.slice(0, historyLimit) : [];
        } catch (error) {
            translationHistory = [];
        }
    }

    function saveTranslationHistory() {
        plasmoid.configuration.translationHistory = JSON.stringify(translationHistory.slice(0, historyLimit));
    }

    function addTranslationHistory(sourceText, translatedText, sourceLanguage, targetLanguage, result) {
        if (!sourceText || !translatedText)
            return ;

        const item = {
            "sourceText": sourceText,
            "translatedText": translatedText,
            "sourceLanguage": TranslationEngine.normalizeLanguage(sourceLanguage),
            "targetLanguage": TranslationEngine.normalizeLanguage(targetLanguage) || "EN-US",
            "detectedSourceLanguage": TranslationEngine.normalizeLanguage(result.detectedSourceLanguage),
            "timestamp": Date.now()
        };
        const filteredHistory = translationHistory.filter(function(historyItem) {
            return historyItem.sourceText !== item.sourceText
                || historyItem.translatedText !== item.translatedText
                || historyItem.sourceLanguage !== item.sourceLanguage
                || historyItem.targetLanguage !== item.targetLanguage;
        });
        filteredHistory.unshift(item);
        translationHistory = filteredHistory.slice(0, historyLimit);
        saveTranslationHistory();
    }

    function clearTranslationHistory() {
        translationHistory = [];
        saveTranslationHistory();
        setStatus(i18n("History cleared"), "neutral");
    }

    function statusColor() {
        if (statusText.length === 0)
            return Kirigami.Theme.disabledTextColor;

        if (statusTone === "error")
            return Kirigami.Theme.negativeTextColor;

        if (statusTone === "success")
            return Kirigami.Theme.positiveTextColor;

        if (statusTone === "warning")
            return Kirigami.Theme.neutralTextColor;

        return Kirigami.Theme.textColor;
    }

    function setComboValue(comboBox, languages, value, fallbackIndex) {
        comboBox.currentIndex = languageIndex(languages, value, fallbackIndex);
    }

    function sourceValueForTarget(targetLanguage) {
        const target = TranslationEngine.normalizeLanguage(targetLanguage);
        if (hasLanguage(sourceLanguages, target))
            return target;

        const family = TranslationEngine.languageFamily(target);
        return hasLanguage(sourceLanguages, family) ? family : "";
    }

    function targetValueForSource(sourceLanguage) {
        const source = TranslationEngine.normalizeLanguage(sourceLanguage);
        if (hasLanguage(targetLanguages, source))
            return source;

        const family = TranslationEngine.languageFamily(source);
        if (family === "EN")
            return "EN-US";

        return firstTargetForLanguageFamily(family);
    }

    function fallbackTargetForAutoDetect(previousTarget) {
        const previousTargetFamily = TranslationEngine.languageFamily(previousTarget);
        return previousTargetFamily === "EN" ? "TR" : "EN-US";
    }

    function targetValueForAutoDetect(previousTarget, detectedSourceLanguage) {
        const detected = targetValueForSource(detectedSourceLanguage);
        if (detected.length > 0)
            return detected;

        return fallbackTargetForAutoDetect(previousTarget);
    }

    function swapStatus(sourceLanguage, targetLanguage) {
        return i18n("Swapped: %1 -> %2", sourceLanguage.length > 0 ? sourceLanguage : i18n("Auto"), targetLanguage);
    }

    function clearInput(inputTextArea) {
        if (busy)
            return ;

        inputTextArea.text = "";
        translatedText = "";
        lastDetectedSourceLanguage = "";
        setStatus("", "neutral");
    }

    function copyTranslation() {
        if (translatedText.length === 0)
            return ;

        copyToClipboard(translatedText);
        setStatus(i18n("Copied"), "success");
    }

    function translate(text, sourceLanguage, targetLanguage) {
        const apiKey = plasmoid.configuration.apiKey;
        const apiHost = plasmoid.configuration.apiHost || "https://api-free.deepl.com";
        if (!apiKey || apiKey.trim().length === 0) {
            setStatus(i18n("Set your DeepL API key in the widget settings."), "warning");
            return ;
        }
        const validation = TranslationEngine.validateRequest(text, sourceLanguage, targetLanguage);
        if (!validation.ok) {
            setStatus(validation.message, "error");
            return ;
        }
        busy = true;
        setStatus(i18n("Translating..."), "neutral");
        translatedText = "";
        lastDetectedSourceLanguage = "";
        const body = TranslationEngine.buildRequestBody(text, sourceLanguage, targetLanguage);
        const request = new XMLHttpRequest();
        request.open("POST", apiHost + "/v2/translate");
        request.setRequestHeader("Authorization", "DeepL-Auth-Key " + apiKey.trim());
        request.setRequestHeader("Content-Type", "application/json");
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return ;

            busy = false;
            if (request.status >= 200 && request.status < 300) {
                try {
                    const response = TranslationEngine.parseTranslateResponse(request.responseText);
                    translatedText = response.text;
                    lastDetectedSourceLanguage = response.detectedSourceLanguage;
                    if (translatedText.length > 0) {
                        addTranslationHistory(text, translatedText, sourceLanguage, targetLanguage, response);
                        const successStatus = TranslationEngine.formatSuccessStatus(response, sourceLanguage, targetLanguage);
                        if (plasmoid.configuration.autoCopy) {
                            copyToClipboard(translatedText);
                            setStatus(successStatus + " · " + i18n("Copied"), "success");
                        } else {
                            setStatus(successStatus, "success");
                        }
                    } else {
                        setStatus(i18n("No translation returned."), "warning");
                    }
                } catch (error) {
                    setStatus(i18n("Could not read DeepL response."), "error");
                }
                return ;
            }
            setStatus(TranslationEngine.formatDeepLError(request.status, request.responseText), "error");
        };
        request.onerror = function() {
            busy = false;
            setStatus(TranslationEngine.formatDeepLError(0, ""), "error");
        };
        request.send(JSON.stringify(body));
    }

    Component.onCompleted: loadTranslationHistory()

    KQuickControlsAddons.Clipboard {
        id: clipboard
    }

    Plasmoid.icon: "accessories-dictionary"
    Plasmoid.title: i18n("DeepL Translator")
    preferredRepresentation: compactRepresentation

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.medium
        implicitHeight: Kirigami.Units.iconSizes.medium

        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            mipmap: true
            smooth: true
            source: root.appIconSource
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }

    }

    fullRepresentation: Item {
        id: popup

        implicitWidth: Kirigami.Units.gridUnit * 25
        implicitHeight: Kirigami.Units.gridUnit * 34

        function sourceLanguage() {
            return root.languageValue(root.sourceLanguages, sourceLang.currentIndex);
        }

        function targetLanguage() {
            return root.languageValue(root.targetLanguages, targetLang.currentIndex) || "EN-US";
        }

        function currentValidation() {
            return TranslationEngine.validateRequest(inputText.text, sourceLanguage(), targetLanguage());
        }

        function requestSizeRatio() {
            const validation = currentValidation();
            return validation.limitBytes > 0 ? Math.min(validation.bytes / validation.limitBytes, 1) : 0;
        }

        function requestSizeColor() {
            const validation = currentValidation();
            if (!validation.ok)
                return Kirigami.Theme.negativeTextColor;

            return requestSizeRatio() >= 0.85 ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.disabledTextColor;
        }

        function swapLanguagesAndText() {
            const previousSource = sourceLanguage();
            const previousTarget = targetLanguage();
            const previousInput = inputText.text;
            const previousOutput = root.translatedText;
            const sourceForTarget = root.sourceValueForTarget(previousTarget);
            const targetForSource = previousSource && previousSource.length > 0 ? root.targetValueForSource(previousSource) : root.targetValueForAutoDetect(previousTarget, root.lastDetectedSourceLanguage);
            root.setComboValue(sourceLang, root.sourceLanguages, sourceForTarget, 0);
            root.setComboValue(targetLang, root.targetLanguages, targetForSource, 0);
            if (previousOutput.length > 0) {
                inputText.text = previousOutput;
                root.translatedText = previousInput;
            }
            root.setStatus(root.swapStatus(sourceLanguage(), targetLanguage()), "neutral");
        }

        function translateInput() {
            root.translate(inputText.text, sourceLanguage(), targetLanguage());
        }

        function translateIfReady() {
            if (!root.busy && inputText.text.trim().length > 0)
                translateInput();
        }

        function pasteAndTranslate() {
            if (root.busy)
                return ;

            const text = root.clipboardText();
            if (text.trim().length === 0) {
                root.setStatus(i18n("Clipboard is empty"), "warning");
                return ;
            }
            inputText.text = text;
            root.translatedText = "";
            root.lastDetectedSourceLanguage = "";
            inputText.forceActiveFocus();
            translateInput();
        }

        function loadHistoryItem(index) {
            if (index < 0 || index >= root.translationHistory.length)
                return ;

            const item = root.translationHistory[index];
            root.setComboValue(sourceLang, root.sourceLanguages, item.sourceLanguage || "", 0);
            root.setComboValue(targetLang, root.targetLanguages, item.targetLanguage || "EN-US", 0);
            inputText.text = item.sourceText || "";
            root.translatedText = item.translatedText || "";
            root.lastDetectedSourceLanguage = item.detectedSourceLanguage || "";
            inputText.forceActiveFocus();
            root.setStatus(i18n("Loaded from history"), "neutral");
        }

        function focusSource() {
            inputText.forceActiveFocus();
            inputText.selectAll();
        }

        Shortcut {
            sequences: ["Ctrl+Return", "Ctrl+Enter"]
            onActivated: popup.translateIfReady()
        }

        Shortcut {
            sequence: "Ctrl+L"
            onActivated: popup.focusSource()
        }

        Shortcut {
            sequence: "Ctrl+C"
            enabled: root.translatedText.length > 0 && !inputText.activeFocus && !outputText.activeFocus
            onActivated: root.copyTranslation()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing * 1.2

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Image {
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    smooth: true
                    source: root.appIconSource
                }

                PlasmaComponents.Label {
                    font.weight: Font.DemiBold
                    text: i18n("DeepL Translator")
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    color: root.statusColor()
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    text: root.statusText.length > 0 ? root.statusText : i18n("Ready")
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    PlasmaComponents.Label {
                        text: i18n("From")
                    }

                    QQC2.ComboBox {
                        id: sourceLang

                        Layout.fillWidth: true
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 7
                        enabled: !root.busy
                        textRole: "text"
                        valueRole: "value"
                        model: root.sourceLanguages
                        Component.onCompleted: currentIndex = root.languageIndex(root.sourceLanguages, plasmoid.configuration.sourceLang, 0)
                    }

                }

                QQC2.Button {
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    enabled: !root.busy
                    icon.name: "exchange-positions"
                    onClicked: popup.swapLanguagesAndText()
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    QQC2.ToolTip.text: i18n("Swap languages and text")
                    QQC2.ToolTip.visible: hovered
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    PlasmaComponents.Label {
                        text: i18n("To")
                    }

                    QQC2.ComboBox {
                        id: targetLang

                        Layout.fillWidth: true
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 7
                        enabled: !root.busy
                        textRole: "text"
                        valueRole: "value"
                        model: root.targetLanguages
                        Component.onCompleted: currentIndex = root.languageIndex(root.targetLanguages, plasmoid.configuration.targetLang, 0)
                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    font.weight: Font.DemiBold
                    text: i18n("Source")
                }

                QQC2.ToolButton {
                    enabled: !root.busy && inputText.text.length > 0
                    icon.name: "edit-clear"
                    onClicked: root.clearInput(inputText)
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    QQC2.ToolTip.text: i18n("Clear all")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ToolButton {
                    enabled: !root.busy
                    icon.name: "edit-paste"
                    onClicked: popup.pasteAndTranslate()
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    QQC2.ToolTip.text: i18n("Paste and translate")
                    QQC2.ToolTip.visible: hovered
                }

            }

            QQC2.TextArea {
                id: inputText

                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 7
                readOnly: root.busy
                wrapMode: TextEdit.Wrap
                placeholderText: i18n("Text to translate")
                selectByMouse: true
                Keys.onPressed: function(event) {
                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                        event.accepted = true;
                        popup.translateIfReady();
                    } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_L) {
                        event.accepted = true;
                        popup.focusSource();
                    } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C && inputText.selectedText.length === 0 && root.translatedText.length > 0) {
                        event.accepted = true;
                        root.copyTranslation();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        color: popup.requestSizeColor()
                        elide: Text.ElideRight
                        text: popup.currentValidation().ok ? TranslationEngine.requestSizeText(inputText.text, popup.sourceLanguage(), popup.targetLanguage()) : popup.currentValidation().message
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        from: 0
                        to: popup.currentValidation().limitBytes
                        value: Math.min(popup.currentValidation().bytes, popup.currentValidation().limitBytes)
                    }

                }

                QQC2.Button {
                    highlighted: true
                    text: root.busy ? i18n("Translating") : i18n("Translate")
                    enabled: !root.busy && inputText.text.trim().length > 0
                    icon.name: "run-build"
                    onClicked: popup.translateInput()
                }

            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    font.weight: Font.DemiBold
                    text: i18n("Translation")
                }

                QQC2.ToolButton {
                    enabled: !root.busy && root.translatedText.length > 0
                    icon.name: "edit-copy"
                    onClicked: root.copyTranslation()
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    QQC2.ToolTip.text: i18n("Copy translation")
                    QQC2.ToolTip.visible: hovered
                }

            }

            QQC2.TextArea {
                id: outputText

                Layout.fillWidth: true
                Layout.fillHeight: true
                readOnly: true
                wrapMode: TextEdit.Wrap
                text: root.translatedText
                placeholderText: i18n("Translation")
                selectByMouse: true
                Keys.onPressed: function(event) {
                    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_L) {
                        event.accepted = true;
                        popup.focusSource();
                    } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C && outputText.selectedText.length === 0 && root.translatedText.length > 0) {
                        event.accepted = true;
                        root.copyTranslation();
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.translationHistory.length > 0
                spacing: Kirigami.Units.smallSpacing / 2

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        font.weight: Font.DemiBold
                        text: i18n("History")
                    }

                    QQC2.ToolButton {
                        enabled: !root.busy
                        icon.name: "edit-clear-history"
                        onClicked: root.clearTranslationHistory()
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        QQC2.ToolTip.text: i18n("Clear history")
                        QQC2.ToolTip.visible: hovered
                    }

                }

                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                    clip: true

                    ListView {
                        id: historyList

                        model: root.translationHistory
                        spacing: Kirigami.Units.smallSpacing / 2

                        delegate: QQC2.ItemDelegate {
                            required property int index
                            required property var modelData

                            width: historyList.width
                            enabled: !root.busy
                            icon.name: "document-open-recent"
                            text: root.historyLabel(modelData)
                            onClicked: popup.loadHistoryItem(index)
                        }

                    }

                }

            }

        }

    }

}
