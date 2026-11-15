import numpy as np
import pandas as pd
import glob
import os
import sys
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Input, LSTM, Dense, Dropout
from tensorflow.keras.callbacks import EarlyStopping
from sklearn.model_selection import StratifiedGroupKFold, GroupKFold
from sklearn.metrics import confusion_matrix

# Uso (precisa de um Python com TensorFlow): py -3.11 backend/treinar_frases.py
# Lê backend/dados_frases/<FRASE>/*.npz e gera backend/api/modelo/frases_pesos.npz,
# que a API usa sem TensorFlow.

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'api'))
from frases import (FRASES, FRAMES_POR_SEQ, N_CARACTERISTICAS, DURACAO_SEGUNDOS,
                    preparar_frase, espelhar)
from gesto import ModeloGesto

dados_path = os.environ.get('SINALIZA_DADOS_FRASES', 'backend/dados_frases')
pesos_path = os.environ.get('SINALIZA_PESOS_FRASES', 'backend/api/modelo/frases_pesos.npz')
rng = np.random.default_rng(42)
tf.random.set_seed(42)

print("=== SINALIZA - Treino das frases ===\n")

# 1. Gravações do coletar_frases.py
gravacoes = []  # (maos, tempos, classe, pessoa)
videos = []     # de qual vídeo/sessão veio cada exemplo (para não misturar treino e teste)
for frase in FRASES:
    for arquivo in sorted(glob.glob(os.path.join(dados_path, frase, '*.npz'))):
        d = np.load(arquivo)
        partes = os.path.basename(arquivo).split('_')
        gravacoes.append((d['maos'], d['tempos'], frase, partes[0]))
        videos.append('_'.join(partes[:2]))

classes = [f for f in FRASES if any(g[2] == f for g in gravacoes)]
if 'NENHUM' not in classes:
    classes.append('NENHUM')

# 2. Mão parada fazendo vogais também é NENHUM
vogais = [pd.read_csv(f) for f in ['backend/dados.csv'] + glob.glob('backend/dados/*.csv')
          if os.path.exists(f)]
if vogais:
    linhas = pd.concat(vogais).drop('letra', axis=1).values
    for i in rng.choice(len(linhas), min(40, len(linhas)), replace=False):
        maos = np.full((FRAMES_POR_SEQ, 2, 63), np.nan)
        maos[:, 0] = linhas[i] + rng.normal(0, 0.002, (FRAMES_POR_SEQ, 63))
        gravacoes.append((maos, None, 'NENHUM', 'vogais'))
        videos.append(f'vogal_{i}')

print("Gravações por frase:")
for c in classes:
    pessoas = sorted({g[3] for g in gravacoes if g[2] == c})
    print(f"  {c:15s} {sum(g[2] == c for g in gravacoes):4d}  ({', '.join(pessoas)})")
if len([c for c in classes if c != 'NENHUM']) < 1:
    raise SystemExit("\nNenhuma frase gravada ainda. Rode o backend/coletar_frases.py.")

rotulos = np.array([classes.index(g[2]) for g in gravacoes])
pessoas = np.array([g[3] for g in gravacoes])


def variacoes(maos, tempos, n):
    """Simula o celular: menos frames, ritmos diferentes, ruído e imagem espelhada."""
    em_ms = tempos is not None
    if tempos is None:
        tempos = np.arange(len(maos), dtype=np.float64)
    saida = []
    total = len(maos)
    janela = DURACAO_SEGUNDOS * 1000
    for _ in range(n):
        if em_ms and tempos[-1] - tempos[0] > janela:
            # Gravação maior que a janela do app: o app só pega um pedaço
            inicio = rng.uniform(tempos[0], tempos[-1] - janela)
            ini = int(np.searchsorted(tempos, inicio))
            fim = int(np.searchsorted(tempos, inicio + janela))
        else:
            # Recorte no tempo: a pessoa pode começar um pouco antes ou depois
            corte = int(0.15 * total)
            ini = rng.integers(0, corte + 1)
            fim = total - rng.integers(0, corte + 1)
        if fim - ini < 4:
            ini, fim = 0, total
        qtd = rng.integers(min(4, fim - ini), fim - ini + 1)
        idx = np.sort(rng.choice(np.arange(ini, fim), qtd, replace=False))
        seq = maos[idx] + rng.normal(0, 0.003, maos[idx].shape)
        if rng.random() < 0.5:
            seq = espelhar(seq)
        x = preparar_frase(seq, tempos[idx])
        if x is not None:
            saida.append(x)
    return saida


por_classe = np.bincount(rotulos, minlength=len(classes))


