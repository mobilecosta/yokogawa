#INCLUDE "TOTVS.CH
#INCLUDE "PROTHEUS.CH
#INCLUDE "TBICONN.CH"
#INCLUDE "APVT100.CH"

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
	
	// (HOME) Pagamento (YOACD01Pag), Visualizacao (YOACD01Vis), Impressao (YOACD01Imp) ou Sair (YOACD01Sair)
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
	Local aOpts := { "Pagamento", "Visualizacao", "Imprimir", "Sair" }
	Local aCols := {}
	Local aHeader := {}
	Local aSize := {}
	Local nOpt := 0
	Local nPos := 0
	Local nCol := 0
	
	// Cria um array para armazenar os dados da OP
	aCols := {}
	aAdd(aCols, { SC2->C2_NUM, SC2->C2_ITEM, SC2->C2_SEQUEN, SC2->C2_PRODUTO, SC2->C2_EMISSAO, SC2->C2_LOCAL, SC2->C2_QUANT })

	// cria cabecalho de exibicao da tela de browse da OP com o titulo das colunas
	aHeader := { fwX3Titulo("C2_OP"), fwX3Titulo("C2_ITEM"), fwX3Titulo("C2_SEQUEN"), fwX3Titulo("C2_PRODUTO"), fwX3Titulo("C2_EMISSAO"), fwX3Titulo("C2_LOCAL"), fwX3Titulo("C2_QUANT") }
	// Tamanho de cada coluna
	aSize := { Len(aHeader[1]), Len(aHeader[2]), Len(aHeader[3]), Len(aHeader[4]), Len(aHeader[5]), Len(aHeader[6]), Len(aHeader[7]) }

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
		YOACD01Imp(cOP)
	ElseIf nOpt == 4
		YOACD01Sair()
	EndIf
Return

// --- Funções de Exibição --------------------------------------------------

