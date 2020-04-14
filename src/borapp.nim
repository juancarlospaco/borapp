import webgui, os, strutils, httpclient, json, times, re, sequtils, q, xmltree

const url = "https://www.boletinoficial.gob.ar/busquedaAvanzada/realizarBusqueda"

let client = newHttpClient(headers = newHttpHeaders({"dnt": "1", "accept": "application/json"}))

template getMultipartData(search = ""; todasLasPalabras = true; seccion = 1;
    nroNorma = ""; anioNorma = ""; fecha = now().format("dd/MM/yyyy"); rubros): MultipartData =
  newMultipartData({"params": """{
      "busquedaRubro":false,"hayMasResultadosBusqueda":true,"ejecutandoLlamadaAsincronicaBusqueda":false,
      "ultimaSeccion":"","filtroPorRubrosSeccion":false,"filtroPorRubroBusqueda":false,"filtroPorSeccionBusqueda":false,
      "busquedaOriginal":true,"ordenamientoSegunda":false,"seccionesOriginales":[1],"ultimoItemExterno":null,
      "ultimoItemInterno":null,"texto":"""" & search & """","rubros":[""" & rubros & """],"nroNorma":"""" & nroNorma & """","anioNorma":"""" & anioNorma & """","denominacion":"","tipoContratacion":"",
      "anioContratacion":"","nroContratacion":"","fechaDesde":"""" & fecha & """","fechaHasta":"""" & fecha & """","todasLasPalabras":""" & $todasLasPalabras & """,
      "comienzaDenominacion":true,"seccion":[""" & $seccion & """],"tipoBusqueda":"Avanzada","numeroPagina":1,"ultimoRubro":""
    }""", "array_volver": "[]"})

proc boraUpdate(search = ""; todasLasPalabras = true; seccion = 1;
    nroNorma = ""; anioNorma = ""; fecha = now().format("dd/MM/yyyy"); rubros = ""): seq[string] =
  let
    mltprt = getMultipartData(search, todasLasPalabras, seccion, nroNorma, anioNorma, fecha, rubros)
    bodyUrls = parseJson(client.postContent(url, multipart = mltprt)){"content", "html"}.getStr
    urlsSeq = mapIt(findAll(bodyUrls, re"""<a href="(?<URL>\S+)\?busqueda=1" onclick="""),
      it.replace("<a href=\"", "https://www.boletinoficial.gob.ar").replace("?busqueda=1\" onclick=", ""))
    news = mapIt(urlsSeq, q(client.getContent(it)).select("#detalleAviso"))
  result = mapIt(news, replace($(it[0]), " id=\"cuerpoDetalleAviso\">", " id=\"cuerpoDetalleAviso\"><details>") & "</details><hr>")

template updateUI(news: seq[string]) =
  app.js(app.setText("#output", ""))
  for item in news: app.js(app.addHtml("#output", item))

let app = newWebView(currentHtmlPath(), "Boletin Oficial Republica Argentina", 850, 900)
updateUI(boraUpdate())

proc updateInternal(data: string) =
  let jsn = parseJson(data)
  updateUI(boraUpdate(
    search = jsn["search"].getStr,
    todasLasPalabras = jsn["todasLasPalabras"].getBool,
    seccion = jsn["seccion"].getInt,
    nroNorma = jsn["nroNorma"].getStr,
    anioNorma = jsn["anioNorma"].getStr,
    rubros = jsn["rubros"].getStr))

app.bindProcs("api"):
  proc update(data: string) = updateInternal(data)

app.run()
app.exit()
