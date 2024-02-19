#INCLUDE 'RWMAKE.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOPCONN.CH'
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º Programa ³ YOPCPR04 º Autor ³ Anderson Messias   º Data ³  23/02/2010 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescri‡„o ³ Imprime etiquetas de codigo de barras Zebra TLP 2844       º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ YOKOGAWA                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function YOPCPR04()

SetPrvt("CPERG,NRESP,CPORTA,CPADRAO,MV_PAR06")
SetPrvt("CARQ,NHDLARQ,I,CPRECO,CCOD,CLINHA1")
SetPrvt("CLINHA2,CLINHA3,CLINHA4,_SALIAS,AREGS,J")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Montagem da tela                                                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Private cEtiq_OP  := Space(TamSx3("PX1_OP")[1]-2)
Private nEtiq_Qtd := 1
Private nEtiq_Vol := 1
Private nEtiq_Cop := 1
Private cEnderc   := Space(TamSx3("BE_LOCALIZ")[1])
Private nTamObs	:= 60
//-----Foi desabilitado as Etiquetas de Produçao e DEVEST conforme chamado IR851 do Celso Fukuda----//
Private aRadio := {/*"Etiqueta de Producao","Etiqueta DEVEST",*/"Etiqueta Beneficiamento","Etiqueta GC420t","Etiqueta S4M"}
Private nRadio := 2
Private oRadio := Nil

@ 210,1 TO 500,400 DIALOG oDlgEtiq TITLE OemToAnsi("Impress„o de Etiquetas de C¢digo de Barras")
@ 02,05 TO 120,190 OF oDlgEtiq PIXEL

@ 07,10 Say " Este programa imprimi etiquetas de código de barras da" OF oDlgEtiq PIXEL
@ 14,10 Say " impressora ARGOX OS 314, ZEBRA S4M ou GC420t de acordo" OF oDlgEtiq PIXEL
@ 21,10 Say " com os parâmetros definidos pelo usuário.             " OF oDlgEtiq PIXEL

@ 30,10 TO 88,185 TITLE "Selecione a etiqueta desejada"
@ 39,15 RADIO oRadio VAR nRadio 3D SIZE 120,20 PROMPT /*"Etiqueta de Producao","Etiqueta DEVEST",*/"Etiqueta Beneficiamento","Etiqueta (GC420t)","Etiqueta S4M" OF oDlgEtiq PIXEL
oRadio:bChange 	:= {|| oDlgEtiq:Refresh() }

@ 93,10 SAY "O.Produção : " OF oDlgEtiq  PIXEL Color CLR_BLACK,CLR_WHITE PIXEL
@ 93,45 MSGET oEtiq_OP VAR cEtiq_OP F3 "SC2" SIZE 45,07 OF oDlgEtiq PIXEL Valid iif(!Empty(cEtiq_OP),existcpo("SC2",cEtiq_OP,,,,.F.),.T.) .And. PreenEnder(cEtiq_OP)

@ 93,95 SAY "Qtde : " OF oDlgEtiq PIXEL Color CLR_BLACK,CLR_WHITE PIXEL
@ 93,110 MSGET oEtiq_Qtd VAR nEtiq_Qtd SIZE 20,07 PICTURE "@E 9999" OF oDlgEtiq PIXEL WHEN (nRadio==2 .Or. nRadio==3)

@ 93,135 SAY "Volumes : " OF oDlgEtiq PIXEL Color CLR_BLACK,CLR_WHITE PIXEL
@ 93,160 MSGET oEtiq_Vol VAR nEtiq_Vol SIZE 20,07 PICTURE "@E 999" OF oDlgEtiq PIXEL WHEN (nRadio==2 .Or. nRadio==3)

@ 106,10 SAY "Copias : " OF oDlgEtiq PIXEL Color CLR_BLACK,CLR_WHITE PIXEL
@ 106,45 MSGET oEtiq_Cop VAR nEtiq_Cop SIZE 20,07 PICTURE "@E 9999" OF oDlgEtiq PIXEL WHEN (nRadio==1 .Or. nRadio==2 .Or. nRadio==3)

@ 106,84 SAY "Endereço : " OF oDlgEtiq PIXEL Color CLR_BLACK,CLR_WHITE PIXEL
@ 106,110 MSGET oEnderc VAR cEnderc F3 "SBE" SIZE 50,07 OF oDlgEtiq PIXEL Valid iif(!Empty(cEnderc),existcpo("SBE",cEnderc,,,,.F.),.T.) WHEN (nRadio==2)

nOpc := 0
@ 125,125 BMPBUTTON TYPE 01 ACTION (iif(existcpo("SC2",cEtiq_OP,,,,.F.),ArgoxImp(),))
@ 125,153 BMPBUTTON TYPE 02 ACTION (oDlgEtiq:End())

SetKey( VK_F9 , {|| u_YOPCPR4A() } )

oEtiq_OP:SetFocus()
Activate Dialog oDlgEtiq Centered

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º Programa ³ ArgoxImp º Autor ³ Anderson Messias   º Data ³  26/02/2010 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescri‡„o ³ Imprime etiquetas de codigo de barras Argox OS 314         º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ YOKOGAWA                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ArgoxImp()
/* // Desabilitado por solicitação do Celso Fukuda
if nRadio == 1
	RptStatus({|| ArgoxEtq() })
Elseif nRadio == 2
	RptStatus({|| ArgoxDev() })
Else
*/
if nRadio == 1
	RptStatus({|| ImpBenef() })
