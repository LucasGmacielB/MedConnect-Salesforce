public with sharing class ViaCepAddressVerificationService {
    private static final String ENDPOINT_BASE = 'https://viacep.com.br/ws/';
    private static final Integer TIMEOUT_MS = 10000;

    public static Boolean verify(Location__c location) {
        if (location == null || !isBrazilianAddress(location) || String.isBlank(location.Postal_Code__c)) {
            return false;
        }

        String cep = normalizeCep(location.Postal_Code__c);
        if (cep.length() != 8 || cep.replaceAll('[0-9]', '').length() != 0) {
            return false;
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(ENDPOINT_BASE + cep + '/json/');
        request.setTimeout(TIMEOUT_MS);

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() != 200) {
            throw new CalloutException('ViaCEP returned HTTP ' + response.getStatusCode() + ': ' + response.getBody());
        }

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        if (payload.containsKey('erro') && Boolean.valueOf(String.valueOf(payload.get('erro')))) {
            return false;
        }

        return fieldMatches(location.City__c, String.valueOf(payload.get('localidade'))) &&
            fieldMatches(location.State__c, String.valueOf(payload.get('uf'))) &&
            streetMatches(location.Street__c, String.valueOf(payload.get('logradouro')));
    }

    private static String normalizeCep(String postalCode) {
        return postalCode.replaceAll('[^0-9]', '');
    }

    private static Boolean isBrazilianAddress(Location__c location) {
        if (String.isBlank(location.Country__c)) {
            return true;
        }

        String country = normalizeText(location.Country__c);
        return country == 'brazil' || country == 'brasil' || country == 'br';
    }

    private static Boolean fieldMatches(String localValue, String apiValue) {
        if (String.isBlank(localValue) || String.isBlank(apiValue)) {
            return true;
        }

        return normalizeText(localValue) == normalizeText(apiValue);
    }

    private static Boolean streetMatches(String localStreet, String apiStreet) {
        if (String.isBlank(localStreet) || String.isBlank(apiStreet)) {
            return true;
        }

        String normalizedLocalStreet = normalizeText(localStreet);
        String normalizedApiStreet = normalizeText(apiStreet);
        return normalizedLocalStreet == normalizedApiStreet ||
            normalizedLocalStreet.contains(normalizedApiStreet) ||
            normalizedApiStreet.contains(normalizedLocalStreet);
    }

    private static String normalizeText(String value) {
        if (value == null) {
            return '';
        }

        return value.trim().toLowerCase()
            .replace('á', 'a')
            .replace('à', 'a')
            .replace('â', 'a')
            .replace('ã', 'a')
            .replace('é', 'e')
            .replace('ê', 'e')
            .replace('í', 'i')
            .replace('ó', 'o')
            .replace('ô', 'o')
            .replace('õ', 'o')
            .replace('ú', 'u')
            .replace('ü', 'u')
            .replace('ç', 'c');
    }
}
