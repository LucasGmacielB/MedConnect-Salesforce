# Integracao ViaCEP: Validacao de Endereco

## Visao geral

A integracao com a **ViaCEP** valida enderecos brasileiros cadastrados no objeto `Location__c`.

O campo principal de resultado e:

* `Location__c.Verified__c`: indica se o CEP e os dados do endereco foram validados pela ViaCEP.
* `Medical_Event__c.Location_Verified__c`: formula que reflete `Address__r.Verified__c` no evento.

Como a validacao pertence ao local, ela nao depende da criacao de um `Medical_Event__c`.

## Fluxo tecnico

1. Um registro `Location__c` e criado.
2. A trigger `LocationTrigger` chama `LocationTriggerHandler`.
3. O handler enfileira `ViaCepAddressVerificationQueueable` com o Id do local.
4. O queueable consulta o registro `Location__c` e chama `ViaCepAddressVerificationService`.
5. O service faz callout para a API ViaCEP.
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
* `force-app/main/default/classes/api/ViaCepAddressVerificationQueueable.cls`
* `force-app/main/default/classes/api/ViaCepAddressVerificationService.cls`
* `force-app/main/default/classes/test/ViaCepAddressVerificationTest.cls`

### Metadata

* `force-app/main/default/remoteSiteSettings/ViaCep.remoteSite-meta.xml`

## Endpoint utilizado

```text
https://viacep.com.br/ws/{CEP}/json/
```

Exemplo:

```text
https://viacep.com.br/ws/01001000/json/
```

## Parametros enviados

A consulta usa apenas o CEP armazenado em `Location__c.Postal_Code__c`.

Antes da chamada, o CEP e normalizado para manter apenas numeros. O valor final precisa ter 8 digitos.

## Criterio de validacao

O endereco e considerado valido quando:

* `Country__c` esta vazio, `Brazil`, `Brasil` ou `BR`.
* `Postal_Code__c` tem 8 digitos apos normalizacao.
* A ViaCEP retorna HTTP 200.
* A resposta nao contem `"erro": true`.
* `City__c`, `State__c` e `Street__c`, quando preenchidos, sao compativeis com `localidade`, `uf` e `logradouro` retornados pela API.

Campos locais vazios nao invalidam o endereco. Isso permite validar um local apenas pelo CEP, desde que o CEP exista na ViaCEP.

## Configuracao obrigatoria

A ViaCEP nao usa `auth-id`, token ou senha.

O Salesforce precisa permitir callout para:

```text
https://viacep.com.br
```

Essa permissao foi adicionada via `RemoteSiteSetting`.

## Observacoes importantes

* A validacao e assincrona. O checkbox `Verified__c` pode nao mudar no mesmo instante em que o local e salvo.
* Falhas de callout sao registradas via `ErrorLogService`.
* A ViaCEP cobre CEPs brasileiros. Enderecos fora do Brasil retornam `false`.
* O campo `Postal_Code__c` tem tamanho 8 no projeto, entao o formato recomendado e `01001000`, sem hifen.

## Validacao

Comando usado para validar deploy e testes Apex:

```bash
sf project deploy validate --source-dir force-app --test-level RunLocalTests --json
```
