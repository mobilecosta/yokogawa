
#Include "TOTVS.CH"

/*/
+---------------------------------------------------------------------------+
| Programa  | IMG05     | Autor | Antonio Nunes           | Data | 05/03/24 |
+-----------+---------------------------------------------------------------+
| Descrição | Rotina para impressão da etiqueta - Rotina ACDV173            |
              CB5SetImp(cImp,.t.) .and. ExistBlock("IMG05")                 |
+-----------+---------------------------------------------------------------+
| Uso       | Yokogawa                                                      |
+---------------------------------------------------------------------------+
/*/ 

User Function IMG05OFI() 
Local nVolumes := PARAMIXB[1]
Local nVolume  := PARAMIXB[2]
Local _cZModel := Alltrim(GetNewPar("YO_MODIMPE","ZDesigner GC420T")) // parametro utilizado para definir a impressora termica. "OS 214"//
Local _cZPorta := "COM1" //"LPT1"
Local cFila := "01"
Local cPathSpool := "\system\spool\"
Local cNome   := ''
Local cCidade := ''
Local cUF     := ''
Local cPedido := ""


nQtdCopias := 1
nVolIniPvt := 1
nVolFimPvt := 1
dbSelectArea("SF2")
//dbSelectArea("SC6")

// //INICIALIZAÇÃO DA IMPRESSAO
MSCBPRINTER(_cZModel, _cZPorta,,,,,,,, cFila,,cPathSpool)
MSCBINFOETI("Etiqueta Volume","Volume [" + CB6->CB6_VOLUME + "/" + AllTrim(nVolume) + "/" + AllTrim(nVolumes) + "]")
MSCBCHKStatus(.F.)
MSCBBEGIN(1,6,200) //Qtde de copias, velocidade (1 a 6) e tamanho da etiqueta em mm
//MSCBBox(02, 03, 98, 98/*78*/, 3)

// CABECALHO DA ETIQUETA

MSCBSAY( 118, 005, AllTrim("YOKOGAWA"),"R","0","072,068")
MSCBLineV(120, 000, 080, 3)
//MSCBLineV(30, 01, 13, 3)
MSCBSAY( 115, 005, "YOKOGAWA America do Sul Ltda","R","0","024,034")
MSCBSAY( 126, 085, AllTrim(SM0->M0_ENDENT),"R","0","024,034")
MSCBSAY( 122, 085, Trans(SM0->M0_CGC, "@R 99.999.999/9999-99"),"R","0","024,034")
MSCBBox(116, 160, 210, 220, 3)
//MSCBBox(120, 118, 220, 150, 3)

MSCBSay(120, 162, "NF: " + CB7->CB7_NOTA, "R", "0", "024, 034")
//MSCBLineH(118, 005, 220, 3)

//DADOS DA NF/PEDIDO
cPedido := POSICIONE('SF2',1,xFilial('SF2')+CB7->CB7_PEDIDO,'F2_EMISSAO') 
MSCBSAY( 110, 140, "Pedido n.: " + AllTrim(CB7->CB7_PEDIDO)   ,"R","0","024,034")     // Numero do Pedido de Vendas
MSCBSAY( 110, 190, "Data : " + AllTrim(SF2->F2_EMISSAO),"R","0","024,034") // Nome do CLiente

MSCBLineV(108, 000, 290, 3)

//NO INTERIOR DA ETIQUETA
cNome := POSICIONE('SA1',1,xFilial('SA1')+CB7->CB7_CLIENT,'A1_NOME')    
MSCBSAY( 090, 005, "Cliente: "      ,"R","0","024,034")
MSCBSAY( 090, 025, cNome            ,"R","0","034,044")
MSCBSAY( 080, 140, "Pedido : "      ,"R","0","024,034")
MSCBSAY( 080, 165, SC5->C5_PEDCLI   ,"R","0","034,044")
MSCBSAY( 070, 005, "Códigos: " + AllTrim(CB9->CB9_PROD)       ,"R","0","024,034")
MSCBSAY( 060, 005, "Quantidade : " + AllTrim(str(CB9->CB9_QTESEP)),"R","0","024,034")

//NO RODAPE DA ETIQUETA
//Dados da NF
//MSCBBox(02, 65, 98, 78, 3)
cCidade := POSICIONE('SA1',1,xFilial('SA1')+SC5->C5_CLIENT,'A1_MUN')    
cUF     := POSICIONE('SA1',1,xFilial('SA1')+SC5->C5_CLIENT,'A1_EST')    
MSCBSay(030, 005, "Cidade Entr: ", "R", "0", "024, 034")
MSCBSay(030, 040, cCidade, "R", "0", "034, 044")
MSCBSay(030, 140, "UF Entrega : ",  "R", "0", "024, 034")
MSCBSay(030, 175, cUF,  "R", "0", "034, 044")
MSCBSay(030, 200, IIF(SC5->C5_TPFRETE=="F", "FOB", "CIF"),  "R", "0", "034, 044")

//MSCBLineH(02, 76, 98, 3)
//MSCBSay(037, 088, cValToChar(SC5->C5_VOLUME1) + " " + Upper(Alltrim(SC5->C5_ESPECI1)), "N", "0", "024, 034")
MSCBSay(010, 005, "Volume: ",  "R", "0", "024, 034")
MSCBSay(010, 025, cValToChar(nVolIniPvt) + "/" + cValToChar(nVolFimPvt),  "R", "0", "034, 044")
MSCBSay(010, 160, "Peso: ",  "R", "0", "024, 034")
MSCBSay(010, 180, str(SF2->F2_PBRUTO),  "R", "0", "034, 044")

MSCBSAY( 005, 180,"Volume [" + CB6->CB6_VOLUME + "/" + AllTrim(nVolume) + "/" + AllTrim(nVolumes) + "]","R","0","014,024")
//MSCBSAY( 125, 200,"Volume [" + CB6->CB6_VOLUME + "/" + AllTrim(nVolume) + "/" + AllTrim(nVolumes) + "]","R","0","014,024")
//MSCBLineH(02, 99, 98, 3)
//20 comprimento x 10 altura.

MSCBEnd()
MSCBClosePrinter()

RETURN .T.
