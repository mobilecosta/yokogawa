#INCLUDE "TOTVS.CH
#INCLUDE "PROTHEUS.CH
#INCLUDE "TBICONN.CH"
//#INCLUDE "APVT100.CH"

#Define ENTER CHR(13)+CHR(10)

/*/
+---------------------------------------------------------------------------+
| Programa  | YOACD01   | Autor | Vinícius Bittencourt    | Data | 08/01/24 |
+-----------+---------------------------------------------------------------+
| Descrição | Rotina para gravar dados da Expedicao e Gerar Etiqueta.       |
+-----------+---------------------------------------------------------------+
| Uso       | Yokogawa                                                      |
+---------------------------------------------------------------------------+
/*/
User Function YOACD01()
	Local aArea    	  := FWGetArea()
	Local nMaxLinha   := Val(GetPvProfString( "TELNET", "MAXROW" , "12", GetADV97()))
	Local nMaxColuna  := Val(GetPvProfString( "TELNET", "MAXCOL" , "20", GetADV97()))
	Local cOP      	  := space(11)

	YOACD01Cfg(nMaxLinha, nMaxColuna)
	cOP := YOACD01GOP()
	
	// (HOME) Pagamento (YOACD01Pag), Visualizacao (YOACD01Vis) ou Sair (YOACD01Sair)
	YOACD01HM(cOP)

	FWRestArea(aArea)
Return

// Configuração inicial do modulo
Static Function YOACD01Cfg(cMaxLinha, cMaxColuna)
	If Select("SM0") > 0
		Return
	EndIf

	OpenSM0()

	RpcSetType(3)
	DbGoTop()
	RpcSetEnv(SM0->M0_CODIGO, SM0->M0_CODFIL)

	//Configura MSAPP
	MsApp():New('SIGAACD', .T.)
	oApp:cInternet := NIL
	oApp:lIsBlind  := .T.
	oApp:cEmpAnt := "01"
	oApp:cfOpened := "SX3"
	oApp:CreateEnv()

	//Configura VT
	VTSetSize(cMaxLinha, cMaxColuna)
	TerProtocolo("VT100")
	SetsDefault()
Return

// Obtem e valida a OP informada (get OP)
Static Function YOACD01GOP()
	Local cOP := Space(11)

	VTClear()

	@ 00,00 VTSay "Pagamento de OP"
	@ 02,00 VTSay "Digite a OP: " VTGet cOP Valid YOACD01VOP(cOP)

	VTRead()
Return cOP

// Exibe menu de opções para a OP (HOME)
Static Function YOACD01HM(cOP)
	Local aOpts := { "Pagamento", "Visualizacao", "Sair" }
	Local aCols := {}
	Local aHeader := {}
	Local aSize := {}
	Local nOpt := 0
	Local nPos := 0
	
	// Cria um array para armazenar os dados da OP
	aCols := {}
	aAdd(aCols, { SC2->C2_NUM, SC2->C2_ITEM, SC2->C2_SEQUEN, SC2->C2_PRODUTO, SC2->C2_EMISSAO, SC2->C2_LOCAL, SC2->C2_QUANT })

	// cria cabecalho de exibicao da tela de browse da OP com o titulo das colunas
	aHeader := { fwX3Titulo("C2_OP"), fwX3Titulo("C2_ITEM"), fwX3Titulo("C2_SEQUEN"), fwX3Titulo("C2_PRODUTO"), fwX3Titulo("C2_EMISSAO"), fwX3Titulo("C2_LOCAL"), fwX3Titulo("C2_QUANT") }

	aSize := GerSize(aHeader, aCols)
	
	// Exibe a tela de browse da OP e recebe a posicao do item selecionado
	VTClear()
	YOACD01CAP(cOP)
	@ 02,00 VtSay "Selecione o a opcao"
	nPos := VTaBrowse(3,0,VTMaxRow(),VTmaxCol(),aHeader,aCols, aSize)

	If nPos == 0
		Return
	EndIf

	// Pega código da opção selecionada
	cOP := aCols[nPos][1] + aCols[nPos][2] + aCols[nPos][3]

	// Exibe menu de opções para a OP
	nOpt := VTaChoice(3,0,5,VTMaxCol(),aOpts)

	// Processa a opção selecionada
	If nOpt == 1
		YOACD01Pag(cOP)
	ElseIf nOpt == 2
		YOACD01Vis(cOP)
	ElseIf nOpt == 3
		YOACD01Sair()
	EndIf
Return

// --- Funções de Exibição --------------------------------------------------

