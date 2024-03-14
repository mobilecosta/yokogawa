
#Include "TOTVS.CH"

/*/
+---------------------------------------------------------------------------+
| Programa  | IMG05     | Autor | Antonio Nunes           | Data | 05/03/24 |
+-----------+---------------------------------------------------------------+
| Descrição | Rotina para impressão da etiqueta - Rotina ACDV166            |
              CB5SetImp(cImp,.t.) .and. ExistBlock("IMG05")                 |
+-----------+---------------------------------------------------------------+
| Uso       | Yokogawa                                                      |
+---------------------------------------------------------------------------+
/*/ 

User Function IMG05() 
Local nVolumes := PARAMIXB[1]
Local nVolume  := PARAMIXB[2]
Local _cZModel := Alltrim(GetNewPar("YO_MODIMPE","ZDesigner GC420T")) // parametro utilizado para definir a impressora termica. "OS 214"//
Local _cZPorta := "COM1" //"LPT1"
Local cFila := "01"
Local cPathSpool := "\system\spool\"

//dbSelectArea("SF2")
//dbSelectArea("SC6")

// CABECALHO DA ETIQUETA
MSCBINFOETI("Etiqueta Volume","Volume [" + CB6->CB6_VOLUME + "/" + AllTrim(nVolume) + "/" + AllTrim(nVolumes) + "]")
MSCBPRINTER(_cZModel, _cZPorta,,,,,,,, cFila,,cPathSpool)
MSCBCHKStatus(.F.)
MSCBBEGIN(1,2)
MSCBSAY( 03, 01, AllTrim(SM0->M0_NOMECOM),"N","D","1,2")
MSCBSAY( 03, 02, AllTrim(SM0->M0_FULNAME),"N","D","1,2")
MSCBSAY( 03, 03, AllTrim(SM0->M0_ENDENT),"N","D","1,2")
MSCBSAY( 03, 04, Trans(SM0->M0_CGC, "@R 99.999.999/9999-99"),"N","D","1,2")

//DADOS DA NF/PEDIDO
MSCBSAY( 03, 01, AllTrim(SC5->C5_NUM),"N","D","1,2")     // Numero do Pedido de Vendas
MSCBSAY( 03, 02, AllTrim(SC5->C5_DTREAL),"N","D","1,2") // Nome do CLiente

//NO INTERIOR DA ETIQUETA
MSCBSAY( 03, 03, AllTrim(SC5->C5_CLIENTE),"N","D","1,2")
MSCBSAY( 03, 04, AllTrim(SC5->C5_PEDCLI),"N","D","1,2")
MSCBSAY( 03, 05, AllTrim(SD2->D2_COD),"N","D","1,2")
MSCBSAY( 03, 06, AllTrim(SD2->D2_QUANT),"N","D","1,2")

//NO RODAPE DA ETIQUETA
/*Cidade de entrega da Nota Fiscal
o UF de entrega da Nota Fiscal
o Tipo de Frete
o Numeração que representa o volume.
? 001/004
? 002/004
? 003/004
? 004/004
20 comprimento x 10 altura.
*/

MSCBEnd()
MSCBClosePrinter()

RETURN .T.
