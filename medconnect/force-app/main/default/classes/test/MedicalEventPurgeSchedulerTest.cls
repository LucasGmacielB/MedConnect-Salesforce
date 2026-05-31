@IsTest
private class MedicalEventPurgeSchedulerTest {
    
    @IsTest
    static void testSchedulerExecution() {
        // Expressão CRON para execução no dia primeiro do próximo ano.
        // É apenas para agendamento, pois o Test.stopTest() forçará a execução síncrona se necessário
        // ou podemos apenas validar que a job foi agendada corretamente.
        String cronExp = '0 0 0 1 1 ? 2030';
        
        Test.startTest();
        
        // Agendar a classe
        String jobId = System.schedule(
            'Test_MedicalEventPurgeScheduler', 
            cronExp, 
            new MedicalEventPurgeScheduler()
        );
        
        Test.stopTest();
        
        // Obter as informações do agendamento
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime 
            FROM CronTrigger 
            WHERE Id = :jobId
        ];
        
        // Verificar se a expressão CRON é a mesma e se a job foi criada
        System.assertEquals(cronExp, ct.CronExpression, 'A expressão CRON deve ser a mesma.');
        System.assertEquals(0, ct.TimesTriggered, 'A job não deve ter sido engatilhada ainda.');
        System.assertEquals('2030-01-01 00:00:00', String.valueOf(ct.NextFireTime), 'A data da próxima execução deve ser 01/01/2030');
    }
}