// Pagamento da OP
Static Function YOACD01Pag(cOP)
	Local aCombo := {"02-Almoxarifado","03-LM 2.5","04-Inspecao","08-Projeto P&P"}	// Tabela NNR
	Local _aItAux    := {}
	Local _lGrv      := .F.
	Local _nCnt		 := 1
	Local _nCont2	 := 1
	Local _nCnt5	 := 1
	Local _nReq	 	 := 1
	Local _cOpOrig   := ''
	Local _cSeqSD4   := ''  
	Local _nPosReq   := 0
	Local _nPosChkEmp:= 0
	Local _aReqOps	 := {}
	Local _lPagOk    := .T.
	Local _nChkTran  := 0
	Local _aItAuxTrf := {}
	Local _aArea 	 := GetArea()
	Local nPos       := 1
	Local nCol       := 1
	Local aCols 	 := {}
	Local aHeader 	 := {}
	Local aSize 	 := {}

	Private _aSelec  := {}
	Private _aCampos := {}
	Private _aCampo2 := {}
	Private _aEstru  := {}
	Private _aEstru2 := {}
	Private _aProds  := {}
	Private lMsErroAuto := .F.
	Private _cLocEst := Alltrim(GetMV("MV_YLOCEST"))
	Private aItMata381 := {}
	Private aCbMata381 := {}
	
	YOACD01CAP(cOP)
	@ 03,00 VtSay "Escolha o armazem: "
	nOpt := VTaChoice(4,0,7,18,aCombo)
	If nOpt == 0
		Return
	EndIF

	_cLocEst := "02" //aCombo[nOpt]

	If Select("SLDD") > 0
		SLDD->(dbCloseArea())
	EndIf

	If Select("SLDO") > 0
		SLDO->(dbCloseArea())
	EndIf

	aAdd(_aCampos,{'PRODUTO' ,'C',15,00})
	aAdd(_aCampos,{'ALMOX'   ,'C',02,00})
	aAdd(_aCampos,{'LOTE'    ,'C',10,00})
	aAdd(_aCampos,{'SUB_LOTE','C',06,00})
	aAdd(_aCampos,{'ENDERECO','C',15,00})
	aAdd(_aCampos,{'N_SERIE' ,'C',20,00})
	aAdd(_aCampos,{'VALIDADE','D',08,00})
	aAdd(_aCampos,{'QUANT'   ,'N',09,02})

	//Cria Arquivo de Saldo no Destino
	_cArqSLDD := CriaTrab(_aCampos,.T.)
	_cIndSLDD := CriaTrab(Nil,.F.)
	dbUseArea(.T.,,_cArqSLDD,"SLDD",.F.,.F.)
	IndRegua("SLDD",_cIndSLDD,"PRODUTO + ALMOX + LOTE + SUB_LOTE + ENDERECO",,,"Criando Índice Temporário...")

	dbSelectArea("SLDD")
	SLDD->(dbSetOrder(1))
	SLDD->(dbGoTop())

	//Cria Arquivo de Saldo na Origem
	_cArqSLDO := CriaTrab(_aCampos,.T.)
	_cIndSLDO := CriaTrab(Nil,.F.)
	dbUseArea(.T.,,_cArqSLDO,"SLDO",.F.,.F.)
	IndRegua("SLDO",_cIndSLDO,"PRODUTO + ALMOX + LOTE + SUB_LOTE + ENDERECO",,,"Criando Índice Temporário...")

	dbSelectArea("SLDO")
	SLDO->(dbSetOrder(1))
	SLDO->(dbGoTop())

	aAdd(_aCampo2,{'NUMOP'   ,'C',013,000})
	aAdd(_aCampo2,{'PRODUTO' ,'C',015,000})
	aAdd(_aCampo2,{'DESCRI'  ,'C',100,000})
	aAdd(_aCampo2,{'UM'      ,'C',002,000})
	aAdd(_aCampo2,{'QTDEMP'  ,'N',009,002})
	aAdd(_aCampo2,{'SALDO'   ,'N',009,002})
	aAdd(_aCampo2,{'LOCDES'  ,'C',002,000})
	aAdd(_aCampo2,{'LOTDES'  ,'C',010,000})
	aAdd(_aCampo2,{'SBLDES'  ,'C',006,000})
	aAdd(_aCampo2,{'ENDDES'  ,'C',015,000})
	aAdd(_aCampo2,{'QTDTRF'  ,'N',009,002})
	aAdd(_aCampo2,{'LOCORI'  ,'C',002,000})
	aAdd(_aCampo2,{'LOTORI'  ,'C',010,000})
	aAdd(_aCampo2,{'SBLORI'  ,'C',006,000})
	aAdd(_aCampo2,{'ENDORI'  ,'C',015,000})
	aAdd(_aCampo2,{'VALIDADE','D',008,000})
	aAdd(_aCampo2,{'NUMSER'  ,'C',020,000})
	aAdd(_aCampo2,{'TABELA'  ,'C',003,000})
	aAdd(_aCampo2,{'RECNO'   ,'N',010,000})
	aAdd(_aCampo2,{'TRT'     ,'C',003,000})
	aAdd(_aCampo2,{'YFORNEC' ,'C',006,000})
	aAdd(_aCampo2,{'YLOJA'   ,'C',004,000})
	aAdd(_aCampo2,{'YPEDBEN' ,'C',006,000})
	aAdd(_aCampo2,{'YPEDCOM' ,'C',006,000})
	aAdd(_aCampo2,{'YPEDITE' ,'C',004,000})
	aAdd(_aCampo2,{'NUMSC'   ,'C',006,000})
	aAdd(_aCampo2,{'YFORNE2' ,'C',006,000})
	aAdd(_aCampo2,{'YLOJA2'  ,'C',004,000})
	aAdd(_aCampo2,{'YPEDBE2' ,'C',006,000})
	aAdd(_aCampo2,{'YPEDCO2' ,'C',006,000})
	aAdd(_aCampo2,{'YPEDIT2' ,'C',004,000})
	//Cria Arquivo de Transferência
	_cArqTRF := CriaTrab(_aCampo2,.T.)
	_cIndTRF := CriaTrab(Nil,.F.)
	dbUseArea(.T.,,_cArqTRF,"TRF",.F.,.F.)
	//IndRegua("TRF",_cIndTRF,"NUMOP + PRODUTO + DESCEND(Transform(QTDEMP,'@E 999,999.99')) + LOCDES + LOTDES + SBLDES + ENDDES + LOCORI + LOTORI + SBLORI + ENDORI",,,"Criando Índice Temporário...")
	IndRegua("TRF",_cIndTRF,"NUMOP + PRODUTO + LOCDES + LOTDES + SBLDES + ENDDES + LOCORI + LOTORI + SBLORI + ENDORI",,,"Criando Índice Temporário...")

	YOPA02NOP(cOP)

	If (Len(_aEstru) + Len(_aEstru2)) > 0
		Processa({|| YOPA02Nec(@_aProds)},"Calculando a necessidade...")
	EndIf

	If Len(_aProds) > 0
		Processa({|| YOPA02Sld()},"Verificando a disponibilidade...")
	EndIf

	If (Len(_aEstru) + Len(_aEstru2)) > 0
		Processa({|| YOPA02Trf()},"Calculando as transferências...")
	EndIf

	dbSelectArea("TRF")
	TRF->(dbGoTop())
	If !TRF->(Eof())
		Processa({|| YOPA02Arr(@_aSelec)},"Organizando os dados...")
	EndIf

	If Select("TRF") > 0
		TRF->(dbCloseArea())
	EndIf

	If Len(_aSelec) > 0
		_aLbxIt := {}
		For _nCnt := 1 to Len(_aSelec)
			//Carregar apenas D4_PAGOP em branco
			dbSelectArea("SD4")
			SD4->(dbGoTo(_aSelec[_nCnt][19]))
			If Empty(SD4->D4_PAGOP)
				//Carregar apenas com Saldo
				If _aSelec[_nCnt][11] > 0 .Or. _aSelec[_nCnt][06] > 0 .Or. !Empty(_aSelec[_nCnt][08])
					 //aAdd(_aEstru, {SD4->D4_COD,SD4->D4_LOCAL,"","",SD4->D4_LOTECTL,SD4->D4_NUMLOTE,SD4->D4_DTVALID,SD4->D4_QUANT,_cNumOP,"SD4",SD4->(Recno()),SD4->D4_TRT,SD4->D4_YFORNEC,SD4->D4_YLOJA,SD4->D4_YPEDBEN,SD4->D4_YPEDCOM,SD4->D4_YPEDITE,SD4->D4_NUMSC,SD4->D4_YFORNE2,SD4->D4_YLOJA2,SD4->D4_YPEDBE2,SD4->D4_YPEDCO2,SD4->D4_YPEDIT2})
					aAdd(_aLbxIt,_aSelec[_nCnt])
				Endif
			Endif
		Next _nCnt
		If Len(_aLbxIt) <= 0
			Alert("Não ha itens com saldo para exibição")
			RestArea(_aArea)
			Return
		Endif
		
		aSort(_aLbxIt,,,{|x,y| x[2] < y[2] })
		_aLbxBk := aClone(_aLbxIt)

		YOACD01CAP(cOP)
		
		// cria cabecalho de exibicao da tela de browse da OP com o titulo das colunas
		aHeader := { 	"Status",;
						"Número da OP"		,; //01
						"Produto"			,; //02
						"Descrição"			,; //03
						"U.M."				,; //04
						"Qt. Empenhada"		,; //05
						"Saldo"				,; //06
						"Qt. a Transferir"	,; //11  Posição da coluna alterado por solicitação do Rogério - Chamado 29695
						"Endereço Origem"	,; //15  Posição da coluna alterado por solicitação do Rogério - Chamado 29695
						"Local Empenho"		,; //07
						"Lote Empenho"		,; //08
						"Sub-Lote Empenho"	,; //09
						"Endereço Empenho"	,; //10
						"Local Origem"		,; //12
						"Lote Origem"		,; //13
						"Sub-Lote Origem"	,; //14
						"Validade"			,; //16
						"Número de Série"	,; //17
						"Tabela"			,; //18
						"Registro"			,; //19
						"TRT"				,; //20
						"Fornecedor"		,; //21
						"Loja"				,; //22
						"Ped.Benef"			,; //23
						"Ped.Compra"		,; //24
						"Item Pedido"		,; //25
						"Num S.C."			,; //26
						"Fornecedor 2"		,; //27
						"Loja 2"			,; //28
						"Ped.Benef 2"		,; //29
						"Ped.Compra 2"		,; //30
						"Item Pedido 2"		 } //31	 }

		aSize := GerSize(aHeader, aCols)
		
		// Exibe a tela de browse da OP e recebe a posicao do item selecionado
		While .t.
			// Cria um array para armazenar os dados da OP
			aCols := {}
			For nCol := 1 To Len(_aLbxIt)
				aItem := { 	Iif(_aLbxIt[nCol,11] > 0,"ENABLE",Iif(_aLbxIt[nCol,6] > 0 .Or. _aLbxIt[nCol,5] <= 0, "AMARELO",;
							Iif(_aLbxIt[nCol,11] <= 0 .And. _aLbxIt[nCol,6] <= 0 .And. !Empty(_aLbxIt[nCol,8]),"AZUL","DISABLE"))),;
							_aLbxIt[nCol,1],;
							_aLbxIt[nCol,2],;
							_aLbxIt[nCol,3],;
							_aLbxIt[nCol,4],;
							_aLbxIt[nCol,5],;
							_aLbxIt[nCol,6],;
							_aLbxIt[nCol,11],; //Posição da coluna alterado por solicitação do Rogério - Chamado 29695
							_aLbxIt[nCol,15],; //Posição da coluna alterado por solicitação do Rogério - Chamado 29695
							_aLbxIt[nCol,7],;
							_aLbxIt[nCol,8],;
							_aLbxIt[nCol,9],;
							_aLbxIt[nCol,10],;
							_aLbxIt[nCol,12],;
							_aLbxIt[nCol,13],;
							_aLbxIt[nCol,14],;
							_aLbxIt[nCol,16],;
							_aLbxIt[nCol,17],;
							_aLbxIt[nCol,18],;
							_aLbxIt[nCol,19],;
							_aLbxIt[nCol,20],;
							_aLbxIt[nCol,21],;
							_aLbxIt[nCol,22],;
							_aLbxIt[nCol,23],;
							_aLbxIt[nCol,24],;
							_aLbxIt[nCol,25],;
							_aLbxIt[nCol,26],;
							_aLbxIt[nCol,27],;
							_aLbxIt[nCol,28],;
							_aLbxIt[nCol,29],;
							_aLbxIt[nCol,30],;
							_aLbxIt[nCol,31],;
							_aLbxIt[nCol,11] }

				aAdd(aCols, AClone(aItem))
			Next

			YOACD01CAP(cOP)
			@ 03,00 VtSay "Transferencias"
			nPos := VTaBrowse(3,0,VTMaxRow(),VTmaxCol(),aHeader,aCols, aSize)

			If nPos == 0
				Exit
			EndIf

			// Exibe menu de opções para a OP
			aOpts := { "Zera Qtde", "Qtde Transf.", "Ok", "Cancelar" }
			nOpt := VTaChoice(3,0,5,VTMaxCol(),aOpts)

			If nOpt == 1
				YOPA02Zer(@_aLbxIt)
			ElseIf nOpt == 2
				YOPA02Qtd(cOp, @_aLbxIt, aCols, nPos)
			ElseIf nOpt == 3
				_lGrv := .T.
				Exit
			Else
				Exit
			EndIf
		EndDo
	EndIf

	_aReqOps	:= {}
	If _lGrv
		u_YOPA02G(cOP, .T.)
	Else
		MsgAlert("Processo cancelado ou não há itens para transferência!!!")
	EndIf

	If Select("SLDD") > 0
		SLDD->(dbCloseArea())
	EndIf

	If Select("SLDO") > 0
		SLDO->(dbCloseArea())
	EndIf

	RestArea(_aArea)
	//Apaga os arquivos
	Ferase(_cArqSLDD)
	Ferase(_cArqSLDO)

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ YOPA02ZerºAutor  ³Anderson Messias    º Data ³  26/04/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina que permite alterar a quantidade a ser transferida  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ YOKOGAWA                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function YOPA02Zer(_aLbxIt)
Local nI := 1

if MsgYesNo("Deseja zerar a quantidade de transferencia de todos os produtos?")
	For nI := 1 to Len(_aLbxIt)
		_aLbxIt[nI,11] := 0
	Next
endif

Return

Static Function YOPA02Qtd(cOp, _aLbxIt, aCols, nPos)

Local nOpt  := 0
Local aOpts := { "Ok", "Cancelar" }

YOACD01CAP(cOP)

nQtdSug := _aLbxBK[nPos,11]
nQtdNov := _aLbxIt[nPos,11]

@ 02,00 VtSay "Quantidade a Transferir"
@ 03,00 VTSAY "Qtde Sugerida"
@ 03,15 VTGET nQtdSug PICTURE "@E 999999.99" When .F.
@ 04,00 VTSAY "Nova Quantidade"
@ 04,15 VtGet nQtdNov PICTURE "@E 999999.99";
		Valid iif((nQtdNov>=0 .AND. nQtdNov<=nQtdSug),.T.,(Alert("A nova quantidade nao pode ser maior que a quantidade original"),.F.))
VtRead

// Exibe menu de opções para a OP
nOpt := VTaChoice(5,0,6,10,aOpts)