// Pagamento da OP
Static Function YOACD01Pag(cOP)
	Local aCombo := {"02-Almoxarifado","03-LM 2.5","04-Inspeção","08-Projeto P&P"}	// Tabela NNR
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

	_cLocEst := aCombo[nOpt]

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
					// aAdd(_aEstru, {SD4->D4_COD,SD4->D4_LOCAL,"","",SD4->D4_LOTECTL,SD4->D4_NUMLOTE,SD4->D4_DTVALID,SD4->D4_QUANT,_cNumOP,"SD4",SD4->(Recno()),SD4->D4_TRT,SD4->D4_YFORNEC,SD4->D4_YLOJA,SD4->D4_YPEDBEN,SD4->D4_YPEDCOM,SD4->D4_YPEDITE,SD4->D4_NUMSC,SD4->D4_YFORNE2,SD4->D4_YLOJA2,SD4->D4_YPEDBE2,SD4->D4_YPEDCO2,SD4->D4_YPEDIT2})
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

		YOACD01CAP(cOP)
		
		_cTitulo := "Transferências"

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
						_aLbxIt[nCol,31] }

			aAdd(aCols, AClone(aItem))
		Next

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
		
		// Exibe a tela de browse da OP e recebe a posicao do item selecionado
		YOACD01CAP(cOP)
		@ 03,00 VtSay "Selecione o a opcao desejada"
		nPos := VTaBrowse(3,0,VTMaxRow(),VTmaxCol(),aHeader,aCols, aSize)

		// Exibe menu de opções para a OP
		aOpts := { "Zera Qtde", "Qtde Transf.", "Ok", "Cancelar" }
		nOpt := VTaChoice(3,0,5,VTMaxCol(),aOpts)

		If nOpt == 0
			Return
		ElseIf nOpt == 1
			YOPA02Zer()
		ElseIf nOpt == 2
			YOPA02Qtd()
		EndIf
	EndIf

	_aReqOps	:= {}
	If _lGrv
		_aItens    := {}
		_aItAux    := {}
		_aItAuxTrf := {}
		lContinua := .T.
		
		//Guardando o Log do SD4 Antes da Alteração dos Emprenhos
		If SuperGetMV("MV_YOLOGOP",,.T.)
			//Guardando o Log do SD4 Antes da Alteração dos Emprenhos
			aItemLog := {}
			DBSelectArea("SD4")
			DBSetOrder(2)
			If DBSeek(xFilial("SD4")+cMV_PAR01)
				While !SD4->(Eof()) .AND. alltrim(SD4->D4_OP) == alltrim(cMV_PAR01)
					aDadLog := {}
					aadd(aDadLog,{"ZF_FILIAL",xFilial("SZF"),Nil})
					aadd(aDadLog,{"ZF_OP",cMV_PAR01,Nil})
					aadd(aDadLog,{"ZF_EMISSAO",dDataBase,Nil})
					aadd(aDadLog,{"ZF_HORA",Time(),Nil})
					aadd(aDadLog,{"ZF_USUARIO",Substr(cUsuario,7,15),Nil})
					aadd(aDadLog,{"ZF_TIPO","AN",Nil})
					aadd(aDadLog,{"ZF_COD",SD4->D4_COD,Nil})
					aadd(aDadLog,{"ZF_QUANTOR",SD4->D4_QTDEORI,Nil})
					aadd(aDadLog,{"ZF_LOCALOR",SD4->D4_LOCAL,Nil})
					aadd(aDadLog,{"ZF_LOTECTO",SD4->D4_LOTECTL,Nil})
					aadd(aDadLog,{"ZF_NUMLOTO",SD4->D4_NUMLOTE,Nil})
					aadd(aDadLog,{"ZF_QUANTDE",SD4->D4_QUANT,Nil})
					aadd(aDadLog,{"ZF_TRT",SD4->D4_TRT,Nil})
					aadd(aItemLog,aDadLog)
					SD4->(DBSkip())
				enddo
				u_YOLOGOP1(aItemLog,.T.,"")
			endif
		Endif
		
		aItemLog := {}
		aAdd(_aItens,{Substr(cMV_PAR01,1,8),dDataBase})
		aItMata381 := {}
		aCbMata381 := {}
		For _nCont2 := 1 to Len(_aLbxIt)
			//Begin Transaction // Inclusao
			// Efetua a Transferencia  do Item Para a Producao
			If _aLbxIt[_nCont2][11] > 0   //Transferir
				_cNumSeq := ProxNum()
				//_aItens  := {} //Comentado para ajustar o EmpMod2
				_nItem   := 1
				_aItAux  := {}
				aAdd(_aItAux,{;
				_aLbxIt[_nCont2][02] ,;   // 01 - Produto Origem
				_aLbxIt[_nCont2][03] ,;   // 02 - Descricao
				_aLbxIt[_nCont2][04] ,;   // 03 - UM Origem
				_aLbxIt[_nCont2][12] ,;   // 04 - Local Origem
				_aLbxIt[_nCont2][15] ,;   // 05 - Localização Origem
				_aLbxIt[_nCont2][02] ,;   // 06 - Produto Destino
				_aLbxIt[_nCont2][03] ,;   // 07 - Descricao
				_aLbxIt[_nCont2][04] ,;   // 08 - UM Destino
				_aLbxIt[_nCont2][07] ,;   // 09 - Local Destino
				_aLbxIt[_nCont2][10] ,;   // 10 - Localização Destino
				_aLbxIt[_nCont2][17] ,;   // 11 - Número de Série
				_aLbxIt[_nCont2][13] ,;   // 12 - Lote
				_aLbxIt[_nCont2][14] ,;   // 13 - Sub-Lote
				_aLbxIt[_nCont2][16] ,;   // 14 - Validade
				CriaVar("D3_POTENCI"),;   // 15 - Potencia
				_aLbxIt[_nCont2][11] ,;   // 16 - Quantidade
				CriaVar("D3_QTSEGUM"),;   // 17 - Quantidade na 2a UM
				CriaVar('D3_ESTORNO'),;   // 18 - Estornado
				_cNumSeq             ,;   // 19 - Sequência
				_aLbxIt[_nCont2][08] ,;   // 20 - Lote Destino
				_aLbxIt[_nCont2][16] ,;   // 21 - Validade Destino
				CriaVar('D3_ITEMGRD');    // 22 - Item Grade						       			    			
				} )

				If SD3->(FieldPos(PADR('D3_OBSERVA',10))) > 0 //Campo Existe
					__nPos := Len(_aItAux[Len(_aItAux)])+1
					ASize(_aItAux[Len(_aItAux)], __nPos) //Redimensiona o Array
					_aItAux[Len(_aItAux)][__nPos] := CriaVar('D3_OBSERVA')
				Endif	

				If SD3->(FieldPos(PADR('D3_YPEDIDO',10))) > 0 //Campo Existe
					__nPos := Len(_aItAux[Len(_aItAux)])+1
					ASize(_aItAux[Len(_aItAux)], __nPos) //Redimensiona o Array
					_aItAux[Len(_aItAux)][__nPos] := CriaVar('D3_YPEDIDO') // Pedido
				Endif			
				
				// Atualiza Arquivos de Empenho
				If Len(_aItAux) > 0
					//aAdd(_aItens,{Substr(cMV_PAR01,1,8),dDataBase}) //Comentado para ajustar o EmpMod3
					For _nCnt5 := 1 to Len(_aItAux)
						If Len(_aItAuxTrf) > 0
							_nChkTran := aScan(_aItAuxTrf,{|x| x[1]+x[4]+x[5]+x[12] == _aItAux[_nCnt5][01]+_aItAux[_nCnt5][04]+_aItAux[_nCnt5][05]+_aItAux[_nCnt5][12] })
						EndIf
						If _nChkTran > 0
							_aItens[_nChkTran+1][16] += _aItAux[_nCnt5][16]
							_aItens[_nChkTran+1][17] += _aItAux[_nCnt5][17]
						Else
							aAdd(_aItens,_aItAux[_nCnt5])
							aAdd(_aItAuxTrf,_aItAux[_nCnt5])
						EndIf
						//Verificando se deve gravar Log
						if SuperGetMV("MV_YOLOGOP",,.T.)
							//Gravação do Log Para Validação
							aDadLog := {}
							aadd(aDadLog,{"ZF_FILIAL",xFilial("SZF"),Nil})
							aadd(aDadLog,{"ZF_OP",cMV_PAR01,Nil})
							aadd(aDadLog,{"ZF_EMISSAO",dDataBase,Nil})
							aadd(aDadLog,{"ZF_HORA",Time(),Nil})
							aadd(aDadLog,{"ZF_USUARIO",Substr(cUsuario,7,15),Nil})
							aadd(aDadLog,{"ZF_TIPO","T",Nil})
							aadd(aDadLog,{"ZF_DOC",Substr(cMV_PAR01,1,8),Nil})
							aadd(aDadLog,{"ZF_COD",_aItAux[_nCnt5][01],Nil})		// 01 - Produto Origem
							aadd(aDadLog,{"ZF_UM",_aItAux[_nCnt5][03],Nil})     	// 03 - UM Origem
							aadd(aDadLog,{"ZF_QUANTOR",_aItAux[_nCnt5][16],Nil})	// 16 - Quantidade
							aadd(aDadLog,{"ZF_LOCALOR",_aItAux[_nCnt5][04],Nil})	// 04 - Local Origem
							aadd(aDadLog,{"ZF_LOTECTO",_aItAux[_nCnt5][12],Nil})	// 12 - Lote
							aadd(aDadLog,{"ZF_NUMLOTO",_aItAux[_nCnt5][13],Nil})	// 13 - Sub-Lote
							aadd(aDadLog,{"ZF_LOCALIO",_aItAux[_nCnt5][05],Nil})	// 05 - Localização Origem
							aadd(aDadLog,{"ZF_QUANTDE",_aItAux[_nCnt5][16],Nil})	// 16 - Quantidade
							aadd(aDadLog,{"ZF_LOCALDE",_aItAux[_nCnt5][10],Nil})	// 10 - Localização Destino
							aadd(aDadLog,{"ZF_LOTECTD",_aItAux[_nCnt5][20],Nil})	// 20 - Lote Destino
							aadd(aDadLog,{"ZF_LOCALID",_aItAux[_nCnt5][09],Nil})	// 09 - Local Destino
							aadd(aDadLog,{"ZF_NUMSEQ",_aItAux[_nCnt5][19],Nil})		// 19 - Sequência
							aadd(aDadLog,{"ZF_NUMSERI",_aItAux[_nCnt5][11],Nil})	// 11 - Número de Série
							aadd(aDadLog,{"ZF_DTVALIO",_aItAux[_nCnt5][14],Nil})	// 14 - Validade Origem
							aadd(aDadLog,{"ZF_DTVALID",_aItAux[_nCnt5][21],Nil})	// 21 - Validade Destino
							aadd(aItemLog,aDadLog)
						endif
					Next _nCnt5
				EndIf
				// Processa os ajustes de Empenhos
				_cNumOp	  := _aLbxIt[_nCont2][01]
				_cCodPro  := _aLbxIt[_nCont2][02]
				_nSalEmp  := _aLbxIt[_nCont2][05]
				_cLocEmp  := _aLbxIt[_nCont2][07]
				_nQtdTran := _aLbxIt[_nCont2][11]
				_cLoteTran:= _aLbxIt[_nCont2][13]
				_cSubTran := _aLbxIt[_nCont2][14]
				_cTRT	  := _aLbxIt[_nCont2][20] //Space(3) -- Anderson Messias - 23/06/2009
				_aBenef   := {_aLbxIt[_nCont2][21],_aLbxIt[_nCont2][22],_aLbxIt[_nCont2][23],_aLbxIt[_nCont2][24],_aLbxIt[_nCont2][25],_aLbxIt[_nCont2][26],_aLbxIt[_nCont2][27],_aLbxIt[_nCont2][28],_aLbxIt[_nCont2][29],_aLbxIt[_nCont2][30],_aLbxIt[_nCont2][31]}
				//Abaixo o ajuste para EmpMod2
				_nPosReq  := aScan(_aEstru,{|x| Alltrim(x[1])+Alltrim(x[12]) == Alltrim(_cCodPro)+Alltrim(_cTRT) })
				_nRegSD4  := _aEstru[_nPosReq,11]
				DbSelectArea("SD4")
				DbGoTo(_nRegSD4)			
				_nD4QtdOri:= SD4->D4_QTDEORI
				_nQtEmpNew:= _nSalEmp - _nQtdTran
				_cOpOrig  := SD4->D4_OPORIG
				_cSeqSD4  := SD4->D4_SEQ   
				If _nD4QtdOri > _nQtdTran
					_nPosChkEmp := aScan(_aReqOps,{|x| x[1]+x[2] == _cCodPro+_cTrt })
					If _nPosChkEmp > 0
						_aReqOps[_nPosChkEmp,03] := _aReqOps[_nPosChkEmp,03] + _nQtdTran
						aAdd(aItMata381, YOEmpMod2(3,_cCodPro,_cNumOP,_cTrt,_cLocEmp,_nQtdTran,_nQtdTran,dDataBase,_cLoteTran,_cSubTran,"I",_aBenef,0 ) )
					Else
						AADD(_aReqOps,{_cCodPro,_cTrt,_nQtdTran,_nD4QtdOri,_cNumOP,_cLocEmp,_aBenef})
						aAdd(aItMata381, YOEmpMod2(4,_cCodPro,_cNumOP,_cTrt,_cLocEmp,_nQtdTran,_nQtdTran,dDataBase,_cLoteTran,_cSubTran,"I",_aBenef,_nRegSD4,_cOpOrig,_cSeqSD4 ) )
					Endif	
				Else 
					aAdd(aItMata381, YOEmpMod2(4,_cCodPro,_cNumOP,_cTrt,_cLocEmp,_nD4QtdOri,_nQtdTran,dDataBase,_cLoteTran,_cSubTran,"I",_aBenef,_nRegSD4,_cOpOrig,_cSeqSD4 ) )
				Endif		
			Endif
			//End Transaction
		Next _nCont2

		For _nReq := 1 To Len(_aReqOps)
			If _aReqOps[_nReq][03] < _aReqOps[_nReq][04] //Verifico se o total transferido para o mesmo Codigo e TRT é menor que o saldo original do empenho, para criar um empenho da diferenca
				_nValDif := _aReqOps[_nReq][04]-_aReqOps[_nReq][03]
				aAdd(aItMata381, YOEmpMod2(3,_aReqOps[_nReq][01],_aReqOps[_nReq][05],_aReqOps[_nReq][02],_aReqOps[_nReq][06],_nValDif,_nValDif,dDataBase,,,"",_aBenef,0 ) )
			ElseIf _aReqOps[_nReq][03] > _aReqOps[_nReq][04]
				MsgAlert("Processo com diferença no item "+Alltrim(_aReqOps[_nReq][01])+" o saldo transferido está maior que a quantidade original do Empenho. Pagamento Cancelado.") 
				_lPagOk := .F.
			Endif
		Next _nReq
		//Abaixo incluido para ajuste de EmpMod2
		If _lPagOk
			Begin Transaction // Inclusao
			If Len(_aItens) > 1
				lMsErroAuto := .F.
				cMsg := ""
				MSExecAuto({|x,y| MATA261(x,y)},_aItens,3)
				If lMsErroAuto
					DisarmTransaction()
					MostraErro()					
					lContinua := .F.
				EndIf
				//Verificando se deve gravar Log
				if SuperGetMV("MV_YOLOGOP",,.T.) .And. Len(aItemLog) > 0
					u_YOLOGOP1(aItemLog,lContinua,cMsg)
				endif
			Endif
			If Len(aItMata381) > 0 .And. lContinua
				lMsErroAuto := .F.
				aCbMata381 := {{"D4_OP",PadR(cMV_PAR01,TamSx3("D4_OP")[1]),NIL},;
							{"INDEX",2,Nil}}
				MSExecAuto({|x,y,z| mata381(x,y,z)},aCbMata381,aItMata381,4)
				If lMsErroAuto
					//Se ocorrer erro.
					DisarmTransaction()
					MostraErro()
				EndIf	
			Endif
			End Transaction
		EndIf
		//Fim da inclusao do ajsute de EmpMod2

		//Guardando o Log do SD4 Depois da Alteração dos Empenhos
		if SuperGetMV("MV_YOLOGOP",,.T.)
			//Guardando o Log do SD4 Antes da Alteração dos Emprenhos
			aItemLog := {}
			DBSelectArea("SD4")
			DBSetOrder(2)
			if DBSeek(xFilial("SD4")+cMV_PAR01)
				While !SD4->(Eof()) .AND. alltrim(SD4->D4_OP) == alltrim(cMV_PAR01)
					aDadLog := {}
					aadd(aDadLog,{"ZF_FILIAL",xFilial("SZF"),Nil})
					aadd(aDadLog,{"ZF_OP",cMV_PAR01,Nil})
					aadd(aDadLog,{"ZF_EMISSAO",dDataBase,Nil})
					aadd(aDadLog,{"ZF_HORA",Time(),Nil})
					aadd(aDadLog,{"ZF_USUARIO",Substr(cUsuario,7,15),Nil})
					aadd(aDadLog,{"ZF_TIPO","DP",Nil})
					aadd(aDadLog,{"ZF_COD",SD4->D4_COD,Nil})
					aadd(aDadLog,{"ZF_QUANTOR",SD4->D4_QTDEORI,Nil})
					aadd(aDadLog,{"ZF_LOCALOR",SD4->D4_LOCAL,Nil})
					aadd(aDadLog,{"ZF_LOTECTO",SD4->D4_LOTECTL,Nil})
					aadd(aDadLog,{"ZF_NUMLOTO",SD4->D4_NUMLOTE,Nil})
					aadd(aDadLog,{"ZF_QUANTDE",SD4->D4_QUANT,Nil})
					aadd(aDadLog,{"ZF_TRT",SD4->D4_TRT,Nil})
					aadd(aItemLog,aDadLog)
					SD4->(DBSkip())
				enddo
				u_YOLOGOP1(aItemLog,.T.,"")
			endif
		endif
		
		MsAguarde( {||YOPA02Trb()}, "Carregando Dados...")
		
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

	/* Opções/telas a organizar
	1) zerar OPT
	2) qtde a transferir OPT -> TELA (POPUP)
	3) legenda -> TELA (POPUP) (DIRETO) 
		-> DADOS: (Situação da OP - transf (verde), saldo suficiente (amarelo), saldo insuficiente (azul), Sem saldo (vermelho)) 
	4) lOTES DISPONIVEIS -> TELA (POPUP) (DIRETO) 
		-> DADOS: (QTD, LOTE ORIGEM, SUB-LOTE ORIGEM, eNDERECO ORIGEM, VALIDADE, N SERIE)
	*/

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

