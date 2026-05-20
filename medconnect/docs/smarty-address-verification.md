# Integracao SmartyStreets: Validacao de Endereco

## Visao geral

A integracao com a **Smarty US Street Address API** valida enderecos cadastrados no objeto `Location__c`.

O campo principal de resultado e:

* `Location__c.Verified__c`: indica se o endereco do local foi validado pela Smarty.
* `Medical_Event__c.Location_Verified__c`: formula que reflete `Address__r.Verified__c` no evento.

Como a validacao pertence ao local, ela nao depende da criacao de um `Medical_Event__c`.

## Fluxo tecnico

1. Um registro `Location__c` e criado.
2. A trigger `LocationTrigger` chama `LocationTriggerHandler`.
3. O handler enfileira `SmartyAddressVerificationQueueable` com o Id do local.
4. O queueable consulta o registro `Location__c` e chama `SmartyAddressVerificationService`.
5. O service faz callout para a Smarty US Street Address API.
6. O resultado atualiza `Location__c.Verified__c`.
7. O campo formula `Medical_Event__c.Location_Verified__c` passa a refletir automaticamente o novo valor quando um evento aponta para esse local.

O mesmo fluxo tambem roda quando um `Location__c` existente tem algum campo de endereco alterado:

* `Street__c`
* `City__c`
* `State__c`
* `Postal_Code__c`
* `Country__c`

Atualizacoes apenas no campo `Verified__c` nao disparam nova validacao, evitando ciclo entre trigger e queueable.

## Componentes criados

### Apex

* `force-app/main/default/triggers/LocationTrigger.trigger`
* `force-app/main/default/classes/triggers/LocationTriggerHandler.cls`
* `force-app/main/default/classes/api/SmartyAddressVerificationQueueable.cls`
* `force-app/main/default/classes/api/SmartyAddressVerificationService.cls`
* `force-app/main/default/classes/test/SmartyAddressVerificationTest.cls`

### Metadata

* `force-app/main/default/remoteSiteSettings/Smarty_US_Street_Address.remoteSite-meta.xml`
* Labels em `force-app/main/default/labels/CustomLabels.labels-meta.xml`:
  * `Smarty_Auth_Id`
  * `Smarty_Auth_Token`

## Endpoint utilizado

```text
https://us-street.api.smarty.com/street-address
```

Parametros enviados:

* `auth-id`
* `auth-token`
* `street`
* `city`
* `state`
* `zipcode`
* `candidates=1`
* `match=strict`

## Criterio de validacao

O endereco e considerado valido quando a API retorna pelo menos um candidato e o campo `analysis.dpv_match_code` possui um destes valores:

* `Y`
* `S`
* `D`

Se a API nao retornar candidatos, ou se o endereco nao for dos Estados Unidos, o resultado sera `false`.

## Configuracao obrigatoria

Antes de usar em uma org real, substituir os placeholders das Custom Labels:

```text
Smarty_Auth_Id = CHANGE_ME
Smarty_Auth_Token = CHANGE_ME
```

Use os valores reais gerados na conta Smarty.

Nao versionar credenciais reais no repositorio.

## Remote Site Setting

O Salesforce precisa permitir callout para o dominio da Smarty. A metadata criada ja configura:

```text
https://us-street.api.smarty.com
```

## Observacoes importantes

* A validacao e assincrona. O checkbox `Verified__c` pode nao mudar no mesmo instante em que o local e salvo.
* Falhas de callout ou credenciais ausentes sao registradas via `ErrorLogService`.
* O service valida apenas enderecos dos Estados Unidos, porque a API usada e a **US Street Address API**.
* Para enderecos de outros paises, sera necessario outro endpoint/produto da Smarty ou outra integracao.

## Validacao realizada

Comando executado:

```bash
sf project deploy validate --source-dir force-app --test-level RunLocalTests --json
```

Resultado: validacao concluida com sucesso.