If nOpt == 1
	_aLbxIt[nPos,11] := nQtdNov
EndIf

Return


/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02NOP  | Autor | Cristiano Gomes Cunha  | Data | 24/09/08 |
|-----------+---------------------------------------------------------------|
| Descrição | Verifica a necessidade de cada Ordem de Produção.             |
|-----------+---------------------------------------------------------------|
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOPA02NOP(_cNumOP)

Local _cChvSC2 := xFilial("SC2") + _cNumOP
Local _cChvSD4 := xFilial("SD4") + _cNumOP

dbSelectArea("SC2")
SC2->(dbSetOrder(1))
SC2->(dbSeek(_cChvSC2))

// +----------------------------+
// | Estrutura do array _aEstru |
// +----------------------------+
// | 01 - Produto               |
// | 02 - Local                 |
// | 03 - Endereço              |
// | 04 - Número de Série       |
// | 05 - Lote                  |
// | 06 - Sub-Lote              |
// | 07 - Validade              |
// | 08 - Quantidade            |
// | 09 - Ordem de Produção     |
// +----------------------------+

dbSelectArea("SDC")
SDC->(dbSetOrder(2))

dbSelectArea("SD4")
SD4->(dbSetOrder(2))
If SD4->(dbSeek(_cChvSD4))
	While !SD4->(Eof()) .And. (Alltrim(SD4->(D4_FILIAL + D4_OP)) == Alltrim(_cChvSD4))
		If SD4->D4_QUANT > 0 .AND. EMPTY(SD4->D4_LOTECTL) .And. !(Alltrim(GetAdvFval("SB1","B1_GRUPO",xFilial("SB1")+SD4->D4_COD,1," ")) $ SuperGetMV("MV_YKANBAN",,"KANB/LM25"))
			aAdd(_aEstru, {SD4->D4_COD,SD4->D4_LOCAL,"","",SD4->D4_LOTECTL,SD4->D4_NUMLOTE,SD4->D4_DTVALID,SD4->D4_QUANT,_cNumOP,"SD4",SD4->(Recno()),SD4->D4_TRT,SD4->D4_YFORNEC,SD4->D4_YLOJA,SD4->D4_YPEDBEN,SD4->D4_YPEDCOM,SD4->D4_YPEDITE,SD4->D4_NUMSC,SD4->D4_YFORNE2,SD4->D4_YLOJA2,SD4->D4_YPEDBE2,SD4->D4_YPEDCO2,SD4->D4_YPEDIT2})
		EndIf
		
		dbSelectArea("SD4")
		SD4->(dbSkip())
	EndDo
EndIf

Return


// Visualizacao da OP
Static Function YOACD01Vis(cOP)
	Local _cChvSC2 := xFilial("SC2") + cOP
	Local cExit := Space(1)

	dbSelectArea("SC2")
	SC2->(dbSetOrder(1))

	dbSeek(_cChvSC2)
	@ 00,00 VtSay "OP: " + cOP
	@ 01,00 VtSay "Item: " + SC2->C2_ITEM
	@ 02,00 VtSay "Sequencia: " + SC2->C2_SEQUEN
	@ 03,00 VtSay "Produto: " + SC2->C2_PRODUTO
	@ 04,00 VtSay "Emissao: " + DTOC(SC2->C2_EMISSAO)
	@ 05,00 VtSay "Local: " + SC2->C2_LOCAL
	@ 06,00 VtSay "Quantidade: " + cValToChar(SC2->C2_QUANT)
	@ 07,00 VtSay "Sair" VtGet cExit 
	VTRead()
	
	YOACD01HM(cOP)
Return

// --- Funções de Acesso a Dados --------------------------------------------

// --- Validações -----------------------------------------------------------

// Validação da OP informada
Static Function YOACD01VOP(cOP)
	If Empty(cOP)
		VTClear()
		VTAlert("OP invalida !", "Aviso", .T., 2000)
		Return .F.
	EndIf

	dbSelectArea("SC2")
	dbSetOrder(1)
		
	If !DBSeek(xFilial("SC2") + cOP) .AND. SC2->C2_TPOP == 'F'
		VTClear()
		VtAlert("Aviso","OP invalida !",.t.,2000)
		Return .F.
	EndIf
Return .T.

// Validação do armazem informado
Static Function YOACD01VAr(cArm)
	// *** AQUI VAI O CODIGO PARA VALIDACAO DO ARMAZEM ***
Return .T.

// --- Funções Auxiliares ---------------------------------------------------

// Cabecalho da tela de Pagamento de OP
Static Function YOACD01CAP(cOP)
	VTClear()
	
	@ 00,00 VtSay "Pagamento de OP"
	@ 01,00 VtSay "OP: " + cOP
Return

// Fecha o modulo
Static Function YOACD01Sair()
	VTClear()
	VTAlert("Saindo do modulo de Pagamento de OP", "Aviso", .T., 2000)
Return


/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02Nec  | Autor | Cristiano Gomes Cunha  | Data | 24/09/08 |
|-----------+---------------------------------------------------------------|
| Descrição | Verifica a necessidade de cada produto.                       |
|-----------+---------------------------------------------------------------|
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOPA02Nec(_aProds)
Local _nCont := 1

ProcRegua(Len(_aEstru) + Len(_aEstru2))

For _nCont := 1 to Len(_aEstru2)
	
	IncProc()
	
	// Alimenta array com a necessidade de cada produto
	_nPosPro := aScan(_aProds,{|x| Alltrim(x[1]) + Alltrim(x[2]) + Alltrim(x[3]) + Alltrim(x[4]) + Alltrim(x[5]) == Alltrim(_aEstru2[_nCont][1]) + Alltrim(_aEstru2[_nCont][2]) + Alltrim(_aEstru2[_nCont][5]) + Alltrim(_aEstru2[_nCont][6]) + Alltrim(_aEstru2[_nCont][3])})
	If _nPosPro <= 0
		aAdd(_aProds,{_aEstru2[_nCont][1],_aEstru2[_nCont][2],_aEstru2[_nCont][5],_aEstru2[_nCont][6],_aEstru2[_nCont][3],_aEstru2[_nCont][8]})
	Else
		_aProds[_nPosPro][6] += _aEstru2[_nCont][8]
	EndIf
	
Next _nCont

For _nCont := 1 to Len(_aEstru)
	
	IncProc()
	
	// Alimenta array com a necessidade de cada produto
	_nPosPro := aScan(_aProds,{|x| Alltrim(x[1]) + Alltrim(x[2]) + Alltrim(x[3]) + Alltrim(x[4]) + Alltrim(x[5]) == Alltrim(_aEstru[_nCont][1]) + Alltrim(_aEstru[_nCont][2]) + Alltrim(_aEstru[_nCont][5]) + Alltrim(_aEstru[_nCont][6]) + Alltrim(_aEstru[_nCont][3])})
	If _nPosPro <= 0
		aAdd(_aProds,{_aEstru[_nCont][1],_aEstru[_nCont][2],_aEstru[_nCont][5],_aEstru[_nCont][6],_aEstru[_nCont][3],_aEstru[_nCont][8]})
	Else
		_aProds[_nPosPro][6] += _aEstru[_nCont][8]
	EndIf
	
Next _nCont

Return



/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02Add  | Autor | Cristiano Gomes Cunha  | Data | 10/09/08 |
|-----------+---------------------------------------------------------------|
| Descrição | Adiciona os dados no arquivo temporário de transferência.     |
|-----------+---------------------------------------------------------------|
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOPA02Add(_aDados)

_cProdut := _aDados[02]
_nQuant  := _aDados[03]
_cNumOP  := _aDados[09]
_cLocDes := _aDados[11]
_cLotDes := _aDados[04]
_cSbLDes := _aDados[05]
_nSaldo  := _aDados[12]
_cNSerie := _aDados[07]
_nQtdTrf := _aDados[13]
_cTabela := _aDados[14]
_nRecno  := _aDados[15]
_cTRT    := _aDados[16]
_cFornec := _aDados[17]
_cLoja   := _aDados[18]
_cPedBen := _aDados[19]
_cPedCom := _aDados[20]
_cPedItem:= _aDados[21]
_cNumSC  := _aDados[22]
_cForne2 := _aDados[23]
_cLoja2  := _aDados[24]
_cPedBe2 := _aDados[25]
_cPedCo2 := _aDados[26]
_cPedIte2:= _aDados[27]

_cDescri := ""
_cUM     := ""
dbSelectArea("SB1")
SB1->(dbSetOrder(1))
SB1->(dbGoTop())
If SB1->(dbSeek(xFilial("SB1") + _cProdut))
	_cDescri := SB1->B1_DESC
	_cUM     := SB1->B1_UM
EndIf

If _aDados[01] == 1
	_cLocOri := CriaVar("D3_LOCAL")
	_cLotOri := CriaVar("D3_LOTECTL")
	_cSbLOri := CriaVar("D3_NUMLOTE")
	_cEndOri := CriaVar("D3_LOCALIZ")
	_dValidd := CriaVar("D3_DTVALID")
	_cEndDes := _aDados[06]
Else
	_cLocOri := _aDados[10]
	_cLotOri := _aDados[04]
	_cSbLOri := _aDados[05]
	_cEndOri := _aDados[06]
	_dValidd := Iif(_nQtdTrf > 0,_aDados[08],CriaVar("D3_DTVALID"))
	If _cLocDes = GetMv("MV_YLOCSIS") .OR. _cLocDes = GetMv("MV_YLOCANA")
		_cEndDes := _cLocDes
	Else
		_cEndDes := _cLocDes
	EndIf
EndIf

