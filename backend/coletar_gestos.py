import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import numpy as np
import os

# Configurações
modelo_path = "backend/hand_landmarker.task"
dados_path = "backend/dados_gestos"
gestos = ['NENHUM']         # começa com 1 gesto, adiciona mais depois
sequencias = 30         # 30 repetições por gesto
frames_por_seq = 30     # 30 frames por repetição

# Cria as pastas
for gesto in gestos:
    os.makedirs(os.path.join(dados_path, gesto), exist_ok=True)

# Configura o MediaPipe
base_options = python.BaseOptions(model_asset_path=modelo_path)
options = vision.HandLandmarkerOptions(
    base_options=base_options,
    num_hands=1
)
detector = vision.HandLandmarker.create_from_options(options)

cap = cv2.VideoCapture(1)

for gesto in gestos:
    print(f'\n=== GESTO: {gesto} ===')
    print('Pressione ESPACO para começar...')

    # Aguarda o espaço para começar
    while True:
        ret, frame = cap.read()
        cv2.putText(frame, f'PREPARE: {gesto}', (50, 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 255, 255), 3)
        cv2.putText(frame, 'Pressione ESPACO para gravar', (50, 150),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
        cv2.imshow('SINALIZA - Coleta Gestos', frame)
        if cv2.waitKey(1) & 0xFF == ord(' '):
            break

    for seq in range(sequencias):
        print(f'  Gravando sequencia {seq + 1}/{sequencias}...')
        frames_coletados = []
        frame_count = 0

        # Countdown antes de cada sequência
        for countdown in range(3, 0, -1):
            ret, frame = cap.read()
            cv2.putText(frame, str(countdown), (300, 250),
                        cv2.FONT_HERSHEY_SIMPLEX, 5, (0, 0, 255), 5)
            cv2.putText(frame, f'Seq {seq + 1}/{sequencias}', (50, 80),
                        cv2.FONT_HERSHEY_SIMPLEX, 1.5, (255, 255, 0), 3)
            cv2.imshow('SINALIZA - Coleta Gestos', frame)
            cv2.waitKey(700)

        # Captura os 30 frames da sequência
        while frame_count < frames_por_seq:
            ret, frame = cap.read()
            if not ret:
                break

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
            result = detector.detect(mp_image)

            if result.hand_landmarks:
                hand = result.hand_landmarks[0]
                landmarks = []
                for landmark in hand:
                    landmarks += [landmark.x, landmark.y, landmark.z]
                frames_coletados.append(landmarks)

                # Desenha os pontos
                for landmark in hand:
                    h, w, _ = frame.shape
                    cx, cy = int(landmark.x * w), int(landmark.y * h)
                    cv2.circle(frame, (cx, cy), 5, (0, 255, 0), -1)

                frame_count += 1
            else:
                # Se não detectou mão, adiciona frame zerado
                frames_coletados.append([0.0] * 63)
                frame_count += 1

            cv2.putText(frame, f'{gesto} | Seq {seq+1} | Frame {frame_count}/{frames_por_seq}',
                        (10, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
            cv2.imshow('SINALIZA - Coleta Gestos', frame)
            cv2.waitKey(1)

        # Salva a sequência como arquivo numpy
        if len(frames_coletados) == frames_por_seq:
            caminho = os.path.join(dados_path, gesto, f'{seq}.npy')
            np.save(caminho, np.array(frames_coletados))
            print(f'    Sequencia {seq + 1} salva!')
        else:
            print(f'    Sequencia {seq + 1} ignorada (mão não detectada)')

        # Pausa entre sequências
        cv2.waitKey(500)

cap.release()
cv2.destroyAllWindows()
print('\nColeta finalizada!')
print(f'Dados salvos em: {dados_path}/')
print(f'Total: {sequencias} sequencias de {frames_por_seq} frames para o gesto OI')