Static Function YOPA02Zer()
Local nI := 1

if MsgYesNo(OemToAnsi("Deseja zerar a quantidade de transferencia de todos os produtos?"))

	For nI := 1 to Len(_aLbxIt)
		_aLbxIt[nI,11] := 0
	Next

endif

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

	// *** AQUI VAI O CODIGO PARA VISUALIZACAO DA OP ***

Return

// Impressao da OP
Static Function YOACD01Imp(cOP)

	// *** AQUI VAI O CODIGO PARA IMPRESSAO DA OP ***

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
	
	DEFINE MSDIALOG _oDlg1 TITLE "Lotes Disponíveis" FROM 000,000 to 037,125
	
	@ 005,005 LISTBOX _oLbxLt Var _oLote FIELDS HEADER	;
	"Quantidade"		,;
	"Lote Origem"		,;
	"Sub-Lote Origem"	,;
	"Endereço Origem"	,;
	"Validade"			,;
	"Número de Série"	;
	SIZE 486,255 OF _oDlg1 PIXEL
	
	_oLbxLt:SetArray(_aLotes)
	_oLbxLt:bLine := {||{   _aLotes[_oLbxLt:nAt,1],;
	_aLotes[_oLbxLt:nAt,2],;
	_aLotes[_oLbxLt:nAt,3],;
	_aLotes[_oLbxLt:nAt,4],;
	_aLotes[_oLbxLt:nAt,5],;
	_aLotes[_oLbxLt:nAt,6]}	}
	//                    001 002 003 004 005 006
	_oLbxLt:aColSizes := {050,050,050,050,040,050}
	_oLote:nAt := 1
	_oLbxLt:SetFocus()
	
	@ 026,103 Button oBtn4 Prompt "Ok"         Size 039,015 Action (_nSelec := _oLbxLt:nAt,_oDlg1:End())
	@ 026,113 Button oBtn5 Prompt "Cancelar"   Size 039,015 Action Close(_oDlg1)
	
	ACTIVATE MSDIALOG _oDlg1 CENTERED
	
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