RecLock("TRF",.T.)
TRF->NUMOP    := _cNumOP	// Ordem de Produção
TRF->PRODUTO  := _cProdut	// Produto
TRF->DESCRI   := _cDescri	// Descrição
TRF->UM       := _cUM		// Unidade de Medida
TRF->QTDEMP   := _nQuant	// Quantidade Empenhada
TRF->SALDO    := _nSaldo	// Saldo
TRF->LOCDES   := _cLocDes	// Local Empenho
TRF->LOTDES   := _cLotDes	// Lote Empenho
TRF->SBLDES   := _cSbLDes	// Sub-Lote Empenho
TRF->ENDDES   := _cEndDes   //_cEndDes	// Endereço Empenho -- Anderson Messias - 20/04/2009
TRF->QTDTRF   := _nQtdTrf	// Quantidade a Transferir
TRF->LOCORI   := _cLocOri	// Local Origem
TRF->LOTORI   := _cLotOri	// Lote Origem
TRF->SBLORI   := _cSbLOri	// Sub-Lote Origem
TRF->ENDORI   := _cEndOri	// Endereço Origem
TRF->VALIDADE := _dValidd	// Validade
TRF->NUMSER   := _cNSerie	// Número de Série
TRF->TABELA   := _cTabela	// Tabela do Registro
TRF->RECNO    := _nRecno	// Recno SD4
TRF->TRT      := _cTRT		// TRT
TRF->YFORNEC  := _cFornec	// TRT
TRF->YLOJA    := _cLoja		// TRT
TRF->YPEDBEN  := _cPedBen	// TRT
TRF->YPEDCOM  := _cPedCom	// TRT
TRF->YPEDITE  := _cPedItem  // TRT
TRF->NUMSC    := _cNumSC    // NUM. SC
TRF->YFORNE2  := _cForne2
TRF->YLOJA2   := _cLoja2
TRF->YPEDBE2  := _cPedBe2
TRF->YPEDCO2  := _cPedCo2
TRF->YPEDIT2  := _cPedIte2

TRF->(MsUnLock())

Return

/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02Arr  | Autor | Cristiano Gomes Cunha  | Data | 24/09/08 |
|-----------+---------------------------------------------------------------|
| Descrição | Adiciona os dados no array para visualização.                 |
|-----------+---------------------------------------------------------------|
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOPA02Arr(_aSelec)

Local _aRetAux := {}

// +------------------------------+
// | Estrutura do array _aRetAux  |
// +------------------------------+
// | 01 - Ordem de Produção       |
// | 02 - Produto                 |
// | 03 - Descrição               |
// | 04 - Unidade de Medida       |
// | 05 - Quantidade Empenhada    |
// | 06 - Saldo                   |
// | 07 - Local Empenho           |
// | 08 - Lote Empenho            |
// | 09 - Sub-Lote Empenho        |
// | 10 - Endereço Empenho        |
// | 11 - Quantidade a Transferir |
// | 12 - Local Origem            |
// | 13 - Lote Origem             |
// | 14 - Sub-Lote Origem         |
// | 15 - Endereço Origem         |
// | 16 - Validade                |
// | 17 - Número de Série         |
// | 18 - Tabela                  |
// | 19 - Recno                   |
// | 20 - TRT                     |
// | 21 - Fornecedor              |
// | 22 - Loja                    |
// | 23 - Pedido Beneficiamento   |
// | 24 - Pedido Compra           |
// | 25 - Item Pedido Compra      |
// +------------------------------+

ProcRegua(TRF->(RecCount()))

dbSelectArea("TRF")
TRF->(dbGoTop())
While !TRF->(Eof())
	
	IncProc()
	
	_aRetAux := {}
	
	aAdd(_aRetAux,TRF->NUMOP)		// Ordem de Produção
	aAdd(_aRetAux,TRF->PRODUTO)		// Produto
	aAdd(_aRetAux,TRF->DESCRI)		// Descrição
	aAdd(_aRetAux,TRF->UM)		 	// Unidade de Medida
	aAdd(_aRetAux,TRF->QTDEMP)		// Quantidade Empenhada
	aAdd(_aRetAux,TRF->SALDO)		// Saldo
	aAdd(_aRetAux,TRF->LOCDES)		// Local Empenho
	aAdd(_aRetAux,TRF->LOTDES)		// Lote Empenho
	aAdd(_aRetAux,TRF->SBLDES)		// Sub-Lote Empenho
	aAdd(_aRetAux,TRF->ENDDES)		// Endereço Empenho
	aAdd(_aRetAux,TRF->QTDTRF)		// Quantidade a Transferir
	aAdd(_aRetAux,TRF->LOCORI)		// Local Origem
	aAdd(_aRetAux,TRF->LOTORI)		// Lote Origem
	aAdd(_aRetAux,TRF->SBLORI)		// Sub-Lote Origem
	aAdd(_aRetAux,TRF->ENDORI)		// Endereço Origem
	aAdd(_aRetAux,TRF->VALIDADE)	// Validade
	aAdd(_aRetAux,TRF->NUMSER)		// Número de Série
	aAdd(_aRetAux,TRF->TABELA)		// Tabela
	aAdd(_aRetAux,TRF->RECNO)		// Recno
	aAdd(_aRetAux,TRF->TRT)			// TRT
	aAdd(_aRetAux,TRF->YFORNEC)		// Fornecedor
	aAdd(_aRetAux,TRF->YLOJA)		// Loja
	aAdd(_aRetAux,TRF->YPEDBEN)		// Ped.Benef.
	aAdd(_aRetAux,TRF->YPEDCOM)		// Ped.Compra
	aAdd(_aRetAux,TRF->YPEDITE)		// Item Ped.Compra
	aAdd(_aRetAux,TRF->NUMSC)		// Num. S.C.
	aAdd(_aRetAux,TRF->YFORNE2)		// Fornecedor 2º Beneficiamento 27
	aAdd(_aRetAux,TRF->YLOJA2)		// Loja 2º Beneficiamento 
	aAdd(_aRetAux,TRF->YPEDBE2)		// Ped.Benef. 2º Beneficiamento
	aAdd(_aRetAux,TRF->YPEDCO2)		// Ped.Compra 2º Beneficiamento
	aAdd(_aRetAux,TRF->YPEDIT2)		// Item Ped.Compra 2º Beneficiamento

	aAdd(_aSelec,_aRetAux)
	
	dbSelectArea("TRF")
	TRF->(dbSkip())
	
EndDo

Return



/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02Sld  | Autor | Cristiano Gomes Cunha  | Data | 22/09/08 |
|-----------+---------------------------------------------------------------|
| Descrição | Verifica o saldo do produto no almoxarifado de processo e no  |
|           | almoxarifado de estoque.                                      |
|-----------+---------------------------------------------------------------|
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOPA02Sld()
Local _nCnt1 := 1
Local _nCnt2 := 1
Local _nCnt3 := 1

ProcRegua(Len(_aProds))

For _nCnt1 := 1 to Len(_aProds)
	
	IncProc()
	
	// Verifica o saldo no almoxarifado do empenho
	_aSaldo := SldPorLote(_aProds[_nCnt1][1],_aProds[_nCnt1][2],_aProds[_nCnt1][6],,_aProds[_nCnt1][3],_aProds[_nCnt1][4],_aProds[_nCnt1][5],,,.T.)
	If Len(_aSaldo) > 0
		For _nCnt2 := 1 to Len(_aSaldo)
			RecLock("SLDD",.T.)
			SLDD->PRODUTO  := _aProds[_nCnt1][01]
			SLDD->ALMOX    := _aSaldo[_nCnt2][11]
			SLDD->LOTE     := _aSaldo[_nCnt2][01]
			SLDD->SUB_LOTE := _aSaldo[_nCnt2][02]
			SLDD->ENDERECO := _aSaldo[_nCnt2][03]
			SLDD->VALIDADE := _aSaldo[_nCnt2][07]
			SLDD->QUANT    := _aSaldo[_nCnt2][05]
			SLDD->N_SERIE  := _aSaldo[_nCnt2][04]
			SLDD->(MsUnLock())
		Next _nCnt2
	EndIf
	
	// Verifica o saldo no almoxarifado de estoque
	If Alltrim(_aProds[_nCnt1][2]) <> _cLocEst
		_aSaldo := SldPorLote(_aProds[_nCnt1][1],_cLocEst,_aProds[_nCnt1][6])
		
		If Len(_aSaldo) > 0
			For _nCnt3 := 1 to Len(_aSaldo)
				RecLock("SLDO",.T.)
				SLDO->PRODUTO  := _aProds[_nCnt1][01]
				SLDO->ALMOX    := _aSaldo[_nCnt3][11]
				SLDO->LOTE     := _aSaldo[_nCnt3][01]
				SLDO->SUB_LOTE := _aSaldo[_nCnt3][02]
				SLDO->ENDERECO := _aSaldo[_nCnt3][03]
				SLDO->VALIDADE := _aSaldo[_nCnt3][07]
				SLDO->QUANT    := _aSaldo[_nCnt3][05]
				SLDO->N_SERIE  := _aSaldo[_nCnt3][04]
				SLDO->(MsUnLock())
			Next _nCnt3
		EndIf
	EndIf
	
Next _nCnt1

Return



/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02Trf  | Autor | Cristiano Gomes Cunha  | Data | 22/09/08 |
|-----------+---------------------------------------------------------------|
| Descrição | Distribui a quantidade disponível.                            |
|-----------+---------------------------------------------------------------|
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOPA02Trf()
Local _nCnt4 := 1

aSort(_aEstru2,,,{|x,y| x[9] + x[1] + x[2] + x[5] + x[6] + x[3] < y[9] + y[1] + y[2] + y[5] + y[6] + y[3]})
aSort(_aEstru ,,,{|x,y| x[9] + x[1] + x[2] + x[5] + x[6] + x[3] < y[9] + y[1] + y[2] + y[5] + y[6] + y[3]})

ProcRegua(Len(_aEstru) + Len(_aEstru2))

