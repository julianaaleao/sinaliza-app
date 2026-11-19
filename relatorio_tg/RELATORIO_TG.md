# RELATÓRIO TÉCNICO: SINALIZA (base para o artigo do TG)

Levantado em 15/11/2026 a partir da pasta `C:\Users\jotam\Documents\sinaliza-app` (cópia de trabalho), do histórico Git e das execuções registradas em `relatorio_tg/`.

**Etiquetas:** [CÓDIGO] arquivo:linha · [MEDIDO] execução real (script, data, ambiente) · [HISTÓRICO] commit ou registro anterior · [ESTIMADO] aproximação com o método explicado · [PERGUNTAR] só o grupo sabe · [NÃO DISPONÍVEL] não existe ou não foi feito.

**Estados:** CONCLUÍDO E PUBLICADO · CONCLUÍDO SÓ NO LOCAL · EM DESENVOLVIMENTO · PLANEJADO · ABANDONADO.

**O que foi alterado no dia deste relatório:** antes do levantamento, e a pedido do grupo, foram importados 22 vídeos novos da Juliana ("Qual seu nome?" e "Quanto custa?") e o modelo das frases foi retreinado (`backend/api/modelo/frases_pesos.npz`, log em `relatorio_tg/logs/treino_frases.txt`). Depois disso nada foi alterado no código, nos modelos, nos dados, no Firebase ou na produção. Tudo o que foi calculado para este relatório está em `relatorio_tg/`.

**Ambiente das medições [MEDIDO]:** notebook AMD Ryzen 5 3500U, 9,9 GB de RAM, Windows 11 Home Single Language. API e scripts em Python 3.14.3; treino dos LSTMs em Python 3.11.9.

---

## 1. Conferência do que o artigo já afirma

| Item | Veredito | Evidência |
|---|---|---|
| a) Modos Frases (principal) e Vogais | **CONFIRMADO** | Seletor Frases/Vogais e modo inicial `_Modo.frases` [CÓDIGO] `lib/camera.dart:40` e bloco do `SegmentedButton` |
| a) Contagem 3, 2, 1 | **CONFIRMADO** | `for (var i = 3; i > 0; i--)` [CÓDIGO] `lib/camera.dart:136` |
| a) Gravação de 4 s | **CORRIGIR: 5 s** | `_janelaFrase = Duration(seconds: 5)` [CÓDIGO] `lib/camera.dart:67`; `DURACAO_SEGUNDOS = 5.0` [CÓDIGO] `backend/api/frases.py:18`. Mudou de 4 s para 5 s em 15/11/2026, porque as gravações dos integrantes duravam de 3,6 s a 7,0 s [MEDIDO] `relatorio_tg/logs/importacao_frases.txt` |
| a) Cinco frases | **CONFIRMADO** | [CÓDIGO] `lib/frases.dart` (lista `frases`) e `backend/api/frases.py:8-15` |
| a) Vogais A, E, I, O, U e "OI" contínuos | **CONFIRMADO, com detalhe** | Ciclos de 1,5 s em sequência, um pedido por vez [CÓDIGO] `lib/camera.dart:66` e `_loop`; o "OI" só aparece com probabilidade ≥ 0,9 [CÓDIGO] `backend/api/main.py:41,146` |
| b) Captura a cada 100 ms | **CORRIGIR: 200 ms** | `_intervaloFrames = Duration(milliseconds: 200)` [CÓDIGO] `lib/camera.dart:70`. Mudou em 15/11/2026 para reduzir o tempo de processamento na API |
| b) Navegador: getUserMedia e Canvas, JPEG 320x240 | **CONFIRMADO** | [CÓDIGO] `lib/camera_web_impl.dart:18,23,51`; qualidade JPEG 0,7 [CÓDIGO] `lib/camera_web_impl.dart:52` |
| b) Android: pacote camera | **CONFIRMADO, com detalhe** | `CameraController(..., ResolutionPreset.medium)` e `takePicture()` [CÓDIGO] `lib/camera_android.dart:26,78`. **No Android a foto não é reduzida para 320x240**: vai no tamanho do preset "medium" |
| c) Reamostragem para 30 instantes por interpolação linear | **CONFIRMADO** | `np.linspace` + `np.interp` [CÓDIGO] `backend/api/gesto.py:63-77` e `backend/api/frases.py:42-60` |
| d) Normalização: pulso como origem e divisão pela maior distância até o pulso | **CONFIRMADO, com detalhe** | [CÓDIGO] `backend/api/normalizacao.py:11-16`. A distância é medida só em x e y; o z também é dividido por ela |
| e) Rotas /reconhecer, /reconhecer_sequencia (~1,5 s), /reconhecer_frase (~4 s) | **CORRIGIR** | Rotas existem [CÓDIGO] `backend/api/main.py:112,122,169`. A janela de /reconhecer_frase é **5 s**. Há uma 4ª rota: `GET /saude` [CÓDIGO] `main.py:97` |
| f) LSTM do "OI": 1 camada de 32, Dropout, 2 densas, 65 características | **CONFIRMADO** | [CÓDIGO] `backend/treinar_lstm.py:86-90` (LSTM 32, Dropout 0,3, Dense 16 ReLU, Dense 2 softmax); 13.106 parâmetros [MEDIDO] contagem dos arrays em `lstm_pesos.npz` |
| g) LSTM das frases: 1 camada de 64, Dropout, 2 densas, 132 características | **CONFIRMADO** | [CÓDIGO] `backend/treinar_frases.py:119-123` (LSTM 64, Dropout 0,3, Dense 32 ReLU, Dense 6 softmax); `N_CARACTERISTICAS = 2 * 66` [CÓDIGO] `frases.py:19`; 52.710 parâmetros [MEDIDO] `frases_pesos.npz` |
| h) LSTMs só com NumPy no servidor; diferença para o Keras < 0,000001 | **CONFIRMADO** | Classe `ModeloGesto` [CÓDIGO] `backend/api/gesto.py`. Maior diferença absoluta de probabilidade: "OI" 7,6 × 10⁻⁸ [HISTÓRICO, saída do `treinar_lstm.py` em 29/10/2026]; frases 2,0 × 10⁻⁷ [MEDIDO] `relatorio_tg/logs/treino_frases.txt` |
| i) Limiares: "OI" ≥ 90%; frases ≥ 70% | **CONFIRMADO** | `LIMIAR_GESTO = 0.9`, `LIMIAR_FRASE = 0.7` [CÓDIGO] `backend/api/main.py:41,43` |
| j) Vogais: 96,6% em coletas não vistas (3 coletas, 1.500 amostras); 99,7% em divisão aleatória | **CONFIRMADO** | [HISTÓRICO] saída do `backend/treinar.py` em 29/10/2026 (log não salvo em arquivo; matrizes transcritas em `relatorio_tg/medicoes/vogais_matrizes.csv`). Contagem de 3 × 500 amostras [MEDIDO] nos CSVs |
| k) "OI": 97,5% em 5 partes; modelo antigo de 43% a 65% | **CONFIRMADO** | 97,46% de média [HISTÓRICO] saída do `treinar_lstm.py` em 29/10/2026. Probabilidade de "OI" do modelo antigo: 0,43 a 0,65 nos 30 "OI" e 0,38 a 0,57 nos 30 NENHUM [HISTÓRICO, mesma data] |
| l) Frases: 1 vídeo de referência por frase; 13 em 15 nos próprios vídeos | **DESATUALIZADO** | Era verdade em 29/10/2026 [HISTÓRICO]. Hoje são **96 gravações de 3 pessoas**, avaliadas por pessoa não vista: **86,4%** [MEDIDO] `relatorio_tg/logs/treino_frases.txt` (seção 8) |
| m) Latência: 20 frames em ~0,95 s; meta de 3 s | **CORRIGIR** | Os 0,95 s vieram de **1 execução com 20 imagens de ruído aleatório, sem mãos** [HISTÓRICO, 29/10/2026], o que não representa o uso real. Medição nova com mãos reais, 20 repetições: vogais 8 frames = 694 ± 135 ms; frases 25 frames = 2.732 ± 392 ms [MEDIDO] (seção 9) |
| n) GIFs: FFmpeg, 12 fps, 360 px, 128 cores | **CONFIRMADO NO CÓDIGO / NÃO DISPONÍVEL NA PRÁTICA** | [CÓDIGO] `backend/video_para_gif.py:14-15,25-26`. **Nenhum GIF foi gravado ainda**: `assets/respostas/` só tem o LEIA-ME |
| o) Regras do Firestore | **CONFIRMADO NO ARQUIVO** | [CÓDIGO] `firestore.rules` (texto completo na seção 10). Publicação no console: [PERGUNTAR] |