Local _aArea	:= GetArea()
Local _aVetor	:= {}
Local _nChkTrt  := 0
Local _cD4TRTAux:= Space(03)

DEFAULT _cD4Lote 	 := Space(10)
DEFAULT _cD4SubLote  := Space(06)
DEFAULT _cD4PagOp    := Space(05)
DEFAULT _cD4TRT      := Space(03)
DEFAULT _aBenef      := {Space(06),Space(04),Space(06),Space(06),Space(04),Space(06), Space(06),Space(04),Space(06),Space(06),Space(04)}
DEFAULT _cOpOrig     := Space(TamSx3("D4_OPORIG")[1])
DEFAULT _cSeqSD4     := Space(TamSx3("D4_SEQ")[1])

If _nOpc == 3 //Inclusao de Empenho
	If Select("TRBTRT") <> 0
		TRBTRT->(dbCloseArea())
	EndIf
	
	BeginSQL Alias "TRBTRT"
	   SELECT ISNULL(MAX(D4_TRT),'###') D4_TRT, ISNULL(COUNT(1),0) AS QTDITENS
		 FROM %Table:SD4% SD4
	    WHERE D4_FILIAL = %xfilial:SD4% AND D4_OP = %Exp:_cD4OP% AND D4_COD = %Exp:_cD4Cod%
		  AND D4_LOCAL = %Exp:_cD4Local% AND SD4.%NotDel%	
   EndSQL
	
	_cD4TRT := Space(3)
	dbSelectArea("TRBTRT")
	TRBTRT->(dbGoTop())
	//Se nao achar na base, retorna ### se retornar mesmo que vazio tem que somar1
	//Anderson Messias - 17/06/2009
	If TRBTRT->D4_TRT<>"###" .AND. TRBTRT->QTDITENS > 0
		_cD4TRT := Soma1(TRBTRT->D4_TRT)
	EndIf

	TRBTRT->(dbCloseArea())
	
	While .T.
		_nChkTrt := aScan(aItMata381,{|x| x[1][2]+x[3][2] == _cD4Cod+_cD4TRT })
		If _nChkTrt > 0
			_cD4TRT := Soma1(_cD4TRT)
		Else
			Exit
		EndIf
	EndDo

	Aadd(_aVetor,{"D4_COD" 	  ,_cD4Cod	   ,NIL})
	Aadd(_aVetor,{"D4_OP"	  ,_cD4OP	   ,NIL})
	Aadd(_aVetor,{"D4_TRT"	  ,_cD4TRT	   ,NIL})
	Aadd(_aVetor,{"D4_LOCAL"  ,_cD4Local   ,NIL})
	Aadd(_aVetor,{"D4_QTDEORI",_nD4QtdOri  ,NIL})
	Aadd(_aVetor,{"D4_QUANT"  ,_nD4Quant   ,NIL})
	Aadd(_aVetor,{"D4_DATA"	  ,_dD4DtEmp   ,NIL})
	If Rastro(_cD4Cod)
		Aadd(_aVetor,{"D4_LOTECTL",_cD4Lote	   ,NIL})
		Aadd(_aVetor,{"D4_NUMLOTE",_cD4SubLote ,NIL})
	EndIf
	Aadd(_aVetor,{"D4_SEQ"    ,_cSeqSD4    ,NIL}) 
	Aadd(_aVetor,{"D4_PAGOP"  ,_cD4PagOp   ,NIL})
	Aadd(_aVetor,{"D4_YFORNEC",_aBenef[1]  ,NIL})
	Aadd(_aVetor,{"D4_YLOJA"  ,_aBenef[2]  ,NIL})
	Aadd(_aVetor,{"D4_YPEDBEN",_aBenef[3]  ,NIL})
	Aadd(_aVetor,{"D4_YPEDCOM",_aBenef[4]  ,NIL})
	Aadd(_aVetor,{"D4_YPEDITE",_aBenef[5]  ,NIL})
	Aadd(_aVetor,{"D4_NUMSC"  ,_aBenef[6]  ,NIL})
	Aadd(_aVetor,{"D4_YFORNE2",_aBenef[7]  ,NIL})
	Aadd(_aVetor,{"D4_YLOJA2" ,_aBenef[8]  ,NIL})
	Aadd(_aVetor,{"D4_YPEDBE2",_aBenef[9]  ,NIL})
	Aadd(_aVetor,{"D4_YPEDCO2",_aBenef[10] ,NIL})
	Aadd(_aVetor,{"D4_YPEDIT2",_aBenef[11] ,NIL})

