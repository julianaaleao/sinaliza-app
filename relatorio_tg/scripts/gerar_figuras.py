"""Gera as figuras do relatório em relatorio_tg/figuras/ (PNG, 300 dpi).
Lê dados e logs existentes; não altera nada do projeto.
Uso: python relatorio_tg/scripts/gerar_figuras.py
"""
import csv, os, re, sys
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

sys.path.insert(0, 'backend/api')
from normalizacao import normalizar_landmarks

SAIDA = 'relatorio_tg/figuras'
os.makedirs(SAIDA, exist_ok=True)
plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 9})
AZUL, CINZA = '#01247A', '#5B6475'


def salvar(nome):
    plt.savefig(os.path.join(SAIDA, nome), dpi=300, bbox_inches='tight', facecolor='white')
    plt.close()
    print('ok', nome)


# ---------- 1. Arquitetura ----------
def caixa(ax, x, y, w, h, titulo, linhas, cor):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle='round,pad=0.02,rounding_size=0.06',
                                fc='white', ec=cor, lw=1.4))
    ax.text(x + w / 2, y + h - 0.13, titulo, ha='center', va='top', weight='bold', color=cor, fontsize=9)
    ax.text(x + w / 2, y + h - 0.38, '\n'.join(linhas), ha='center', va='top', color='#222', fontsize=7.4,
            linespacing=1.35)


def seta(ax, a, b, texto='', cor=CINZA, desloc=(0, 0.1)):
    ax.add_patch(FancyArrowPatch(a, b, arrowstyle='-|>', mutation_scale=11, lw=1.2, color=cor))
    if texto:
        ax.text((a[0] + b[0]) / 2 + desloc[0], (a[1] + b[1]) / 2 + desloc[1], texto, ha='center',
                va='bottom', fontsize=7, color=cor)


fig, ax = plt.subplots(figsize=(10, 4.4))
ax.set_xlim(0, 10); ax.set_ylim(0, 4.4); ax.axis('off')
caixa(ax, 0.05, 2.2, 2.55, 2.1, 'Aplicativo (Flutter)', [
    'Navegador: getUserMedia + Canvas', '(JPEG 320x240)', 'Android: pacote camera',
    '1 frame a cada 200 ms', 'Frases: janela de 5 s', 'Vogais: janela de 1,5 s', 'Respostas em GIF'], AZUL)
caixa(ax, 3.75, 2.2, 2.6, 2.1, 'API (Python + FastAPI)', [
    'OpenCV: decodifica a imagem', 'MediaPipe Hand Landmarker:', '21 pontos (x, y, z) por mão',
    'NumPy: normalização e', 'reamostragem (30 instantes)', 'Hospedagem: Railway (Docker)'], AZUL)
caixa(ax, 7.4, 2.2, 2.55, 2.1, 'Modelos', [
    'Random Forest (scikit-learn):', 'vogais A, E, I, O, U', 'LSTM "OI" (NumPy)',
    'LSTM frases, 2 mãos (NumPy)', '5 frases + NENHUM'], AZUL)
caixa(ax, 0.05, 0.1, 2.55, 1.35, 'Firebase', ['Authentication: login', 'Firestore: histórico', '(uid, letra, data)'],
      '#B45309')
caixa(ax, 6.0, 0.1, 3.95, 1.35, 'Treino (fora do app)', [
    'Coleta: scripts Python e vídeos', 'Vogais: scikit-learn (Python 3.14)',
    'LSTMs: TensorFlow/Keras (Python 3.11)', 'Pesos exportados para .npz'], '#047857')
seta(ax, (2.65, 3.75), (3.7, 3.75), 'HTTP POST' + chr(10) + '(imagens base64)', desloc=(0, 0.08))
seta(ax, (3.7, 2.75), (2.65, 2.75), 'JSON' + chr(10) + '(resultado)', desloc=(0, 0.08))
seta(ax, (6.4, 3.25), (7.35, 3.25))
seta(ax, (8.67, 1.5), (8.67, 2.15), 'pesos .npz', '#047857', (0.45, -0.12))
seta(ax, (1.32, 2.15), (1.32, 1.5), 'histórico', '#B45309', (0.42, -0.12))
salvar('fig01_arquitetura.png')

# ---------- 2. Fluxo do modo Frases ----------
passos = ['Toque em\n"Ler sinal"', 'Contagem\n3, 2, 1', 'Grava 5 s\n(~25 frames)', 'API: MediaPipe\n2 mãos/frame',
          'Normaliza e\nreamostra (30)', 'LSTM frases\n(limiar 70%)', 'Mostra frase e\nrespostas', 'GIF da resposta\nem LIBRAS']
