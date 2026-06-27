import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_apiKey: apiKeyField.text
    property string cfg_apiHost: "https://api-free.deepl.com"
    property string cfg_targetLang: "EN-US"
    property string cfg_sourceLang: ""
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

    function languageIndex(comboBox, value, fallbackIndex) {
        const index = comboBox.indexOfValue(value || "");
        return index >= 0 ? index : fallbackIndex;
    }

    QQC2.TextField {
        id: apiKeyField

        Kirigami.FormData.label: i18n("API key:")
        echoMode: TextInput.Password
        placeholderText: i18n("DeepL API key")
    }

    QQC2.ComboBox {
        id: apiHostBox

        Kirigami.FormData.label: i18n("Account:")
        textRole: "text"
        valueRole: "value"
        model: [{
            "text": i18n("Free"),
            "value": "https://api-free.deepl.com"
        }, {
            "text": i18n("Pro"),
            "value": "https://api.deepl.com"
        }]
        Component.onCompleted: {
            const index = indexOfValue(page.cfg_apiHost);
            currentIndex = index >= 0 ? index : 0;
        }
        onCurrentValueChanged: page.cfg_apiHost = currentValue
    }

    QQC2.ComboBox {
        id: targetLangBox

        Kirigami.FormData.label: i18n("Default target language:")
        textRole: "text"
        valueRole: "value"
        model: page.targetLanguages
        Component.onCompleted: currentIndex = page.languageIndex(targetLangBox, page.cfg_targetLang, 0)
        onCurrentValueChanged: page.cfg_targetLang = currentValue
    }

    QQC2.ComboBox {
        id: sourceLangBox

        Kirigami.FormData.label: i18n("Default source language:")
        textRole: "text"
        valueRole: "value"
        model: page.sourceLanguages
        Component.onCompleted: currentIndex = page.languageIndex(sourceLangBox, page.cfg_sourceLang, 0)
        onCurrentValueChanged: page.cfg_sourceLang = currentValue
    }

    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("Leave source language empty for automatic detection.")
    }

}
