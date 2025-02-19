// Programa   : DIGITAL_SMART
// Fecha/Hora : <FECHA>
// Propósito  : Generar JSON FACTURA DIGITAL https://github.com/AdaptaProERP/facturacion_digital_smart/blob/main/JSON_SMART.pdf
// Creado Por : Juan Navas
// Aplicació  : Facturación
// Tabla      : DPDOCCLI

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cTipDoc,cNumero,nOption,lSendMail)
   LOCAL oDocCli,cWhere,oTable,cJsonE:="",cSql,cLine,cIni,cJsonM:="",cJsonP:="",nAt,cJson:="",oTable
   LOCAL aTipDoc:={"FAV","DEB","CRE","GDD","NEN"} // Tipo de documento (factura=1, Nota de dÃ©bito=2, nota de crÃ©dito=3, GuÃ­a de despacho=4, Nota de Entrega = 5) 
   LOCAL nTipDoc:=1
   LOCAL cTipCed:="",cTipMon:="",cTipRif:=""
           
   DEFAULT cCodSuc  :=oDp:cSucursal,;
           cTipDoc  :="FAV",;
           cNumero  :=SQLGETMAX("DPDOCCLI","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_TIPTRA"+GetWhere("=","D")),;
           nOption  :=5,;
           lSendMail:=.T.

   // Empresa
      
   cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
           "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
           "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
           "DOC_TIPTRA"+GetWhere("=","D")


   cTipMon:=[ CASE ]+CRLF+;
            [   WHEN DOC_CODMON]+GetWhere("=","DBC")+[ THEN 1]+CRLF+;
            [   WHEN DOC_CODMON]+GetWhere("=","EBC")+[ THEN 2]+CRLF+;
            [ ELSE 1 ]+CRLF+;
            [ END  ]+CRLF


   /*
   // idtipocedulacliente 	Numérico 	Si 	Cédula =1 Pasaporte=2 RIF=3 
   // https://es.wikipedia.org/wiki/Registro_%C3%9Anico_de_Informaci%C3%B3n_Fiscal
   // C	Comuna o Consejo Comunal
   // E	Extranjero
   // G	Gobierno
   // J	Jurídico
   // P	Pasaporte
   // V	Venezolano	
   */

   cTipRif:=[ CASE ]+CRLF+;
            [   WHEN LEFT(CLI_RIF,1)="V" OR LEFT(CLI_RIF,1)="E" THEN 1]+CRLF+;
            [   WHEN LEFT(CLI_RIF,1)="P"  THEN 2]+CRLF+;
            [   WHEN LEFT(CLI_RIF,1)="C" OR LEFT(CLI_RIF,1)="J" OR LEFT(CLI_RIF,1)="G" THEN 3]+CRLF+;
            [ ELSE 0 ]+CRLF+;
            [ END  ]+CRLF

   // no puede enviar la factura si es 0



   // solo para validaciones
   IF oDp:POR_GN=NIL
      DPDOCCLIIMP(cCodSuc,cTipDoc,NIL,cNumero,.F.)
   ENDIF

   // obtiene los valores    

   cSql:=[ SELECT ]+;
         [ DOC_NUMERO    AS numerointerno,    ]+CRLF+;
         [ "]+oDp:cRifGuion+["    AS rif,     ]+CRLF+;
         [ DOC_NUMERO    AS trackingid,       ]+CRLF+;
         [ DOC_NUMERO    AS numerointerno,    ]+CRLF+;
         [ DOC_FACAFE    AS relacionado  ,    ]+CRLF+;
         [ CLI_NOMBRE    AS nombrecliente,    ]+CRLF+;
         [ ]+LSTR(nTipDoc,1)+[ AS idtipodocumento,]+CRLF+;
         [ CLI_RIF       AS rifcedulacliente, ]+CRLF+;
         [ CLI_EMAIL     AS emailcliente    , ]+CRLF+;
         [ CONCAT(CLI_AREA," ",CLI_TEL1," ",CLI_TEL2," ",CLI_TEL3," ",CLI_TEL4) AS telefonocliente,]+CRLF+;
         [ CONCAT(CLI_DIR1," ",CLI_DIR2," ",CLI_DIR3," ",CLI_DIR4) AS direccioncliente,]+CRLF+;
         [ ]+cTipRif+[   AS idtipocedulacliente,]+CRLF+;
         [ DOC_NETO-DOC_MTOIVA  AS subtotal  ,]+CRLF+; 
         [ DOC_MTOEXE           AS exento    ,]+CRLF+;
         [ ]+LSTR(oDp:POR_GN,19,2)+[ AS tasag     ,]+CRLF+;
         [ ]+LSTR(oDp:BAS_GN,19,2)+[ AS baseg     ,]+CRLF+;
         [ ]+LSTR(oDp:IVA_GN,19,2)+[ AS impuestog ,]+CRLF+;
         [ ]+LSTR(oDp:POR_RD,19,2)+[ AS tasar     ,]+CRLF+;
         [ ]+LSTR(oDp:BAS_RD,19,2)+[ AS baser     ,]+CRLF+;
         [ ]+LSTR(oDp:IVA_RD,19,2)+[ AS impuestor ,]+CRLF+;
         [ ]+LSTR(oDp:POR_S1,19,2)+[ AS tasaa ,]+CRLF+;
         [ ]+LSTR(oDp:BAS_S1,19,2)+[ AS basea ,]+CRLF+;
         [ ]+LSTR(oDp:IVA_S1,19,2)+[ AS impuestoa ,]+CRLF+;
         [ 0.00                  AS tasaigtf    ,]+CRLF+;
         [ 0.00                  AS baseigtf    ,]+CRLF+;
         [ 0.00                  AS impuestoigtf,]+CRLF+;
         [ DOC_NETO              AS total       ,]+CRLF+;
         [ ]+GetWhere("",lSendMail)+[ AS sendmail    ,]+CRLF+;
         [ LEFT(CONCAT(DOC_CODSUC," ",SUC_DESCRI),10)   AS sucursal    ,]+CRLF+;
         [ LEFT(CONCAT(SUC_DIR1," ",SUC_DIR2," ",SUC_DIR3," ",SUC_DIR4),500) AS direccionsucursa , ]+CRLF+;
         [ ]+cTipMon+[          AS tipomoneda  ,]+CRLF+;
         [ DOC_VALCAM           AS tasacambio  ,]+CRLF+;
         [ LEFT(MEM_MEMO,200)   AS observacion ,]+CRLF+;
         [ CONCAT(DOC_FECHA," ",DOC_HORA) AS fecha_emision]+CRLF+;
         [ FROM DPDOCCLI ]+;
         [ INNER JOIN DPCLIENTES    ON DOC_CODIGO=CLI_CODIGO ]+;
         [ LEFT  JOIN DPCLIENTESSUC ON DOC_SUCCLI=SDC_CODIGO ]+;      
         [ LEFT  JOIN DPSUCURSAL    ON DOC_CODSUC=SUC_CODIGO ]+;   
         [ LEFT  JOIN DPMEMO        ON DOC_NUMMEM=MEM_NUMERO AND MEM_ID=DOC_CODSUC ]+;        
         [ WHERE ]+cWhere


   oTable:=OpenTable(cSql,.T.)

   IF oTable:idtipocedulacliente=0
      MsgMemo("idtipocedulacliente Incorrecto","Validar el RIF del Cliente")
      ? "PISTA DE AUDITORIA"
      RETURN .F.
   ENDIF

   cJsonE:=EJECUTAR("TTABLETOJSON",cSql,NIL,",")

   cSql:=[SELECT ]+;
         [ DOC_CONDIC  AS forma,]+CRLF+;
         [ DOC_NETO  AS monto ]+CRLF+;
         [ FROM DPDOCCLI ]+;
         [ WHERE ]+cWhere
    
   cJsonP:=EJECUTAR("TTABLETOJSON",cSql)

   cWhere:="MOV_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
           "MOV_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
           "MOV_DOCUME"+GetWhere("=",cNumero)+" AND "+;
           "MOV_APLORG"+GetWhere("=","V")

   cSql:=[SELECT ]+;
         [ MOV_CODIGO  AS codigo,     ]+CRLF+;
         [ INV_DESCRI  AS descripcion,]+CRLF+;
         [ MEM_DESCRI  AS comentario, ]+CRLF+;
         [ MOV_PRECIO  AS precio,     ]+CRLF+;
         [ MOV_CANTID  AS cantidad,   ]+CRLF+;
         [ MOV_IVA     AS tasa,       ]+CRLF+;
         [ MOV_DESCUE     AS descuento,  ]+CRLF+;
         [ IF(MOV_IVA=0,"true","false") AS exento,]+CRLF+;
         [ MOV_TOTAL   AS monto       ]+CRLF+;
         [ FROM DPMOVINV ]+;
         [ INNER JOIN DPINV  ON MOV_CODIGO=INV_CODIGO ]+;
         [ LEFT  JOIN DPMEMO ON INV_NUMMEM=MEM_NUMERO ]+;
         [ WHERE ]+cWhere
    
  cJsonM:=EJECUTAR("TTABLETOJSON",cSql,10)
  cJson :=EJECUTAR("DPDOCCLIIMPDIGJSON",cJsonE,cJsonM,cJsonP,"cuerpofactura","formasdepago")
  
RETURN cJson
// EOF

