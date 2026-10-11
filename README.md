# SSpotToTube

Aplicativo Flutter (Android) para **transferir playlists do Spotify para o YouTube Music** de forma 100% legal, usando apenas as APIs oficiais do Spotify e do Google (YouTube Data API v3).

> O app **não baixa músicas**. Ele lê o nome + artista das faixas no Spotify, busca o vídeo correspondente no YouTube e monta a playlist no YouTube Music.

## Funcionalidades

- Login OAuth 2.0 com Spotify (AppAuth/Custom Tabs) e Google/YouTube
- Tokens salvos de forma segura (flutter_secure_storage) com renovação automática
- Listagem e seleção múltipla de playlists do Spotify
- Transferência com progresso em tempo real (adicionadas / não encontradas / puladas)
- Relatório final por playlist + **histórico persistente** de transferências
- 3 modos de velocidade: **Rápido / Normal / Lento** (delays configurados para respeitar rate limits)
- Tema **Escuro** (padrão), Claro e Seguir o sistema — Material 3
- Opção **"pular músicas que já existem"** (transfere apenas as que faltam)
- 100% em português do Brasil

## Estrutura do projeto

```
lib/
  main.dart                    # composição do app, providers e rotas
  core/
    constants.dart             # Client ID do Spotify, escopos, redirect URI
    app_theme.dart             # temas claro/escuro (Material 3)
    exceptions.dart            # exceções de domínio
  models/                      # Track, SpotifyPlaylist, Histórico, SpeedMode
  services/
    secure_storage_service.dart
    spotify_auth_service.dart  # OAuth 2.0 Spotify (flutter_appauth)
    spotify_service.dart       # Web API do Spotify (leitura de playlists)
    youtube_auth_service.dart  # OAuth Google (google_sign_in)
    youtube_music_service.dart # YouTube Data API v3 (busca, criar playlist, inserir)
    history_service.dart       # histórico local
  providers/                   # estado (Provider): auth, tema, settings, transfer
  screens/                     # home, playlists, transferência, settings, histórico
  widgets/                     # componentes reutilizáveis
android/                       # configuração Android pronta (Gradle 8.4, AGP 8.3)
```

## Configuração obrigatória (antes de compilar)

### 1. Spotify

1. Acesse https://developer.spotify.com/dashboard e crie um app.
2. Em **Redirect URIs**, adicione exatamente:
   ```
   com.spottotube:/oauth2redirect
   ```
   (precisa bater com o `intent-filter` do `AndroidManifest.xml` e com
   `AppConstants.spotifyRedirectUri`).
3. Copie o **Client ID** e cole em `lib/core/constants.dart`:
   ```dart
   static const String spotifyClientId = 'SEU_CLIENT_ID_AQUI';
   ```

### 2. Google / YouTube

1. No [Google Cloud Console](https://console.cloud.google.com), crie um projeto.
2. Ative a **YouTube Data API v3** (APIs e Serviços → Biblioteca).
3. Em **Tela de consentimento OAuth**, adicione os escopos
   `.../auth/youtube` e `.../auth/youtube.force-ssl` e os usuários de teste.
4. Em **Credenciais → Criar credencial → OAuth Client ID → Android**, informe:
   - **Package name:** `com.spottotube.app`
   - **SHA-1:** impressão digital do seu keystore (debug e/ou release)

   Para obter o SHA-1 do keystore de debug:
   ```
   keytool -list -v -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -keypass android
   ```
   Não é necessário colar nenhum Client ID no código (o Android resolve pelo package + SHA-1).

### 3. Cota do YouTube (importante)

A API oficial tem cota diária padrão de 10.000 unidades. Como
`playlistItems.insert` custa **50 unidades por música**, o limite prático é de
**~200 músicas/dia**. Para transferir mais, solicite aumento de cota no Google
Cloud Console (formulário de auditoria de API) — ou transfira ao longo de
vários dias usando a opção "pular músicas que já existem".

## Build do APK

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (3.19+) e Android SDK (API 34).

```bash
flutter pub get
flutter build apk --release
```

O APK é gerado em `build/app/outputs/flutter-apk/app-release.apk`.

- O build release já está configurado para assinar com a chave de debug (apenas para testes locais). Para publicar na Play Store, crie seu keystore e configure a assinatura em `android/app/build.gradle`.
- Se o Gradle reclamar do wrapper, rode `flutter create . --platforms android --org com.spottotube` para restaurar arquivos binários do wrapper (os arquivos de código não são sobrescritos).

## Observações técnicas

- **Rate limits**: os modos de velocidade controlam delays entre buscas e gravações. Em caso de HTTP 429 do Spotify, o app respeita o header `Retry-After`.
- **Busca**: as faixas são procuradas com `artista + nome`; uma heurística simples prioriza canais oficiais (Topic/VEVO) e penaliza covers/lives/karaoke.
- **Ícone**: o projeto usa um ícone vetorial provisório. Para gerar ícones em todas as densidades, use o pacote `flutter_launcher_icons`.
- **Privacidade**: nenhum dado sai do dispositivo além das chamadas oficiais às APIs do Spotify e do Google.
