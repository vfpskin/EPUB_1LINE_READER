# Epub 1line Reader

Lector de libros **TXT y EPUB** que muestra **una sola línea de texto** en una barra delgada pegada al borde superior de la pantalla. Siempre visible, semitransparente y discreta, para leer mientras haces otras cosas.

Hecho con [AutoHotkey](https://www.autohotkey.com/) 1.1 para Windows.

## Características

- Barra de 20 px de alto y ancho de pantalla completa, siempre encima de otras ventanas.
- Al pasar el mouse por encima, la barra se vuelve transparente y deja pasar los clics, para no estorbar.
- Abre archivos **TXT** (UTF-8) y **EPUB**. Los EPUB se convierten automáticamente a TXT, respetando el orden de lectura del libro.
- Recuerda el último archivo y la última línea leída de cada libro.
- Lista de **archivos recientes** (los últimos 10).
- **Búsqueda de texto** con "buscar siguiente".
- **Colores personalizables** de fondo y de letra, que se guardan entre sesiones.
- Las líneas largas se dividen automáticamente (alrededor de 150 caracteres) sin cortar palabras.

## Instalación

1. Descarga `Epub1LineReader.zip` desde la sección [Releases](../../releases).
2. Descomprime la carpeta en un lugar donde puedas escribir (Documentos, Escritorio, etc.). **No** la pongas en `C:\Program Files`.
3. Ejecuta `Epub1LineReader.exe`.

No necesitas instalar AutoHotkey. Funciona en Windows 7 o superior (32 y 64 bits).

## Uso

Al ejecutarlo aparece un ícono en la bandeja del sistema. Haz clic derecho sobre él para ver el menú:

| Opción | Qué hace |
|---|---|
| Abrir archivo | Elige un archivo TXT o EPUB |
| Buscar texto | Busca una palabra o frase en el libro |
| Buscar siguiente (F3) | Salta a la siguiente coincidencia |
| Archivos recientes | Reabre un libro anterior en la línea donde quedaste |
| Colores | Cambia el color de fondo y de letra, o restaura los originales |
| Salir | Guarda la posición y cierra el programa |

### Atajos de teclado

| Tecla | Acción |
|---|---|
| `↓` (Down) | Línea siguiente |
| `↑` (Up) | Línea anterior |
| `F3` | Buscar siguiente |
| `Esc` o `Ctrl+Shift+F12` | Guardar y salir |

> **Nota:** estos atajos son globales, es decir, funcionan en cualquier ventana mientras el programa esté abierto. Esto significa que las flechas, `F3` y `Esc` no llegarán a otras aplicaciones mientras el lector esté en ejecución. Cierra el lector con `Esc` cuando no lo estés usando.

## Archivos que crea el programa

Junto al ejecutable se crean:

- `settings.ini`: último libro, posición de lectura, archivos recientes y colores.
- `TXT\`: carpeta con los EPUB convertidos a texto.

Para empezar de cero, borra `settings.ini`.

## Conversión de EPUB

Un EPUB es un archivo comprimido. El programa lo extrae con [7-Zip](https://www.7-zip.org/) si está instalado, y si no, con la extracción integrada de Windows. Luego lee los capítulos en el orden definido por el propio libro, convierte el HTML a texto plano y guarda el resultado en `TXT\`.

Los EPUB con protección DRM no se pueden convertir.

## Compilar desde el código fuente

1. Instala [AutoHotkey 1.1](https://www.autohotkey.com/).
2. Abre **Ahk2Exe** y completa:
   - Source: `Epub.ahk`
   - Custom Icon: `Epub.ico`
   - Base File: `Unicode 32-bit`
3. Pulsa **Convert**.

También puedes ejecutar `Epub.ahk` directamente con AutoHotkey 1.1 (con `Epub.ico` en la misma carpeta).

## Aviso sobre antivirus

Algunos antivirus marcan como sospechosos los ejecutables creados con AutoHotkey (falso positivo). Todo el código fuente está en este repositorio para que puedas revisarlo y compilarlo tú mismo.

## Licencia

Distribuido bajo la licencia MIT. Consulta el archivo `LICENSE`.

Hecho con [AutoHotkey](https://www.autohotkey.com/).