### Outras mudanças que o artigo precisa refletir
- **Rota `/saude`:** o app chama ao abrir a câmera e só libera os botões quando a API responde [CÓDIGO] `lib/camera.dart:84-101`.
- **Descarte de respostas atrasadas:** no modo Vogais, resposta com mais de 3 s é descartada e a tela mostra "Servidor lento" [CÓDIGO] `lib/camera.dart:57,274`. Corrige o problema da apresentação anterior, em que as letras chegavam atrasadas e todas juntas [HISTÓRICO, relato do grupo].
- **Um pedido por vez:** antes havia um `Timer.periodic` de 2 s que não esperava a resposta anterior [HISTÓRICO] commit `f69735f` e anteriores.
- **Cabeçalho `X-Tempo-Processamento-Ms`** em todas as respostas [CÓDIGO] `main.py:88-94`.
- **Detector de 1 mão nas rotas de vogais e de 2 mãos nas frases** [CÓDIGO] `main.py:59-62`.
- **Importação automática de vídeos** e **dados de 3 pessoas para as frases** [CÓDIGO] `backend/importar_videos.py`.
- **O histórico mostra "Sinal:" ou "Vogal:"**, conforme o tamanho do texto [CÓDIGO] `lib/camera.dart:631`.
- **O `docs/Tecnologias-SINALIZA.docx` está desatualizado** em três pontos: gravação de 4 s, captura a cada 100 ms e "processamento em paralelo" (ver 4.3).
- **A API em produção está fora do ar** (seção 2).

---

## 2. Estado atual e publicação

| Item | Situação | Evidência |
|---|---|---|
| Branch local | `parte2-gestos-dinamicos`, último commit `3c801b9` (15/11/2026 19:35) | [HISTÓRICO] `git log` |
| `main` no GitHub | `c7a80fa` (15/11/2026 19:44), merge do PR #2 | [HISTÓRICO] `git branch -a -vv` |
| Alterações não enviadas | Novo `frases_pesos.npz`, `backend/dados_frases/` (com os vídeos novos da Juliana) e a pasta `relatorio_tg/` | [MEDIDO] `git status` em 15/11/2026 |
| Railway | **Fora do ar**: `GET /saude` e `GET /docs` retornam HTTP 404 "Application not found" | [MEDIDO] `curl`, 15/11/2026 por volta das 19:50 |
| O que esteve no ar | Última versão publicada conhecida: commits de 07/06 a 12/06/2026 (só vogais, rota `/reconhecer`) | [HISTÓRICO]; o que rodava no Railway antes de sair do ar: [PERGUNTAR] |
| Regras do Firestore | Arquivo pronto; publicação no console [PERGUNTAR] | — |
| Plataformas | Web (Chrome) e Android configurados; iOS tem a pasta `ios/`, mas **não tem** `GoogleService-Info.plist` | [CÓDIGO] `android/app/google-services.json` existe; iOS sem Firebase configurado |
| Testes reais | Navegador: [PERGUNTAR] (a versão nova não foi testada com câmera durante o desenvolvimento); Android em emulador ou celular: [PERGUNTAR]. Commits citam câmera Android [HISTÓRICO] `42f5518`, `284f41c` | — |
| Plano do Railway, custo, memória, CPU, inicialização a frio | [PERGUNTAR] / [NÃO DISPONÍVEL]. O grupo decidiu contratar um servidor pago para a apresentação [HISTÓRICO, relato do grupo em 15/11/2026] | — |

### O que falta até a entrega (datas de entrega: [PERGUNTAR])
| Prioridade | Item | Estado |
|---|---|---|
| 1 | Contratar e configurar o servidor (pasta raiz `backend/api`, Dockerfile, porta 8000) e atualizar a URL no app | PLANEJADO |
| 1 | Gravar os 11 GIFs de resposta (lista em `assets/respostas/LEIA-ME.txt`) | PLANEJADO |
| 1 | Testar o app completo com câmera (navegador e Android físico) | PLANEJADO |
| 1 | Publicar o `firestore.rules` | CONCLUÍDO SÓ NO LOCAL |
| 2 | Enviar ao GitHub o modelo retreinado em 15/11/2026 | CONCLUÍDO SÓ NO LOCAL |
| 2 | Medir a latência no celular com o servidor contratado | PLANEJADO |
| 2 | Questionário SUS com usuários | PLANEJADO |
| 2 | Validar os sinais com um surdo ou intérprete | PLANEJADO |
| 3 | Mais gravações de "Quanto custa?" (41% de revocação) | EM DESENVOLVIMENTO |
| 3 | Corrigir o teste automático quebrado (`test/widget_test.dart`) | PLANEJADO |

---

## 3. Ambiente e versões

### 3.1 Versões
| Tecnologia | Local (desenvolvimento) | Produção (Dockerfile) | Fonte |
|---|---|---|---|
| Flutter | 3.41.4 (stable, 03/03/2026) | — | [MEDIDO] `flutter --version` |
| Dart | 3.11.1 | — | [MEDIDO]; `sdk: ^3.11.0` [CÓDIGO] `pubspec.yaml` |
| Python | 3.14.3 (API local, coletas, vogais) e 3.11.9 (TensorFlow) | imagem `python:3.11-slim` | [MEDIDO]; [CÓDIGO] `backend/api/Dockerfile:1` |
| FastAPI | 0.136.1 | sem versão fixa | [MEDIDO]; [CÓDIGO] `requirements.txt` |
| Uvicorn | 0.46.0 | sem versão fixa | idem |
| Pydantic | 2.13.3 | dependência do FastAPI | [MEDIDO] |
| Starlette | 1.0.0 | dependência do FastAPI | [MEDIDO] |
| MediaPipe | 0.10.33 | **0.10.9** | [MEDIDO]; [CÓDIGO] `requirements.txt` |
| OpenCV | 4.13.0.92 (opencv-python) | 4.8.1.78 (headless) | idem |
| NumPy | 2.4.3 (3.14) / 2.4.4 (3.11) | sem versão fixa | idem |
| pandas | 3.0.3 (3.14) / 3.0.2 (3.11) | não instalado | [MEDIDO] |
| scikit-learn | 1.8.0 | 1.8.0 | [MEDIDO]; [CÓDIGO] |
| TensorFlow | 2.21.0 (só Python 3.11) | não instalado | [MEDIDO] |
| Keras | 3.15.1 | não instalado | [MEDIDO] |
| FFmpeg | N-124279-g0f6ba39122 (30/04/2026) | — | [MEDIDO] |
| matplotlib | 3.10.8 (só para as figuras deste relatório) | — | [MEDIDO] |
| Modelo MediaPipe | `hand_landmarker.task`, 7.819.105 bytes | mesmo arquivo | [MEDIDO] |

Pacotes Flutter (versões resolvidas no `pubspec.lock`) [CÓDIGO]: firebase_core 3.15.2 · firebase_auth 5.7.0 · cloud_firestore 5.6.12 · camera 0.11.4 (camera_web 0.3.5+3) · http 1.6.0 · permission_handler 11.4.0 · flutter_svg 2.3.0 · flutter_lints 4.0.0.

**Atenção:** a versão do MediaPipe em produção (0.10.9) é diferente da usada no treino e nos testes (0.10.33). O efeito dessa diferença nos pontos detectados não foi medido [NÃO DISPONÍVEL].

### 3.2 Python em cada etapa
| Etapa | Versão | Evidência |
|---|---|---|
| Coleta (vogais, OI, frases) e importação de vídeos | 3.14.3 | [MEDIDO] executado com `python` nesta máquina |
| Treino das vogais (Random Forest) | 3.14.3 | [MEDIDO] |
| Treino dos LSTMs | 3.11.9 (`py -3.11`) | [MEDIDO]; o TensorFlow não instala no 3.14 [HISTÓRICO] artigo, seção 7.6 |
| API local | 3.14.3 | [MEDIDO] |
| API em produção | 3.11 (imagem Docker) | [CÓDIGO] `Dockerfile:1`; `runtime.txt` = python-3.11.15, sobra da tentativa na Azure |

