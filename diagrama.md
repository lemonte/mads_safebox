```mermaid
usecaseDiagram
    title Visão Geral - Casos de Uso SafeBox

    actor Utilizador
    actor Administrador
    actor Terceiro
    actor "Sistema de Notificações" as SysNotify

    rectangle SafeBox {
        Utilizador -- (Fazer Upload de Documento)
        Utilizador -- (Gerir Categorias)
        Utilizador -- (Partilhar Documento)
        Utilizador -- (Autenticar-se)
        Utilizador -- (Receber Notificação)

        (Partilhar Documento) <.. (Aceder a Documento Partilhado) : <<include>>
        Terceiro -- (Aceder a Documento Partilhado)

        SysNotify -- (Notificar Expiração de Documento)
        (Notificar Expiração de Documento) ..> (Receber Notificação) : notifica

        Administrador --|> Utilizador
        Administrador -- (Consultar Pista de Auditoria)
        Administrador -- (Gerir Backups)
    }
```
