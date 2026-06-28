.pragma library

function normalizeLanguage(language) {
    return (language || "").trim().toUpperCase();
}

function buildRequestBody(text, sourceLanguage, targetLanguage) {
    const source = normalizeLanguage(sourceLanguage);
    const body = {
        "text": [text],
        "target_lang": normalizeLanguage(targetLanguage) || "EN-US",
        "show_billed_characters": true
    };

    if (source.length > 0)
        body.source_lang = source;

    return body;
}

function requestBodyBytes(body) {
    return utf8ByteLength(JSON.stringify(body));
}

function validateRequest(text, sourceLanguage, targetLanguage) {
    return {
        "ok": true,
        "message": ""
    };
}

function parseTranslateResponse(responseText) {
    const response = JSON.parse(responseText);
    const translations = response.translations || [];
    const translation = translations.length > 0 ? translations[0] : {};

    return {
        "text": translation.text || "",
        "detectedSourceLanguage": translation.detected_source_language || "",
        "billedCharacters": translation.billed_characters || 0
    };
}

function formatDeepLError(status, responseText) {
    return "DeepL error: " + status;
}

function utf8ByteLength(text) {
    let bytes = 0;

    for (let i = 0; i < text.length; i++) {
        const code = text.charCodeAt(i);

        if (code < 0x80) {
            bytes += 1;
        } else if (code < 0x800) {
            bytes += 2;
        } else if (code >= 0xd800 && code <= 0xdbff) {
            bytes += 4;
            i += 1;
        } else {
            bytes += 3;
        }
    }

    return bytes;
}