fig, ax = plt.subplots(figsize=(10, 1.9)); ax.axis('off'); ax.set_xlim(0, 8); ax.set_ylim(0, 1.4)
for i, t in enumerate(passos):
    cor = AZUL if i not in (3, 4, 5) else '#047857'
    ax.add_patch(FancyBboxPatch((i + 0.05, 0.3), 0.85, 0.85, boxstyle='round,pad=0.02,rounding_size=0.08',
                                fc='white', ec=cor, lw=1.3))
    ax.text(i + 0.475, 0.725, t, ha='center', va='center', fontsize=7.2)
    if i < len(passos) - 1:
        seta(ax, (i + 0.9, 0.725), (i + 1.05, 0.725))
ax.text(0.05, 0.08, 'Azul: aplicativo   Verde: API', fontsize=7, color=CINZA)
salvar('fig02_fluxo_frases.png')

# ---------- 3. 21 pontos e normalização ----------
LIGACOES = [(0, 1), (1, 2), (2, 3), (3, 4), (0, 5), (5, 6), (6, 7), (7, 8), (5, 9), (9, 10), (10, 11), (11, 12),
            (9, 13), (13, 14), (14, 15), (15, 16), (13, 17), (0, 17), (17, 18), (18, 19), (19, 20)]
d = pd.read_csv('backend/dados.csv')
linha = d[d.letra == 'E'].drop('letra', axis=1).values[10]
bruto = linha.reshape(21, 3)
norm = normalizar_landmarks(linha).reshape(21, 3)
fig, axs = plt.subplots(1, 2, figsize=(8, 3.8))
for ax, p, titulo, lim in [(axs[0], bruto, 'Coordenadas do MediaPipe (fração da imagem)', None),
                           (axs[1], norm, 'Após normalização (pulso na origem, escala 1)', None)]:
    for a, b in LIGACOES:
        ax.plot(p[[a, b], 0], p[[a, b], 1], color=CINZA, lw=1)
    ax.scatter(p[:, 0], p[:, 1], s=18, color=AZUL, zorder=3)
    for i in (0, 4, 8, 12, 16, 20):
        ax.annotate(str(i), (p[i, 0], p[i, 1]), textcoords='offset points', xytext=(4, 3), fontsize=7)
    ax.invert_yaxis(); ax.set_aspect('equal'); ax.set_title(titulo, fontsize=8.5); ax.grid(alpha=0.25)
    if lim:
        ax.set_xlim(-lim, lim); ax.set_ylim(lim * 0.3, -lim)
axs[0].set_xlabel('x'); axs[0].set_ylabel('y'); axs[1].set_xlabel('x normalizado')
fig.suptitle('Vogal "E" (amostra do dados.csv): 21 pontos da mão. 0 = pulso, 4/8/12/16/20 = pontas dos dedos',
             fontsize=8.5)
salvar('fig03_pontos_normalizacao.png')


# ---------- 4. Matrizes de confusão ----------
def matriz(m, rotulos, titulo, nome):
    m = np.array(m)
    pct = m / m.sum(axis=1, keepdims=True) * 100
    fig, ax = plt.subplots(figsize=(0.75 * len(rotulos) + 2, 0.65 * len(rotulos) + 1.6))
    ax.imshow(pct, cmap='Blues', vmin=0, vmax=100)
    for i in range(len(rotulos)):
        for j in range(len(rotulos)):
            ax.text(j, i, f'{m[i, j]}\n({pct[i, j]:.0f}%)'.replace('.', ','), ha='center', va='center', fontsize=6.8,
                    color='white' if pct[i, j] > 55 else '#111')
    ax.set_xticks(range(len(rotulos))); ax.set_xticklabels(rotulos, rotation=30, ha='right', fontsize=7.5)
    ax.set_yticks(range(len(rotulos))); ax.set_yticklabels(rotulos, fontsize=7.5)
    ax.set_xlabel('Previsto'); ax.set_ylabel('Real'); ax.set_title(titulo, fontsize=8.5)
    salvar(nome)


vogais = pd.read_csv('relatorio_tg/medicoes/vogais_matrizes.csv', sep=';')
soma = vogais.groupby('real')[list('AEIOU')].sum().loc[list('AEIOU')].values
matriz(soma, list('AEIOU'), 'Vogais (Random Forest): soma das 3 coletas não vistas', 'fig04_matriz_vogais.png')

texto = open('relatorio_tg/logs/treino_frases.txt', encoding='utf-8').read()
bloco = texto.split('Matriz de confusão')[1].split('\n\n')[0].strip().splitlines()[2:]
m = [[int(v) for v in l.split()[:6]] for l in bloco]
rot = ['Olá tudo bem', 'Qual seu nome', 'Onde banheiro', 'Quanto custa', 'Que horas', 'NENHUM']
matriz(m, rot, 'Frases (LSTM): validação por pessoa não vista, soma das partes', 'fig05_matriz_frases.png')