For _nCnt4 := 1 to Len(_aEstru2)
	
	IncProc()
	
	_nQuant  := _aEstru2[_nCnt4][8]
	_nQFalta := _nQuant
	
	While .T.
		
		_aDados  := {}
		_nSaldo  := 0
		
		_cCodPro := _aEstru2[_nCnt4][1]
		_cLocPro := _aEstru2[_nCnt4][2]
		_cLotPro := _aEstru2[_nCnt4][5]
		_cSbLPro := _aEstru2[_nCnt4][6]
		_cEndPro := _aEstru2[_nCnt4][3]
		
		_cChave := _cCodPro + _cLocPro + _cLotPro + _cSbLPro + _cEndPro
		
		_lAtende := .F.
		
		If !Empty(Alltrim(_cLotPro)) .Or. !Empty(Alltrim(_cSbLPro)) .Or. !Empty(Alltrim(_cEndPro))
			dbSelectArea("SLDD")
			SLDD->(dbGoTop())
			If SLDD->(dbSeek(_cChave))
				While !SLDD->(Eof()) .And. (((SLDD->(PRODUTO + ALMOX + LOTE + SUB_LOTE + ENDERECO) == _cChave) .And. (SLDD->QUANT == 0)) .OR. ALMOX $ GetNewPar("MV_YARMZVL","12/13/14/15"))
					SLDD->(dbSkip())
				EndDo
				If SLDD->(PRODUTO + ALMOX + LOTE + SUB_LOTE + ENDERECO) == _cChave
					_nSaldo := SLDD->QUANT
					If SLDD->QUANT < _nQFalta
						aAdd(_aDados,1)							//Tipo
						aAdd(_aDados,_aEstru2[_nCnt4][1])		//Produto
						aAdd(_aDados,_nQFalta)					//Quantidade Necessária
						aAdd(_aDados,SLDD->LOTE)				//Lote
						aAdd(_aDados,SLDD->SUB_LOTE)			//Sub-Lote
						aAdd(_aDados,SLDD->ENDERECO)			//Endereço
						aAdd(_aDados,SLDD->N_SERIE)				//Número de Série
						aAdd(_aDados,SLDD->VALIDADE) 			//Validade do Lote
						aAdd(_aDados,_aEstru2[_nCnt4][9])		//Ordem de Produção
						aAdd(_aDados,CriaVar("D3_LOCAL"))		//Local Origem
						aAdd(_aDados,SLDD->ALMOX)				//Local Destino
						aAdd(_aDados,SLDD->QUANT)	  			//Saldo Disponível no Almoxarifado Destino
						aAdd(_aDados,0)							//Quantidade a Transferir
						aAdd(_aDados,_aEstru2[_nCnt4][10])		//Tabela
						aAdd(_aDados,_aEstru2[_nCnt4][11])		//Recno SD4
						aAdd(_aDados,_aEstru2[_nCnt4][12])		//TRT
						aAdd(_aDados,_aEstru2[_nCnt4][13])		//Fornecedor
						aAdd(_aDados,_aEstru2[_nCnt4][14])		//Loja
						aAdd(_aDados,_aEstru2[_nCnt4][15])		//Ped.Benef
						aAdd(_aDados,_aEstru2[_nCnt4][16])		//Ped.Compra
						aAdd(_aDados,_aEstru2[_nCnt4][17])		//Item Ped.Compra
						
						_nQFalta -= SLDD->QUANT
						
						RecLock("SLDD",.F.)
						SLDD->QUANT := 0
						SLDD->(MsUnLock())
					Else
						_lAtende := .T.
					EndIf
				Else
					Exit
				EndIf
			Else
				Exit
			EndIf
		Else
			dbSelectArea("SLDD")
			SLDD->(dbGoTop())
			If SLDD->(dbSeek(_cCodPro + _cLocPro))
				While !SLDD->(Eof()) .And. (((SLDD->(PRODUTO + ALMOX) == _cCodPro + _cLocPro) .And. (SLDD->QUANT == 0)) .OR. ALMOX $ GetNewPar("MV_YARMZVL","12/13/14/15"))
					SLDD->(dbSkip())
				EndDo
				If SLDD->(PRODUTO + ALMOX) == _cCodPro + _cLocPro
					_nSaldo := SLDD->QUANT
					If SLDD->QUANT < _nQFalta
						aAdd(_aDados,1)							//Tipo
						aAdd(_aDados,_aEstru2[_nCnt4][1])		//Produto
						aAdd(_aDados,_nQFalta)					//Quantidade Necessária
						aAdd(_aDados,SLDD->LOTE)				//Lote
						aAdd(_aDados,SLDD->SUB_LOTE)			//Sub-Lote
						aAdd(_aDados,SLDD->ENDERECO)			//Endereço
						aAdd(_aDados,SLDD->N_SERIE)				//Número de Série
						aAdd(_aDados,SLDD->VALIDADE) 			//Validade do Lote
						aAdd(_aDados,_aEstru2[_nCnt4][9])		//Ordem de Produção
						aAdd(_aDados,CriaVar("D3_LOCAL"))		//Local Origem
						aAdd(_aDados,SLDD->ALMOX)				//Local Destino
						aAdd(_aDados,SLDD->QUANT)	  			//Saldo Disponível no Almoxarifado Destino
						aAdd(_aDados,0)							//Quantidade a Transferir
						aAdd(_aDados,_aEstru2[_nCnt4][10])		//Tabela
						aAdd(_aDados,_aEstru2[_nCnt4][11])		//Recno SD4
						aAdd(_aDados,_aEstru2[_nCnt4][12])		//TRT
						aAdd(_aDados,_aEstru2[_nCnt4][13])		//Fornecedor
						aAdd(_aDados,_aEstru2[_nCnt4][14])		//Loja
						aAdd(_aDados,_aEstru2[_nCnt4][15])		//Ped.Benef
						aAdd(_aDados,_aEstru2[_nCnt4][16])		//Ped.Compra
						aAdd(_aDados,_aEstru2[_nCnt4][17])		//Item Ped.Compra
						
						_nQFalta -= SLDD->QUANT
						
						RecLock("SLDD",.F.)
						SLDD->QUANT := 0
						SLDD->(MsUnLock())
					Else
						_lAtende := .T.
					EndIf
				Else
					Exit
				EndIf
			Else
				Exit
			EndIf
		EndIf
		
		If _lAtende
			aAdd(_aDados,1)							//Tipo
			aAdd(_aDados,_aEstru2[_nCnt4][1])		//Produto
			aAdd(_aDados,_aEstru2[_nCnt4][8])		//Quantidade Necessária
			aAdd(_aDados,SLDD->LOTE)				//Lote
			aAdd(_aDados,SLDD->SUB_LOTE)			//Sub-Lote
			aAdd(_aDados,SLDD->ENDERECO)			//Endereço
			aAdd(_aDados,SLDD->N_SERIE)				//Número de Série
			aAdd(_aDados,SLDD->VALIDADE) 			//Validade do Lote
			aAdd(_aDados,_aEstru2[_nCnt4][9])		//Ordem de Produção
			aAdd(_aDados,CriaVar("D3_LOCAL"))		//Local Origem
			aAdd(_aDados,SLDD->ALMOX)				//Local Destino
			aAdd(_aDados,SLDD->QUANT)	  			//Saldo Disponível no Almoxarifado Destino
			aAdd(_aDados,0)							//Quantidade a Transferir
			aAdd(_aDados,_aEstru2[_nCnt4][10])		//Tabela
			aAdd(_aDados,_aEstru2[_nCnt4][11])		//Recno SD4
			aAdd(_aDados,_aEstru2[_nCnt4][12])		//TRT
			aAdd(_aDados,_aEstru2[_nCnt4][13])		//Fornecedor
			aAdd(_aDados,_aEstru2[_nCnt4][14])		//Loja
			aAdd(_aDados,_aEstru2[_nCnt4][15])		//Ped.Benef
			aAdd(_aDados,_aEstru2[_nCnt4][16])		//Ped.Compra
			aAdd(_aDados,_aEstru2[_nCnt4][17])		//Item Ped.Compra
			aAdd(_aDados,_aEstru2[_nCnt4][18])		//NUm SC
			
			RecLock("SLDD",.F.)
			SLDD->QUANT -= _nQFalta
			SLDD->(MsUnLock())
			
			_nQFalta := 0
		EndIf
		
		If Len(_aDados) > 0
			YOPA02Add(_aDados,@_aSelec)
		EndIf
		
		If _nQFalta == 0
			Exit
		EndIf
		
	EndDo
	
	If _nQFalta > 0 .And. (_cLocPro <> _cLocEst)
		
		While _nQFalta > 0
			
			_aDados  := {}
			_nQtdTrf := 0
			
			dbSelectArea("SLDO")
			SLDO->(dbGoTop())
			If SLDO->(dbSeek(_cCodPro + _cLocEst))
				While !SLDO->(Eof()) .And. (SLDO->(PRODUTO + ALMOX) == _cCodPro + _cLocEst) .And. (SLDO->QUANT == 0)
					SLDO->(dbSkip())
				EndDo
				If (SLDO->(PRODUTO + ALMOX) == (_cCodPro + _cLocEst))
					If SLDO->QUANT <= _nQFalta
						_nQtdTrf := SLDO->QUANT
					Else
						_nQtdTrf := _nQFalta
					EndIf
					
				EndIf
				If _nQtdTrf <> 0
					aAdd(_aDados,2)						//Tipo
					aAdd(_aDados,_aEstru2[_nCnt4][1])	//Produto
					aAdd(_aDados,_nQFalta)				//Quantidade Necessária
					aAdd(_aDados,SLDO->LOTE)			//Lote
					aAdd(_aDados,SLDO->SUB_LOTE)		//Sub-Lote
					aAdd(_aDados,SLDO->ENDERECO)		//Endereço
					aAdd(_aDados,SLDO->N_SERIE)			//Número de Série
					aAdd(_aDados,SLDO->VALIDADE)		//Validade do Lote
					aAdd(_aDados,_aEstru2[_nCnt4][9])	//Ordem de Produção
					aAdd(_aDados,SLDO->ALMOX)			//Local Origem
					aAdd(_aDados,_aEstru2[_nCnt4][2])	//Local Destino
					aAdd(_aDados,_nSaldo)				//Saldo Disponível no Almoxarifado Destino
					aAdd(_aDados,_nQtdTrf)				//Quantidade a Transferir
					aAdd(_aDados,_aEstru2[_nCnt4][10])	//Tabela
					aAdd(_aDados,_aEstru2[_nCnt4][11])	//Recno SD4
					aAdd(_aDados,_aEstru2[_nCnt4][12])	//TRT
					aAdd(_aDados,_aEstru2[_nCnt4][13])		//Fornecedor
					aAdd(_aDados,_aEstru2[_nCnt4][14])		//Loja
					aAdd(_aDados,_aEstru2[_nCnt4][15])		//Ped.Benef
					aAdd(_aDados,_aEstru2[_nCnt4][16])		//Ped.Compra
					aAdd(_aDados,_aEstru2[_nCnt4][17])		//Item Ped.Compra
					aAdd(_aDados,_aEstru2[_nCnt4][18])		//NUm SC
					
					RecLock("SLDO",.F.)
					SLDO->QUANT -= _nQtdTrf
					SLDO->(MsUnLock())
					
					_nQFalta -= _nQtdTrf
					_nQuant  -= _nQtdTrf
				Else
					aAdd(_aDados,2)							//Tipo
					aAdd(_aDados,_aEstru2[_nCnt4][1])		//Produto
					aAdd(_aDados,_nQFalta)					//Quantidade Necessária
					aAdd(_aDados,CriaVar("D3_LOTECTL"))		//Lote
					aAdd(_aDados,CriaVar("D3_NUMLOTE"))		//Sub-Lote
					aAdd(_aDados,CriaVar("D3_LOCALIZ"))		//Endereço
					aAdd(_aDados,CriaVar("D3_NUMSERIE"))	//Número de Série
					aAdd(_aDados,CriaVar("D3_DTVALID"))		//Validade do Lote
					aAdd(_aDados,_aEstru2[_nCnt4][9])		//Ordem de Produção
					aAdd(_aDados,CriaVar("D3_LOCAL"))		//Local Origem
					aAdd(_aDados,_aEstru2[_nCnt4][2])		//Local Destino
					aAdd(_aDados,0)				  			//Saldo Disponível no Almoxarifado Destino
					aAdd(_aDados,0)							//Quantidade a Transferir
					aAdd(_aDados,_aEstru2[_nCnt4][10])		//Tabela
					aAdd(_aDados,_aEstru2[_nCnt4][11])		//Recno SD4
					aAdd(_aDados,_aEstru2[_nCnt4][12])		//TRT
					aAdd(_aDados,_aEstru2[_nCnt4][13])		//Fornecedor
					aAdd(_aDados,_aEstru2[_nCnt4][14])		//Loja
					aAdd(_aDados,_aEstru2[_nCnt4][15])		//Ped.Benef
					aAdd(_aDados,_aEstru2[_nCnt4][16])		//Ped.Compra
					aAdd(_aDados,_aEstru2[_nCnt4][17])		//Item Ped.Compra
					aAdd(_aDados,_aEstru2[_nCnt4][18])		//NUm SC
					
					_nQFalta := 0
				EndIf
			Else
				aAdd(_aDados,2)							//Tipo
				aAdd(_aDados,_aEstru2[_nCnt4][1])		//Produto
				aAdd(_aDados,_nQFalta)					//Quantidade Necessária
				aAdd(_aDados,CriaVar("D3_LOTECTL"))		//Lote
				aAdd(_aDados,CriaVar("D3_NUMLOTE"))		//Sub-Lote
				aAdd(_aDados,CriaVar("D3_LOCALIZ"))		//Endereço
				aAdd(_aDados,CriaVar("D3_NUMSERIE"))	//Número de Série
				aAdd(_aDados,CriaVar("D3_DTVALID"))		//Validade do Lote
				aAdd(_aDados,_aEstru2[_nCnt4][9])		//Ordem de Produção
				aAdd(_aDados,CriaVar("D3_LOCAL"))		//Local Origem
				aAdd(_aDados,_aEstru2[_nCnt4][2])		//Local Destino
				aAdd(_aDados,0)				  			//Saldo Disponível no Almoxarifado Destino
				aAdd(_aDados,0)							//Quantidade a Transferir
				aAdd(_aDados,_aEstru2[_nCnt4][10])		//Tabela
				aAdd(_aDados,_aEstru2[_nCnt4][11])		//Recno SD4
				aAdd(_aDados,_aEstru2[_nCnt4][12])		//TRT
				aAdd(_aDados,_aEstru2[_nCnt4][13])		//Fornecedor
				aAdd(_aDados,_aEstru2[_nCnt4][14])		//Loja
				aAdd(_aDados,_aEstru2[_nCnt4][15])		//Ped.Benef
				aAdd(_aDados,_aEstru2[_nCnt4][16])		//Ped.Compra
				aAdd(_aDados,_aEstru2[_nCnt4][17])		//Item Ped.Compra
				aAdd(_aDados,_aEstru2[_nCnt4][18])		//NUm SC
				
				_nQFalta := 0
			EndIf
			
			If Len(_aDados) > 0
				YOPA02Add(_aDados,@_aSelec)
			EndIf
			
		EndDo
		
	EndIf
	
