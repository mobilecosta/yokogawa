
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
Local cNome := ''

nQtdCopias := 1
nVolIniPvt := 1
nVolFimPvt := 1
//dbSelectArea("SF2")
//dbSelectArea("SC6")

// //INICIALIZAÇÃO DA IMPRESSAO
MSCBPRINTER(_cZModel, _cZPorta,,,,,,,, cFila,,cPathSpool)
MSCBINFOETI("Etiqueta Volume","Volume [" + CB6->CB6_VOLUME + "/" + AllTrim(nVolume) + "/" + AllTrim(nVolumes) + "]")
MSCBCHKStatus(.F.)
MSCBBEGIN(1,6,20) //Qtde de copias, velocidade (1 a 6) e tamanho da etiqueta em mm
MSCBBox(02, 03, 98, 98/*78*/, 3)

// CABECALHO DA ETIQUETA
MSCBSAY( 005, 006, AllTrim(SM0->M0_NOMECOM),"N","0","029,036")
MSCBSAY( 005, 011, AllTrim(SM0->M0_ENDENT),"N","0","024,034")
MSCBSAY( 005, 016, Trans(SM0->M0_CGC, "@R 99.999.999/9999-99"),"N","0","024,034")
MSCBLineH(02, 020, 98, 3)

//DADOS DA NF/PEDIDO
MSCBSAY( 005, 022, "Pedido n.: " + AllTrim(SC5->C5_NUM)   ,"N","0","024,034")     // Numero do Pedido de Vendas
MSCBSAY( 005, 028, "Data     : " + AllTrim(SC5->C5_DTREAL),"N","0","024,034") // Nome do CLiente
cNome := POSICIONE('SA1',1,xFilial('SA1')+SC5->C5_CLIENTE,'A1_NOME')    

//NO INTERIOR DA ETIQUETA
MSCBSAY( 005, 034, "Cod Cliente: " + AllTrim(cNome)   ,"N","0","024,034")
MSCBSAY( 005, 040, "Pedido Cli : " + AllTrim(SC5->C5_PEDCLI)    ,"N","0","024,034")
MSCBSAY( 005, 046, "Produto    : " + AllTrim(SD2->D2_COD)       ,"N","0","024,034")
MSCBSAY( 005, 052, "Quantidade : " + AllTrim(str(SD2->D2_QUANT)),"N","0","024,034")

//NO RODAPE DA ETIQUETA
//Dados da NF
//MSCBBox(02, 65, 98, 78, 3)
MSCBSay(005, 060, "Cidade Entr: " + SC5->C5_YLOCEMB,                                   "N", "0", "024, 034")
MSCBSay(005, 066, "UF Entrega : " + SC5->C5_YUFEMB,                                    "N", "0", "024, 034")
MSCBSay(005, 072, "Nota Fiscal: " + SC5->C5_NOTA,                                      "N", "0", "024, 034")

MSCBLineH(02, 76, 98, 3)
MSCBSay(005, 078, "Pedido n.: " + Alltrim(SC5->C5_NUM)                               , "N", "0", "024, 034")
//MSCBSay(037, 088, cValToChar(SC5->C5_VOLUME1) + " " + Upper(Alltrim(SC5->C5_ESPECI1)), "N", "0", "024, 034")
MSCBSay(005, 084, "Volume: " + cValToChar(nVolIniPvt) + "/" + cValToChar(nVolFimPvt),  "N", "0", "024, 034")
//MSCBLineH(02, 99, 98, 3)
//20 comprimento x 10 altura.

MSCBEnd()
MSCBClosePrinter()

RETURN .T.
