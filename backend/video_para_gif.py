import argparse
import os
import shutil
import subprocess
import sys

# Converte o vídeo de uma resposta em LIBRAS para GIF leve, para o app.
# Uso: python backend/video_para_gif.py VIDEO.mp4 assets/respostas/sim_tudo_bem.gif
# Precisa do ffmpeg instalado (winget install ffmpeg).

parser = argparse.ArgumentParser(description='SINALIZA - video para GIF')
parser.add_argument('video')
parser.add_argument('gif')
parser.add_argument('--largura', type=int, default=360, help='largura do GIF em pixels')
parser.add_argument('--fps', type=int, default=12)
parser.add_argument('--inicio', type=float, default=0, help='corta o começo (segundos)')
parser.add_argument('--duracao', type=float, default=0, help='duração máxima (segundos, 0 = tudo)')
args = parser.parse_args()

ffmpeg = shutil.which('ffmpeg')
if not ffmpeg:
    sys.exit('ffmpeg não encontrado. Instale com: winget install ffmpeg')

corte = ['-ss', str(args.inicio)] + (['-t', str(args.duracao)] if args.duracao else [])
filtro = (f'fps={args.fps},scale={args.largura}:-1:flags=lanczos,'
          'split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer')

os.makedirs(os.path.dirname(os.path.abspath(args.gif)), exist_ok=True)
subprocess.run([ffmpeg, '-y', '-loglevel', 'error', *corte, '-i', args.video,
                '-vf', filtro, '-loop', '0', args.gif], check=True)
print(f'GIF salvo em {args.gif} ({os.path.getsize(args.gif) / 1024:.0f} KB)')
