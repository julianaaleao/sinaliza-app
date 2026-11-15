import numpy as np
import pandas as pd
import glob
import os
import sys
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Input, LSTM, Dense, Dropout
from tensorflow.keras.callbacks import EarlyStopping
from sklearn.model_selection import StratifiedKFold

# Uso (precisa de um Python com TensorFlow): py -3.11 backend/treinar_lstm.py
# Gera backend/api/modelo/lstm_pesos.npz, que a API usa sem TensorFlow.

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'api'))
from gesto import GESTOS, FRAMES_POR_SEQ, preparar_sequencia, ModeloGesto

dados_path = "backend/dados_gestos"
pesos_path = "backend/api/modelo/lstm_pesos.npz"
rng = np.random.default_rng(42)
tf.random.set_seed(42)

print("=== SINALIZA - Treino LSTM ===\n")


def sem_zeros(seq):
    # Na coleta, frame sem mão foi gravado como zeros; a API usa None
    return [None if not np.any(f) else f for f in seq]


def variacoes(seq, n):
    """Simula o celular capturando menos frames e em ritmos diferentes,
    do mesmo jeito que a API vai receber."""
    saida = []
    for _ in range(n):
        qtd = rng.integers(6, FRAMES_POR_SEQ + 1)
        idx = np.sort(rng.choice(FRAMES_POR_SEQ, qtd, replace=False))
        frames = [seq[i] for i in idx]
        if rng.random() < 0.5:
            frames = [None if f is None else np.asarray(f) + rng.normal(0, 0.003, 63)
                      for f in frames]
        x = preparar_sequencia(frames, list(idx))
        if x is not None:
            saida.append(x)
    return saida


# 1. Sequências gravadas pelo coletar_gestos.py
grupos = []  # (sequência original, rótulo)
for idx, gesto in enumerate(GESTOS):
    for arquivo in sorted(glob.glob(os.path.join(dados_path, gesto, '*.npy'))):
        seq = np.load(arquivo)
        if seq.shape == (FRAMES_POR_SEQ, 63):
            grupos.append((sem_zeros(seq), idx))
print(f"Sequências gravadas: {len(grupos)}")

# 2. Mão parada fazendo vogais também é NENHUM (evita confundir vogal com OI)
nenhum = GESTOS.index('NENHUM')
vogais = [pd.read_csv('backend/dados.csv')]
vogais += [pd.read_csv(f) for f in glob.glob('backend/dados/*.csv')]
linhas = pd.concat(vogais).drop('letra', axis=1).values
for i in rng.choice(len(linhas), 60, replace=False):
    parada = [linhas[i] + rng.normal(0, 0.002, 63) for _ in range(FRAMES_POR_SEQ)]
    grupos.append((parada, nenhum))
print(f"Com vogais paradas como NENHUM: {len(grupos)}\n")

rotulos = np.array([g[1] for g in grupos])


def montar(indices, n_var):
    X, y = [], []
    for i in indices:
        seq, rot = grupos[i]
        completa = preparar_sequencia(seq)
        if completa is not None:
            X.append(completa)
            y.append(rot)
        for v in variacoes(seq, n_var):
            X.append(v)
            y.append(rot)
    return np.array(X), np.array(y)


def criar_modelo():
    modelo = Sequential([
        Input((FRAMES_POR_SEQ, 65)),
        LSTM(32),
        Dropout(0.3),
        Dense(16, activation='relu'),
        Dense(len(GESTOS), activation='softmax'),
    ])
    modelo.compile(optimizer='adam', loss='sparse_categorical_crossentropy',
                   metrics=['accuracy'])
    return modelo


def pesos_classe(y):
    contagem = np.bincount(y, minlength=len(GESTOS))
    return {i: len(y) / (len(GESTOS) * c) for i, c in enumerate(contagem) if c}


def embaralhar(X, y):
    # O validation_split do Keras pega sempre o final dos dados
    ordem = rng.permutation(len(y))
    return X[ordem], y[ordem]


# 3. Avaliação honesta: as variações de uma sequência ficam todas
#    no mesmo lado (treino ou teste)
print("Validação cruzada (5 partes)...")
acertos = []
for parte, (tr, te) in enumerate(StratifiedKFold(5, shuffle=True, random_state=42)
                                 .split(np.zeros(len(rotulos)), rotulos), start=1):
    X_tr, y_tr = embaralhar(*montar(tr, 8))
    X_te, y_te = montar(te, 4)
    m = criar_modelo()
    m.fit(X_tr, y_tr, epochs=60, batch_size=32, verbose=0,
          class_weight=pesos_classe(y_tr), validation_split=0.15,
          callbacks=[EarlyStopping(monitor='val_loss', patience=10,
                                   restore_best_weights=True)])
    p = m.predict(X_te, verbose=0)
    acc = (p.argmax(1) == y_te).mean()
    oi = GESTOS.index('OI')
    conf_oi = p[y_te == oi, oi]
    acertos.append(acc)
    print(f"  parte {parte}: acurácia {acc * 100:.1f}% | prob. OI nos OI reais: "
          f"mediana {np.median(conf_oi):.2f}")
print(f"Média: {np.mean(acertos) * 100:.1f}%\n")

# 4. Modelo final com tudo
print("Treinando modelo final...")
X, y = embaralhar(*montar(range(len(grupos)), 8))
modelo = criar_modelo()
modelo.fit(X, y, epochs=60, batch_size=32, verbose=0,
           class_weight=pesos_classe(y), validation_split=0.15,
           callbacks=[EarlyStopping(monitor='val_loss', patience=10,
                                    restore_best_weights=True)])

lstm, dense1, dense2 = [l for l in modelo.layers if l.get_weights()]
kernel, recorrente, bias = lstm.get_weights()
np.savez(pesos_path,
         lstm0_kernel=kernel, lstm0_recorrente=recorrente, lstm0_bias=bias,
         dense0_kernel=dense1.get_weights()[0], dense0_bias=dense1.get_weights()[1],
         dense1_kernel=dense2.get_weights()[0], dense1_bias=dense2.get_weights()[1])
modelo.save("backend/modelo/modelo_lstm.keras")

# Confere se a versão numpy da API dá o mesmo resultado do Keras
numpy_m = ModeloGesto(pesos_path)
dif = np.abs(np.array([numpy_m.prever(x) for x in X[:50]]) - modelo.predict(X[:50], verbose=0)).max()
print(f"Diferença numpy x Keras: {dif:.1e}")
print(f"Pesos salvos em {pesos_path}")