EndIf

If _nOpc == 4 //Alteracao Empenho
	If Select("TRBTRT") <> 0
		TRBTRT->(dbCloseArea())
	EndIf
	
	If Select("TRBTRT") <> 0
		TRBTRT->(dbCloseArea())
	EndIf
	
	BeginSQL Alias "TRBTRT"
	   SELECT ISNULL(MAX(D4_TRT),'###') D4_TRT, ISNULL(COUNT(1),0) AS QTDITENS
		 FROM %Table:SD4% SD4
	    WHERE D4_FILIAL = %xfilial:SD4% AND D4_OP = %Exp:_cD4OP% AND D4_COD = %Exp:_cD4Cod%
		  AND D4_LOCAL = %Exp:_cD4Local% AND D4_LOTECTL = %Exp:cD4Lote% AND D4_TRT = %Exp:_cD4TRT% AND SD4.%NotDel%	
   EndSQL

	// Chave Unica do SD4 -> D4_FILIAL, D4_COD, D4_OP, D4_TRT, D4_LOTECTL, D4_NUMLOTE, D4_LOCAL, D4_ORDEM, D4_OPORIG, D4_SEQ, R_E_C_D_E_L_
	_cD4TRTAux := _cD4TRT

	dbSelectArea("TRBTRT")
	TRBTRT->(dbGoTop())
	//Se nao achar na base, retorna ### se retornar mesmo que vazio tem que somar1
	//Anderson Messias - 17/06/2009
	If TRBTRT->D4_TRT<>"###" .AND. TRBTRT->QTDITENS > 0
		_cD4TRTAux := Soma1(TRBTRT->D4_TRT)
	EndIf

	TRBTRT->(dbCloseArea())
	
	Aadd(_aVetor,{"D4_COD" 	  ,_cD4Cod	   ,NIL})
	Aadd(_aVetor,{"D4_OP"	  ,_cD4OP	   ,NIL})
	Aadd(_aVetor,{"D4_TRT"	  ,_cD4TRTAux  ,NIL})
	Aadd(_aVetor,{"D4_LOCAL"  ,_cD4Local   ,NIL})
	Aadd(_aVetor,{"D4_QTDEORI",_nD4QtdOri  ,NIL})
	Aadd(_aVetor,{"D4_QUANT"  ,_nD4Quant   ,NIL})
	Aadd(_aVetor,{"D4_DATA"	  ,_dD4DtEmp   ,NIL})
	If Rastro(_cD4Cod)
		Aadd(_aVetor,{"D4_LOTECTL",_cD4Lote	   ,NIL})
		Aadd(_aVetor,{"D4_NUMLOTE",_cD4SubLote ,NIL})
	EndIf
	Aadd(_aVetor,{"D4_SEQ"    ,_cSeqSD4    ,NIL}) 
	Aadd(_aVetor,{"D4_PAGOP"  ,_cD4PagOp   ,NIL})
	Aadd(_aVetor,{"D4_YFORNEC",_aBenef[1]  ,NIL})
	Aadd(_aVetor,{"D4_YLOJA"  ,_aBenef[2]  ,NIL})
	Aadd(_aVetor,{"D4_YPEDBEN",_aBenef[3]  ,NIL})
	Aadd(_aVetor,{"D4_YPEDCOM",_aBenef[4]  ,NIL})
	Aadd(_aVetor,{"D4_YPEDITE",_aBenef[5]  ,NIL})
	Aadd(_aVetor,{"D4_NUMSC"  ,_aBenef[6]  ,NIL})
	Aadd(_aVetor,{"D4_YFORNE2",_aBenef[7]  ,NIL})
	Aadd(_aVetor,{"D4_YLOJA2" ,_aBenef[8]  ,NIL})
	Aadd(_aVetor,{"D4_YPEDBE2",_aBenef[9]  ,NIL})
	Aadd(_aVetor,{"D4_YPEDCO2",_aBenef[10] ,NIL})
	Aadd(_aVetor,{"D4_YPEDIT2",_aBenef[11] ,NIL})
	Aadd(_aVetor,{"LINPOS","D4_COD+D4_TRT+D4_LOTECTL+D4_NUMLOTE+D4_LOCAL+D4_OPORIG+D4_SEQ",; 
                _cD4Cod,;
                _cD4TRT,;
                SD4->D4_LOTECTL,;
                SD4->D4_NUMLOTE,;
                _cD4Local,;
                _cOpOrig,;
                _cSeqSD4})

EndIf

RestArea(_aArea)

Return _aVetor
