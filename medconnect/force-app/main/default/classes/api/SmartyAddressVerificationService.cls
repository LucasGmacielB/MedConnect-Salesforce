public with sharing class SmartyAddressVerificationService {
    private static final String ENDPOINT = 'https://us-street.api.smarty.com/street-address';
    private static final Integer TIMEOUT_MS = 10000;

    @TestVisible private static String authIdOverride;
    @TestVisible private static String authTokenOverride;

    public class MissingCredentialsException extends Exception {}

    public static Boolean verify(Location__c location) {
        if (location == null || !isUsAddress(location) || String.isBlank(location.Street__c)) {
            return false;
        }

        String authId = getAuthId();
        String authToken = getAuthToken();
        if (String.isBlank(authId) || String.isBlank(authToken) || authId == 'CHANGE_ME' || authToken == 'CHANGE_ME') {
            throw new MissingCredentialsException('Smarty credentials are not configured.');
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(buildEndpoint(location, authId, authToken));
        request.setTimeout(TIMEOUT_MS);

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() != 200) {
            throw new CalloutException('Smarty returned HTTP ' + response.getStatusCode() + ': ' + response.getBody());
        }

        List<Object> candidates = (List<Object>) JSON.deserializeUntyped(response.getBody());
        if (candidates.isEmpty()) {
            return false;
        }

        Map<String, Object> candidate = (Map<String, Object>) candidates[0];
        Map<String, Object> analysis = (Map<String, Object>) candidate.get('analysis');
        if (analysis == null || !analysis.containsKey('dpv_match_code')) {
            return true;
        }

        String dpvMatchCode = String.valueOf(analysis.get('dpv_match_code'));
        return new Set<String>{ 'Y', 'S', 'D' }.contains(dpvMatchCode);
    }

    private static String buildEndpoint(Location__c location, String authId, String authToken) {
        List<String> parameters = new List<String>{
            'auth-id=' + EncodingUtil.urlEncode(authId, 'UTF-8'),
            'auth-token=' + EncodingUtil.urlEncode(authToken, 'UTF-8'),
            'street=' + EncodingUtil.urlEncode(location.Street__c, 'UTF-8'),
            'candidates=1',
            'match=strict'
        };

        if (String.isNotBlank(location.City__c)) {
            parameters.add('city=' + EncodingUtil.urlEncode(location.City__c, 'UTF-8'));
        }
        if (String.isNotBlank(location.State__c)) {
            parameters.add('state=' + EncodingUtil.urlEncode(location.State__c, 'UTF-8'));
        }
        if (String.isNotBlank(location.Postal_Code__c)) {
            parameters.add('zipcode=' + EncodingUtil.urlEncode(location.Postal_Code__c, 'UTF-8'));
        }

        return ENDPOINT + '?' + String.join(parameters, '&');
    }

    private static Boolean isUsAddress(Location__c location) {
        if (String.isBlank(location.Country__c)) {
            return true;
        }

        String country = location.Country__c.trim().toLowerCase();
        return new Set<String>{ 'us', 'usa', 'u.s.', 'u.s.a.', 'united states', 'united states of america' }.contains(country);
    }

    private static String getAuthId() {
        return authIdOverride != null ? authIdOverride : Label.Smarty_Auth_Id;
    }

    private static String getAuthToken() {
        return authTokenOverride != null ? authTokenOverride : Label.Smarty_Auth_Token;
    }
}