def montar(indices, n_var):
    X, y = [], []
    for i in indices:
        maos, tempos, _, _ = gravacoes[i]
        # Frases com poucas gravações ganham mais variações
        n_var_i = max(n_var, 120 // por_classe[rotulos[i]])
        for seq in (maos, espelhar(maos)):
            x = preparar_frase(seq, tempos)
            if x is not None:
                X.append(x)
                y.append(rotulos[i])
        for x in variacoes(maos, tempos, n_var_i):
            X.append(x)
            y.append(rotulos[i])
    return np.array(X), np.array(y)


def criar_modelo():
    modelo = Sequential([
        Input((FRAMES_POR_SEQ, N_CARACTERISTICAS)),
        LSTM(64),
        Dropout(0.3),
        Dense(32, activation='relu'),
        Dense(len(classes), activation='softmax'),
    ])
    modelo.compile(optimizer='adam', loss='sparse_categorical_crossentropy',
                   metrics=['accuracy'])
    return modelo


def treinar(X, y):
    # Embaralha: o validation_split do Keras pega sempre o final dos dados
    ordem = rng.permutation(len(y))
    X, y = X[ordem], y[ordem]
    contagem = np.bincount(y, minlength=len(classes))
    pesos = {i: len(y) / (len(classes) * c) for i, c in enumerate(contagem) if c}
    m = criar_modelo()
    if por_classe.min() < 3:
        # Com 1 ou 2 gravações por frase a validação seria só cópia do treino:
        # treina um número fixo de épocas
        m.fit(X, y, epochs=40, batch_size=32, verbose=0, class_weight=pesos)
        return m
    m.fit(X, y, epochs=80, batch_size=32, verbose=0, class_weight=pesos,
          validation_split=0.15,
          callbacks=[EarlyStopping(monitor='val_loss', patience=10,
                                   restore_best_weights=True)])
    return m


# 3. Avaliação honesta. Com 2+ pessoas, testa sempre em quem o modelo não viu.
gravadores = sorted(set(pessoas) - {'vogais'})
minimo_por_frase = np.bincount(rotulos, minlength=len(classes)).min()
if minimo_por_frase < 3:
    print("\nPoucos exemplos por frase para avaliar (mínimo 3). "
          "Grave mais com o coletar_frases.py ou importar_videos.py.")
    divisoes = []
elif len(gravadores) >= 3:
    print(f"\nValidação por pessoa não vista ({len(gravadores)} pessoas)...")
    grupos = np.array([p if p != 'vogais' else gravadores[i % len(gravadores)]
                       for i, p in enumerate(pessoas)])
    divisoes = list(GroupKFold(len(gravadores)).split(np.zeros(len(rotulos)), rotulos, grupos))
else:
    # Poucas pessoas: separa por vídeo (nunca testa num vídeo visto no treino)
    print("\nValidação cruzada por vídeo (5 partes). É otimista para pessoas que não gravaram.")
    divisoes = list(StratifiedGroupKFold(5, shuffle=True, random_state=42).split(
        np.zeros(len(rotulos)), rotulos, videos))


def avaliar(divisoes, titulo=None):
    acertos = []
    reais, previstos = [], []
    for parte, (tr, te) in enumerate(divisoes, start=1):
        X_tr, y_tr = montar(tr, 6)
        X_te, y_te = montar(te, 3)
        p = treinar(X_tr, y_tr).predict(X_te, verbose=0).argmax(1)
        acertos.append((p == y_te).mean())
        reais += list(y_te)
        previstos += list(p)
        print(f"  {titulo or f'parte {parte}'}: {acertos[-1] * 100:.1f}%")
    if acertos and not titulo:
        print(f"Média: {np.mean(acertos) * 100:.1f}%")
    if acertos:
        print("\nMatriz de confusão (linhas = frase real):")
        print("  " + " ".join(f"{c[:6]:>6s}" for c in classes))
        for c, linha in zip(classes, confusion_matrix(reais, previstos, labels=range(len(classes)))):
            print(f"  {' '.join(f'{v:6d}' for v in linha)}  {c}")


avaliar(divisoes)

# Com exatamente 2 pessoas: treina com uma e testa na outra
if len(gravadores) == 2 and minimo_por_frase >= 3:
    for teste in gravadores:
        te = np.where(pessoas == teste)[0]
        if len({rotulos[i] for i in te}) < 2:
            continue
        tr = np.where(pessoas != teste)[0]
        print(f"\nPessoa não vista: treina sem '{teste}', testa em '{teste}'")
        avaliar([(tr, te)], titulo=f"acerto em '{teste}'")

# 4. Modelo final com tudo
print("\nTreinando modelo final...")
X, y = montar(range(len(gravacoes)), 6)
modelo = treinar(X, y)

lstm, dense1, dense2 = [l for l in modelo.layers if l.get_weights()]
kernel, recorrente, bias = lstm.get_weights()
os.makedirs(os.path.dirname(pesos_path), exist_ok=True)
np.savez(pesos_path, classes=np.array(classes),
         lstm0_kernel=kernel, lstm0_recorrente=recorrente, lstm0_bias=bias,
         dense0_kernel=dense1.get_weights()[0], dense0_bias=dense1.get_weights()[1],
         dense1_kernel=dense2.get_weights()[0], dense1_bias=dense2.get_weights()[1])

numpy_m = ModeloGesto(pesos_path)
dif = np.abs(np.array([numpy_m.prever(x) for x in X[:50]]) - modelo.predict(X[:50], verbose=0)).max()
print(f"Diferença numpy x Keras: {dif:.1e}")
print(f"Classes: {classes}")
print(f"Pesos salvos em {pesos_path}")
