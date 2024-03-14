
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

// //INICIALIZAÇÃO DA IMPRESSAO
MSCBPRINTER(_cZModel, _cZPorta,,,,,,,, cFila,,cPathSpool)
MSCBINFOETI("Etiqueta Volume","Volume [" + CB6->CB6_VOLUME + "/" + AllTrim(nVolume) + "/" + AllTrim(nVolumes) + "]")
MSCBCHKStatus(.F.)
MSCBBEGIN(1,6,20) //Qtde de copias, velocidade (1 a 6) e tamanho da etiqueta em mm
MSCBBox(02, 03, 98, 78, 3)
// CABECALHO DA ETIQUETA
MSCBSAY( 005, 006, AllTrim(SM0->M0_NOMECOM),"N","0","029,036")
MSCBSAY( 026, 006, AllTrim(SM0->M0_FULNAME),"N","0","043,053", .F.)
MSCBSAY( 005, 013, AllTrim(SM0->M0_ENDENT),"N","0","024,034")
MSCBSAY( 023, 017, Trans(SM0->M0_CGC, "@R 99.999.999/9999-99"),"N","0","024,034")
MSCBLineH(02, 21, 98, 3)

//DADOS DA NF/PEDIDO
MSCBSAY( 005, 022, AllTrim(SC5->C5_NUM),"N","D","1,2")     // Numero do Pedido de Vendas
MSCBSAY( 005, 026, AllTrim(SC5->C5_DTREAL),"N","D","1,2") // Nome do CLiente

//NO INTERIOR DA ETIQUETA
MSCBSAY( 005, 069, AllTrim(SC5->C5_CLIENTE),"N","0","024,034")
MSCBSAY( 005, 069, AllTrim(SC5->C5_PEDCLI),"N","0","024,034")
MSCBSAY( 037, 073, AllTrim(SD2->D2_COD),"N","0","043,053")
MSCBSAY( 005, 073, AllTrim(SD2->D2_QUANT),"N","0","024,034")

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