Next _nCnt4

For _nCnt4 := 1 to Len(_aEstru)
	
	IncProc()
	
	_nQuant  := _aEstru[_nCnt4][8]
	_nQFalta := _nQuant
	
	While .T.
		
		_aDados  := {}
		_nSaldo  := 0
		
		_cCodPro := _aEstru[_nCnt4][1]
		_cLocPro := _aEstru[_nCnt4][2]
		_cLotPro := _aEstru[_nCnt4][5]
		_cSbLPro := _aEstru[_nCnt4][6]
		_cEndPro := _aEstru[_nCnt4][3]
		
		_cChave := _cCodPro + _cLocPro + _cLotPro + _cSbLPro
		
		_lAtende := .F.
		
		If !Empty(Alltrim(_cLotPro)) .Or. !Empty(Alltrim(_cSbLPro))
			dbSelectArea("SLDD")
			SLDD->(dbGoTop())
			If SLDD->(dbSeek(_cChave))
				While !SLDD->(Eof()) .And. (((SLDD->(PRODUTO + ALMOX + LOTE + SUB_LOTE) == _cChave) .And. (SLDD->QUANT == 0)) .OR. ALMOX $ GetNewPar("MV_YARMZVL","12/13/14/15"))
					SLDD->(dbSkip())
				EndDo
				If SLDD->(PRODUTO + ALMOX + LOTE + SUB_LOTE) == _cChave
					_nSaldo := SLDD->QUANT
					If SLDD->QUANT < _nQFalta
						aAdd(_aDados,1)							//Tipo
						aAdd(_aDados,_aEstru[_nCnt4][1])		//Produto
						aAdd(_aDados,_nQFalta)					//Quantidade Necessária
						aAdd(_aDados,SLDD->LOTE)				//Lote
						aAdd(_aDados,SLDD->SUB_LOTE)			//Sub-Lote
						aAdd(_aDados,SLDD->ENDERECO)			//Endereço
						aAdd(_aDados,SLDD->N_SERIE)				//Número de Série
						aAdd(_aDados,SLDD->VALIDADE) 			//Validade do Lote
						aAdd(_aDados,_aEstru[_nCnt4][9])		//Ordem de Produção
						aAdd(_aDados,CriaVar("D3_LOCAL"))		//Local Origem
						aAdd(_aDados,SLDD->ALMOX)				//Local Destino
						aAdd(_aDados,SLDD->QUANT)	  			//Saldo Disponível no Almoxarifado Destino
						aAdd(_aDados,0)							//Quantidade a Transferir
						aAdd(_aDados,_aEstru[_nCnt4][10])		//Tabela
						aAdd(_aDados,_aEstru[_nCnt4][11])		//Recno SD4
						aAdd(_aDados,_aEstru[_nCnt4][12])		//TRT
						aAdd(_aDados,_aEstru[_nCnt4][13])		//Fornecedor
						aAdd(_aDados,_aEstru[_nCnt4][14])		//Loja
						aAdd(_aDados,_aEstru[_nCnt4][15])		//Ped.Benef
						aAdd(_aDados,_aEstru[_nCnt4][16])		//Ped.Compra
						aAdd(_aDados,_aEstru[_nCnt4][17])		//Item Ped.Compra
						aAdd(_aDados,_aEstru[_nCnt4][18])		//NUm SC
						aAdd(_aDados,_aEstru[_nCnt4][19])		//Fornecedor 2
						aAdd(_aDados,_aEstru[_nCnt4][20])		//Loja 2
						aAdd(_aDados,_aEstru[_nCnt4][21])		//Ped.Benef 2
						aAdd(_aDados,_aEstru[_nCnt4][22])		//Ped.Compra 2
						aAdd(_aDados,_aEstru[_nCnt4][23])		//Item Ped.Compra 2						

						_nQFalta -= SLDD->QUANT
						
						RecLock("SLDD",.F.)
						SLDD->QUANT := 0
						SLDD->(MsUnLock())
					Else
						_lAtende := .T.
					EndIf
				Else
					Exit
				EndIf
			Else
				Exit
			EndIf
		Else
			dbSelectArea("SLDD")
			SLDD->(dbGoTop())
			If SLDD->(dbSeek(_cCodPro + _cLocPro))
				While !SLDD->(Eof()) .And. (((SLDD->(PRODUTO + ALMOX) == _cCodPro + _cLocPro) .And. (SLDD->QUANT == 0)) .OR. SLDD->ALMOX $ GetNewPar("MV_YARMZVL","12/13/14/15"))
					SLDD->(dbSkip())
				EndDo
				If SLDD->(PRODUTO + ALMOX) == _cCodPro + _cLocPro
					_nSaldo := SLDD->QUANT
					If SLDD->QUANT < _nQFalta
						aAdd(_aDados,1)							//Tipo
						aAdd(_aDados,_aEstru[_nCnt4][1])		//Produto
						aAdd(_aDados,_nQFalta)					//Quantidade Necessária
						aAdd(_aDados,SLDD->LOTE)				//Lote
						aAdd(_aDados,SLDD->SUB_LOTE)			//Sub-Lote
						aAdd(_aDados,SLDD->ENDERECO)			//Endereço
						aAdd(_aDados,SLDD->N_SERIE)				//Número de Série
						aAdd(_aDados,SLDD->VALIDADE) 			//Validade do Lote
						aAdd(_aDados,_aEstru[_nCnt4][9])		//Ordem de Produção
						aAdd(_aDados,CriaVar("D3_LOCAL"))		//Local Origem
						aAdd(_aDados,SLDD->ALMOX)				//Local Destino
						aAdd(_aDados,SLDD->QUANT)	  			//Saldo Disponível no Almoxarifado Destino
						aAdd(_aDados,0)							//Quantidade a Transferir
						aAdd(_aDados,_aEstru[_nCnt4][10])		//Tabela
						aAdd(_aDados,_aEstru[_nCnt4][11])		//Recno SD4
						aAdd(_aDados,_aEstru[_nCnt4][12])		//TRT
						aAdd(_aDados,_aEstru[_nCnt4][13])		//Fornecedor
						aAdd(_aDados,_aEstru[_nCnt4][14])		//Loja
						aAdd(_aDados,_aEstru[_nCnt4][15])		//Ped.Benef
						aAdd(_aDados,_aEstru[_nCnt4][16])		//Ped.Compra
						aAdd(_aDados,_aEstru[_nCnt4][17])		//Item Ped.Compra
						aAdd(_aDados,_aEstru[_nCnt4][18])		//NUm SC
						aAdd(_aDados,_aEstru[_nCnt4][19])		//Fornecedor 2
						aAdd(_aDados,_aEstru[_nCnt4][20])		//Loja 2
						aAdd(_aDados,_aEstru[_nCnt4][21])		//Ped.Benef 2
						aAdd(_aDados,_aEstru[_nCnt4][22])		//Ped.Compra 2
						aAdd(_aDados,_aEstru[_nCnt4][23])		//Item Ped.Compra 2							
						
						_nQFalta -= SLDD->QUANT
						
						RecLock("SLDD",.F.)
						SLDD->QUANT := 0
						SLDD->(MsUnLock())
					Else
						_lAtende := .T.
					EndIf
				Else
					Exit
				EndIf
			Else
				Exit
			EndIf
		EndIf
		
		If _lAtende
			aAdd(_aDados,1)							//Tipo
			aAdd(_aDados,_aEstru[_nCnt4][1])		//Produto
			aAdd(_aDados,_aEstru[_nCnt4][8])		//Quantidade Necessária
			aAdd(_aDados,SLDD->LOTE)				//Lote
			aAdd(_aDados,SLDD->SUB_LOTE)			//Sub-Lote
			aAdd(_aDados,SLDD->ENDERECO)			//Endereço
			aAdd(_aDados,SLDD->N_SERIE)				//Número de Série
			aAdd(_aDados,SLDD->VALIDADE) 			//Validade do Lote
			aAdd(_aDados,_aEstru[_nCnt4][9])		//Ordem de Produção
			aAdd(_aDados,CriaVar("D3_LOCAL"))		//Local Origem
			aAdd(_aDados,SLDD->ALMOX)				//Local Destino
			aAdd(_aDados,SLDD->QUANT)	  			//Saldo Disponível no Almoxarifado Destino
			aAdd(_aDados,0)							//Quantidade a Transferir
			aAdd(_aDados,_aEstru[_nCnt4][10])		//Tabela
			aAdd(_aDados,_aEstru[_nCnt4][11])		//Recno SD4
			aAdd(_aDados,_aEstru[_nCnt4][12])		//TRT
			aAdd(_aDados,_aEstru[_nCnt4][13])		//Fornecedor
			aAdd(_aDados,_aEstru[_nCnt4][14])		//Loja
			aAdd(_aDados,_aEstru[_nCnt4][15])		//Ped.Benef
			aAdd(_aDados,_aEstru[_nCnt4][16])		//Ped.Compra
			aAdd(_aDados,_aEstru[_nCnt4][17])		//Item Ped.Compra
			aAdd(_aDados,_aEstru[_nCnt4][18])		//NUm SC
			aAdd(_aDados,_aEstru[_nCnt4][19])		//Fornecedor 2
			aAdd(_aDados,_aEstru[_nCnt4][20])		//Loja 2
			aAdd(_aDados,_aEstru[_nCnt4][21])		//Ped.Benef 2
			aAdd(_aDados,_aEstru[_nCnt4][22])		//Ped.Compra 2
			aAdd(_aDados,_aEstru[_nCnt4][23])		//Item Ped.Compra 2				
			
			RecLock("SLDD",.F.)
			SLDD->QUANT -= _nQFalta
			SLDD->(MsUnLock())
			
			_nQFalta := 0
		EndIf
		
		If Len(_aDados) > 0
			YOPA02Add(_aDados,@_aSelec)
		EndIf
		
		If _nQFalta == 0
			Exit
		EndIf
		
	EndDo
	
	If _nQFalta > 0 .And. (_cLocPro <> _cLocEst)
		
		While _nQFalta > 0
			
			_aDados  := {}
			_nQtdTrf := 0
			
			dbSelectArea("SLDO")
			SLDO->(dbGoTop())
			If SLDO->(dbSeek(_cCodPro + _cLocEst))
				While !SLDO->(Eof()) .And. (SLDO->(PRODUTO + ALMOX) == _cCodPro + _cLocEst) .And. (SLDO->QUANT == 0)
					SLDO->(dbSkip())
				EndDo
				If (SLDO->(PRODUTO + ALMOX) == (_cCodPro + _cLocEst))
					If SLDO->QUANT <= _nQFalta
						_nQtdTrf := SLDO->QUANT
					Else
						_nQtdTrf := _nQFalta
					EndIf
					
				EndIf
				If _nQtdTrf <> 0
					aAdd(_aDados,2)						//Tipo
					aAdd(_aDados,_aEstru[_nCnt4][1])	//Produto
					aAdd(_aDados,_nQFalta)				//Quantidade Necessária
					aAdd(_aDados,SLDO->LOTE)			//Lote
					aAdd(_aDados,SLDO->SUB_LOTE)		//Sub-Lote
					aAdd(_aDados,SLDO->ENDERECO)		//Endereço
					aAdd(_aDados,SLDO->N_SERIE)			//Número de Série
					aAdd(_aDados,SLDO->VALIDADE)		//Validade do Lote
					aAdd(_aDados,_aEstru[_nCnt4][9])	//Ordem de Produção
					aAdd(_aDados,SLDO->ALMOX)			//Local Origem
					aAdd(_aDados,_aEstru[_nCnt4][2])	//Local Destino
					aAdd(_aDados,_nSaldo)				//Saldo Disponível no Almoxarifado Destino
					aAdd(_aDados,_nQtdTrf)				//Quantidade a Transferir
					aAdd(_aDados,_aEstru[_nCnt4][10])	//Tabela
					aAdd(_aDados,_aEstru[_nCnt4][11])	//Recno SD4
					aAdd(_aDados,_aEstru[_nCnt4][12])	//TRT
					aAdd(_aDados,_aEstru[_nCnt4][13])	//Fornecedor
					aAdd(_aDados,_aEstru[_nCnt4][14])	//Loja
					aAdd(_aDados,_aEstru[_nCnt4][15])	//Ped.Benef
					aAdd(_aDados,_aEstru[_nCnt4][16])	//Ped.Compra
					aAdd(_aDados,_aEstru[_nCnt4][17])	//Item Ped.Compra
					aAdd(_aDados,_aEstru[_nCnt4][18])	//NUm SC
					aAdd(_aDados,_aEstru[_nCnt4][19])	//Fornecedor 2
					aAdd(_aDados,_aEstru[_nCnt4][20])	//Loja 2
					aAdd(_aDados,_aEstru[_nCnt4][21])	//Ped.Benef 2
					aAdd(_aDados,_aEstru[_nCnt4][22])	//Ped.Compra 2
					aAdd(_aDados,_aEstru[_nCnt4][23])	//Item Ped.Compra 2						
					
					RecLock("SLDO",.F.)
					SLDO->QUANT -= _nQtdTrf
					SLDO->(MsUnLock())
					
					_nQFalta -= _nQtdTrf
					_nQuant  -= _nQtdTrf
				Else
					aAdd(_aDados,2)							//Tipo
					aAdd(_aDados,_aEstru[_nCnt4][1])		//Produto
					aAdd(_aDados,_nQFalta)					//Quantidade Necessária
					aAdd(_aDados,CriaVar("D3_LOTECTL"))		//Lote
					aAdd(_aDados,CriaVar("D3_NUMLOTE"))		//Sub-Lote
					aAdd(_aDados,CriaVar("D3_LOCALIZ"))		//Endereço
					aAdd(_aDados,CriaVar("D3_NUMSERIE"))	//Número de Série
					aAdd(_aDados,CriaVar("D3_DTVALID"))		//Validade do Lote
					aAdd(_aDados,_aEstru[_nCnt4][9])		//Ordem de Produção
					aAdd(_aDados,CriaVar("D3_LOCAL"))		//Local Origem
					aAdd(_aDados,_aEstru[_nCnt4][2])		//Local Destino
					aAdd(_aDados,0)				  			//Saldo Disponível no Almoxarifado Destino
					aAdd(_aDados,0)							//Quantidade a Transferir
					aAdd(_aDados,_aEstru[_nCnt4][10])		//Tabela
					aAdd(_aDados,_aEstru[_nCnt4][11])		//Recno SD4
					aAdd(_aDados,_aEstru[_nCnt4][12])		//TRT
					aAdd(_aDados,_aEstru[_nCnt4][13])		//Fornecedor
					aAdd(_aDados,_aEstru[_nCnt4][14])		//Loja
					aAdd(_aDados,_aEstru[_nCnt4][15])		//Ped.Benef
					aAdd(_aDados,_aEstru[_nCnt4][16])		//Ped.Compra
					aAdd(_aDados,_aEstru[_nCnt4][17])		//Item Ped.Compra
					aAdd(_aDados,_aEstru[_nCnt4][18])		//NUm SC
					aAdd(_aDados,_aEstru[_nCnt4][19])		//Fornecedor 2
					aAdd(_aDados,_aEstru[_nCnt4][20])		//Loja 2
					aAdd(_aDados,_aEstru[_nCnt4][21])		//Ped.Benef 2
					aAdd(_aDados,_aEstru[_nCnt4][22])		//Ped.Compra 2
					aAdd(_aDados,_aEstru[_nCnt4][23])		//Item Ped.Compra 2						
					
					_nQFalta := 0
				EndIf
			Else
				aAdd(_aDados,2)							//Tipo
				aAdd(_aDados,_aEstru[_nCnt4][1])		//Produto
				aAdd(_aDados,_nQFalta)					//Quantidade Necessária
				aAdd(_aDados,CriaVar("D3_LOTECTL"))		//Lote
				aAdd(_aDados,CriaVar("D3_NUMLOTE"))		//Sub-Lote
				aAdd(_aDados,CriaVar("D3_LOCALIZ"))		//Endereço
				aAdd(_aDados,CriaVar("D3_NUMSERIE"))	//Número de Série
				aAdd(_aDados,CriaVar("D3_DTVALID"))		//Validade do Lote
				aAdd(_aDados,_aEstru[_nCnt4][9])		//Ordem de Produção
				aAdd(_aDados,CriaVar("D3_LOCAL"))		//Local Origem
				aAdd(_aDados,_aEstru[_nCnt4][2])		//Local Destino
				aAdd(_aDados,0)				  			//Saldo Disponível no Almoxarifado Destino
				aAdd(_aDados,0)							//Quantidade a Transferir
				aAdd(_aDados,_aEstru[_nCnt4][10])		//Tabela
				aAdd(_aDados,_aEstru[_nCnt4][11])		//Recno SD4
				aAdd(_aDados,_aEstru[_nCnt4][12])		//TRT
				aAdd(_aDados,_aEstru[_nCnt4][13])		//Fornecedor
				aAdd(_aDados,_aEstru[_nCnt4][14])		//Loja
				aAdd(_aDados,_aEstru[_nCnt4][15])		//Ped.Benef
				aAdd(_aDados,_aEstru[_nCnt4][16])		//Ped.Compra
				aAdd(_aDados,_aEstru[_nCnt4][17])		//Item Ped.Compra
				aAdd(_aDados,_aEstru[_nCnt4][18])		//NUm SC
				aAdd(_aDados,_aEstru[_nCnt4][19])		//Fornecedor 2
				aAdd(_aDados,_aEstru[_nCnt4][20])		//Loja 2
				aAdd(_aDados,_aEstru[_nCnt4][21])		//Ped.Benef 2
				aAdd(_aDados,_aEstru[_nCnt4][22])		//Ped.Compra 2
				aAdd(_aDados,_aEstru[_nCnt4][23])		//Item Ped.Compra 2					
				
				_nQFalta := 0
			EndIf
			
			If Len(_aDados) > 0
				YOPA02Add(_aDados,@_aSelec)
			EndIf
			
		EndDo
		
	EndIf
	
