import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import argparse
import csv
import os
import time
from datetime import datetime

# Uso:
#   python backend/coletar_dados.py --nome joao
#   python backend/coletar_dados.py --nome maria --vogais E I --camera 1
# Cada execução vira um arquivo em backend/dados/ (uma "coleta").

parser = argparse.ArgumentParser(description='SINALIZA - coleta de vogais')
parser.add_argument('--nome', required=True, help='quem está fazendo os sinais')
parser.add_argument('--vogais', nargs='+', default=['A', 'E', 'I', 'O', 'U'])
parser.add_argument('--amostras', type=int, default=100, help='amostras por vogal')
parser.add_argument('--camera', type=int, default=0)
parser.add_argument('--intervalo', type=float, default=0.1,
                    help='segundos entre amostras (evita frames repetidos)')
args = parser.parse_args()

modelo_path = "backend/hand_landmarker.task"
pasta_dados = "backend/dados"

# A amostragem de cada vogal é dividida em fases, para o modelo ver a mão
# em várias posições e distâncias (texto sem acento: o OpenCV não desenha)
fases = [
    'Mao no CENTRO, distancia normal',
    'Mao MAIS PERTO da camera',
    'Mao MAIS LONGE da camera',
    'Mova a mao pela tela e incline um pouco',
]

base_options = python.BaseOptions(model_asset_path=modelo_path)
options = vision.HandLandmarkerOptions(
    base_options=base_options,
    num_hands=1
)
detector = vision.HandLandmarker.create_from_options(options)

header = []
for i in range(21):
    header += [f'x{i}', f'y{i}', f'z{i}']
header.append('letra')


def detectar(frame):
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    result = detector.detect(mp_image)
    return result.hand_landmarks[0] if result.hand_landmarks else None


def mostrar(frame, hand, linhas, cor=(255, 255, 255)):
    h, w, _ = frame.shape
    if hand:
        for landmark in hand:
            cx, cy = int(landmark.x * w), int(landmark.y * h)
            cv2.circle(frame, (cx, cy), 5, (0, 255, 0), -1)
    # Espelha só a visualização, os dados continuam como a câmera captura
    tela = cv2.flip(frame, 1)
    for i, texto in enumerate(linhas):
        cv2.putText(tela, texto, (30, 50 + i * 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.9, cor, 2)
    cv2.imshow('SINALIZA - Coleta', tela)
    return cv2.waitKey(1) & 0xFF


def esperar_espaco(cap, linhas):
    """Mostra a câmera até apertar ESPACO. Retorna False se apertar Q."""
    while True:
        ret, frame = cap.read()
        if not ret:
            return False
        tecla = mostrar(frame, detectar(frame), linhas + ['ESPACO: gravar | Q: sair'],
                        (0, 255, 255))
        if tecla == ord(' '):
            return True
        if tecla == ord('q'):
            return False


cap = cv2.VideoCapture(args.camera)
if not cap.isOpened():
    raise SystemExit(f'Nao consegui abrir a camera {args.camera}')

os.makedirs(pasta_dados, exist_ok=True)
carimbo = datetime.now().strftime('%Y%m%d_%H%M%S')
arquivo = os.path.join(pasta_dados, f'{args.nome}_{carimbo}.csv')

linhas_salvas = []
por_fase = [args.amostras // len(fases)] * len(fases)
por_fase[-1] += args.amostras - sum(por_fase)
saiu = False

for vogal in args.vogais:
    print(f'\n=== Vogal {vogal} ===')
    amostras_vogal = []

    for n_fase, (fase, total) in enumerate(zip(fases, por_fase), start=1):
        if not esperar_espaco(cap, [f'VOGAL {vogal} - fase {n_fase}/{len(fases)}', fase]):
            saiu = True
            break

        contador = 0
        ultimo = 0.0
        while contador < total:
            ret, frame = cap.read()
            if not ret:
                saiu = True
                break
            hand = detectar(frame)

            agora = time.time()
            if hand and agora - ultimo >= args.intervalo:
                row = []
                for landmark in hand:
                    row += [landmark.x, landmark.y, landmark.z]
                amostras_vogal.append(row + [vogal])
                contador += 1
                ultimo = agora

            status = f'{vogal}: {contador}/{total}' if hand else 'Mao nao detectada'
            tecla = mostrar(frame, hand, [status, fase],
                            (0, 255, 0) if hand else (0, 0, 255))
            if tecla == ord('q'):
                saiu = True
                break
        if saiu:
            break

    if saiu:
        print(f'Coleta interrompida. As amostras de {vogal} foram descartadas.')
        break

    linhas_salvas += amostras_vogal
    print(f'{len(amostras_vogal)} amostras de {vogal} ok')

cap.release()
cv2.destroyAllWindows()

if linhas_salvas:
    with open(arquivo, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(linhas_salvas)
    print(f'\n{len(linhas_salvas)} amostras salvas em {arquivo}')
else:
    print('\nNenhuma vogal completa, nada foi salvo.')
