## BORA Scraper.
##
## Use, assuming PC with Linux, can be adapted for Windows/Mac:
## 1) Install Nim, run `curl https://nim-lang.org/choosenim/init.sh -sSf | sh` and follow installer instructions
## 2) Compile, go to source code folder and run `nim c -d:danger -d:ssl --mm:arc --threads:off borascraper.nim`
## 3) Run `./borascraper nombramiento` or `./borascraper concurso` or any other word to search etc
import std/[httpclient, os, json, re, sequtils, strutils, times]

const url = "https://www.boletinoficial.gob.ar/busquedaAvanzada/realizarBusqueda"

template getMultipartData(search, fechaDesde, fechaHasta: string): MultipartData =
  ## HTTP MultiPart Data, construye params para la API de BORA, retorna MultipartData.
  newMultipartData({"params": """{
    "busquedaRubro":false,"hayMasResultadosBusqueda":true,"ejecutandoLlamadaAsincronicaBusqueda":false,
    "ultimaSeccion":"","filtroPorRubrosSeccion":false,"filtroPorRubroBusqueda":false,"filtroPorSeccionBusqueda":false,
    "busquedaOriginal":true,"ordenamientoSegunda":false,"seccionesOriginales":[1],"ultimoItemExterno":null,
    "ultimoItemInterno":null,"rubros":[],"nroNorma":"","anioNorma":"","denominacion":"","tipoContratacion":"",
    "anioContratacion":"","nroContratacion":"","todasLasPalabras":true,
    "comienzaDenominacion":true,"seccion":[1,2,3],"tipoBusqueda":"Avanzada","numeroPagina":1,"ultimoRubro":"",
    "texto":"""" & search & """","fechaDesde":"""" & fechaDesde & """","fechaHasta":"""" & fechaHasta & """"
  }""", "array_volver": "[]"})  # Esto un formato raro que usa el BORA.

proc main(search: string; fecha = now().format("dd/MM/yyyy")): seq[string] =
  ## Actualiza con data nueva de BORA segun los argumentos, retorna secuencia de strings.
  let
    mltprt = getMultipartData(search, fecha, fecha)
    client = newHttpClient(headers = newHttpHeaders({"dnt": "1", "accept": "application/json"}))
    rekuest = client.postContent(url, multipart = mltprt)
    rawurls = parseJson(rekuest){"content", "html"}.getStr
  result = mapIt(findAll(rawurls, re"""<a href="(?<URL>\S+)\?busqueda=1" onclick="""), it.multiReplace(("<a href=\"", "https://www.boletinoficial.gob.ar"), ("?busqueda=1\" onclick=", "")))
  client.close()

when isMainModule:
  echo main(search = paramStr(1))
