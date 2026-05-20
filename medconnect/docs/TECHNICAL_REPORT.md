# Relatório Técnico: Projeto MedConnect Salesforce

## 1. Visão Geral do Projeto
O **MedConnect** é uma solução robusta para a gestão de eventos médicos desenvolvida nativamente na plataforma Salesforce. O objetivo principal é automatizar o ciclo de vida de eventos, desde a logística de localização e palestrantes até a comunicação pós-registro com os participantes.

### Objetos do Sistema
*   **Medical_Event__c (Principal):** Armazena dados mestres do evento (Data/Hora, Status, Capacidade, Localização).
*   **Attendee__c & Speaker__c:** Cadastros de participantes e palestrantes, respectivamente.
*   **Event_Attendee__c & Event_Speaker__c:** Objetos de junção que gerenciam os relacionamentos N:N e contêm a lógica de negócio específica para cada inscrição.
*   **Location__c & Clinic_Organizer__c:** Gerenciam o contexto físico e administrativo dos eventos.
*   **Error_Log__c:** Centralizador de erros para monitoramento técnico.

---

## 2. Componentes Desenvolvidos

### Lógica de Negócio (Apex Triggers)
*   **EventAttendeeTriggerHandler:** Automatiza o envio de e-mails de confirmação. Após a inserção de um participante, o sistema dispara uma notificação contendo os detalhes do evento e um link dinâmico para o Google Maps baseado no endereço do local.
*   **EventSpeakerTriggerHandler:** Implementa uma regra de validação crítica de "Double-Booking". O código impede que um palestrante seja alocado em eventos simultâneos, garantindo a integridade da agenda.

### Processamento em Lote (Apex Batch)
*   **MedicalEventPurgeBatch:** Job assíncrono projetado para manutenção da base de dados. Ele remove automaticamente eventos com mais de 2 meses de antiguidade que não foram concluídos (`Live__c = false`), otimizando o armazenamento da org.

### Interface do Usuário (LWC)
*   **eventDetails:** Componente Lightning moderno que consolida todas as informações do evento em uma única visualização. Utiliza abas para separar Detalhes, Palestrantes, Participantes e Localização, melhorando a experiência do usuário (UX).

---

## 3. Decisões Técnicas e Boas Práticas

### Arquitetura de Código
*   **Trigger Handler Pattern:** Separação total entre o evento da trigger e a lógica de execução, facilitando a manutenção e permitindo que a lógica seja chamada de outros contextos.
*   **Service Layer:** O `ErrorLogService` centraliza o tratamento de exceções, permitindo que qualquer erro no sistema seja persistido no banco de dados com stack trace completo para depuração.
*   **Wrapper Classes:** O uso de `EventDetailsWrapper` permite que o LWC receba todos os dados necessários em um único "payload" JSON, reduzindo o número de chamadas de servidor (Round-trips).

### Performance e Limites (Governor Limits)
*   **Bulkificação:** Todas as operações de banco de dados (DML) e consultas (SOQL) são realizadas em coleções, prevenindo erros de limite em inserções massivas.
*   **Cacheable Queries:** Métodos do controller LWC marcados com `(cacheable=true)` para aproveitar o cache do cliente e reduzir o consumo de recursos do servidor.

### Estratégia de Testes
*   **Cobertura Abrangente:** O projeto inclui classes de teste para triggers e processos batch.
*   **Massa de Dados Dinâmica:** Uso de `@TestSetup` para garantir um ambiente de teste isolado e performático.
*   **Testes de Regressão:** Verificação explícita de falhas (cenários negativos) para garantir que as validações de palestrantes funcionem conforme o esperado.

---

## 4. Integrações e Metadados
*   **Integração Geográfica:** Geração de URLs de mapa via Apex, utilizando codificação UTF-8 para garantir compatibilidade com endereços internacionais.
*   **Messaging Service:** Uso intensivo da biblioteca `Messaging` do Salesforce para comunicação outbound por e-mail.

---

## 5. Resultados e Pontos de Atenção

### Pontos Positivos
*   Sistema altamente desacoplado e fácil de estender.
*   Interface rica e responsiva com Lightning Web Components.
*   Rastreabilidade de erros implementada.

### Oportunidades de Melhoria (Débitos Técnicos)
*   **Template de E-mail:** Migrar o corpo do e-mail do código Apex para *Lightning Email Templates* para dar autonomia ao marketing.
*   **Custom Labels:** Substituir strings fixas por rótulos personalizados para suportar multi-idioma.
*   **Filtro de Horário:** Refinar a lógica de choque de horário para considerar minutos exatos, não apenas a flag de evento ativo.
