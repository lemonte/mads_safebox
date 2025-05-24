# Configuração do SonarQube para MADS SafeBox

Este documento descreve como configurar e usar o SonarQube para análise de código neste projeto.

## Pré-requisitos

1. Acesso a uma instância do SonarQube (self-hosted ou SonarCloud)
2. Token de acesso do SonarQube

## Configuração do Projeto

### 1. Configuração de Secrets no GitHub

Para que a GitHub Action funcione corretamente, você precisa adicionar os seguintes secrets no seu repositório GitHub:

- `SONAR_TOKEN`: Token de acesso gerado no SonarQube/SonarCloud

Para adicionar estes secrets:
1. Acesse seu repositório no GitHub
2. Vá para "Settings" > "Secrets and variables" > "Actions"
3. Clique em "New repository secret"
4. Adicione os secrets mencionados acima

### 2. Configuração para SonarCloud (Alternativa)

Se você estiver usando o SonarCloud em vez de uma instância self-hosted do SonarQube, modifique o arquivo `sonar-project.properties` para incluir:

```properties
sonar.organization=sua-organizacao
```

E substitua `sua-organizacao` pelo ID da sua organização no SonarCloud.

## Execução Local (Opcional)

Para executar a análise localmente antes de fazer commit:

1. Instale o SonarScanner: https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/
2. Execute os testes com cobertura:
   ```
   flutter test --coverage
   ```
3. Execute o SonarScanner:
   ```
   sonar-scanner
   ```

## Visualização dos Resultados

Após a execução da GitHub Action, os resultados da análise estarão disponíveis no dashboard do SonarQube/SonarCloud.

## Personalização

Você pode personalizar as regras e configurações editando o arquivo `sonar-project.properties` na raiz do projeto.
