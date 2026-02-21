/**
 * Localization Utilities
 * Auto-detect locale and format currency/numbers accordingly
 */

/**
 * Get user's detected locale
 * @returns {string} Locale string like 'en-IN', 'en-US', etc.
 */
export function getDeviceLocale() {
    return navigator.language || navigator.userLanguage || 'en-US';
}

/**
 * Get currency code based on locale
 * @param {string} locale 
 * @returns {string} Currency code like 'INR', 'USD', etc.
 */
export function getCurrencyForLocale(locale) {
    const currencyMap = {
        'en-IN': 'INR',
        'hi-IN': 'INR',
        'en-US': 'USD',
        'en-GB': 'GBP',
        'de-DE': 'EUR',
        'fr-FR': 'EUR',
        'ja-JP': 'JPY',
        'zh-CN': 'CNY',
        'en-AU': 'AUD',
        'en-CA': 'CAD',
    };

    // Try exact match first
    if (currencyMap[locale]) return currencyMap[locale];

    // Try language-only match
    const langOnly = locale.split('-')[0];
    const fallbacks = { 'en': 'USD', 'hi': 'INR', 'de': 'EUR', 'fr': 'EUR', 'ja': 'JPY', 'zh': 'CNY' };
    return fallbacks[langOnly] || 'USD';
}

/**
 * Format a number as currency
 * @param {number} value - The numeric value
 * @param {string} locale - Optional locale override
 * @param {string} currency - Optional currency override (e.g., 'INR', 'USD')
 * @returns {string} Formatted currency string
 */
export function formatCurrency(value, locale = null, currency = null) {
    // If currency is explicitly provided (e.g. from contract), respect it
    // Map currency code to a locale that uses it, or use device locale if match
    let usedLocale = locale || getDeviceLocale();

    if (currency) {
        // Force locale based on currency if generic locale doesn't match
        if (currency === 'INR') usedLocale = 'en-IN';
        else if (currency === 'EUR') usedLocale = 'de-DE';
        else if (currency === 'GBP') usedLocale = 'en-GB';
        else if (currency === 'JPY') usedLocale = 'ja-JP';
    }

    const usedCurrency = currency || getCurrencyForLocale(usedLocale);

    try {
        return new Intl.NumberFormat(usedLocale, {
            style: 'currency',
            currency: usedCurrency,
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    } catch (e) {
        // Fallback formatting
        return `${usedCurrency} ${value.toLocaleString()}`;
    }
}

/**
 * Get location label for UI display
 * @returns {string} Label like "Prices based on India"
 */
export function getLocationLabel() {
    const locale = getDeviceLocale();
    const regionMap = {
        'IN': 'India',
        'US': 'United States',
        'GB': 'United Kingdom',
        'DE': 'Germany',
        'FR': 'France',
        'JP': 'Japan',
        'CN': 'China',
        'AU': 'Australia',
        'CA': 'Canada',
    };

    const regionCode = locale.split('-')[1] || 'US';
    const regionName = regionMap[regionCode] || 'your region';

    return `Prices based on ${regionName}`;
}

export default {
    getDeviceLocale,
    getCurrencyForLocale,
    formatCurrency,
    getLocationLabel
};
