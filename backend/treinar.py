import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, confusion_matrix
import pickle
import os
import sys
import glob

# Mesma normalização usada pela API
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'api'))
from normalizacao import normalizar_landmarks

print("Lendo dados...")
partes = []
nomes_coletas = []

# dados.csv antigo: várias coletas no mesmo arquivo, sempre na ordem A, E, I, O, U.
# Uma nova coleta começa quando a primeira vogal reaparece.
if os.path.exists('backend/dados.csv'):
    antigo = pd.read_csv('backend/dados.csv')
    letras = antigo['letra'].values
    inicio = (letras == letras[0]) & (np.roll(letras, 1) != letras[0])
    inicio[0] = True
    ids = np.cumsum(inicio)
    for c in range(1, ids.max() + 1):
        partes.append(antigo[ids == c])
        nomes_coletas.append(f'dados.csv #{c}')

# Coletas novas: um arquivo por execução do coletar_dados.py
for caminho in sorted(glob.glob('backend/dados/*.csv')):
    partes.append(pd.read_csv(caminho))
    nomes_coletas.append(os.path.basename(caminho))

df = pd.concat(partes, ignore_index=True)
coleta = np.concatenate([[i] * len(p) for i, p in enumerate(partes)])
n_coletas = len(partes)

X = np.array([normalizar_landmarks(r) for r in df.drop('letra', axis=1).values])
y = df['letra'].values

print(f"Total de amostras: {len(df)}")
print(f"Vogais encontradas: {sorted(set(y))}")
print(f"Coletas encontradas: {n_coletas}")

# Split aleatório: frames vizinhos caem no treino e no teste, então é otimista
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)
modelo = RandomForestClassifier(n_estimators=100, random_state=42)
modelo.fit(X_train, y_train)
acuracia = accuracy_score(y_test, modelo.predict(X_test))
print(f"\nAcurácia (split aleatório, otimista): {acuracia * 100:.1f}%")

# Avaliação honesta: testa sempre numa coleta que o modelo não viu
if n_coletas > 1:
    print("\nAcurácia por coleta não vista:")
    acertos = []
    for c in range(n_coletas):
        teste = coleta == c
        m = RandomForestClassifier(n_estimators=100, random_state=42)
        m.fit(X[~teste], y[~teste])
        y_pred = m.predict(X[teste])
        acc = accuracy_score(y[teste], y_pred)
        acertos.append(acc)
        print(f"  {nomes_coletas[c]}: {acc * 100:.1f}%")
        print(confusion_matrix(y[teste], y_pred, labels=sorted(set(y))))
    print(f"Média: {np.mean(acertos) * 100:.1f}%")

print("\nTreinando modelo final com todos os dados...")
modelo = RandomForestClassifier(n_estimators=100, random_state=42)
modelo.fit(X, y)

os.makedirs('backend/modelo', exist_ok=True)
with open('backend/modelo/modelo.pkl', 'wb') as f:
    pickle.dump(modelo, f)
os.makedirs('backend/api/modelo', exist_ok=True)
with open('backend/api/modelo/modelo.pkl', 'wb') as f:
    pickle.dump(modelo, f)

print("Modelo salvo em backend/modelo/ e backend/api/modelo/!")
print("Pronto para usar no app!")