Elseif nRadio == 2
	RptStatus({|| S4MGC420T() })
Else
	RptStatus({|| S4MZEBRA() })
Endif

cEtiq_OP  := Space(11)
oEtiq_OP:SetFocus()
oDlgEtiq:Refresh()


Return(nil)

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±º Programa ³ ArgoxEtq ³ Autor ³ Anderson Messias      ³ Data ³26/02/2010³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Imprime n etiquetas de codigo de barras conforme solicitado³±±
±±³          ³ nos parametros.                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ArgoxEtq()
LOCAL _cZModel,_cZPorta, cPorta, cPadrao
Local _nVelcImp := If(Alltrim(GetNewPar("YO_MODIMPR","OS 314"))=="OS 314",2,4)
Local nI := 1
Local nX := 1

cPadrao := "?3"
cPadrao := Chr(27) + cPadrao + Chr(27) + "A41" + Chr(27)
_cZModel := Alltrim(GetNewPar("YO_MODIMPR","OS 314")) // parametro utilizado para definir a impressora termica.
_cZPorta := "LPT1"

DBSelectArea("SC2")
DBSetOrder(1)
DBSeek(xFilial("SC2")+cEtiq_OP)

DBSelectArea("SB1")
DBSetOrder(1)
DBSeek(xFilial("SB1")+SC2->C2_PRODUTO)

if !Empty(SC2->C2_PEDIDO)
	DBSelectArea("SC5")
	DBSetOrder(1)
	DBSeek(xFilial("SC5")+SC2->C2_PEDIDO)
	cNReduz := Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+C5_LOJACLI,"A1_NREDUZ")
else
	cNReduz := ""
endif

nNumEtiq := 2

MSCBPRINTER(_cZModel,_cZPorta,,)
MSCBCHKStatus(.F.)

for nX := 1 to nEtiq_Cop
	
	nVol := 0
	For nI := 1 to nEtiq_Vol
		
		MSCBBEGIN(1,_nVelcImp)
		//MSCBBOX(   03, 02, 99, 46, 3) // MSCBBOX(x1, y1, x2, y2)
		
		nVol++
		If _cZModel == "OS 314"
			MSCBSAYBAR(03, 32, SC2->C2_PRODUTO,"N","E",8.5,.F.,.F.,.F.,,4,3,,.F.,.F.,.F.)
			MSCBSAY(   03, 28, SC2->C2_PRODUTO,"N","3","2,1")
			MSCBSAY(   55, 35, "N.OP - "+DTOC(dDataBase),"N","2","1,1")
			MSCBSAY(   55, 31, SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN,"N","1","2,2")
			MSCBSAY(   03, 23, PADR(SB1->B1_DESC,50),"N","1","2,2")
			MSCBSAY(   03, 16, "CLIENTE : "+cNReduz,"N","2","2,2")
			MSCBSAY(   03, 10, "P.V : "+SC2->C2_PEDIDO,"N","1","2,2")
			MSCBSAY(   45, 12, "QTDE : "+Alltrim(str(nEtiq_Qtd))+" "+SB1->B1_UM,"N","1","2,2")
			MSCBSAY(   45, 08, "VOLUMES "+alltrim(str(nVol))+" / "+alltrim(str(nEtiq_Vol)),"N","1","2,2")
			MSCBSAY(   03, 03, "YOKOGAWA AMERICA DO SUL","N","2","1,2")
			MSCBSAY(   45, 05, "Prca Acapulco, 31 - Sao Paulo","N","1","1,1")
			MSCBSAY(   45, 03, "CNPJ : 53.761.607/0001-50","N","1","1,1")
		Else
			MSCBSAYBAR(04, 05, SC2->C2_PRODUTO,"N","C",13,.F.,.F.,.F.,,3,2,,.F.,.F.,.F.)
			MSCBSAY(   04, 19, SC2->C2_PRODUTO,"N","G","0,4")
			MSCBSAY(   105,05, "N.OP - "+DTOC(dDataBase),"N","0","35")
			MSCBSAY(   105,11, SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN,"N","0","55")
			MSCBSAY(   04, 28, SubStr(Alltrim(SB1->B1_DESC),1,50),"N","0","35,0")
			MSCBSAY(   04, 33, SubStr(Alltrim(SB1->B1_DESC),51,50),"N","0","35,0")
			MSCBSAY(   04, 41, SubStr(Alltrim(SB1->B1_CODJAP),1,50),"N","0","35,0")
			MSCBSAY(   04, 46, SubStr(Alltrim(SB1->B1_CODJAP),51,50),"N","0","35,0")
			MSCBSAY(   04, 54, cNReduz,"N","0","55") //FOI RETIRADO O CLIENTE POR SOLICITACAO DO ROBSON
			MSCBSAY(   95, 54, "P.V : "+SC2->C2_PEDIDO,"N","0","50,0")
			MSCBSAY(   95, 66, "QTDE : "+Alltrim(str(nEtiq_Qtd))+" "+SB1->B1_UM,"N","0","50,0")
			MSCBSAY(   95, 74, "VOL. : "+alltrim(str(nVol))+" / "+alltrim(str(nEtiq_Vol)),"N","0","50,0")
			MSCBSAY(   04, 68, "YOKOGAWA AMERICA DO SUL","N","0","35,0")
			MSCBSAY(   04, 74, "Praca Acapulco, 31 - Sao Paulo","N","D","1,0")
			MSCBSAY(   04, 78, "CNPJ : 53.761.607/0001-50","N","D","1,0")
		Endif
		MSCBEnd()
		MSCBClosePrinter()
		
	Next
	