### 3.3 Estrutura de pastas
| Pasta | Função |
|---|---|
| `lib/` | App Flutter: telas, câmera (`camera_web_impl.dart`, `camera_android.dart`), frases e respostas |
| `lib/theme/`, `lib/widgets/` | Cores, tema, botões, cartões, ícones e logo |
| `assets/respostas/` | GIFs das respostas (hoje só o LEIA-ME) |
| `public/` | Logo e ícones SVG |
| `backend/api/` | API publicada (main.py, normalizacao.py, gesto.py, frases.py, Dockerfile, requirements.txt, modelos) |
| `backend/api/modelo/` | modelo.pkl (vogais), lstm_pesos.npz (OI), frases_pesos.npz (frases) |
| `backend/` (raiz) | Scripts de coleta, treino, teste, importação e conversão para GIF |
| `backend/dados.csv`, `backend/dados/` | Amostras de vogais |
| `backend/dados_gestos/` | Sequências do OI (.npy) |
| `backend/dados_frases/` | Exemplos das frases (.npz), gerados pela importação |
| `backend/videos_frases/` | Vídeos das frases e cache; **fora do Git** [CÓDIGO] `.gitignore` |
| `backend/modelo/` | Cópias dos modelos e o LSTM em formato Keras |
| `backend/main.py`, `classifier.py`, `landmarks.py`, `sinais.py` | Versões antigas, fora da API publicada [HISTÓRICO]; uso atual [PERGUNTAR] |
| `logs/`, `logs.zip`, `backend/api/.azure/` | Registros da tentativa de deploy na Azure em 03/06/2026 [HISTÓRICO] |
| `docs/` | Documento de tecnologias |
| `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` | Plataformas geradas pelo Flutter |
| `test/` | Teste padrão do Flutter, quebrado (seção 12) |
| `relatorio_tg/` | Este relatório: logs, medições, scripts e figuras |

### 3.4 Tecnologias fora da lista do enunciado
Git e GitHub (repositório `julianaaleao/sinaliza-app`) · Docker · Railway · Microsoft Azure App Service, plano F1 (tentativa em 03/06/2026, abandonada) [HISTÓRICO] `backend/api/.azure/config` · Firebase Authentication e Cloud Firestore · Git Credential Manager · pickle · Starlette · matplotlib (só no relatório).

---

## 4. Arquitetura e API

Figura: `relatorio_tg/figuras/fig01_arquitetura.png`; fluxo do modo Frases: `fig02_fluxo_frases.png`.

### 4.1 Fluxo de uma leitura
**Modo Frases** [CÓDIGO] `lib/camera.dart:133-225`, `backend/api/main.py:161-195`
1. O usuário toca em "Ler sinal". A contagem 3, 2, 1 aparece sobre a câmera (1 s cada).
2. Durante 5 s, o app captura 1 frame a cada 200 ms e guarda o tempo de cada um.
3. Envia `POST /reconhecer_frase` com as imagens em base64 e os tempos (prazo de 20 s).
4. A API decodifica cada imagem (OpenCV) e detecta até 2 mãos (MediaPipe).
5. Cada frame vira uma matriz 2 × 63 (direita e esquerda, com NaN onde não há mão). A sequência é reamostrada para 30 instantes e transformada em 132 características por instante.
6. O LSTM das frases devolve 6 probabilidades. Se a maior for NENHUM, ou menor que 0,7, a resposta vem com a frase vazia.
7. O app mostra a frase e grava no Firestore. Abre o painel de respostas e, ao toque, o GIF em tela cheia.

**Modo Vogais** [CÓDIGO] `lib/camera.dart:241-310`, `main.py:122-158`
1. "Iniciar reconhecimento" começa um ciclo: 1,5 s de captura (1 frame a cada 200 ms, cerca de 7 frames).
2. Envia `POST /reconhecer_sequencia` (prazo de 10 s) e espera a resposta antes do próximo ciclo.
3. A API detecta 1 mão por frame, prevê a vogal de cada frame com mão (Random Forest) e escolhe a mais votada.
4. Com os mesmos frames, o LSTM do "OI" calcula a probabilidade do gesto. "OI" tem prioridade se for ≥ 0,9.
5. Se a resposta demorar mais de 3 s, o app a descarta. Se não, mostra o resultado e grava no Firestore quando ele muda.

### 4.2 Rotas
Exemplos reais: [MEDIDO] `relatorio_tg/medicoes/exemplos_json.txt` (gerados em 15/11/2026 com frames do vídeo de referência de "Que horas são?").

| Rota | Requisição | Resposta | Erros |
|---|---|---|---|
| `GET /saude` | — | `{"ok": true, "frases": true}` | — |
| `POST /reconhecer` | `{"imagem": "<base64>"}` | `{"letra": "O", "detectado": true}` | 422 (JSON inválido, via Pydantic); base64 inválido gera exceção, ou seja, erro 500 [CÓDIGO] `main.py:67` |
| `POST /reconhecer_sequencia` | `{"imagens": ["<base64>", ...], "tempos_ms": [0, 200, ...]}` (`tempos_ms` opcional) | `{"resultado": "O", "gesto": "", "letra": "O", "confianca": 0.9997, "detectado": true}` | 422; 500 (base64 inválido) |
| `POST /reconhecer_frase` | igual à anterior | `{"frase": "", "confianca": 0.509, "detectado": true, "maos_visiveis": 1.0}` | 422; 503 sem modelo de frases [CÓDIGO] `main.py:174`; 500 (base64 inválido) |

Observações:
- O exemplo de `/reconhecer_frase` com 21 frames do próprio vídeo de referência de "Que horas são?" **não reconheceu a frase** (confiança 0,509 < 0,7) [MEDIDO]. É um caso real de falha.
- Com 10 imagens pretas: `{"frase": "", "confianca": 0.0, "detectado": false, "maos_visiveis": 0.0}` [MEDIDO].
- **Não há limite** de tamanho da requisição nem de quantidade de frames [CÓDIGO] (`SequenciaRequest` sem restrição, `main.py:107-109`).
- Tamanho médio enviado [MEDIDO]: 8 frames ≈ 71 KB e 25 frames ≈ 220 KB em base64 (frames 320x240, qualidade 70).

### 4.3 Segurança e concorrência
- **Autenticação na API:** não existe [CÓDIGO]. Qualquer pessoa com a URL pode chamar.
- **CORS:** `allow_origins=["*"]`, todos os métodos e cabeçalhos, expondo `X-Tempo-Processamento-Ms` [CÓDIGO] `main.py:24-31`.
- **Limite de requisições:** não existe [CÓDIGO].
- **"Processamento em paralelo":** as rotas são `def` (síncronas), então o FastAPI as executa num pool de threads e o servidor não trava a fila de conexões [CÓDIGO] `main.py:113,123,170`. **Na prática não há ganho de paralelismo**: 3 pedidos simultâneos levaram 3,8 s, contra 1,35 s de um pedido sozinho [MEDIDO, 15/11/2026, teste local com 15 frames reais]. O MediaPipe ocupa a CPU e o detector é um objeto único compartilhado. **O artigo não deve dizer que a API processa em paralelo.**

### 4.4 Exportação para .npz e comparação com o Keras
- **Exportação:** depois do treino, os pesos de cada camada (`get_weights()`) são salvos com `np.savez` [CÓDIGO] `treinar_lstm.py:139-145`, `treinar_frases.py:205-212`. Saem o kernel, a matriz recorrente e o bias da LSTM e o kernel e bias das duas densas. No .npz das frases também vão os nomes das classes.
- **Execução em NumPy:** a classe `ModeloGesto` refaz as equações da LSTM com as portas na ordem do Keras (i, f, c, o), sigmoide e tanh; aplica ReLU na primeira densa e softmax na saída [CÓDIGO] `gesto.py:16-61`.
- **Comparação:** as primeiras 50 sequências do conjunto de treino final passam pelos dois modelos. A métrica é a maior diferença absoluta entre as probabilidades [CÓDIGO] `treinar_lstm.py:147-149`, `treinar_frases.py:213-214`. Resultados: 7,6 × 10⁻⁸ ("OI") e 2,0 × 10⁻⁷ (frases).

---

## 5. Dados

