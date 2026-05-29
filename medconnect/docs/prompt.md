Crie um LWC para a Experience Cloud do projeto MedConnect, com visual de landing page pública parecida com um site externo de eventos médicos.

Nome do componente:
communityEventLanding

Objetivo:
Exibir uma página inicial pública da comunidade MedConnect com cabeçalho, seção principal, cards de próximos eventos e rodapé.

Requisitos visuais:
1. Header simples com logo/texto "MedConnect" à esquerda e "Healthcare Events and Conferences" à direita.
2. Hero section com título:
   "Central de Informações Científicas"
3. Subtítulo:
   "Consulte o cronograma atualizado de congressos, simpósios e painéis médicos do setor de saúde."
4. Seção "Próximos Eventos Programados".
5. Cards de eventos em grid responsivo.
6. Rodapé com:
   - MedConnect
   - Navegação
   - Contato & Ajuda

Requisitos técnicos:
1. Criar LWC em:
   force-app/main/default/lwc/communityEventLanding

2. Criar Apex Controller:
   CommunityEventLandingController

3. O controller deve retornar apenas Medical_Event__c com:
   - Live__c = true
   - Start_Date_Time__c >= System.now()

4. Campos retornados:
   - Id
   - Event_Name__c
   - Start_Date_Time__c
   - End_Date_Time__c
   - Event_Type__c
   - Status__c
   - Address__r.Name
   - Address__r.City__c
   - Address__r.State__c

5. Usar wrapper DTO para evitar expor o SObject diretamente.

6. O LWC deve exibir:
   - categoria ou tipo do evento
   - nome do evento
   - período/data
   - local
   - descrição curta, se existir algum campo disponível; se não existir, usar texto padrão.

7. Ao clicar no card, navegar para a página de detalhe do Medical_Event__c, se possível.

8. O meta XML deve permitir uso em Experience Cloud:
   - lightningCommunity__Page
   - lightningCommunity__Default

9. Usar CSS próprio simples, limpo e responsivo.

10. Criar teste Apex para o controller.

11. Criar teste Jest básico para o LWC.

12. Rodar:
   npm run test:unit
   sf project deploy validate --source-dir force-app --test-level RunLocalTests

Importante:
- Não alterar API Names existentes.
- Usar Address__r, não Location__r.
- Usar Specialization__c se algum Speaker for usado.
- Não quebrar os LWCs existentes.