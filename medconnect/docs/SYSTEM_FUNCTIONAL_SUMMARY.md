# Resumo funcional do sistema MedConnect

Este documento consolida o que existe hoje no projeto Salesforce **MedConnect**, com foco nas funcionalidades implementadas e nos pontos que devem ser comparados com o documento original do projeto para identificar o que ainda falta desenvolver.

## Visao geral

O MedConnect e um sistema Salesforce para gestao de eventos medicos. A solucao cobre cadastro de eventos, organizadores, locais, palestrantes e participantes, alem de regras de validacao, integracao com ViaCEP, API REST para consulta de eventos, envio de e-mail de confirmacao e tela Lightning para visualizacao consolidada dos detalhes de um evento.

## Modelo de dados implementado

### Medical_Event__c

Objeto principal do sistema, usado para representar eventos medicos.

Campos e capacidades principais:

- Nome do evento em `Event_Name__c`.
- Data e hora de inicio em `Start_Date_Time__c`.
- Data e hora de termino em `End_Date_Time__c`.
- Status do evento em `Status__c`, com valores como `Created`, `Published`, `In Progress`, `Completed`, `Postponed` e `Cancelled`.
- Tipo do evento em `Event_Type__c`, com suporte a evento presencial e virtual.
- Indicador de evento ativo em `Live__c`.
- Organizador vinculado por lookup em `Organizer__c`.
- Local vinculado por lookup em `Address__c`.
- Controle de recorrencia com `Recurring__c` e `Frequency__c`.
- Capacidade maxima em `Max_Seats__c`.
- Total de participantes em `People_Attending__c`, calculado por roll-up summary.
- Vagas restantes em `Remaining_Seats__c`, calculado por formula `Max_Seats__c - People_Attending__c`.
- Indicador de local verificado em `Location_Verified__c`, calculado a partir de `Address__r.Verified__c`.

Regras de validacao existentes:

- A data de termino deve ser pelo menos 1 dia apos a data de inicio.
- Eventos presenciais precisam ter local informado.
- Eventos virtuais nao podem ter local informado.
- Se o evento for recorrente, a frequencia e obrigatoria.
- Se o evento nao for recorrente, a frequencia deve ficar vazia.

### Location__c

Objeto de locais/endereco dos eventos.

Campos principais:

- Rua (`Street__c`).
- Cidade (`City__c`).
- Estado (`State__c`).
- CEP (`Postal_Code__c`).
- Pais (`Country__c`).
- Ponto de referencia (`Landmark__c`).
- Indicador de endereco verificado (`Verified__c`).

Funcionalidades associadas:

- Validacao assincrona de endereco brasileiro via ViaCEP.
- Revalidacao automatica quando campos de endereco sao alterados.
- Propagacao indireta do status de verificacao para eventos por meio do campo formula `Medical_Event__c.Location_Verified__c`.

### Attendee__c

Objeto de cadastro de participantes.

Campos principais:

- E-mail (`Email__c`).
- Telefone (`Phone__c`).
- Empresa/instituicao (`Company_Institution_Name__c`).
- Endereco (`Address__c`).

### Speaker__c

Objeto de cadastro de palestrantes.

Campos principais:

- E-mail (`Email__c`).
- Telefone (`Phone__c`).
- Especialidade (`Specialization__c`).

### Event_Attendee__c

Objeto de juncao entre evento medico e participante.

Funcionalidades associadas:

- Relaciona participantes a eventos.
- Impede cadastro de participante quando o evento ja terminou, esta inativo ou nao possui vagas.
- Dispara e-mail de confirmacao apos a inscricao.

### Event_Speaker__c

Objeto de juncao entre evento medico e palestrante.

Funcionalidades associadas:

- Relaciona palestrantes a eventos.
- Impede atribuicao de palestrante a evento encerrado ou inativo.
- Impede que o mesmo palestrante seja associado a outro evento ativo/futuro.

### Clinic_Organizer__c

Objeto de cadastro dos organizadores.

Campos principais:

- E-mail principal e alternativo.
- Telefone principal e alternativo.
- Local vinculado.

### Error_Log__c

Objeto tecnico para registro de falhas.

Campos principais:

- Processo de origem (`Process_Name__c`).
- Detalhes do erro (`Log_Details__c`).
- Data/hora do erro (`Log_Date_Time__c`).

E usado por servicos Apex para persistir falhas de API, batch, e-mail e integracoes.

## Automacoes e regras de negocio

### Confirmacao de inscricao por e-mail

Quando um registro `Event_Attendee__c` e criado, a trigger `EventAttendeeTrigger` chama `EventAttendeeTriggerHandler.sendConfirmationEmails`.