### 5.1 Vogais
| Coleta | Arquivo | A | E | I | O | U | Total | Quem |
|---|---|---|---|---|---|---|---|---|
| 1 | `backend/dados.csv` (linhas 1-500) | 100 | 100 | 100 | 100 | 100 | 500 | [PERGUNTAR] |
| 2 | `backend/dados.csv` (linhas 501-1000) | 100 | 100 | 100 | 100 | 100 | 500 | [PERGUNTAR] |
| 3 | `backend/dados/joao_20261029_120432.csv` | 100 | 100 | 100 | 100 | 100 | 500 | João, 29/10/2026 |
[MEDIDO] contagem nos arquivos.

- **Formato:** CSV com 64 colunas, `x0,y0,z0,...,x20,y20,z20,letra`. Coordenadas brutas do MediaPipe; a normalização é feita no treino e na API [CÓDIGO].
- **Aumento de dados:** nenhum [CÓDIGO] `treinar.py`.
- **Coleta 3:** 4 fases por vogal (centro, perto, longe, movendo) e uma amostra a cada 0,1 s [CÓDIGO] `coletar_dados.py`.
- **Condições** (câmera, luz, distância e fundo) das coletas 1 e 2: [PERGUNTAR].
- **Amostras antigas:** todas continuam em uso.

### 5.2 Gesto "OI"
| Classe | Sequências | Formato | Frames sem mão |
|---|---|---|---|
| OI | 30 | .npy 30 × 63 | 2,7% |
| NENHUM | 30 | .npy 30 × 63 | 6,7% |
[MEDIDO] `backend/dados_gestos/`

- **No treino:** mais 60 sequências NENHUM sintéticas, feitas com vogais paradas do CSV com ruído σ = 0,002 [CÓDIGO] `treinar_lstm.py:62-63`. Total de 120 grupos.
- **Aumento de dados:** 8 variações por sequência no treino e 4 no teste, mais a original [CÓDIGO] `treinar_lstm.py:114-115`.
- **Quem gravou e em que condições:** [PERGUNTAR]. Arquivo do modelo antigo datado de 16/09/2026 [HISTÓRICO].

### 5.3 Frases
Vídeos (`backend/videos_frases/`) [MEDIDO]:

| Frase | João | Juliana | Referência | Total |
|---|---|---|---|---|
| Olá, tudo bem? | 10 | 3 | 1 | 14 |
| Qual seu nome? | 8 | 19 | 1 | 28 |
| Onde é o banheiro? | 10 | 5 | 1 | 16 |
| Quanto custa? | 10 | 14 | 1 | 25 |
| Que horas são? | 5 | 7 | 1 | 13 |
| **Sinais (total)** | **43** | **48** | **5** | **96** |
| Vídeos "nada" (NENHUM) | 6 (1 sem mão, descartado) | 12 | 0 | 18 |

Exemplos NENHUM gerados na importação [MEDIDO]:

| Pessoa | Vídeos de NENHUM | Descanso ≥ 1,2 s | Início ou fim de sinal |
|---|---|---|---|
| João | 5 | 50 | 86 |
| Juliana | 12 | 2 | 96 |
| Referência | 0 | 1 | 10 |

No treino entram também 40 vogais paradas, o que dá **302 grupos NENHUM** [MEDIDO] log.

- **Formato:** .npz com `maos` (n × 2 × 63, NaN quando a mão não aparece) e `tempos` (ms) [CÓDIGO] `importar_videos.py`, `coletar_frases.py`.
- **Vídeos dos integrantes:** 464 × 832 ou 576 × 1024 pixels, em pé (retrato), 60 fps, de 2,9 s a 12,7 s. Vídeos de referência: 1024 × 576, 24 fps [MEDIDO] `ffprobe`.
- **Condições:** João sentado (1º lote) e de pé de corpo inteiro (2º lote); Juliana de pé, filmada por outra pessoa [MEDIDO] inspeção de quadros. Luz e local: [PERGUNTAR].
- **Pessoas:** 2 integrantes (João e Juliana) e 1 pessoa dos vídeos de referência, terceira. Alguém é surdo ou fluente em LIBRAS? [PERGUNTAR]
- **Vídeos de referência:** origem (título, autor, site, URL, data de acesso) e permissão de uso: [PERGUNTAR]. Sem essa informação eles não podem ser citados nem usados no artigo.
- **GIFs de resposta:** [NÃO DISPONÍVEL]. Ainda não foram gravados; quem vai conferir os sinais: [PERGUNTAR].
- **Pessoas de fora do grupo, termo de consentimento ou Comitê de Ética:** [PERGUNTAR]. Nenhum termo existe no repositório [NÃO DISPONÍVEL].

---

## 6. Pré-processamento

### 6.1 Características por instante
**"OI", 65 valores** [CÓDIGO] `gesto.py:80-91`

| Posição | Conteúdo |
|---|---|
| 0-62 | 21 pontos × (x, y, z) normalizados (pulso na origem, divididos pela maior distância 2D até o pulso) |
| 63-64 | Posição (x, y) do pulso menos a média do pulso na sequência, dividida pela mediana do tamanho da mão na sequência |

**Frases, 66 valores por mão, 132 no total** [CÓDIGO] `frases.py:63-87`. A mão 0 é a marcada como "Right" pelo MediaPipe e a mão 1 como "Left" [CÓDIGO] `frases.py:22-31`.

| Posição (mão 0 / mão 1) | Conteúdo |
|---|---|
| 0-62 / 66-128 | 63 coordenadas normalizadas (zeros se a mão não aparece) |
| 63-64 / 129-130 | Pulso em relação ao centro de todos os pulsos visíveis, em tamanhos de mão |
| 65 / 131 | 1 se a mão está visível nesse instante, senão 0 |

### 6.2 Ausência de mão
- **"OI":** frames sem mão viram `None` e saem da interpolação. Com menos de 2 frames com mão, não há previsão [CÓDIGO] `gesto.py:63-77`.
- **Frases:** a interpolação usa só os frames em que cada mão aparece. A mão é considerada visível no instante interpolado se estava presente em ≥ 50% dos frames vizinhos (interpolação de 0/1). Fora disso vira NaN e depois zero com indicador 0 [CÓDIGO] `frases.py:42-60`. Com menos de 2 frames com alguma mão, a API responde `detectado: false` [CÓDIGO] `frases.py:93`.
- **Vogais:** frames sem mão não votam [CÓDIGO] `main.py:130,149`.

### 6.3 Aumento de dados
| Modelo | Transformação | Parâmetros | Por gravação |
|---|---|---|---|
| OI | Subconjunto de frames | 6 a 30 frames sorteados | 8 no treino, 4 no teste [CÓDIGO] `treinar_lstm.py:31-46,114-115` |
| OI | Ruído gaussiano | σ = 0,003, com probabilidade de 50% | idem |
| Frases | Recorte no tempo | até 15% em cada ponta; se a gravação tem mais de 5 s, uma janela de 5 s sorteada | max(6, ⌊120 / nº de gravações da classe⌋) no treino; 3 no teste [CÓDIGO] `treinar_frases.py:65-98,105,172-173` |
| Frases | Subconjunto de frames | de 4 até todos | idem |
| Frases | Ruído gaussiano | σ = 0,003 (sempre) | idem |
| Frases | Espelhamento horizontal (x → 1 − x e troca de mãos) | probabilidade de 50%; e mais 1 cópia espelhada fixa de cada gravação | + original + espelhada [CÓDIGO] `treinar_frases.py:106` |
| Vogais | — | sem aumento | — |

### 6.4 Classe NENHUM das frases
Vídeos "nada", trechos de descanso ≥ 1,2 s, pedaços de início e fim de sinal (20% do sinal + margem) e 40 vogais paradas [CÓDIGO] `importar_videos.py`, `treinar_frases.py:43-51`. Total: 302 grupos [MEDIDO].

### 6.5 Detecção de repetições na importação de vídeos
[CÓDIGO] `backend/importar_videos.py`
1. **Leitura:** o vídeo é lido a cerca de 20 quadros por segundo; cada quadro passa pelo MediaPipe com 2 mãos.
2. **Altura:** em cada quadro, considera-se o pulso mais alto.
3. **Descanso:** é o percentil 95 dessas alturas, ou 95% da altura da imagem quando as mãos aparecem em menos de 60% dos quadros.
4. **Sinal ativo:** quando o pulso está mais de 1 tamanho de mão acima do descanso.
5. **Pausas:** pausas menores que 0,4 s não separam repetições, e trechos menores que 0,6 s são ignorados.
6. **Um sinal por vídeo:** como cada vídeo tem uma única repetição, os pedaços encontrados são unidos.
7. **Margem:** 0,5 s de descanso antes e depois do sinal.
8. **Cache:** os pontos de cada vídeo ficam guardados em `backend/videos_frases/.cache/`.