Next

#IFDEF WINDOWS
	Set Device To Screen
	Set Printer To
#ENDIF

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±º Programa ³ ArgoxDev ³ Autor ³ Anderson Messias      ³ Data ³26/02/2010³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Imprime n etiquetas de codigo de barras conforme solicitado³±±
±±³          ³ nos parametros.                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ArgoxDev()
LOCAL _cZModel,_cZPorta, cPorta, cPadrao
Local _nVelcImp := If(Alltrim(GetNewPar("YO_MODIMPR","OS 314"))=="OS 314",2,4)
Local nX := 1

cPadrao := "?3"
cPadrao := Chr(27) + cPadrao + Chr(27) + "A41" + Chr(27)
_cZModel := Alltrim(GetNewPar("YO_MODIMPR","OS 314")) // parametro utilizado para definir a impressora termica.
_cZPorta := "LPT1"

DBSelectArea("SC2")
DBSetOrder(1)
DBSeek(xFilial("SC2")+cEtiq_OP)

//Query Alterada "AND D3_CF = 'RE7'", para atender o chamado 24451 - Diego Fernandes
//Substituido o filtro AND D3_CF = 'RE7' para D3_ESTORNO <> 'S' porque o sistema precisa considerar o que e DE7, so os estornos nao podem ser considerados
cQuery := "SELECT * FROM SD3010 WHERE D_E_L_E_T_='' AND D3_YOPDESM='"+cEtiq_OP+"' AND D3_YDEVEST='S' AND D3_ESTORNO <> 'S'"
// Monta Query
If Select("TDES") > 0
	DbSelectArea("TDES")
	DbCloseArea()
Endif
TCQUERY cQuery NEW ALIAS "TDES"
dbSelectArea("TDES")
TDES->(dbGotop())

MSCBPRINTER(_cZModel,_cZPorta,,)
MSCBCHKStatus(.F.)

While !TDES->(Eof())
	
	DBSelectArea("SB1")
	DBSetOrder(1)
	DBSeek(xFilial("SB1")+TDES->D3_COD)
	
	nEtiq_Cop := Round(TDES->D3_QUANT,0)
	if nEtiq_Cop <= 0
		nEtiq_Cop := 1
	endif
	
	for nX := 1 to nEtiq_Cop
		MSCBBEGIN(1,_nVelcImp)
		//MSCBBOX(   03, 02, 99, 46, 3) // MSCBBOX(x1, y1, x2, y2)
		
		If _cZModel == "OS 314"
			MSCBSAYBAR(03, 32, TDES->D3_COD,"N","E",8.5,.F.,.F.,.F.,,4,3,,.F.,.F.,.F.)
			MSCBSAY(   03, 28, TDES->D3_COD,"N","3","2,1")
			MSCBSAY(   55, 35, "N.OP - "+DTOC(dDataBase),"N","2","1,1")
			MSCBSAY(   55, 31, SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN,"N","1","2,2")
			MSCBSAY(   03, 23, Substr(SB1->B1_DESC,1,35),"N","3","1,1")
			MSCBSAY(   03, 18, Substr(SB1->B1_DESC,36,35),"N","3","1,1")
			MSCBSAY(   03, 12, Substr(SB1->B1_DESC,76,35),"N","3","1,1")
			MSCBSAY(   30, 08, "QTDE : 1 "+SB1->B1_UM,"N","1","2,2")
			//MSCBSAY(   40, 08, "VOLUMES "+alltrim(str(nVol))+" / "+alltrim(str(nEtiq_Vol)),"N","1","2,2")
		Else
			MSCBSAYBAR(03, 05, TDES->D3_COD,"N","C",16,.F.,.F.,.F.,,3,2,,.F.,.F.,.F.)
			MSCBSAY(   03, 22, TDES->D3_COD,"N","G","0,5")
			MSCBSAY(  105, 07, "N.OP - "+DTOC(dDataBase),"N","0","35")
			MSCBSAY(  105, 15, SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN,"N","0","35")
			MSCBSAY(   03, 33, IIf(Empty(Alltrim(SB1->B1_CODJAP)),Substr(SB1->B1_DESC,1,35) ,Substr(SB1->B1_CODJAP,1,35)),"N","0","35")
			MSCBSAY(   03, 43, IIf(Empty(Alltrim(SB1->B1_CODJAP)),Substr(SB1->B1_DESC,36,35),Substr(SB1->B1_CODJAP,36,35)),"N","0","35")
			MSCBSAY(   03, 53, IIf(Empty(Alltrim(SB1->B1_CODJAP)),Substr(SB1->B1_DESC,76,35),Substr(SB1->B1_CODJAP,76,35)),"N","0","35")
			MSCBSAY(   60, 73, "QTDE : 1 "+SB1->B1_UM,"N","0","35")
		Endif
		//MSCBLineH( 04, 36, 98 )       // MSCBLineH( x1, y1, x2)
		MSCBEnd()
		MSCBClosePrinter()
	Next
	
	TDES->(DBSkip())
	
