@IsTest
private class ViaCepAddressVerificationTest {
    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assert(request.getEndpoint().contains('/01001000/json/'));

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"cep":"01001-000","logradouro":"Praca da Se","complemento":"lado impar","bairro":"Se","localidade":"Sao Paulo","uf":"SP","ibge":"3550308","gia":"1004","ddd":"11","siafi":"7107"}');
            return response;
        }
    }

    private class NotFoundMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"erro":true}');
            return response;
        }
    }

    @IsTest
    static void verifiesBrazilianLocationWhenViaCepReturnsCompatibleAddress() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Location__c location = new Location__c(
            Name = 'Praca da Se',
            Street__c = 'Praca da Se',
            City__c = 'Sao Paulo',
            State__c = 'SP',
            Postal_Code__c = '01001000',
            Country__c = 'Brazil'
        );

        Test.startTest();
        Boolean verified = ViaCepAddressVerificationService.verify(location);
        Test.stopTest();

        System.assertEquals(true, verified);
    }

    @IsTest
    static void marksLocationVerifiedWhenLocationIsCreated() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Location__c location = new Location__c(
            Name = 'Praca da Se',
            Street__c = 'Praca da Se',
            City__c = 'Sao Paulo',
            State__c = 'SP',
            Postal_Code__c = '01001000',
            Country__c = 'Brazil'
        );
        insert location;
        Test.stopTest();

        Location__c updatedLocation = [SELECT Verified__c FROM Location__c WHERE Id = :location.Id];
        System.assertEquals(true, updatedLocation.Verified__c);
    }

    @IsTest
    static void returnsFalseWhenViaCepReturnsError() {
        Test.setMock(HttpCalloutMock.class, new NotFoundMock());

        Location__c location = new Location__c(
            Name = 'Invalid',
            Street__c = 'Rua Inexistente',
            City__c = 'Cidade',
            State__c = 'PE',
            Postal_Code__c = '99999999',
            Country__c = 'Brazil'
        );

        Test.startTest();
        Boolean verified = ViaCepAddressVerificationService.verify(location);
        Test.stopTest();

        System.assertEquals(false, verified);
    }
}