Resultado: as 96 gravações de sinal viraram exatamente 1 exemplo cada [MEDIDO] `relatorio_tg/logs/importacao_frases.txt`.

### 6.6 Parâmetros do MediaPipe
`num_hands` = 1 (vogais e OI) ou 2 (frases) [CÓDIGO] `main.py:59-62`. Os demais estão no padrão da biblioteca, não definidos no código: `running_mode = IMAGE`, `min_hand_detection_confidence = 0,5`, `min_hand_presence_confidence = 0,5`, `min_tracking_confidence = 0,5` [MEDIDO] leitura de `HandLandmarkerOptions` no MediaPipe 0.10.33.

---

## 7. Modelos

### 7.1 Random Forest (vogais)
Parâmetros lidos do `modelo.pkl` [MEDIDO]: `n_estimators=100`, `random_state=42`. Os demais no padrão do scikit-learn 1.8.0: `criterion='gini'`, `max_depth=None`, `max_features='sqrt'`, `min_samples_split=2`, `min_samples_leaf=1`, `bootstrap=True`, `class_weight=None`. Entrada: 63 valores normalizados. Classes: A, E, I, O, U. Como os hiperparâmetros foram escolhidos: [PERGUNTAR]. Não há registro de busca de hiperparâmetros [NÃO DISPONÍVEL].

### 7.2 LSTMs
| | "OI" | Frases |
|---|---|---|
| Entrada | 30 × 65 | 30 × 132 |
| LSTM | 32 unidades (tanh, portas sigmoides) | 64 unidades |
| Dropout | 0,3 | 0,3 |
| Densa 1 | 16, ReLU | 32, ReLU |
| Saída | 2, softmax (OI, NENHUM) | 6, softmax (5 frases + NENHUM) |
| Parâmetros | 13.106 | 52.710 |
| Otimizador | Adam (taxa padrão do Keras, 0,001) | Adam (0,001) |
| Perda | entropia cruzada categórica esparsa | idem |
| Lote | 32 | 32 |
| Épocas | máximo 60 | máximo 80 (40 fixas quando há menos de 3 gravações por classe) |
| Parada antecipada | `val_loss`, paciência 10, restaura os melhores pesos, validação de 15% | idem |
| Pesos por classe | inversamente proporcionais à frequência | idem |
| Sementes | NumPy 42, TensorFlow 42 | idem |
| Épocas efetivas | [NÃO DISPONÍVEL]: não registradas | [NÃO DISPONÍVEL] |
[CÓDIGO] `treinar_lstm.py:20-21,86-95,112-136`; `treinar_frases.py:24-25,117-147`

Para obter as épocas efetivas, sem sobrescrever nada: copiar o script, trocar o caminho de saída e imprimir `len(historico.history['loss'])`. Tempo estimado: 3 min (OI) e 10 min (frases) [ESTIMADO pela duração dos treinos nesta máquina].

### 7.3 Por que Random Forest e LSTM; alternativas testadas
- **Escolha:** Random Forest para sinais estáticos (1 frame); LSTM para gestos que dependem da sequência [HISTÓRICO] artigo, seções 4.7 e 7.6. Comparação formal com outros algoritmos: [NÃO DISPONÍVEL]. Motivo da escolha original: [PERGUNTAR].
- **Alternativas testadas** [HISTÓRICO, registros desta sessão de desenvolvimento, 29/10 a 15/11/2026]:
  - Vogais sem normalização: 38,6% e 50,2% em coleta não vista, contra 70,8% e 87,6% com normalização (2 coletas).
  - Normalização com alinhamento de rotação: 70,0% e 77,2%, contra 70,8% e 87,6% sem rotação. Abandonada.
  - LSTM antigo do OI (2 camadas, 64 e 32 unidades, coordenadas brutas): probabilidades de 0,43 a 0,65. Substituído.
  - Frases com pedaços negativos de 35% do sinal: rejeitava frases inteiras. Trocado por 20%.
  - Treino com parada antecipada sem embaralhar: a validação ficava só com NENHUM. Corrigido; as frases simuladas subiram de 65% para 89% e o OI de 96,1% para 97,5%.

### 7.4 Limiares
- **90% para o "OI":** com o modelo antigo, 100 sequências sintéticas de vogal parada tiveram probabilidade média de "OI" de 0,458, e nenhuma passou de 0,9 [HISTÓRICO, 29/10/2026]. O limiar não foi reavaliado no modelo atual [NÃO DISPONÍVEL].
- **70% para as frases:** escolhido sem experimento [ESTIMADO, decisão de projeto]. A taxa de rejeição por limiar não foi medida (seção 8.4).

---

## 8. Resultados

Métricas por classe calculadas a partir das matrizes de confusão [MEDIDO] `relatorio_tg/medicoes/metricas_por_classe.csv`.

### 8.1 Vogais (Random Forest)
- **Protocolo:** validação por coleta. Treina com 2 coletas e testa na 3ª, 3 vezes. Sem aumento de dados e sem vazamento entre coletas [CÓDIGO] `treinar.py:57-69`.

