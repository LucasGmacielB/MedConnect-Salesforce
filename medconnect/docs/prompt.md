Corrija a regra de duplicidade no objeto Event_Attendee__c.

Problema:
Atualmente o sistema permite adicionar o mesmo Attendee__c mais de uma vez ao mesmo Medical_Event__c. Isso está incorreto. O mesmo participante não pode se inscrever duas vezes no mesmo evento.

Comportamento esperado:
Ao criar ou atualizar um Event_Attendee__c, o sistema deve bloquear quando já existir outro Event_Attendee__c com:
- o mesmo Medical_Event__c
- o mesmo Attendee__c

Requisitos técnicos:
1. Atualizar EventAttendeeTrigger para rodar em before insert e before update, além do fluxo atual de after insert para envio de e-mail.
2. Criar ou atualizar EventAttendeeTriggerHandler com um método, por exemplo:
   preventDuplicateAttendeeRegistration(List<Event_Attendee__c> newRecords, Map<Id, Event_Attendee__c> oldMap)

3. A lógica deve ser bulk-safe:
   - coletar Medical_Event__c e Attendee__c dos registros novos
   - consultar Event_Attendee__c existentes
   - ignorar o próprio registro no caso de update
   - usar addError() para bloquear duplicidade

4. Mensagem de erro sugerida:
   "This attendee is already registered for this medical event."

5. Manter o envio de e-mail somente em after insert.
6. Não enviar e-mail se o registro foi bloqueado por duplicidade.
7. Atualizar ou criar testes Apex cobrindo:
   - criação válida de Event_Attendee__c
   - tentativa duplicada do mesmo attendee no mesmo evento deve falhar
   - mesmo attendee em evento diferente deve ser permitido
   - attendee diferente no mesmo evento deve ser permitido

8. Garantir que:
   sf project deploy validate --source-dir force-app --test-level RunLocalTests
   passe com sucesso.

9. Ao final, informar:
   - arquivos alterados
   - regra implementada
   - testes executados