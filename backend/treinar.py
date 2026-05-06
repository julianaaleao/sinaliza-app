import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import pickle
import os

print("Lendo dados...")
df = pd.read_csv('backend/dados.csv')

X = df.drop('letra', axis=1)
y = df['letra']

print(f"Total de amostras: {len(df)}")
print(f"Vogais encontradas: {df['letra'].unique()}")

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

print("Treinando modelo...")
modelo = RandomForestClassifier(n_estimators=100, random_state=42)
modelo.fit(X_train, y_train)

y_pred = modelo.predict(X_test)
acuracia = accuracy_score(y_test, y_pred)
print(f"Acurácia do modelo: {acuracia * 100:.1f}%")

os.makedirs('backend/modelo', exist_ok=True)
with open('backend/modelo/modelo.pkl', 'wb') as f:
    pickle.dump(modelo, f)

print("Modelo salvo em backend/modelo/modelo.pkl!")
print("Pronto para usar no app!")