Next _nCnt4

Return


/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02Lot  | Autor | Cristiano G. Cunha     | Data | 28/04/09 |
+-----------+---------------------------------------------------------------+
| Descrição | Rotina que busca os lotes do produto para o usuário informar  |
|           | qual lote será utilizado na transferência.                    |
+-----------+---------------------------------------------------------------+
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOPA02Lot()

Local _aQtdUti := {}
Local _aLotes := {}
Local _nSelec := 0
Local nI := 1
Local _nCnt6 := 1

_aAreaAtu := GetArea()

//Abatendo quantidade ja utilizada na tela do Saldo do Lote para evitar, Exemplo :
//Produto 001 - Lote A - Saldo Lote 10 Unidades - 8 Pecas selecionadas do Lote - Quantidade Disponivel do Lote 2
//Produto 001 - Lote B - porem quero usar o resto do lote A, o sistema estava permitindo usar as 10 pecas pois nao abatendo as 8 pecas do lancameto anterior.
//Subitraindo a quantidade do lote utilizado para que nao seja usado quantidade erra e trave a transferencia e o empenho
//Anderson Messias - 17/06/2009
For nI := 1 to len(_aLbxIt)
	if _aLbxIt[nI][2] == _aLbxIt[_oLbxIt:nAt,2]
		_nPos := aScan(_aQtdUti,{|x| x[1]+x[2]+x[3]+x[4] == _aLbxIt[nI,2]+_aLbxIt[nI,13]+_aLbxIt[nI,14]+_aLbxIt[nI,15] })
		if _nPos > 0
			_aQtdUti[_nPos][5] += _aLbxIt[nI,11]
		else
			aadd(_aQtdUti,{_aLbxIt[nI,2],_aLbxIt[nI,13],_aLbxIt[nI,14],_aLbxIt[nI,15],_aLbxIt[nI,11] })
		endif
	endif
