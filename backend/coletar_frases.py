import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import argparse
import numpy as np
import os
import sys
import time
from datetime import datetime

# Grava as frases em LIBRAS para treinar o LSTM.
# Uso:
#   python backend/coletar_frases.py --nome joao --camera 1
#   python backend/coletar_frases.py --nome maria --frases QUE_HORAS NENHUM --repeticoes 10
# Cada repetição vira um arquivo backend/dados_frases/<FRASE>/<nome>_<data>_<n>.npz

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'api'))
from frases import FRASES, DURACAO_SEGUNDOS, maos_do_resultado

# Texto sem acento: o OpenCV não desenha acentos
DICAS = {
    'OLA_TUDO_BEM': 'Sinalize: OLA, TUDO BEM?',
    'QUAL_SEU_NOME': 'Sinalize: QUAL SEU NOME?',
    'ONDE_BANHEIRO': 'Sinalize: ONDE E O BANHEIRO?',
    'QUANTO_CUSTA': 'Sinalize: QUANTO CUSTA?',
    'QUE_HORAS': 'Sinalize: QUE HORAS SAO?',
    'NENHUM': 'Mexa as maos SEM fazer as frases (vogais, cocar, apontar...)',
}

parser = argparse.ArgumentParser(description='SINALIZA - coleta de frases')
parser.add_argument('--nome', required=True, help='quem está sinalizando')
parser.add_argument('--frases', nargs='+', default=FRASES, choices=FRASES)
parser.add_argument('--repeticoes', type=int, default=20, help='gravações por frase')
parser.add_argument('--camera', type=int, default=0)
args = parser.parse_args()

base_options = python.BaseOptions(model_asset_path="backend/hand_landmarker.task")
options = vision.HandLandmarkerOptions(base_options=base_options, num_hands=2)
detector = vision.HandLandmarker.create_from_options(options)

cap = cv2.VideoCapture(args.camera)
if not cap.isOpened():
    raise SystemExit(f'Nao consegui abrir a camera {args.camera}')

carimbo = datetime.now().strftime('%Y%m%d_%H%M%S')


def ler():
    ret, frame = cap.read()
    if not ret:
        raise SystemExit('Camera parou de responder')
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    result = detector.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb))
    h, w, _ = frame.shape
    for mao in result.hand_landmarks:
        for p in mao:
            cv2.circle(frame, (int(p.x * w), int(p.y * h)), 4, (0, 255, 0), -1)
    return frame, result


def mostrar(frame, linhas, cor=(255, 255, 255), grande=None):
    # Espelha só a visualização, os dados ficam como a câmera captura
    tela = cv2.flip(frame, 1)
    for i, texto in enumerate(linhas):
        cv2.putText(tela, texto, (20, 40 + i * 35), cv2.FONT_HERSHEY_SIMPLEX, 0.8, cor, 2)
    if grande:
        cv2.putText(tela, grande, (tela.shape[1] // 2 - 40, tela.shape[0] // 2 + 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 4, (0, 0, 255), 8)
    cv2.imshow('SINALIZA - Coleta de Frases', tela)
    return cv2.waitKey(1) & 0xFF


total = 0
for frase in args.frases:
    pasta = os.path.join('backend', 'dados_frases', frase)
    os.makedirs(pasta, exist_ok=True)
    print(f'\n=== {frase} ===')

    # Espera ESPACO para começar a frase
    while True:
        frame, _ = ler()
        tecla = mostrar(frame, [f'FRASE: {frase}', DICAS[frase],
                                f'{args.repeticoes} gravacoes de {DURACAO_SEGUNDOS:.0f}s',
                                'ESPACO: comecar | Q: sair'], (0, 255, 255))
        if tecla == ord(' '):
            break
        if tecla == ord('q'):
            raise SystemExit(f'\nSaindo. {total} gravacoes salvas.')

    for rep in range(1, args.repeticoes + 1):
        # Contagem regressiva com as mãos em posição de descanso
        fim = time.time() + 2.0
        while time.time() < fim:
            frame, _ = ler()
            restante = int(fim - time.time()) + 1
            if mostrar(frame, [f'{frase} - {rep}/{args.repeticoes}', 'Prepare...'],
                       grande=str(restante)) == ord('q'):
                raise SystemExit(f'\nSaindo. {total} gravacoes salvas.')

        # Grava
        maos, tempos = [], []
        inicio = time.time()
        while time.time() - inicio < DURACAO_SEGUNDOS:
            frame, result = ler()
            maos.append(maos_do_resultado(result))
            tempos.append((time.time() - inicio) * 1000)
            mostrar(frame, [f'GRAVANDO {frase} - {rep}/{args.repeticoes}', DICAS[frase]],
                    (0, 0, 255))

        maos = np.array(maos)
        com_mao = (~np.isnan(maos[:, :, 0])).any(axis=1).mean()
        if com_mao < 0.3 and frase != 'NENHUM':
            print(f'  {rep}: descartada (maos visiveis em so {com_mao:.0%} dos frames)')
            continue
        caminho = os.path.join(pasta, f'{args.nome}_{carimbo}_{rep:02d}.npz')
        np.savez(caminho, maos=maos, tempos=np.array(tempos))
        total += 1
        print(f'  {rep}: ok ({len(maos)} frames, maos em {com_mao:.0%})')

cap.release()
cv2.destroyAllWindows()
print(f'\nColeta finalizada! {total} gravacoes salvas em backend/dados_frases/')