EndDo

#IFDEF WINDOWS
	Set Device To Screen
	Set Printer To
#ENDIF

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ YOPCPA11 ºAutor  ³ Anderson Messias   º Data ³  17/03/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Altera Horario Limite de Trabalho ( Apontamentos )         º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ YOKOGAWA                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function YOPCPR4A()

Local aParams := {}
Local aRetPar := {}
Local cClientes:= PADR(GetMV("MV_YSELBEN"),80)//alltrim(SuperGetMV("MV_YLIMAPO",,"18:00"))
AADD(aParams,{1,"Fornecedor Selo",cClientes,"","","","",80,.T.})

OldMV_PAR01 := MV_PAR01

If ParamBox(aParams,"Config Forn. de Selo",@aRetPar)
	cClientes := aRetPar[1]
	PutMv("MV_YSELBEN",cClientes)
Endif

MV_PAR01 := OldMV_PAR01

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ IMPRESS  ³ Autor ³ Atilio Amarilla       ³ Data ³27/06/07  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ IMPRESSAO DA ETIQUETA                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Especifico para Clientes Microsiga. Vidrotec               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ImpBenef()

LOCAL oFont08
LOCAL oFont10
LOCAL oFont14
LOCAL i := 0
LOCAL oBrush    
Local nI := 1

Private nQuebra	:= 2200

oPrint:= TMSPrinter():New("Etiqueta de Beneficiamento")   
//oPrint:Setup() 
oPrint:SetPortrait()
oPrint:StartPage()
lIniPrn := .T.

