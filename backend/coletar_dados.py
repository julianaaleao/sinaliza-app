import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import csv
import os

modelo_path = "backend/hand_landmarker.task"
dados_path = "backend/dados.csv"

base_options = python.BaseOptions(model_asset_path=modelo_path)
options = vision.HandLandmarkerOptions(
    base_options=base_options,
    num_hands=1
)
detector = vision.HandLandmarker.create_from_options(options)

vogais = ['A', 'E', 'I', 'O', 'U']
amostras_por_vogal = 100

if not os.path.exists(dados_path):
    with open(dados_path, 'w', newline='') as f:
        writer = csv.writer(f)
        header = []
        for i in range(21):
            header += [f'x{i}', f'y{i}', f'z{i}']
        header.append('letra')
        writer.writerow(header)

cap = cv2.VideoCapture(0)

for vogal in vogais:
    print(f'\n=== Prepare o sinal da vogal: {vogal} ===')
    print('Pressione ESPACO para começar a gravar...')

    while True:
        ret, frame = cap.read()
        cv2.putText(frame, f'PREPARE: {vogal}', (50, 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 255, 255), 3)
        cv2.putText(frame, 'Pressione ESPACO para gravar', (50, 150),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
        cv2.imshow('SINALIZA - Coleta', frame)
        if cv2.waitKey(1) & 0xFF == ord(' '):
            break

    contador = 0
    print(f'Gravando {amostras_por_vogal} amostras de {vogal}...')

    while contador < amostras_por_vogal:
        ret, frame = cap.read()
        if not ret:
            break

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
        result = detector.detect(mp_image)

        if result.hand_landmarks:
            hand = result.hand_landmarks[0]
            row = []
            for landmark in hand:
                row += [landmark.x, landmark.y, landmark.z]
            row.append(vogal)

            with open(dados_path, 'a', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(row)

            contador += 1

            for landmark in hand:
                h, w, _ = frame.shape
                cx, cy = int(landmark.x * w), int(landmark.y * h)
                cv2.circle(frame, (cx, cy), 5, (0, 255, 0), -1)

        cv2.putText(frame, f'{vogal}: {contador}/{amostras_por_vogal}', (50, 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 255, 0), 3)
        cv2.imshow('SINALIZA - Coleta', frame)
        cv2.waitKey(1)

    print(f'{amostras_por_vogal} amostras de {vogal} salvas!')

cap.release()
cv2.destroyAllWindows()
print('\nColeta finalizada! Arquivo salvo em backend/dados.csv')