Next

// Verifica os lotes disponíveis no almoxarifado de estoque
_nTrfQtd := _aLbxIt[_oLbxIt:nAt,11]
_aSaldo := SldPorLote(_aLbxIt[_oLbxIt:nAt,2],_cLocEst,999999999)
If Len(_aSaldo) > 0
	For _nCnt6 := 1 to Len(_aSaldo)
		_nPos := aScan(_aQtdUti,{|x| x[1]+x[2]+x[3]+x[4] == _aLbxIt[_oLbxIt:nAt,2]+_aSaldo[_nCnt6,1]+_aSaldo[_nCnt6,2]+_aSaldo[_nCnt6,3] })
		_nQtdUsada := 0
		if _nPos > 0
			_nQtdUsada := _aQtdUti[_nPos][5]
		endif
		
		if (_aSaldo[_nCnt6,5]-_nQtdUsada) > 0
			aAdd(_aLotes,{(_aSaldo[_nCnt6,5]-_nQtdUsada),_aSaldo[_nCnt6,1],_aSaldo[_nCnt6,2],_aSaldo[_nCnt6,3],_aSaldo[_nCnt6,7],_aSaldo[_nCnt6,4]})
		endif
	Next _nCnt6
EndIf

If Len(_aLotes) > 0
	aHeader := { "Quantidade", "Lote Origem", "Sub-Lote Origem", "Endereço Origem", "Validade", "Número de Série" }

	aSize := GerSize(aHeader, _aLotes)
	
	YOACD01CAP(cOP)
	@ 03,00 VtSay "Lotes Disponiveis"
	nPos := VTaBrowse(3,0,VTMaxRow(),VTmaxCol(),aHeader,aCols, aSize)

	// Exibe menu de opções para a OP
	aOpts := { "Ok", "Cancelar" }
	nOpt  := VTaChoice(4,0,5,8,aOpts)
	
	If _nSelec > 0
		_nTrfQtd := _aLbxIt[_oLbxIt:nAt,11]
		If _aLotes[_nSelec,1] > _nTrfQtd
			_aLbxIt[_oLbxIt:nAt,11] := _nTrfQtd
		Else
			_aLbxIt[_oLbxIt:nAt,11] := _aLotes[_nSelec,1]
		EndIf
		_aLbxIt[_oLbxIt:nAt,08] := _aLotes[_nSelec,2] //Anderson Messias - 05/06/2009 - ao mudar o lote de origem, deve-se mudar o lote de destino tambem
		_aLbxIt[_oLbxIt:nAt,13] := _aLotes[_nSelec,2]
		_aLbxIt[_oLbxIt:nAt,14] := _aLotes[_nSelec,3]
		_aLbxIt[_oLbxIt:nAt,15] := _aLotes[_nSelec,4]
		_aLbxIt[_oLbxIt:nAt,16] := _aLotes[_nSelec,5]
		_aLbxIt[_oLbxIt:nAt,17] := _aLotes[_nSelec,6]
		_oLbxIt:Refresh()
	EndIf
	
Else
	
	MsgAlert("Não existe(m) lote(s) com saldo para este produto!!!")
	
EndIf

RestArea(_aAreaAtu)

Return

/*/
+---------------------------------------------------------------------------+
| Função    | YOEmpMod2  | Autor | Anderson Sano          | Data | 06/12/22 |
+-----------+---------------------------------------------------------------+
| Descrição | Rotina que realiza o ajuste de empenho automaticamente.       |
|           | Criado para substituir o YOPA02Emp porque mudou para ModII.   |
+-----------+---------------------------------------------------------------+
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOEmpMod2(_nOpc,_cD4Cod,_cD4OP,_cD4TRT,_cD4Local,_nD4QtdOri,_nD4Quant,_dD4DtEmp,_cD4Lote,_cD4SubLote,_cD4PagOp,_aBenef,_nRegSD4,_cOpOrig,_cSeqSD4)

Return U_YOEmpMd2(_nOpc,_cD4Cod,_cD4OP,_cD4TRT,_cD4Local,_nD4QtdOri,_nD4Quant,_dD4DtEmp,_cD4Lote,_cD4SubLote,_cD4PagOp,_aBenef,_nRegSD4,_cOpOrig,_cSeqSD4)

Static Function GerSize(aHeader, aCols)

Local nCol  := 1
Local nPos  := 1
Local aSize := {}

	// Tamanho de cada coluna
	For nCol := 1 To Len(aHeader)
		Aadd(aSize, Len(aHeader[nCol]))
	Next

	// aSize deve ser o tamanho do maior valor de cada coluna (cabecalho e dados)
	// Comparando o tamanho do cabecalho com o tamanho do valor de cada registro de cada coluna
	For nCol := 1 to Len(aCols)
		For nPos := 1 to Len(aHeader)
			cCampo := aCols[nCol][nPos]
			If Empty(cCampo)
				Loop
			EndIf

			// Se campo for nulo ou vazio, pula para o próximo
			// Se campo for numérico, converte para string
			// Se campo for data, converte para string
			If  valtype(cCampo) == "N"
				cCampo := cValToChar(cCampo)
			ElseIf  valtype(cCampo) == "D"
				cCampo := DTOC(cCampo)
			EndIf

			If aSize[nPos] < Len(cCampo)
				aSize[nPos] := Len(cCampo)
			EndIf
		Next
	Next

Return aSize