oFont08 := TFont():New("TIMES NEW ROMAN",9,08,.T.,.F.,5,.T.,5,.T.,.F.)
oFont10 := TFont():New("TIMES NEW ROMAN",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
oFont12 := TFont():New("TIMES NEW ROMAN",9,12,.T.,.T.,5,.T.,5,.T.,.F.)
oFont14 := TFont():New("TIMES NEW ROMAN",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
oFont20 := TFont():New("TIMES NEW ROMAN",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
oFont36n:= TFont():New("TIMES NEW ROMAN",9,36,.T.,.F.,5,.T.,5,.T.,.F.)

oBrush := TBrush():New("",4)

DBSelectArea("SD4")
DBSetOrder(2)
if DBSeek(xFilial("SD4")+cEtiq_OP)
	
	lImpr := .T.
	nRow  := 20
	While !SD4->(Eof()) .AND. Substr(SD4->D4_OP,1,11) == cEtiq_OP
		lPv1  := .F.
		lPv2  := .F. 		
		//Verifica qual PV será impresso
		If !Empty(SD4->D4_YPEDBEN) .And. Empty(SD4->D4_YPEDBE2)
			lPv1  := .T.
		ElseIf !Empty(SD4->D4_YPEDBE2)
			lPv2  := .T.
		Endif
		
		//Pedido de Beneficiamento 
		If lPv1 .Or. lPv2
			
			if lImpr
				oPrint:StartPage()   // Inicia uma nova página
				nRow := 0
				lImpr := .F.
			endif
			
			If lPv1
				cNReduz := Posicione("SA2",1,xFilial("SA2")+SD4->D4_YFORNEC+SD4->D4_YLOJA,"A2_NREDUZ")
			Else
				cNReduz := Posicione("SA2",1,xFilial("SA2")+SD4->D4_YFORNE2+SD4->D4_YLOJA2,"A2_NREDUZ")
			Endif
			oPrint:Say  (nRow+=030,0050,cNReduz,oFont36n )
			oPrint:SayBitmap(nRow,1750,"yokoazul.bmp",500,120)
			nRow+=160
			oPrint:Line (nRow,0050	,nRow+=1,2300 )
			nRowC := nRow
			oPrint:Say  (nRow+=050	,0070,"PED. COM." ,oFont20 )
			If lPv1
				oPrint:Say  (nRow		,0555,SD4->D4_YPEDCOM ,oFont20 )
			Else
				oPrint:Say  (nRow		,0555,SD4->D4_YPEDCO2 ,oFont20 )			
			Endif
			oPrint:Say  (nRow		,1055,"PED. BEN." ,oFont20 )
			If lPv1
				oPrint:Say  (nRow		,1555,SD4->D4_YPEDBEN ,oFont20 )
			Else
				oPrint:Say  (nRow		,1555,SD4->D4_YPEDBE2 ,oFont20 )
			Endif
			nRow+=100
			oPrint:Line (nRow,0050	,nRow+=1,2300 )
			oPrint:Line (nRow,0050	,nRowC,0050 )
			oPrint:Line (nRow,0550	,nRowC,0550 )
			oPrint:Line (nRow,0550	,nRowC,0550 )
			oPrint:Line (nRow,1050	,nRowC,1050 )
			oPrint:Line (nRow,1550	,nRowC,1550 )
			oPrint:Line (nRow,2300	,nRowC,2300 )
			nRowC := nRow
			_cCodJap := Alltrim(GETADVFVAL("SB1","B1_CODJAP",xFilial("SB1")+SD4->D4_COD,1," "))
			cDesc := IIf(!Empty(_cCodJap),Posicione("SB1",1,xFilial("SB1")+SD4->D4_COD,"B1_CODJAP"),Posicione("SB1",1,xFilial("SB1")+SD4->D4_COD,"B1_DESC"))
			oPrint:Say  (nRow+=50	,0070,cDesc,oFont20 )
			nRow+=100
			oPrint:Line (nRow,0050	,nRowC,0050 )
			oPrint:Line (nRow,2300	,nRowC,2300 )
			oPrint:Line (nRow,0050	,nRow+=1,2300 )
			nRowC := nRow
			oPrint:Say  (nRow+=050	,0070,"O.P."   ,oFont20 )
			oPrint:Say  (nRow		,0555,SD4->D4_OP ,oFont20 )
			oPrint:Say  (nRow		,1055,"PRODUTO" ,oFont20 )
			oPrint:Say  (nRow		,1555,SD4->D4_COD,oFont20 )
			DBSelectArea("SC7")
			DBSetOrder(1)
			//Modificado em 13/09/2010 para considerar pedido+item na busca do selo - Anderson Messias
			//if DBSeek(xFilial("SC7")+SD4->D4_YPEDCOM/*+"/"+SD4->D4_YPEDITE*/)
			If lPv1
				_cC7Seek := xFilial("SC7")+SD4->D4_YPEDCOM+SD4->D4_YPEDITE
			Else
				_cC7Seek := xFilial("SC7")+SD4->D4_YPEDCO2+SD4->D4_YPEDIT2
			Endif
			
			If SC7->(dbSeek(_cC7Seek))
				cSelo := SC7->C7_PRODUTO
				/*
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Solicitado pelo Celso para descrever o tipo de serviço que³
				//³o fornecedor terá que realizar                            ³
				//³Chamado 32491 - Ivandro Santos - 24/07/2013               ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				*/
				aUM := GetAdvFVal("SB1",{"B1_TIPO","B1_DESC"},xFilial("SB1")+SC7->C7_PRODUTO, 1 )
				If Alltrim(aUM[1]) == "MO"
					cDescS := Alltrim(aUM[2])
				Else
					cCodObs := Posicione("SB1",1,xFilial("SB1")+SC7->C7_PRODUTO,"B1_XOBS")
					cObs := cCodObs //MSMM(cCodObs,,,,3,,,"SB1","B1_CODOBS") //Retirado porque o campo B1_CODOBS esta sendo modificado conforme alterar a descricao dos itens na Invoice, devido a ter chego no numero maximo de codigos possiveis ZZZZZZ.
					cDescS:= cObs //SC7->C7_OBS
				End If
			Else
				cSelo := ""
				cDescS:= ""
			Endif
			
			nRow+=100
			oPrint:Line (nRow,0050	,nRow+=1,2300 )
			oPrint:Line (nRow,0050	,nRowC,0050 )
			oPrint:Line (nRow,0550	,nRowC,0550 )
			oPrint:Line (nRow,0550	,nRowC,0550 )
			oPrint:Line (nRow,1050	,nRowC,1050 )
			oPrint:Line (nRow,1550	,nRowC,1550 )
			oPrint:Line (nRow,2300	,nRowC,2300 )
			nRowC := nRow
			oPrint:Say  (nRow+=050	,0070,"N. SERIE" ,oFont20 )
			oPrint:Say  (nRow		,0555,"" ,oFont20 )
			nRow+=100
			oPrint:Line (nRow,0050	,nRow+=1,2300 )
			oPrint:Line (nRow,0050	,nRowC,0050 )
			oPrint:Line (nRow,0550	,nRowC,0550 )
			oPrint:Line (nRow,2300	,nRowC,2300 )
			nRowC := nRow
			oPrint:Say  (nRow+=050	,0070,"Observação"   ,oFont20 )
			//Fazendo quebra inteligente da Observção
			cTag := cDescS
			cTag := StrTran(cTag,Chr(12),"")
			cTag := StrTran(cTag,Chr(13),"!@#  ")
			cTag := StrTran(cTag,Chr(10),"")
			nPass := 0
			aTag := {}
			While .T.
				if Len(Alltrim(cTag)) == 0
					exit
				endif
				//Se achar quebra do CHR(13)
				nPos := AT("!@# ",cTag)
				if nPos > 0
					if nPos == 1
						cLinha := ""
						cTag := Substr(cTag,nPos+5)
						Loop
					endif
					cLinha := Substr(cTag,1,nPos-1)
					if len(cLinha)>nTamObs
						cLinha := Substr(cTag,1,nTamObs-1)
						nPos := RAT(" ",cLinha)
						if nPos>0
							cLinha := Substr(cTag,1,nPos-1)
							cTag := Substr(cTag,nPos+1)
						else
							cLinha := Substr(cTag,1,nTamObs-1)
							cTag := Substr(cTag,nTamObs+1)
						endif
					else
						cLinha := Substr(cTag,1,nPos-1)
						cTag := Substr(cTag,nPos+5)
					endif
				else
					//Se nao achar quebra do CHR(13)
					cLinha := Substr(cTag,1,nTamObs-1)
					if Len(cLinha)>=(nTamObs-1)
						nPos := RAT(" ",cLinha)
						if nPos>0
							cLinha := Substr(cTag,1,nPos-1)
							cTag := Substr(cTag,nPos+1)
						else
							cLinha := Substr(cTag,1,nTamObs-1)
							cTag := Substr(cTag,nTamObs+1)
						endif
					else
						cLinha := cTag
						cTag := ""
					endif
				endif
				
				if len(cLinha)>0
					Aadd(aTag,cLinha)
					//nTam += nTamObs-1
				endif
				
				//Colocando um Limitador para o while não ficar prezo
				nPass++
				if nPass > 100
					exit
				endif
			EndDo
			
			If lPv1
				If Alltrim(SD4->D4_YFORNEC) $ GetMV("MV_YSELBEN")
					For nI := 1 to len(aTag)+1
						if nI == 1
							oPrint:Say  (nRow,0555,cSelo ,oFont14 )
						else
							oPrint:Say  (iif(nI==1,nRow,nRow+=50),0555,aTag[nI-1] ,oFont14 )
						endif
					Next
				Endif
			Else
				If Alltrim(SD4->D4_YFORNE2) $ GetMV("MV_YSELBEN")
					For nI := 1 to len(aTag)+1
						if nI == 1
							oPrint:Say  (nRow,0555,cSelo ,oFont14 )
						else
							oPrint:Say  (iif(nI==1,nRow,nRow+=50),0555,aTag[nI-1] ,oFont14 )
						endif
					Next
				Endif			
			Endif
			
			nRow+=100
			oPrint:Line (nRow,0050	,nRow+=1,2300 )
			oPrint:Line (nRow,0050	,nRowC,0050 )
			oPrint:Line (nRow,0550	,nRowC,0550 )
			oPrint:Line (nRow,2300	,nRowC,2300 )
			nRow+=100
			oPrint:Line (nRow,0010	,nRow+=1,2350 )
			nRow+=100
			
		endif
		
		if nRow >= nQuebra
			oPrint:EndPage() // Finaliza a página
			lImpr := .T.
		endif
		
		SD4->(DBSkip())
	enddo
	
	oPrint:EndPage() // Finaliza a página
	//oPrint:Preview() // Visualiza antes de imprimir
	
	oPrint:Print( , nEtiq_Cop )    
	
endif


Return Nil

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±º Programa ³ S4MGC420T ³ Autor ³ Marcio Gois           ³ Data ³21/02/2014³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Imprime n etiquetas de codigo de barras conforme solicitado³±±
±±³          ³ nos parametros.                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Static Function S4MGC420T()
Local _cZModel,_cZPorta, cPorta, cPadrao
Local _nVelcImp := 4
Local cTag 		:= ""
Local cRange 	:= ""
Local lCopias 	:= .T.
Local cNumSerie := ""  
Local _cSequenc := ""    
Local _cPedVen	:= ""  
Local _cItmPed	:= ""  
Local nI 		:= 1
Local nX 		:= 1

cPadrao := "?3"
cPadrao := Chr(27) + cPadrao + Chr(27) + "A41" + Chr(27)
//_cZModel := "SM4" // parametro utilizado para definir a impressora termica.
_cZModel := "GK420 T"
_cZPorta := "LPT2"

DBSelectArea("SC2")
DBSetOrder(1)
DBSeek(xFilial("SC2")+cEtiq_OP)

If !Empty(SC2->C2_DTPAG)
	If !MSGYESNO("Já foi impresso a Etiqueta (GC420t) para OP "+Alltrim(cEtiq_OP)+". Deseja Imprimi-la novamente?","Atenção")
		Return
	Endif
Endif

DBSelectArea("SB1")
DBSetOrder(1)
DBSeek(xFilial("SB1")+SC2->C2_PRODUTO)    

DBSelectArea("SH6")
DBSetOrder(1)
DBSeek(xFilial("SH6")+cEtiq_OP)

DBSelectArea("SBF")
DBSetOrder(2)
DBSeek(xFilial("SBF")+SC2->C2_PRODUTO+SH6->(H6_LOCAL+H6_LOTECTL)) //BF_FILIAL, BF_PRODUTO, BF_LOCAL, BF_LOTECTL, BF_NUMLOTE, BF_PRIOR, BF_LOCALIZ, BF_NUMSERI, R_E_C_N_O_, D_E_L_E_T_

//Verifica a sequencia para buscar a serie pois o pedido fica preenchido apenas na OP Pai
If SC2->C2_SEQPAI == "000" .Or. Empty(SC2->C2_SEQPAI)
	_cSequenc := SC2->C2_SEQUEN 
Else
	_cSequenc := SC2->C2_SEQPAI
Endif

//Carrega o pedido e item
_cPedVen := GetAdvFVal("SC2","C2_PEDIDO",xFilial("SC2")+SC2->C2_NUM+SC2->C2_ITEM+_cSequenc,1)
_cItmPed := GetAdvFVal("SC2","C2_ITEMPV",xFilial("SC2")+SC2->C2_NUM+SC2->C2_ITEM+_cSequenc,1)

If !Empty(_cPedVen)
	DBSelectArea("SC5")
	DBSetOrder(1)
	DBSeek(xFilial("SC5")+_cPedVen)
	cNomeCli := Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+C5_LOJACLI,"A1_NOME")
Else
	cNomeCli := ""
Endif

dbSelectArea("PXA")
PXA->(dbSetOrder(2)) //PXA_FILIAL+PXA_PEDVEN+PXA_ITEMPV+PXA_SEQ_OP
If PXA->( dbSeek(xFilial("PXA")+ _cPedVen + _cItmPed + _cSequenc) )
	cTag 	  := Alltrim(PXA->PXA_TAG_NO)
	cRange 	  := Alltrim(STR(PXA->PXA_FX_MIN))+" a "+Alltrim(STR(PXA->PXA_FX_MAX))+" - "+Alltrim(PXA->PXA_UN_MED)
	cNumSerie := Alltrim(PXA->PXA_NSERIE)
Endif                 

If Empty(cNumSerie)
	If !Empty(SC2->C2_NUMSERI)
		cNumSerie := Alltrim(SC2->C2_NUMSERI)
	Endif
Endif

//Inicia a Impressao da etiqueta
//MSCBPRINTER(_cZModel,_cZPorta,,)
MSCBPRINTER(_cZModel,_cZPorta,,,.f.)
MSCBCHKStatus(.F.)

If nEtiq_Cop >= 200 .Or. nEtiq_Vol >=200 .Or. nEtiq_Qtd >=200
	If !MSGYESNO("Confirma a impressão de "+Alltrim(Str(nEtiq_Cop))+" Cópias, Quantidade "+Alltrim(Str(nEtiq_Qtd))+" para "+Alltrim(Str(nEtiq_Vol))+" Volumes ?","Atenção")
		lCopias:= .F.
	Endif
Endif

If lCopias
	For nX := 1 to nEtiq_Cop
		
		nVol := 0
		For nI := 1 to nEtiq_Vol
			
			MSCBBEGIN(1,_nVelcImp)
			
			nVol++
			
			MSCBSAYBAR(08, 03, SC2->C2_PRODUTO+SH6->H6_LOTECTL,"N","MB07",13,.F.,.F.,.F.,,2,4,.F.,.F.,.F.,.F.)
			MSCBSAY(   08, 18, SC2->C2_PRODUTO+" LOTE:"+SH6->H6_LOTECTL,"N","F","25")
			//MSCBSAY(   100,08, DTOC(dDataBase),"N","0","35")
			//MSCBSAY(   90, 18, SC2->C2_NUM+" - "+SC2->C2_ITEM+SC2->C2_SEQUEN,"N","0","35")
			MSCBSAY(   08, 28, SubStr(Alltrim(SB1->B1_DESC),1,50),"N","0","25,0")
			MSCBSAY(   08, 33, SubStr(Alltrim(SB1->B1_DESC),51,Len(SB1->B1_DESC)),"N","0","25,0")
			MSCBSAY(   08, 38, "Tag: "+Alltrim(cTag),"N","0","30,0")
			MSCBSAY(   87, 38, "NS. "+Alltrim(cNumSerie),"N","0","30,0")
			MSCBSAY(   08, 46, "Range: "+Alltrim(cRange),"N","0","25,0")
			MSCBSAY(   08, 52, Alltrim(cNomeCli),"N","0","30")
			MSCBSAY(   90, 57, "QDE : "+Alltrim(strZERO(nEtiq_Qtd,3))+" "+SB1->B1_UM,"N","0","35,0")
			MSCBSAY(   90, 64, "VOL. : "+alltrim(strZERO(nVol,2))+" / "+alltrim(strZERO(nEtiq_Vol,2)),"N","0","35,0") 
			MSCBSAY(   08, 58, DTOC(dDataBase),"N","0","30")
			MSCBSAY(   08, 64, "OP:"+SC2->C2_NUM+" - "+SC2->C2_ITEM+SC2->C2_SEQUEN,"N","0","30")			
			MSCBSAY(   08, 70, "End:"+Iif(Empty(cEnderc),SBF->BF_LOCALIZ,cEnderc),"N","0","30")
			//MSCBSAY(   08, 58, "YOKOGAWA AMERICA DO SUL","N","0","25,0")
			//MSCBSAY(   08, 63, "Praca Acapulco, 31 - Sao Paulo","N","D","1,0")
			//MSCBSAY(   08, 67, "CNPJ : 53.761.607/0001-50","N","D","1,0")
			
			MSCBEnd()
			Sleep(3)
		Next	
	Next
	MSCBClosePrinter()
	SC2->(RecLock("SC2",.F.))
	SC2->C2_DTPAG := dDataBase
	SC2->(MsUnlock())
Endif

#IFDEF WINDOWS
	Set Device To Screen
	Set Printer To
#ENDIF

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±º Programa ³ S4MZEBRA ³ Autor ³ Marcio Gois           ³ Data ³25/02/2014³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Imprime n etiquetas de codigo de barras conforme solicitado³±±
±±³          ³ nos parametros.                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Static Function S4MZEBRA()
LOCAL _cZModel,_cZPorta, cPorta, cPadrao
Local _nVelcImp := 4
Local cTag 		:= ""
Local cRange 	:= ""  
Local lCopias 	:= .T. 
Local _cSequenc := ""
Local nI		:= 1
Local nX		:= 1

cPadrao := "?3"
cPadrao := Chr(27) + cPadrao + Chr(27) + "A41" + Chr(27)
_cZModel := "S4M" // parametro utilizado para definir a impressora
_cZPorta := "LPT1"

DBSelectArea("SC2")
DBSetOrder(1)
DBSeek(xFilial("SC2")+cEtiq_OP)

DBSelectArea("SB1")
DBSetOrder(1)
DBSeek(xFilial("SB1")+SC2->C2_PRODUTO)

If !Empty(SC2->C2_PEDIDO)
	DBSelectArea("SC5")
	DBSetOrder(1)
	DBSeek(xFilial("SC5")+SC2->C2_PEDIDO)
	cNomeCli := Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+C5_LOJACLI,"A1_NOME")
Else
	cNomeCli := ""
Endif

dbSelectArea("PXA")
PXA->(dbSetOrder(2)) //PXA_FILIAL+PXA_PEDVEN+PXA_ITEMPV+PXA_SEQ_OP 
If SC2->C2_SEQPAI == "000" .Or. Empty(SC2->C2_SEQPAI)
	_cSequenc := SC2->C2_SEQUEN 
Else
	_cSequenc := SC2->C2_SEQPAI
Endif

If PXA->( dbSeek(xFilial("PXA")+ SC2->C2_PEDIDO + SC2->C2_ITEMPV + _cSequenc) )
	cTag 	:= Alltrim(PXA->PXA_TAG_NO)
	cRange 	:= Alltrim(STR(PXA->PXA_FX_MIN))+" a "+Alltrim(STR(PXA->PXA_FX_MAX))+" - "+Alltrim(PXA->PXA_UN_MED)
Endif

//Inicia a Impressao da etiqueta
MSCBPRINTER(_cZModel,_cZPorta,,)
MSCBCHKStatus(.F.)   

If nEtiq_Cop >= 200 .Or. nEtiq_Vol >=200 .Or. nEtiq_Qtd >=200
	If !MSGYESNO("Confirma a impressão de "+Alltrim(Str(nEtiq_Cop))+" Cópias, Quantidade "+Alltrim(Str(nEtiq_Qtd))+" para "+Alltrim(Str(nEtiq_Vol))+" Volumes ?","Atenção")
		lCopias:= .F.
	Endif
Endif

If lCopias

For nX := 1 to nEtiq_Cop
	
	nVol := 0
	For nI := 1 to nEtiq_Vol
		
		MSCBBEGIN(1,_nVelcImp)
		
		nVol++
		
		MSCBSAYBAR(12,  05, SC2->C2_PRODUTO,"N","C",16,.F.,.F.,.F.,,3,2,,.F.,.F.,.F.)
		MSCBSAY(   12,  22, SC2->C2_PRODUTO,"N","F","80")
		MSCBSAY(   140, 08, DTOC(dDataBase),"N","0","60")
		MSCBSAY(   120, 20, SC2->C2_NUM+" - "+SC2->C2_ITEM+SC2->C2_SEQUEN,"N","0","55")
		MSCBSAY(   12,  35, SubStr(Alltrim(SB1->B1_DESC),1,60),"N","0","45,0")
		MSCBSAY(   12,  45, SubStr(Alltrim(SB1->B1_DESC),61,Len(SB1->B1_DESC)),"N","0","45,0")
	  	MSCBSAY(   12,  55, "Tag: "+Alltrim(cTag),"N","0","45,0")
		MSCBSAY(   12,  65, "Range: "+Alltrim(cRange),"N","0","45,0")
		MSCBSAY(   12,  75, Alltrim(cNomeCli),"N","0","45")
		MSCBSAY(   120, 85, "QDE : "+Alltrim(strZERO(nEtiq_Qtd,3))+" "+SB1->B1_UM,"N","0","60,0")
		MSCBSAY(   120, 95, "VOL. : "+alltrim(strZERO(nVol,2))+" / "+alltrim(strZERO(nEtiq_Vol,2)),"N","0","60,0")
		MSCBSAY(   12,  85, "YOKOGAWA AMERICA DO SUL","N","0","35,0")
		MSCBSAY(   12,  92, "Praca Acapulco, 31 - Sao Paulo","N","F","15")
		MSCBSAY(   12,  97, "CNPJ : 53.761.607/0001-50","N","F","15")

		MSCBSAY(   12,  45, "Praca Acapulco, 31 - Sao Paulo","N","C","20")
		
		MSCBEnd()
		Sleep(3)
	Next	
Next
MSCBClosePrinter()
Endif

#IFDEF WINDOWS
	Set Device To Screen
	Set Printer To
#ENDIF

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±º Programa ³ PreenEnder³ Autor ³ Anderson Sano        ³ Data ³23/11/2021³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Preenche o endereço localizado na operação 07 da PX1       ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function PreenEnder(cEtiq_OP)
Local cAliasPX1 := GetNextAlias()

BeginSql Alias cAliasPX1

	SELECT 
		TOP(1) PX1_LOCALI
	FROM 
		%TABLE:PX1% PX1
	WHERE PX1.%notDel%
		AND PX1.PX1_OPERAC = '07'
		AND PX1.PX1_OP = %EXP:cEtiq_OP%
	ORDER BY PX1.PX1_DATAFI DESC,PX1.PX1_HORAFI DESC
			
EndSql

(cAliasPX1)->(DbGoTop())
While !(cAliasPX1)->(Eof())
	cEnderc := Alltrim((cAliasPX1)->PX1_LOCALI)
	(cAliasPX1)->(DbSkip())
Enddo

Return(.T.)
