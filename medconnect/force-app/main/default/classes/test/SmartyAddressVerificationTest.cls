@IsTest
private class SmartyAddressVerificationTest {
    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assert(request.getEndpoint().contains('street=1600'));
            System.assert(request.getEndpoint().contains('city=Washington'));
            System.assert(request.getEndpoint().contains('state=DC'));
            System.assert(request.getEndpoint().contains('zipcode=20500'));

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('[{"delivery_line_1":"1600 Pennsylvania Ave NW","last_line":"Washington DC 20500-0003","analysis":{"dpv_match_code":"Y"}}]');
            return response;
        }
    }

    private class EmptyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('[]');
            return response;
        }
    }

    @IsTest
    static void verifiesUsLocationWhenSmartyReturnsCandidate() {
        setSmartyCredentials();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Location__c location = new Location__c(
            Name = 'White House',
            Street__c = '1600 Pennsylvania Ave NW',
            City__c = 'Washington',
            State__c = 'DC',
            Postal_Code__c = '20500',
            Country__c = 'United States'
        );

        Test.startTest();
        Boolean verified = SmartyAddressVerificationService.verify(location);
        Test.stopTest();

        System.assertEquals(true, verified);
    }

    @IsTest
    static void marksLocationVerifiedWhenLocationIsCreated() {
        setSmartyCredentials();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Location__c location = new Location__c(
            Name = 'White House',
            Street__c = '1600 Pennsylvania Ave NW',
            City__c = 'Washington',
            State__c = 'DC',
            Postal_Code__c = '20500',
            Country__c = 'United States'
        );
        insert location;
        Test.stopTest();

        Location__c updatedLocation = [SELECT Verified__c FROM Location__c WHERE Id = :location.Id];
        System.assertEquals(true, updatedLocation.Verified__c);
    }

    @IsTest
    static void returnsFalseWhenSmartyReturnsNoCandidates() {
        setSmartyCredentials();
        Test.setMock(HttpCalloutMock.class, new EmptyMock());

        Location__c location = new Location__c(
            Name = 'Invalid',
            Street__c = 'Unknown Street',
            City__c = 'Nowhere',
            State__c = 'ZZ',
            Postal_Code__c = '00000',
            Country__c = 'United States'
        );

        Test.startTest();
        Boolean verified = SmartyAddressVerificationService.verify(location);
        Test.stopTest();

        System.assertEquals(false, verified);
    }

    private static void setSmartyCredentials() {
        SmartyAddressVerificationService.authIdOverride = 'test-auth-id';
        SmartyAddressVerificationService.authTokenOverride = 'test-auth-token';
    }
}
