#Include "TOTVS.CH"

/*/
+---------------------------------------------------------------------------+
| Programa  | IMG01     | Autor | Antonio Nunes           | Data | 08/01/24 |
+-----------+---------------------------------------------------------------+
| Descrição | Rotina para impressão da etiqueta - Rotina ACDV167            |
+-----------+---------------------------------------------------------------+
| Uso       | Yokogawa                                                      |
+---------------------------------------------------------------------------+
/*/ 

User Function IMG01()


Local nVolumes := PARAMIXB[1]
Local nVolume  := PARAMIXB[2]
Local _cZModel := Alltrim(GetNewPar("YO_MODIMPE","ZDesigner GC420T")) // parametro utilizado para definir a impressora termica. "OS 214"//
Local _cZPorta := "COM1" //"LPT1"
Local cFila := "\system\spool\"
Local cPathSpool := "\system\spool\"

//MSCBINFOETI("Etiqueta Volume","Volume [" + CB6->CB6_VOLUME + "/" + AllTrim(Str(nVolume)) + "/" + AllTrim(Str(nVolumes)) + "]")
MSCBINFOETI("Etiqueta Volume","Volume [" + CB6->CB6_VOLUME +"]")

sMSCBPRINTER(_cZModel, _cZPorta,,,,,,,, cFila,,cPathSpool)
MSCBCHKStatus(.F.)

MSCBBEGIN(1,2)

MSCBSAY( 03, 01, AllTrim(SM0->M0_NOMECOM),"N","D","1,2")
MSCBSAY( 03, 02, AllTrim(SM0->M0_FULNAME),"N","D","1,2")
MSCBSAY( 03, 03, AllTrim(SM0->M0_ENDENT),"N","D","1,2")
MSCBSAY( 03, 04, Trans(SM0->M0_CGC, "@R 99.999.999/9999-99"),"N","D","1,2")

MSCBEnd()
MSCBClosePrinter()


RETURN(aRet)

