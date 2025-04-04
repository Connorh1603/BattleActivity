module.exports = {
  extends: 'airbnb-base',
  env: {
    node: true,
    es2024: true
  },
  rules: {
    'linebreak-style': 'off',       // Deaktiviert CRLF/LF-Prüfung
    'eol-last': 'off',              // Deaktiviert Leerzeile am Dateiende
    'comma-dangle': 'off',          // Deaktiviert fehlende Kommas
    'no-console': 'off',            // Erlaubt console.log
    'object-shorthand': 'off',      // Deaktiviert Property-Shorthand
    'no-multi-spaces': ['error', { ignoreEOLComments: true }] // Ignoriert Kommentare am Ende der Zeile
  }
};
