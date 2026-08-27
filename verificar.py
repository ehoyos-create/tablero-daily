# -*- coding: utf-8 -*-
"""Caza llamadas a funciones que no estan declaradas en el archivo.
   `node --check` solo mira sintaxis y no ve esto: una funcion borrada por error
   deja el archivo perfectamente valido y revienta al ejecutar."""
import re,io,sys
s=io.open('index.html',encoding='utf-8').read()
js='\n'.join(re.findall(r'<script>(.*?)</script>',s,flags=re.S))
js=re.sub(r'/\*.*?\*/','',js,flags=re.S)
js=re.sub(r'(?m)^\s*//.*$','',js)

dec=set(re.findall(r'\bfunction\s+([A-Za-z_$][\w$]*)',js))
dec|=set(re.findall(r'\b(?:const|let|var)\s+([A-Za-z_$][\w$]*)',js))
# parametros de funcion y de flecha
for m in re.finditer(r'\bfunction\s*[A-Za-z_$\w]*\s*\(([^)]*)\)',js):
    dec|=set(re.findall(r'[A-Za-z_$][\w$]*',m.group(1)))
for m in re.finditer(r'\(([^()]*)\)\s*=>',js):
    dec|=set(re.findall(r'[A-Za-z_$][\w$]*',m.group(1)))
dec|=set(re.findall(r'([A-Za-z_$][\w$]*)\s*=>',js))
dec|=set(re.findall(r'\bcatch\s*\(\s*([A-Za-z_$][\w$]*)',js))
dec|=set(re.findall(r'\bfor\s*\(\s*(?:const|let|var)\s+([A-Za-z_$][\w$]*)',js))

# Para las llamadas se ignora el contenido de las cadenas: ahi vive el CSS y el
# SVG que se arma como texto, y `rgba(`, `var(` o `:not(` no son funciones.
sin=re.sub(r"'(?:\\.|[^'\\])*'",  "''", js)
sin=re.sub(r'"(?:\\.|[^"\\])*"',  '""', sin)
sin=re.sub(r'`(?:\\.|[^`\\])*`',  '``', sin)
usa=set(re.findall(r'(?<![.\w$])([A-Za-z_$][\w$]*)\s*\(',sin))
PALABRAS={'if','for','while','switch','catch','return','function','typeof','new','await','do','else','of','in','async'}
GLOB={'Math','JSON','Number','String','Array','Object','Boolean','Date','Set','Map','Promise','RegExp',
 'parseInt','parseFloat','isNaN','setTimeout','clearTimeout','setInterval','requestAnimationFrame',
 'cancelAnimationFrame','fetch','addEventListener','document','window','localStorage','scrollTo',
 'getSelection','encodeURIComponent','alert','console','Error','confirm','Promise',
 'prompt','URL','Node','NodeFilter','FileReader','Blob'}
falt=sorted(usa-dec-PALABRAS-GLOB)
if falt:
    print('  ✗ se llama pero no esta declarado:', ', '.join(falt)); sys.exit(1)
print('  ✓ toda funcion que se llama esta declarada')