| Teste | Acurácia |
|---|---|
| Coleta 1 (dados.csv #1) | 96,6% |
| Coleta 2 (dados.csv #2) | 94,4% |
| Coleta 3 (João) | 98,8% |
| **Média ± desvio padrão** | **96,6% ± 2,2** |
| Divisão aleatória 80/20 (otimista) | 99,7% |
[HISTÓRICO] saída de `treinar.py`, 29/10/2026

| Classe | Amostras | Precisão | Revocação | F1 |
|---|---|---|---|---|
| A | 300 | 0,942 | 0,973 | 0,957 |
| E | 300 | 0,939 | 0,977 | 0,958 |
| I | 300 | 0,982 | 0,907 | 0,943 |
| O | 300 | 0,970 | 0,977 | 0,973 |
| U | 300 | 1,000 | 0,997 | 0,998 |
| Média (macro) | | 0,967 | 0,966 | 0,966 |

Matriz (soma das 3 coletas; linhas = real; colunas A, E, I, O, U): A [292, 4, 4, 0, 0] · E [7, 293, 0, 0, 0] · I [11, 8, 272, 9, 0] · O [0, 7, 0, 293, 0] · U [0, 0, 1, 0, 299]. Figura `fig04_matriz_vogais.png`.

### 8.2 Gesto "OI" (LSTM)
- **Protocolo:** validação cruzada estratificada em 5 partes sobre os 120 grupos (60 gravados e 60 sintéticos). As variações de uma sequência ficam todas no mesmo lado. **O teste contém variações aumentadas** (4 por sequência) além das originais [CÓDIGO] `treinar_lstm.py:112-115`.

| Parte | 1 | 2 | 3 | 4 | 5 | Média ± desvio |
|---|---|---|---|---|---|---|
| Acurácia | 100,0% | 95,7% | 95,8% | 100,0% | 95,8% | **97,5% ± 2,3** |
[HISTÓRICO] saída de `treinar_lstm.py`, 29/10/2026. Mediana da probabilidade de "OI" nos OI reais: de 0,94 a 0,99 por parte.

- **Precisão, revocação, F1 e matriz:** [NÃO DISPONÍVEL]. O script não salva a matriz, e calculá-la exige retreinar em validação cruzada. Para obter: copiar `treinar_lstm.py` para `relatorio_tg/scripts/`, trocar `pesos_path`, imprimir `confusion_matrix` e `classification_report` e rodar com `py -3.11`. Cerca de 3 min [ESTIMADO].

### 8.3 Frases (LSTM de duas mãos)
- **Protocolo:** validação por pessoa não vista (GroupKFold com 3 grupos: João, Juliana, referência). As vogais paradas são distribuídas entre os grupos.
- **Aumento de dados:** fica dentro de cada lado. **O teste inclui a gravação original, a espelhada e 3 variações** de cada gravação de teste [CÓDIGO] `treinar_frases.py:150-200`.
- **Vazamento:** os pedaços NENHUM vêm dos mesmos vídeos das frases, mas ficam com a mesma pessoa e por isso no mesmo lado. Não há vazamento entre pessoas.

| Parte (pessoa no teste) | Acurácia |
|---|---|
| Parte 1 | 89,4% |
| Parte 2 | 80,4% |
| Parte 3 | 89,5% |
| **Média ± desvio padrão** | **86,4% ± 5,2** |
[MEDIDO] `relatorio_tg/logs/treino_frases.txt`, 15/11/2026. Qual pessoa ficou em cada parte não é impresso pelo script [NÃO DISPONÍVEL].

| Classe | Exemplos de teste | Precisão | Revocação | F1 |
|---|---|---|---|---|
| Olá, tudo bem? | 140 | 0,477 | 0,800 | 0,597 |
| Qual seu nome? | 168 | 0,833 | 0,833 | 0,833 |
| Onde é o banheiro? | 144 | 0,725 | 0,840 | 0,778 |
| Quanto custa? | 150 | 0,805 | 0,413 | 0,546 |
| Que horas são? | 143 | 0,752 | 0,804 | 0,777 |
| NENHUM | 1.487 | 0,949 | 0,914 | 0,931 |
| Média (macro) | | 0,757 | 0,768 | 0,744 |

Matriz (linhas = real; colunas Olá, Nome, Banheiro, Custa, Horas, NENHUM):
- Olá [112, 0, 7, 2, 1, 18]
- Nome [11, 140, 3, 0, 6, 8]
- Banheiro [0, 0, 121, 0, 2, 21]
- Custa [33, 12, 0, 62, 25, 18]
- Horas [3, 0, 12, 5, 115, 8]
- NENHUM [76, 16, 24, 8, 4, 1.359]

Figura `fig05_matriz_frases.png`.

- **Falsos positivos em trechos sem sinal:** 128 de 1.487 NENHUM foram lidos como frase, ou seja **8,6%**. Frases lidas como NENHUM: 73 de 745 (9,8%) [MEDIDO, a partir da matriz]. As frases mais lidas como NENHUM são "Onde é o banheiro?" (21) e "Olá, tudo bem?" (18).
- **Evolução com mais dados** [MEDIDO/HISTÓRICO, logs]:

| Data | Gravações de sinal | Pessoas | Acurácia com pessoa não vista |
|---|---|---|---|
| 15/11, 1º treino | 32 | João + referência | — (validação por vídeo: 91,2%; pessoa não vista: 64,2% e 28,2%) |
| 15/11, 2º treino | 58 | 3 | 71,8% |
| 15/11, 3º treino (+ vídeos de "nada") | 74 | 3 | 81,9% |
| 15/11, 4º treino (+ 22 da Juliana) | 96 | 3 | **86,4%** |

- **Os "2 erros" do teste antigo (13/15, 29/10/2026)** [HISTÓRICO]: com 6 frames, "Quanto custa?" virou "Qual seu nome?" (0,97) e "Que horas são?" ficou abaixo do limiar (0,50). Esse teste usou os próprios vídeos do treino e não vale como métrica.

### 8.4 Taxa de repetição por causa do limiar
[NÃO DISPONÍVEL]. A validação usa a maior probabilidade, sem limiar. Para medir: aplicar o limiar de 0,7 nas probabilidades do teste em `treinar_frases.py` e contar as respostas vazias. Isso exige retreinar a validação, cerca de 10 min [ESTIMADO]. Há um caso registrado: o vídeo de referência de "Que horas são?" recebeu 0,509 e teria pedido repetição (4.2).

---

## 9. Desempenho

### 9.1 Tempo por etapa na API
[MEDIDO] `relatorio_tg/scripts/medir_latencia.py`, 15/11/2026, Ryzen 5 3500U, Python 3.14.3. São 20 repetições após 1 de aquecimento, com frames 320x240 do vídeo de referência de "Olá, tudo bem?". **Sem rede e sem servidor HTTP.**

| Etapa | Vogais, 8 frames (ms) | Frases, 25 frames (ms) |
|---|---|---|
| Decodificação (base64 + OpenCV) | 5,2 ± 3,2 | 12,8 ± 4,8 |
| MediaPipe | 661,0 ± 118,2 | 2.710,8 ± 388,6 |
| Normalização e reamostragem | 3,0 ± 0,7 | 5,1 ± 1,5 |
| Inferência (RF + LSTM / LSTM) | 24,7 ± 18,9 | 3,6 ± 1,2 |
| **Total** | **694,0 ± 135,1** | **2.732,3 ± 392,1** |
| Tamanho do envio (base64) | 71 KB | 220 KB |

O MediaPipe responde por cerca de 95% do tempo. A medição de 15/11 foi mais lenta por frame (cerca de 83 e 108 ms) do que a de horas antes (60 e 77 ms) [MEDIDO]. O desempenho varia com a carga e a temperatura do notebook.

### 9.2 Outros tempos
- **0,95 s antigo:** 1 execução, 20 imagens de ruído sem mãos, HTTP local [HISTÓRICO]. Sem desvio padrão. Não usar.
- **Captura no app:** não medida [NÃO DISPONÍVEL].
  - Navegador, pelo código: até 8 frames em 1,5 s e até 25 frames em 5 s [ESTIMADO] (janela ÷ 200 ms). O real é menor porque a captura em si leva tempo.
  - Android: `takePicture()` é mais lento; quantidade real [NÃO DISPONÍVEL].
- **Ciclo completo no modo Vogais** [ESTIMADO]: 1,5 s de captura + ~0,7 s de processamento + rede ≈ 2,2 s mais a rede. Com o limite do app, resposta acima de 3 s é descartada.
- **Latência no celular e no Railway:** [NÃO DISPONÍVEL], porque o servidor está fora do ar. Para medir: o app mostra "Resposta em X s" (vogais) e "Analisado em X s" (frases) [CÓDIGO]; anotar 20 leituras por modo. O cabeçalho `X-Tempo-Processamento-Ms` separa o tempo do servidor do tempo de rede.
- **Origem da meta de 3 s:** consta no resumo do projeto escrito pelo grupo ("Testes formais de latência (meta: ≤ 3s)") [HISTÓRICO]. A justificativa: [PERGUNTAR].

### 9.3 Tamanhos
| Arquivo | Tamanho |
|---|---|
| `modelo.pkl` (Random Forest) | 509.636 bytes (≈ 498 KB) |
| `lstm_pesos.npz` (OI) | 54.242 bytes (≈ 53 KB) |
| `frases_pesos.npz` | 213.216 bytes (≈ 208 KB) |
| `hand_landmarker.task` | 7.819.105 bytes (≈ 7,5 MB) |
| `modelo_lstm.keras` | 188.701 bytes |
| Imagem Docker | [NÃO DISPONÍVEL]: Docker não está instalado nesta máquina |
| GIFs | [NÃO DISPONÍVEL]: não gravados. Teste do conversor: vídeo sintético de 3 s → GIF de 162 KB [HISTÓRICO, 29/10/2026] |
| Memória do servidor | [NÃO DISPONÍVEL]: não medida |
[MEDIDO] `ls -la`

---

## 10. Aplicativo

### 10.1 Telas e navegação
[CÓDIGO] `lib/app.dart`, `lib/login.dart`, `lib/registro.dart`, `lib/welcome.dart`, `lib/camera.dart`
1. **Login** (`/login`, tela inicial): e-mail e senha, recuperação de senha por e-mail (`sendPasswordResetEmail`), link para o cadastro.
2. **Registro** (`/registro`): nome, e-mail e senha. O nome vai para o `displayName` do Firebase Auth.
3. **Boas-vindas** (`/welcome`): botão para a câmera.
4. **Câmera** (`/camera`): seletor Frases/Vogais, botão principal e ícones de Histórico e Sair.
   - **Histórico:** painel (ModalBottomSheet) com os registros do usuário.
   - **Respostas:** painel com a frase e os botões de resposta → **GIF** em tela cheia (`Dialog.fullscreen`).
   - **Sair:** confirmação e volta para o Login.
5. **Perfil** (`/perfil`): a rota existe, mas **nenhuma tela leva até ela**, e o conteúdo é "Informações do perfil em breve."
6. **`HistoricoPage`** (`lib/historico.dart`): tela antiga, sem rota; não é usada.

### 10.2 Frases, respostas e GIFs
[CÓDIGO] `lib/frases.dart`

| Frase | Respostas → GIF |
|---|---|
| Olá, tudo bem? | Sim, tudo bem! → `sim_tudo_bem.gif` · Não estou bem → `nao_estou_bem.gif` |
| Qual seu nome? | Meu nome é... → `meu_nome.gif` · Não entendi → `nao_entendi.gif` |
| Onde é o banheiro? | À direita → `direita.gif` · À esquerda → `esquerda.gif` · Em frente → `em_frente.gif` · Não sei → `nao_sei.gif` |
| Quanto custa? | É grátis → `gratis.gif` · Vou chamar alguém → `vou_chamar_alguem.gif` · Não sei → `nao_sei.gif` |
| Que horas são? | Agora são... → `agora_sao.gif` (mostra a hora atual em números) · Não sei → `nao_sei.gif` |

São 11 arquivos distintos. Enquanto um GIF não existe, aparece o texto "GIF ainda não gravado" [CÓDIGO] `lib/respostas.dart`.

### 10.3 Firestore
- **Coleção:** `historico`. Documento: `{uid: string, letra: string, data: timestamp do servidor}` [CÓDIGO] `lib/camera.dart:231-235`.
- **O campo `letra` guarda também "OI" e o texto das frases** (ex.: "Olá, tudo bem?") [CÓDIGO] `lib/camera.dart:203,296`.
- **Quando grava:** a cada frase reconhecida e, no modo Vogais, só quando o resultado muda.

Texto completo de `firestore.rules` [CÓDIGO]:
```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Histórico de traduções: cada usuário só acessa os próprios registros
    match /historico/{docId} {
      allow read, delete: if request.auth != null
                          && resource.data.uid == request.auth.uid;

      allow create: if request.auth != null
                    && request.resource.data.uid == request.auth.uid
                    && request.resource.data.keys().hasOnly(['uid', 'letra', 'data'])
                    && request.resource.data.letra is string
                    && request.resource.data.data == request.time;

      allow update: if false;
    }

    // Qualquer outra coleção fica bloqueada
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 10.4 Tratamento de erros
[CÓDIGO] `lib/camera.dart`
| Situação | O que o app faz |
|---|---|
| API fora do ar ao abrir | "Servidor fora do ar · tocar para tentar de novo"; botões bloqueados |
| Sem internet ou erro de rede | Vogais: "Sem conexão com o servidor, tentando de novo..."; Frases: "Sem conexão com a API. Tente de novo." |
| Demora | Vogais: prazo de 10 s, e resposta acima de 3 s é descartada ("Servidor lento"); Frases: prazo de 20 s ("O servidor demorou demais") |
| Sem mão visível | Vogais: "Mão não detectada"; Frases: "Não vi as mãos. Tente de novo." |
| Frase abaixo do limiar | "Não reconheci a frase. Tente de novo." |
| Modelo de frases ausente (503) | "O modelo de frases ainda não foi treinado." |
| Permissão de câmera negada | Android: `Permission.camera.request()`; sem permissão a câmera não inicia e a tela fica carregando [CÓDIGO] `camera_android.dart:14-17`. Navegador: o erro do `getUserMedia` é ignorado e a captura devolve nada; o app mostra "A câmera não respondeu". Sem mensagem específica de permissão |

### 10.5 Acessibilidade
Existe: dicas (tooltips) nos botões Histórico, Sair e Fechar; resultado em fonte grande; GIF em tela cheia com fundo preto; hora em números grandes [CÓDIGO]. Não existe: rótulos `Semantics`, teste com leitor de tela, ajuste de contraste ou tamanho de fonte [NÃO DISPONÍVEL].

---

## 11. Privacidade
- **Imagens:** a API não grava as imagens em disco [CÓDIGO] `main.py`, sem escrita de arquivos. O log padrão do Uvicorn registra método, caminho e status, não o conteúdo [ESTIMADO, comportamento padrão do Uvicorn; logs do Railway não verificados].
- **Dados pessoais:**
  - No Firebase Authentication: e-mail, senha (gerenciada pelo Firebase) e nome.
  - No Firestore: uid, texto reconhecido e data/hora.
  - **Não há prazo de retenção** definido [NÃO DISPONÍVEL].
- **Vídeos dos integrantes:** ficam só no computador (`backend/videos_frases/`, fora do Git) [CÓDIGO] `.gitignore`. Os dados de treino no GitHub contêm só coordenadas das mãos.
- **HTTPS:**
  - URL padrão da API: `https://...railway.app` [CÓDIGO] `lib/camera.dart:22`.
  - Em teste local, `http://127.0.0.1`.
  - O Android permite HTTP sem criptografia (`usesCleartextTraffic="true"`) [CÓDIGO] `AndroidManifest.xml:12`.
  - O Firebase usa HTTPS.
- **Apagar os próprios dados:**
  - As regras permitem apagar o próprio histórico, mas **o app não tem botão para isso** [CÓDIGO].
  - Não há exclusão de conta no app [CÓDIGO].
- A chave web do Firebase está no código (`lib/main.dart`). Isso é esperado no Firebase; a proteção vem das regras.

---

## 12. Testes e validação
- **Automatizados:** só `test/widget_test.dart`, o teste padrão do Flutter (contador). Ele usa `MyApp`, que não existe no projeto (a classe é `App`), então **não compila** [CÓDIGO]. Não há testes automatizados no backend [NÃO DISPONÍVEL].
- **Verificações feitas durante o desenvolvimento** [HISTÓRICO/MEDIDO, 29/10 a 15/11/2026, notebook do João]:
  - `flutter analyze` sem erros (só avisos de estilo);
  - compilação de todos os arquivos Python;
  - chamadas diretas às rotas com dados reais e simulados;
  - API rodando localmente via HTTP;
  - teste do OI na webcam pelo grupo ("o OI já está funcionando", relato de 29/10);
  - passagem dos vídeos pela API (`backend/testar_frases_videos.py`).
- **Testes manuais do app completo** (dispositivos, navegadores, quantas pessoas, resultados): [PERGUNTAR].
- **Testes com pessoas surdas ou intérpretes:** [PERGUNTAR]. Não há registro [NÃO DISPONÍVEL].
- **Bugs e limitações conhecidos:**
  1. "Quanto custa?" com 41% de revocação (confunde com "Olá" e "Que horas").
  2. 8,6% dos trechos sem sinal viram frase.
  3. O vídeo de referência de "Que horas são?" ficou abaixo do limiar.
  4. Mão parada que não é vogal ainda vira uma vogal, porque o Random Forest não tem a classe "nenhuma".
  5. Diferença de versões do MediaPipe entre o treino (0.10.33) e a produção (0.10.9).
  6. Os modelos de frases foram treinados com vídeos em retrato. Webcam em paisagem pode piorar, porque as coordenadas do MediaPipe são frações da largura e da altura [ESTIMADO, não medido].
  7. O Android envia fotos em tamanho "medium", não 320x240 (envio maior).
  8. A API não tem autenticação nem limite.
  9. `dart:html` está obsoleto (aviso do `flutter analyze`).
  10. Perfil sem conteúdo e sem acesso.
  11. Teste automático quebrado.
  12. API de produção fora do ar.

---

## 13. Histórico de decisões
[HISTÓRICO] `git log` e registros desta sessão

| Data | Etapa |
|---|---|
| 24/04/2026 | Estrutura inicial; câmera com pontos do MediaPipe (`9eb9f2c`, `f4ee8a6`) |
| 05/05/2026 | API funcionando (`be15858`) |
| 13/05/2026 | Firebase: autenticação e histórico (`ff38ccd`) |
| 15 a 22/05/2026 | Novas telas de login e cadastro (Bianca, Ane Bastos, Juliana); recuperação de senha |
| 27 e 28/05/2026 | API para Chrome e Android; câmera separada por plataforma; `google-services.json` |
| 03/06/2026 | **Tentativa de publicar na Azure** (App Service F1, `sinaliza-api`, eastus); registros em `logs/`. Abandonada; motivo: [PERGUNTAR] |
| 07/06/2026 | **Publicação no Railway**: 11 commits em cerca de 1h20 (Python 3.11, OpenCV headless, Dockerfile, pacotes de sistema, libGLES, caminhos) |
| 12/06/2026 | Layout final e correção de caminhos (`638e420`, `f69735f`) |
| 16/09/2026 | Modelo LSTM antigo do OI (data do arquivo `modelo_lstm.h5`) |
| 29/10/2026 | Normalização, validação honesta, coleta guiada; LSTM do OI refeito; módulo de frases; correção da validação sem embaralhar |
| 15/11/2026 | Correção da lentidão; vídeos de 2 integrantes; importação automática; PR #2 no `main`; API de produção encontrada fora do ar |

- **Conflito do MediaPipe com o Flutter no APK:** relatado no artigo (seção 7.5). Mensagem de erro e tentativas: [PERGUNTAR]. Não há registro no Git.
- **Bibliotecas faltando no deploy:** a sequência de commits de 07/06 mostra o caminho:
  - `fad7b50` "força python 3.11";
  - `65e7261` / `7f454f1` OpenCV headless;
  - `d7b8e96` "adiciona Dockerfile com dependencias do sistema";
  - `636f94d` "fix pacotes sistema no Dockerfile";
  - `2faf242` "fix libGLES versao mediapipe scikit-learn e opencv".
  - O Dockerfile instala libgl1, libgles2, libegl1, libglib2.0-0 e outras [CÓDIGO] `Dockerfile:3-13`. As mensagens de erro exatas: [PERGUNTAR].
- **O LSTM antigo do OI não tinha aprendido:**
  - Probabilidades de 0,43 a 0,65 para qualquer sequência; os "100%" vinham de 12 amostras de teste usadas também na parada antecipada.
  - O que mudou: forma da mão normalizada, movimento do pulso, vogais paradas como NENHUM, aumento de dados, embaralhamento antes da validação e validação cruzada.
  - Resultado: 97,5%.
- **Ideias abandonadas:**
  - Azure: [PERGUNTAR] motivo.
  - TensorFlow no servidor: trocado por NumPy, para deixar a imagem leve.
  - `Timer.periodic` de 2 s: causava a fila de respostas.
  - Rotas `async def` com processamento pesado: travavam o servidor.
  - Alinhamento de rotação: sem ganho.
  - Pedaços negativos de 35%: rejeitavam frases.
  - Janela de 4 s: curta para os integrantes.
  - Captura a cada 100 ms: servidor lento.
  - Regra fixa de "mão abaixo de 85% da imagem" na importação: falhava com corpo inteiro.

---

## 14. Material para figuras
Geradas em `relatorio_tg/figuras/`, PNG a 300 dpi [MEDIDO] `relatorio_tg/scripts/gerar_figuras.py`:

| Arquivo | Conteúdo |
|---|---|
| `fig01_arquitetura.png` | Arquitetura: app, API, modelos, Firebase e treino |
| `fig02_fluxo_frases.png` | Fluxo de uma leitura no modo Frases |
| `fig03_pontos_normalizacao.png` | Os 21 pontos de uma vogal "E" antes e depois da normalização |
| `fig04_matriz_vogais.png` | Matriz de confusão das vogais (3 coletas não vistas) |
| `fig05_matriz_frases.png` | Matriz de confusão das frases (pessoa não vista) |

- **Curvas de treino:** [NÃO DISPONÍVEL], porque o histórico das épocas não é salvo (ver 7.2).
- **Matriz do OI:** [NÃO DISPONÍVEL] (ver 8.2).

**Capturas de tela que os integrantes precisam tirar:**
1. Login.
2. Cadastro.
3. Boas-vindas.
4. Câmera no modo Frases, com a contagem na tela.
5. Câmera no modo Frases, com o painel de respostas.
6. GIF de resposta em tela cheia, quando os GIFs existirem.
7. Câmera no modo Vogais, com a letra e "Resposta em X s".
8. Histórico.
9. "Conectando ao servidor..." e "Servidor fora do ar".
10. Um quadro de cada vídeo de coleta, se houver autorização de imagem.

---

## 15. Fontes

| Fonte | Uso no projeto | Evidência |
|---|---|---|
| LUGARESI, C. et al. MediaPipe: A Framework for Building Perception Pipelines. arXiv:1906.08172, 2019. https://arxiv.org/abs/1906.08172 | Fundamentação do MediaPipe | [HISTÓRICO] referências do artigo |
| Modelo `hand_landmarker.task` (Google, MediaPipe Hand Landmarker) | Detecção dos 21 pontos | [CÓDIGO] `backend/hand_landmarker.task`. URL e data de download: [PERGUNTAR] |
| BRASIL. Lei nº 10.436/2002 | Contexto da LIBRAS | [HISTÓRICO] artigo |
| IBGE. PNS 2019 (2021) | Dados de deficiência auditiva | [HISTÓRICO] artigo |
| SCARABELLI, A. F. et al. (2025), LibrasCam | Trabalho similar; limitação do APK | [HISTÓRICO] artigo |
| GAZOLLA, V. G. M. et al. (2023) | Trabalho similar | [HISTÓRICO] artigo |
| MONTEIRO, C. H. A. et al. (2016) | Trabalho similar | [HISTÓRICO] artigo |
| Vídeos de referência das 5 frases | Treino das frases (1 vídeo por frase) | [PERGUNTAR]: título, autor, site, URL, data de acesso e permissão |
| Documentação de Flutter, FastAPI, TensorFlow/Keras, scikit-learn, Firebase, Railway e tutoriais | Desenvolvimento | [PERGUNTAR]: quais foram usados de fato |

---

## 16. O que o artigo não deve afirmar

**Afirmações sem sustentação nos dados atuais:**
1. "O sistema reconhece LIBRAS com 98%" ou "100%": números antigos com divisão otimista. Usar 96,6% (vogais), 97,5% (OI) e 86,4% (frases), sempre citando o protocolo.
2. "Funciona com qualquer pessoa": as frases foram testadas com apenas 3 pessoas, e "Quanto custa?" tem revocação de 41%.
3. "Testado com surdos" ou "validado por intérprete": não há registro.
4. "Latência abaixo de 3 s no celular": nunca foi medida no celular nem no servidor.
5. "A API processa em paralelo": medido como sequencial (4.3).
6. "Respostas em GIF em LIBRAS" como funcionalidade pronta: os GIFs não existem.
7. "Disponível online" ou "hospedado no Railway": hoje está fora do ar.
8. "Compatível com iOS": não há Firebase configurado no iOS nem teste.
9. "Sem servidor pago" (seção 5.1 do artigo): contradiz o plano de pagar o servidor.
10. "Os dados ficam protegidos": as regras do Firestore precisam estar publicadas e a API não tem autenticação.
11. Citar os vídeos de referência sem a fonte e a permissão.

**Perguntas [PERGUNTAR] para o grupo:**
1. Quem gravou as coletas 1 e 2 das vogais e as 60 sequências do OI? Em que condições (câmera, luz, distância, fundo)?
2. Alguma pessoa das gravações é surda ou fluente em LIBRAS? Quem conferiu se os sinais estão corretos?
3. Qual é a origem exata dos 5 vídeos de referência (título, autor, site, URL, data) e há permissão de uso?
4. Houve ou haverá gravação de pessoas de fora do grupo? Existe termo de consentimento ou parecer de Comitê de Ética?
5. As regras do Firestore foram publicadas no console?
6. Em quais dispositivos e navegadores o app completo foi testado, por quem e com que resultado?
7. Qual era a mensagem de erro do conflito do MediaPipe com o Flutter no APK, e o que foi tentado?
8. Quais eram as mensagens de erro do deploy no Railway antes do Docker? Por que a Azure foi abandonada?
9. Qual plano e custo de servidor será contratado (memória, CPU)?
10. De onde veio a meta de 3 s?
11. Como foram escolhidos os hiperparâmetros do Random Forest?
12. Quais tutoriais e documentações foram usados de fato?
13. Quais são as datas de entrega e da banca?
14. Os arquivos `backend/main.py`, `classifier.py`, `landmarks.py` e `sinais.py` ainda são usados?
15. Os nomes completos dos autores e os e-mails do orientador e da coorientadora (pedido em vermelho no DOC).

---

## Anexo A: correções da coorientadora (texto em vermelho no DOC "entrega 1 - TG2 Sinaliza (1).docx")

| Pedido | Onde | Como este relatório ajuda |
|---|---|---|
| "COLOCAR OS NOMES COMPLETO AQUI" | Autores | [PERGUNTAR] nomes completos |
| "colocar os e-mails do orientador e coorientadora aqui" | E-mails | Só o da coorientadora aparece (valeria.volpe@cps.sp.gov.br); falta o do orientador [PERGUNTAR] |
| "PARA CADA TÓPICO COLOQUE DUAS LINHAS EM BRANCO ANTES E UMA DEPOIS" | Formatação | Ajuste de formatação na escrita do artigo |
| "SENTI FALTA DE FIGURAS, GRÁFICOS, TABELAS, QUADROS" | Desenvolvimento | 5 figuras em `relatorio_tg/figuras/`; tabelas prontas nas seções 3, 5, 8, 9 e 10; capturas de tela listadas na seção 14 |
