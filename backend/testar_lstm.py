import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import argparse
import os
import sys
import time

# Testa o gesto OI na webcam com o mesmo modelo e preparo da API.
# Uso: python backend/testar_lstm.py --camera 1

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'api'))
from gesto import ModeloGesto, GESTOS, preparar_sequencia

parser = argparse.ArgumentParser()
parser.add_argument('--camera', type=int, default=0)
args = parser.parse_args()

JANELA = 1.5  # segundos, igual ao app
LIMIAR = 0.9  # igual à API

modelo = ModeloGesto("backend/api/modelo/lstm_pesos.npz")

base_options = python.BaseOptions(model_asset_path="backend/hand_landmarker.task")
options = vision.HandLandmarkerOptions(base_options=base_options, num_hands=1)
detector = vision.HandLandmarker.create_from_options(options)

buffer = []  # (tempo, landmarks ou None)
resultado = ""
confianca = 0.0

cap = cv2.VideoCapture(args.camera)
print("Webcam aberta! Pressione Q para sair.")

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    result = detector.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb))

    agora = time.time()
    if result.hand_landmarks:
        hand = result.hand_landmarks[0]
        landmarks = []
        h, w, _ = frame.shape
        for landmark in hand:
            landmarks += [landmark.x, landmark.y, landmark.z]
            cv2.circle(frame, (int(landmark.x * w), int(landmark.y * h)), 5, (0, 255, 0), -1)
        buffer.append((agora, landmarks))
    else:
        buffer.append((agora, None))

    # Mantém só a última janela de tempo
    buffer = [b for b in buffer if agora - b[0] <= JANELA]

    entrada = preparar_sequencia([b[1] for b in buffer], [b[0] for b in buffer])
    if entrada is not None:
        probs = modelo.prever(entrada)
        idx = probs.argmax()
        confianca = probs[idx] * 100
        resultado = GESTOS[idx] if probs[idx] >= LIMIAR else ""

    tela = cv2.flip(frame, 1)
    if resultado and resultado != 'NENHUM':
        cv2.putText(tela, f'{resultado} ({confianca:.0f}%)', (50, 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 255, 0), 3)
    else:
        cv2.putText(tela, '...', (50, 80), cv2.FONT_HERSHEY_SIMPLEX, 2, (128, 128, 128), 3)
    cv2.putText(tela, 'Q para sair', (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
    cv2.imshow('SINALIZA - Teste LSTM', tela)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