O fluxo atual:

1. Busca o template `Event_Registration_Confirmation`.
2. Consulta o e-mail do participante.
3. Envia um e-mail para o participante.
4. Registra falhas em `Error_Log__c`.

O template de e-mail esta em `force-app/main/default/email/MedConnect_Templates/Event_Registration_Confirmation.email`.

### Validacao de agenda de palestrantes

Quando um registro `Event_Speaker__c` e criado ou atualizado, a trigger `EventSpeakerTrigger` chama `EventSpeakerTriggerHandler.preventDuplicateActiveSpeakerBooking`.

O fluxo atual:

1. Coleta os palestrantes informados.
2. Busca associacoes existentes em eventos ativos e ainda nao encerrados.
3. Bloqueia o registro se o palestrante ja tiver outro evento ativo/futuro.

Observacao importante: a regra atual bloqueia outro evento ativo/futuro para o mesmo palestrante, mas nao compara intervalo exato de inicio e fim entre eventos.

### Validacao de local via ViaCEP

Quando um `Location__c` e criado ou tem endereco alterado, a trigger `LocationTrigger` chama `LocationTriggerHandler`.

O fluxo atual:

1. Identifica locais novos ou alterados.
2. Enfileira `ViaCepAddressVerificationQueueable`.
3. O queueable consulta o endereco.
4. `ViaCepAddressVerificationService` chama `https://viacep.com.br/ws/{CEP}/json/`.
5. Atualiza `Location__c.Verified__c` com `true` ou `false`.
6. Falhas sao registradas em `Error_Log__c`.

A validacao considera:

- Pais vazio, `Brazil`, `Brasil` ou `BR`.
- CEP com 8 digitos apos normalizacao.
- Resposta HTTP 200.
- Ausencia de `"erro": true`.
- Compatibilidade de cidade, estado e rua quando esses campos estiverem preenchidos localmente.

### Limpeza de eventos antigos

A classe `MedicalEventPurgeBatch` remove eventos antigos que atendem aos criterios:

- `End_Date_Time__c` anterior a 2 meses.
- `Live__c = false`.

O batch usa `MedicalEventPurgeHandler.deleteOldEvents` para exclusao e envia e-mail ao usuario executor ao terminar. Erros sao registrados em `Error_Log__c`.

## API REST implementada

A classe `MedicalEventRestService` expoe endpoints Apex REST em:

```text
/services/apexrest/medical-events/*
```

Endpoints atuais:

- `GET /medical-events/`: lista eventos com `Live__c = true` e `Start_Date_Time__c > now`, ordenados por data de inicio.
- `GET /medical-events/{Id}`: retorna os detalhes de um evento especifico pelo Id.

Campos retornados no DTO `MedicalEventResponse`:

- `eventId`
- `name`
- `startDateTime`
- `endDateTime`
- `status`
- `eventType`
- `organizerName`
- `locationName`
- `address`

Tratamentos existentes:

- Evento virtual retorna endereco como `Virtual Event`.
- Evento sem local retorna `No address provided`.
- Endereco fisico ignora campos vazios para evitar concatenacao de valores nulos.
- Evento inexistente retorna erro 404 com mensagem de `CustomLabel`.
- Erro geral retorna 500 com mensagem de `CustomLabel` e grava log tecnico.
- Consultas usam `WITH USER_MODE` nos endpoints da API.

## Interface Lightning Web Component

O componente `eventDetails` esta exposto para `lightning__RecordPage`.

Ele pode ser usado na pagina de registro de `Medical_Event__c` para mostrar:

- Formulario readonly do evento, usando `lightning-record-form`.
- Lista de palestrantes em tabela.
- Dados do local.
- Lista de participantes em tabela.
- Spinner enquanto carrega.

O LWC consome `EventDetailsController.getEventRelatedDetails`, que retorna um wrapper com:

- `speakers`
- `attendees`
- `location`

## Metadados de suporte

### Remote Site Setting

Existe permissao declarativa para callout em:

```text
https://viacep.com.br
```

Arquivo:

```text
force-app/main/default/remoteSiteSettings/ViaCep.remoteSite-meta.xml
```

### Custom Labels

Labels implementadas:

- `Event_Not_Found`: mensagem para evento nao encontrado na API.
- `API_General_Error`: mensagem generica de erro da API.

### Template de e-mail

Template implementado:

- `Event_Registration_Confirmation`

Uso atual:

- Envio automatico apos criacao de inscricao em `Event_Attendee__c`.

## Testes existentes

O projeto possui testes Apex e Jest.

Testes Apex identificados:

- `MedicalEventRestServiceTest`
- `ViaCepAddressVerificationTest`
- `MedicalEventPurgeBatchTest`
- `MedConnectTriggerTest`
- `EventDetailsControllerTest`

Teste LWC identificado:

- `force-app/main/default/lwc/eventDetails/__tests__/eventDetails.test.js`

Scripts NPM disponiveis:

- `npm run test:unit`
- `npm run test:unit:coverage`
- `npm run lint`
- `npm run prettier`
- `npm run prettier:verify`

## O que o sistema consegue fazer hoje

- Cadastrar eventos medicos com dados de agenda, status, tipo, capacidade, recorrencia, organizador e local.
- Cadastrar locais, participantes, palestrantes e organizadores.
- Relacionar participantes e palestrantes a eventos.
- Controlar vagas por capacidade maxima, total de participantes e vagas restantes.
- Bloquear inscricao em evento encerrado, inativo ou lotado.
- Bloquear palestrante em evento encerrado ou inativo.
- Bloquear associacao duplicada de palestrante em evento ativo/futuro.
- Validar endereco brasileiro de local via ViaCEP de forma assincrona.
- Indicar se o local do evento foi verificado.
- Enviar e-mail de confirmacao de inscricao para participantes.
- Registrar erros tecnicos em objeto proprio.
- Expor eventos por API REST para sistemas externos.
- Exibir detalhes consolidados do evento em componente Lightning.
- Executar limpeza batch de eventos antigos e inativos.
- Rodar testes automatizados Apex e LWC.

## Pontos para comparar com o documento do projeto

Use esta lista como checklist inicial para decidir quais funcionalidades restantes ainda precisam ser feitas.

### Funcionalidades aparentemente implementadas

- Modelo basico de eventos medicos.
- Cadastro de participantes, palestrantes, organizadores e locais.
- Relacionamento N:N entre eventos e participantes.
- Relacionamento N:N entre eventos e palestrantes.
- Regras de validade para eventos presenciais, virtuais e recorrentes.
- Controle basico de capacidade e vagas.
- Validacao de local por ViaCEP.
- API REST de consulta de eventos.
- Tela LWC de detalhes do evento.
- E-mail de confirmacao de inscricao.
- Logging tecnico.
- Batch de limpeza de eventos antigos.
- Testes automatizados principais.

### Funcionalidades que podem estar pendentes ou incompletas

- CRUD completo via interface customizada para criar, editar, cancelar ou publicar eventos.
- Fluxo guiado de inscricao de participante pelo front-end.
- Cancelamento de inscricao com devolucao/liberacao de vaga.
- Controle detalhado de conflito de agenda por intervalo real de horario para palestrantes.
- Processo automatico de mudanca de status do evento, por exemplo de `Created` para `Published`, `In Progress` e `Completed`.
- Agendamento automatico do `MedicalEventPurgeBatch`; a classe existe, mas nao ha metadado de scheduler identificado.
- API REST para criar, atualizar ou cancelar eventos; atualmente a API e somente de consulta (`GET`).
- API REST para inscricao de participantes.
- Autenticacao/autorizacao documentada para consumo externo da API.
- Paginacao, filtros e ordenacao parametrizada na listagem REST.
- Tratamento de duplicidade de inscricao do mesmo participante no mesmo evento, se isso estiver no escopo.
- Layouts, tabs, permission sets ou profiles especificos para uso final; nao foram identificados metadados desses itens no pacote.
- Relatorios e dashboards; os objetos estao com `enableReports=false` nos metadados observados.
- Notificacoes adicionais, como lembrete antes do evento, aviso de cancelamento ou aviso de alteracao de local/data.
- Suporte real a eventos online alem da marcacao de tipo `Virtual`, como campo de link da reuniao ou plataforma.
- Internacionalizacao ampla; existem labels para mensagens da API, mas nem todas as mensagens e textos estao externalizados.
- Politica de auditoria/historico em objetos principais; os objetos observados estao com historico desabilitado.

## Observacoes tecnicas relevantes

- O projeto e um Salesforce DX project com Apex, metadados declarativos e LWC.
- O codigo usa padroes de handler para triggers e servicos dedicados para integracoes/logs.
- A API REST usa DTO para evitar expor diretamente todo o objeto `Medical_Event__c`.
- Ha alguns textos com caracteres acentuados exibidos de forma corrompida em arquivos existentes, indicando possivel problema de encoding em parte da documentacao/codigo.
- O LWC usa a coluna `Specialisation__c`, mas o campo existente no objeto `Speaker__c` e `Specialization__c`. Esse ponto deve ser verificado porque pode impedir a exibicao correta da especialidade do palestrante.
