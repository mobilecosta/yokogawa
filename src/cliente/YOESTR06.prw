//@CHK12.1.2210
#include "rwmake.ch"
#include "protheus.ch"
#include "topconn.ch"

/*/
+---------------------------------------------------------------------------+
| Programa  | YOESTR06   | Autor | Ivandro M. P. Santos   | Data | 20/03/13 |
+-----------+---------------------------------------------------------------+
| Descri��o | Impress�o de etiquetas com c�digo de Barras                   |
+-----------+---------------------------------------------------------------+
| Uso       | Espec�fico Yokogawa                                           |
+---------------------------------------------------------------------------+
/*/

User Function YOESTR06
	Local i, nFld	:= 0
	Local _aCpos	:= {}
	Local _cFields	:= ""
	Local _cFields2	:= ""
	Local _aCpoSX32	:= {}
	Local _aCpoSX3D1:= {}

	SetPrvt("CPERG,NRESP,CPORTA,CPADRAO,MV_PAR06")
	SetPrvt("CARQ,NHDLARQ,I,CPRECO,CCOD,CLINHA1")
	SetPrvt("CLINHA2,CLINHA3,CLINHA4,_SALIAS,AREGS,J")

	Static _aMarcEmb := {}

	Private cPerg	  := "YESTR6EM"
	Private aRotina   := { }
	Private cCadastro := "Etiquetas com c�digo de barras"
	Private nMV_PAR01
	Private cMV_PAR02
	//CHECK VARIAVEIS OTEMP
	Private oTemp

	aAdd(aRotina,{"Etiqueta"  ,"U_YOER6Imp()",0,4})   //Tela com MarkBrowse para sele��o das etiquetas
	aAdd(aRotina,{"Embarque"  ,"U_YESTR6EM()",0,6})   //Impress�o de relat�rio de confer�ncia de embarque

	//Projeto release 12.1.2210
	//julio.nobre@grupoviseu.com.br
	//ValidPerg(cPerg)
	While .T.
		//julio.nobre@grupoviseu.com.br
		//criada static pra chamada e "burlar" o codeanalisys, ja que conforme regra aqui, nao pode ser feito de outra forma sem prejudicar a rotina
		If YOESTR06P()
			nMV_PAR01 := MV_PAR01
			cMV_PAR02 := MV_PAR02

			MsAguarde( {||YOER06Trb()}, "Carregando Dados...")
			_aCpos		:= {}
			_aCpoSX32	:= {}
			_cFields    := "D1_DOC/D1_SERIE/D1_FORNECE/D1_LOJA/D1_ITEM/D1_COD/D1_QUANT/D1_CONHEC/D1_LOTECTL"
			_cFields2   := "T_DOC/T_SERIE/T_FORNECE/T_LOJA/T_ITEM/T_COD/T_QUANT/T_CONHEC/T_LOTECTL"
			_aCpoSX32	:= StrTokArr(_cFields2,"/")
			_aCpoSX3D1  := StrTokArr(_cFields,"/")
			aAdd(_aCpos,{"T_OK","","mark",""})
			For nFld := 1 To Len(_aCpoSX3D1)
				aadd(_aCpos,{_aCpoSX32[nFld], "", AllTrim(GetSx3Cache(_aCpoSX3D1[nFld], 'X3_TITULO')), AllTrim(GetSx3Cache(_aCpoSX3D1[nFld], 'X3_PICTURE'))})
			Next nFld
			aAdd(_aCpos,{"T_RECNO","","rec",""})
			/*
			SX3->(dbSetOrder(2)) // X3_CAMPO
			SX3->(dbGoTop())
			//SX3->(dbGoTop())
			SX3->(dbSeek("D1_DOC"))
			aAdd(_aCpos,{"T_DOC"    ,"",SX3->X3_TITULO,SX3->X3_PICTURE})
			//SX3->(dbGoTop())
			SX3->(dbSeek("D1_SERIE"))
			aAdd(_aCpos,{"T_SERIE" ,"",SX3->X3_TITULO,SX3->X3_PICTURE})
			//SX3->(dbGoTop())
			SX3->(dbSeek("D1_FORNECE"))
			aAdd(_aCpos,{"T_FORNECE","",SX3->X3_TITULO,SX3->X3_PICTURE})
			//SX3->(dbGoTop())
			SX3->(dbSeek("D1_LOJA"))
			aAdd(_aCpos,{"T_LOJA","",SX3->X3_TITULO,SX3->X3_PICTURE})
			//SX3->(dbGoTop())
			SX3->(dbSeek("D1_ITEM"))
			aAdd(_aCpos,{"T_ITEM","",SX3->X3_TITULO,SX3->X3_PICTURE})
			//SX3->(dbGoTop())
			SX3->(dbSeek("D1_COD"))
			aAdd(_aCpos,{"T_COD","",SX3->X3_TITULO,SX3->X3_PICTURE})
			//SX3->(dbGoTop())
			SX3->(dbSeek("D1_QUANT"))
			aAdd(_aCpos,{"T_QUANT","",SX3->X3_TITULO,SX3->X3_PICTURE})
			//SX3->(dbGoTop())
			If nMV_PAR01 == 2
				SX3->(dbSeek("D1_CONHEC"))
				aAdd(_aCpos,{"T_CONHEC","",SX3->X3_TITULO,SX3->X3_PICTURE})
				//SX3->(dbGoTop())
			Endif
			SX3->(dbSeek("D1_LOTECTL"))
			aAdd(_aCpos,{"T_LOTECTL","",SX3->X3_TITULO,SX3->X3_PICTURE})
			*/
			//SX3->(dbGoTop())
			//ISSO NAO EXISTE - JULIO.NOBRE@GRUPOVISEU.COM.BR
			//DBSEEK NA SX3 PELO RECNO DA TABELA?
			//SX3->(dbSeek("SD1->(RECNO())"))
			//aAdd(_aCpos,{"T_RECNO","",SX3->X3_TITULO,SX3->X3_PICTURE})
			MarkBrow("TRB","T_OK",,_aCpos,,GetMark())

			TRB->(dbCloseArea())

		Else

			Exit

		EndIf

	EndDo

Return
/*/{Protheus.doc} YOESTR06P
	Carrega a pergunte dentro do loop. 
	Tungado do fonte danfeii da Totvs como exemplo de tratamento para situacoes onde nao � possivel por motivos da regra tirar a pergunte do loop
	@type  Static Function
	@author julio.nobre@grupoviseu.com.br
	@since 08/06/2023
/*/
Static Function YOESTR06P

Return(Pergunte(cPerg,.T.))

/*/
	+--------------------------------------------------------------------------+
	| Fun��o    | YOER06Trb  | Autor | Ivandro M.P. Santos    | Data | 20/03/13 |
	+-----------+---------------------------------------------------------------+
	| Descri��o | Carrega os dados de acordo com a sele��o do usu�rio.          |
	+-----------+---------------------------------------------------------------+
	| Uso       | Espec�fico YOESTR06                                           |
	+---------------------------------------------------------------------------+
/*/
Static Function YOER06Trb()
	Local _cQuery := ""
	Local aCampos  := {}
	Local cCommSQL := ''

	Pergunte(cPerg,.F.)

	_cQuery += "SELECT '  ' T_OK,D1_DOC T_DOC,D1_SERIE T_SERIE,D1_FORNECE T_FORNECE,D1_LOJA T_LOJA,"
	_cQuery += "D1_ITEM T_ITEM, D1_COD T_COD, D1_QUANT T_QUANT, "
	//If nMV_PAR01 == 2   //Inlucir na tela de sela��o o embarque //Retirado pelo Sano, porque a montagem da tela tem o campo T_CONHEC ent�o precisa ter esse campo para NF
		_cQuery += "D1_CONHEC T_CONHEC, "
	//EndIf
	_cQuery += "ISNULL(D1_LOTECTL,D1_DOC) T_LOTECTL, R_E_C_N_O_ T_RECNO "
	_cQuery += "FROM " + RetSQLName("SD1") + " SD1 "
	_cQuery += "WHERE SD1.D_E_L_E_T_ = ' ' AND D1_QUANT > 0 "
	_cQuery += "AND SD1.D1_FILIAL = '" + xFilial("SD1") + "' "
	If nMV_PAR01 == 1   //Grava o campo conforme par�metro de sele��o 1 = Nota Fiscal 2 = Embarque
		_cQuery += "AND D1_DOC ='" + cMV_PAR02 + "' "
	Else
		_cQuery += "AND D1_CONHEC ='" + cMV_PAR02 + "' "
	End if
	_cQuery += "ORDER BY SD1.D1_FORNECE,SD1.D1_LOJA,SD1.D1_DOC,SD1.D1_SERIE,SD1.D1_ITEM "

	//Projeto release 12.1.2210
	//julio.nobre@grupoviseu.com.br
	If Select("TRB") > 0
		TRB->(dbCloseArea())
	EndIf

	Aadd( aCampos,{"T_OK"		, "C", 2, 0})
	Aadd( aCampos,{"T_DOC"		, GetSx3Cache("D1_DOC","X3_TIPO")	 , GetSx3Cache("D1_DOC","X3_TAMANHO")	 , GetSx3Cache("D1_DOC","X3_DECIMAL")})
	Aadd( aCampos,{"T_SERIE"	, GetSx3Cache("D1_SERIE","X3_TIPO")	 , GetSx3Cache("D1_SERIE","X3_TAMANHO")	 , GetSx3Cache("D1_SERIE","X3_DECIMAL")})
	Aadd( aCampos,{"T_FORNECE"	, GetSx3Cache("D1_FORNECE","X3_TIPO"), GetSx3Cache("D1_FORNECE","X3_TAMANHO"), GetSx3Cache("D1_FORNECE","X3_DECIMAL")})
	Aadd( aCampos,{"T_LOJA"		, GetSx3Cache("D1_LOJA","X3_TIPO")	 , GetSx3Cache("D1_LOJA","X3_TAMANHO")	 , GetSx3Cache("D1_LOJA","X3_DECIMAL")})
	Aadd( aCampos,{"T_ITEM"		, GetSx3Cache("D1_ITEM","X3_TIPO")	 , GetSx3Cache("D1_ITEM","X3_TAMANHO")	 , GetSx3Cache("D1_ITEM","X3_DECIMAL")})
	Aadd( aCampos,{"T_COD"		, GetSx3Cache("D1_COD","X3_TIPO")	 , GetSx3Cache("D1_COD","X3_TAMANHO")	 , GetSx3Cache("D1_COD","X3_DECIMAL")})
	Aadd( aCampos,{"T_QUANT"	, GetSx3Cache("D1_QUANT","X3_TIPO")	 , GetSx3Cache("D1_QUANT","X3_TAMANHO")	 , GetSx3Cache("D1_QUANT","X3_DECIMAL")})
	Aadd( aCampos,{"T_CONHEC"	, GetSx3Cache("D1_CONHEC","X3_TIPO") , GetSx3Cache("D1_CONHEC","X3_TAMANHO") , GetSx3Cache("D1_CONHEC","X3_DECIMAL")})
	Aadd( aCampos,{"T_LOTECTL"	, GetSx3Cache("D1_LOTECTL","X3_TIPO"), GetSx3Cache("D1_LOTECTL","X3_TAMANHO"), GetSx3Cache("D1_LOTECTL","X3_DECIMAL")})
	Aadd( aCampos,{"T_RECNO"	, "N", 10, 0})

	If(oTemp <> NIL)
		oTemp:Delete()
		oTemp := NIL
	EndIf

	oTemp := FWTemporaryTable():New( "TRB" )
	oTemp:SetFields( aCampos )
	oTemp:Create()
	cCommSQL := "INSERT INTO " +oTemp:GetRealName() +" (T_OK, T_DOC, T_SERIE, T_FORNECE, T_LOJA, T_ITEM, T_COD, T_QUANT, T_CONHEC, T_LOTECTL, T_RECNO) "

	FwMsgRun(, {|oSay| TCSQLExec(cCommSQL + _cQuery)}, "Aguarde", "Filtrando registros...")

	//Projeto release 12.1.2210
	//julio.nobre@grupoviseu.com.br
	//TCQuery _cQuery NEW ALIAS "QRY"
	//TCQuery _cQuery NEW ALIAS "TRB"
	/*	
	dbSelectArea("QRY")
	_cNomeArq := CriaTrab(NIL,.F.)
	Copy To &(_cNomeArq)
	QRY->(dbCloseArea())
	If Select("TRB") > 0
		TRB->(dbCloseArea())
	EndIf
	dbUseArea(.T.,,_cNomeArq,"TRB",.F.,.F.)
	*/
	dbSelectArea("TRB")
	TRB->(dbGoTop())

Return


/*/
	+---------------------------------------------------------------------------+
	| Fun��o    | YOER06Imp  | Autor | Ivandro M. P. Santos   | Data | 20/03/13 |
	+-----------+---------------------------------------------------------------+
	| Descri��o | Efetua a sele��o dos itens a serem impressos.                 |
	+-----------+---------------------------------------------------------------+
	| Uso       | Espec�fico YOESTR06                                           |
	+---------------------------------------------------------------------------+
/*/

User Function YOER6Imp()

	Local lInvert    := ThisInv()
	Local _cMarca := ThisMark()
	Local _aItAux    := {}
	Local _lGrv      := .F.
	Local _cNF 		 := ""
	Local _aNumPC    := {}
	Local _nCnt
	Private _aCampo := {}
	Private _aEstru := {}
	Private _aLbxIt := {}

	_aArea := GetArea()
// +----------------------------+
// | Estrutura do array _aEstru |
// +----------------------------+
// | 01 - Nota Fiscal           |
// | 02 - PC                    |
// | 03 - PV                    |
// | 04 - Cliente               |
// | 05 - Produto               |
// | 06 - Qtde NF               |
// | 07 - Qtde NF               |
// | 08 - VOLUMES               |
// | 09 - Cod Jap�o             |
// | 10 - Descri��o             |
// | 11 - Lote                  |
// | 12 - N�mero da OP          |
// | 13 - BU                    |
// | 14 - �ltimo endere�o       |
// +----------------------------+

	dbSelectArea("TRB")
	TRB->(dbGoTop())

	While TRB->(!EOF())
		IF TRB->T_OK == _cMarca .AND. !lInvert
			_cNF := TRB->T_DOC + TRB-> T_SERIE + TRB->T_FORNECE + TRB->T_LOJA + TRB->T_COD + T_ITEM
			_nRecnoSD1 := (TRB->T_RECNO)
			_cChvSD1 := xFilial("SD1") + _cNF
			//Busca o �ltimo endere�o que o produto foi alocado. Caso n�o tenha endere�o traz o campo em branco
			cquery := "select top (1) DB_LOCALIZ ENDERE FROM "+ RetSqlName("SDB") +" SDB WHERE SDB.DB_PRODUTO = '"+TRB->T_COD+"'  AND DB_LOCAL = '02' and DB_ESTORNO <> 'S' ORDER BY DB_DATA DESC"
			If Select("ENDER") > 0
				ENDER->(dbCloseArea())
			EndIf
			TCQuery cQuery NEW ALIAS "ENDER"
			dbSelectArea("ENDER")
			_cEnd := ENDER->ENDERE
			ENDER->(dbCloseArea())

			dbSelectArea("SD1")
			SD1->(dbSetOrder(1))
			DBGoto(_nRecnoSD1)
			//Busca as informa��es do c�digo do Jap�o, Descri��o e Item conta sem disposicionar da tabela
			_aSB1 	 := GETADVFVAL("SB1",{"B1_CODJAP","B1_DESC","B1_ITEMCC"},xFilial("SB1")+SD1->D1_COD,1," ")
			//Busca a Descri��o do Item conta sem disposicionar da tabela
			_cCTD 	 := GETADVFVAL("CTD","CTD_DESC01",xFilial("CTD")+_aSB1[3],1," ")
			//Busca o numero da SC no Pedido de Compra
			_aNumPC  := GETADVFVAL("SC7",{"C7_NUMSC","C7_ITEMSC"},xFilial("SC7")+SD1->(D1_PEDIDO+D1_ITEMPC),1," ")
			//Busca as informa��es do PV e OP sem disposicionar da tabela
			_aPV  	 := GETADVFVAL("SC1",{"C1_PV","C1_OP"},xFilial("SC1")+_aNumPC[1]+_aNumPC[2],1," ")
			//Busca as informa��es do c�digo c�digo e loja do cliente e depois o Nome reduzido sem disposicionar da tabela
			_aCli 	 := GETADVFVAL("SC5",{"C5_CLIENTE","C5_LOJACLI"},xFilial("SD1")+_aPV[1],1," ")
			_cNomCli := GETADVFVAL("SA1","A1_NREDUZ",xFilial("SA1")+_aCli[1]+_aCli[2],1," ")
			//Busca as informa��es do c�digo c�digo e loja do cliente e depois o Nome reduzido sem disposicionar da tabela
			_cForn := GETADVFVAL("SA2","A2_NREDUZ",xFilial("SA2")+D1_FORNECE+D1_LOJA,1," ")
// +----------------------------+
// | Estrutura do array _aEstru |
// +----------------------------+
// | 01 - Nota Fiscal           |
// | 02 - PC                    |
// | 03 - PV                    |
// | 04 - Cliente               |
// | 05 - Produto               |
// | 06 - Qtde NF               |
// | 07 - Qtde NF               |
// | 08 - VOLUMES               |
// | 09 - Cod Jap�o             |
// | 10 - Descri��o             |
// | 11 - Lote                  |
// | 12 - N�mero da OP          |
// | 13 - BU                    |
// | 14 - �ltimo endere�o       |
// | 15 - Fornecedor            |
// +----------------------------+
			aAdd(_aEstru, {SD1->D1_DOC,SD1->D1_PEDIDO,_aPV[1],_cNomCli,SD1->D1_COD,SD1->D1_QUANT,SD1->D1_QUANT,1,_aSB1[1],_aSB1[2],Iif(Empty(Alltrim(SD1->D1_LOTECTL)),SD1->D1_DOC,SD1->D1_LOTECTL),_aPV[2],_cCTD,_cEnd,_cForn})
		ELSEIF TRB->T_OK != _cMarca .AND. lInvert
			_cNF := TRB->T_DOC + TRB-> T_SERIE + TRB->T_FORNECE + TRB->T_LOJA + TRB->T_COD + T_ITEM
			_nRecnoSD1 := (TRB->T_RECNO)
			_cChvSD1 := xFilial("SD1") + _cNF

			//Abre query para buscar o �ltimo endere�o do produto
			cquery := "select top (1) DB_LOCALIZ ENDERE FROM "+ RetSqlName("SDB") +" SDB WHERE SDB.DB_PRODUTO = '"+TRB->T_COD+"'  AND DB_LOCAL = '02' and DB_ESTORNO <> 'S' ORDER BY DB_DATA DESC"
			If Select("ENDER") > 0
				ENDER->(dbCloseArea())
			EndIf
			TCQuery cQuery NEW ALIAS "ENDER"
			dbSelectArea("ENDER")
			_cEnd := ENDER->ENDERE
			ENDER->(dbCloseArea())

			dbSelectArea("SD1")
			SD1->(dbSetOrder(1))
			DBGoto(_nRecnoSD1)
			//Busca as informa��es do c�digo do Jap�o, Descri��o e Item conta sem disposicionar da tabela
			_aSB1 	 := GETADVFVAL("SB1",{"B1_CODJAP","B1_DESC","B1_ITEMCC"},xFilial("SB1")+SD1->D1_COD,1," ")
			//Busca a Descri��o do Item conta sem disposicionar da tabela
			_cCTD 	 := GETADVFVAL("CTD","CTD_DESC01",xFilial("CTD")+_aSB1[3],1," ")
			//Busca o numero da SC no Pedido de Compra
			_aNumPC  := GETADVFVAL("SC7",{"C7_NUMSC","C7_ITEMSC"},xFilial("SC7")+SD1->(D1_PEDIDO+D1_ITEMPC),1," ")
			//Busca as informa��es do PV e OP sem disposicionar da tabela
			_aPV  	 := GETADVFVAL("SC1",{"C1_PV","C1_OP"},xFilial("SD1")+_aNumPC[1]+_aNumPC[2],1," ")
			//Busca as informa��es do c�digo c�digo e loja do cliente e depois o Nome reduzido sem disposicionar da tabela
			_aCli 	 := GETADVFVAL("SC5",{"C5_CLIENTE","C5_LOJACLI"},xFilial("SD1")+_aPV[1],1," ")
			_cNomCli := GETADVFVAL("SA1","A1_NREDUZ",xFilial("SA1")+_aCli[1]+_aCli[2],1," ")
			//Busca as informa��es do c�digo c�digo e loja do cliente e depois o Nome reduzido sem disposicionar da tabela
			_cForn := GETADVFVAL("SA2","A2_NREDUZ",xFilial("SA2")+D1_FORNECE+D1_LOJA,1," ")
// +----------------------------+
// | Estrutura do array _aEstru |
// +----------------------------+
// | 01 - Nota Fiscal           |
// | 02 - PC                    |
// | 03 - PV                    |
// | 04 - Cliente               |
// | 05 - Produto               |
// | 06 - Qtde NF               |
// | 07 - Qtde NF               |
// | 08 - VOLUMES               |
// | 09 - Cod Jap�o             |
// | 10 - Descri��o             |
// | 11 - Lote                  |
// | 12 - N�mero da OP          |
// | 13 - BU                    |
// | 14 - �ltimo endere�o       |
// | 15 - BU                    |
// +----------------------------+
			aAdd(_aEstru, {SD1->D1_DOC,SD1->D1_PEDIDO,_aPV[1],_cNomCli,SD1->D1_COD,SD1->D1_QUANT,SD1->D1_QUANT,1,_aSB1[1],_aSB1[2],Iif(Empty(Alltrim(SD1->D1_LOTECTL)),SD1->D1_DOC,SD1->D1_LOTECTL),_aPV[2],_cCTD,_cEnd,_cForn})
		ENDIF
		TRB->(dbSkip())
	Enddo

	If Len(_aEstru) > 0
		//Classifi��o por Pedido de Compra, Pedido de Venda e Ordem de Produ��o
		aSort(_aEstru,,,{|x,y| x[2]+x[3]+x[12] < y[2]+y[3]+y[12]})

		For _nCnt := 1 to Len(_aEstru)
			aAdd(_aLbxIt,_aEstru[_nCnt])
		Next _nCnt

		_cTitulo := "Impress�es de Etiquetas com c�digo de barras"

		DEFINE MSDIALOG _oDlg TITLE _cTitulo FROM 000,000 to 037,125
		If nMV_PAR01 == 1
			@ 005,005 LISTBOX _oLbxIt Var _oItem FIELDS HEADER	;
				" "				,;
				"PC"			,;
				"PV"			,;
				"Cliente"		,;
				"C�digo"		,;
				"Qt. Etiq" 		,;
				"Qt. Pe�as"		,;
				"Volumes"		,;
				"Descricao"		,;
				"Lote"			,;
				"Num. OP"		,;
				"BU"			,;
				"Endere�o"		,;
				"Fornecedor"	,;
				"Nota Fiscal"	;
				SIZE 486,255 OF _oDlg PIXEL
		Elseif nMV_PAR01 == 2
			@ 005,005 LISTBOX _oLbxIt Var _oItem FIELDS HEADER	;
				" "				,;
				"PC"			,;
				"PV"			,;
				"Cliente"		,;
				"C�digo"		,;
				"Qt. Etiq" 		,;
				"Qt. Pe�as"		,;
				"Volumes"		,;
				"C�digo Jap�o"	,;
				"Lote"			,;
				"Num. OP"		,;
				"BU"			,;
				"Endere�o"		,;
				"Fornecedor"	,;
				"Nota Fiscal"	;
				SIZE 486,255 OF _oDlg PIXEL
		Endif

		_aLbxBk := aClone(_aLbxIt)
		_oLbxIt:SetArray(_aLbxIt)
		//Posi��es array   		1            	2			3		4		5			6		7	 	8		9		  10	  11  12 13     14
		//Estrutura _aLbxIt, {Nota Fiscal,PED COMPRAS ,PED VENDA,CLIENTE,PRODUTO,QUANT NOTA,QUANT NOTA,VOLUME,COD JAP�O,DESCRI��O,LOTE,OP,BU,ENDERE�O}
		If nMV_PAR01 == 1
			_oLbxIt:bLine := {||{	;
				,;
				_aLbxIt[_oLbxIt:nAt,2],;
				_aLbxIt[_oLbxIt:nAt,3],;
				_aLbxIt[_oLbxIt:nAt,4],;
				_aLbxIt[_oLbxIt:nAt,5],;
				_aLbxIt[_oLbxIt:nAt,6],;
				_aLbxIt[_oLbxIt:nAt,7],;
				_aLbxIt[_oLbxIt:nAt,8],;
				_aLbxIt[_oLbxIt:nAt,10],;
				_aLbxIt[_oLbxIt:nAt,11],;
				_aLbxIt[_oLbxIt:nAt,12],;
				_aLbxIt[_oLbxIt:nAt,13],;
				_aLbxIt[_oLbxIt:nAt,14],;
				_aLbxIt[_oLbxIt:nAt,15],;
				_aLbxIt[_oLbxIt:nAt,1]}}
		Else
			_oLbxIt:bLine := {||{	;
				,;
				_aLbxIt[_oLbxIt:nAt,2],;
				_aLbxIt[_oLbxIt:nAt,3],;
				_aLbxIt[_oLbxIt:nAt,4],;
				_aLbxIt[_oLbxIt:nAt,5],;
				_aLbxIt[_oLbxIt:nAt,6],;
				_aLbxIt[_oLbxIt:nAt,7],;
				_aLbxIt[_oLbxIt:nAt,8],;
				_aLbxIt[_oLbxIt:nAt,9],;
				_aLbxIt[_oLbxIt:nAt,11],;
				_aLbxIt[_oLbxIt:nAt,12],;
				_aLbxIt[_oLbxIt:nAt,13],;
				_aLbxIt[_oLbxIt:nAt,14],;
				_aLbxIt[_oLbxIt:nAt,15],;
				_aLbxIt[_oLbxIt:nAt,1]}}
		Endif
		//                    BMP 001 002 003 004 005 006 007 008 009 010 011 012 013 014
		_oLbxIt:aColSizes := {007,007,007,020,020,025,025,025,050,020,040,015,030,030,030,030}
		_oItem:nAt := 1
		_oLbxIt:SetFocus()

		@ 026,002 Button oBtn4 Prompt "Qtde Etiq"      Size 039,015 Action u_YOER06Qtd()
		@ 026,012 Button oBtn4 Prompt "Lista Embarque" Size 039,015 Action (u_YESTR6EM(),_oDlg:Refresh())
		@ 026,103 Button oBtn2 Prompt "Ok"             Size 039,015 Action (ArgoxImp(),_oDlg:End())
		@ 026,113 Button oBtn3 Prompt "Cancelar"       Size 039,015 Action (Close(_oDlg))

		ACTIVATE MSDIALOG _oDlg CENTERED
	EndIf


	RestArea(_aArea)

Return

/*/
	+---------------------------------------------------------------------------+
	| Fun��o    | ValidPerg  | Autor | Cristiano Gomes Cunha  | Data | 08/09/08 |
	|-----------+---------------------------------------------------------------|
	| Descri��o | Verifica a exist�ncia das perguntas, criando-as caso seja     |
	|           | necess�rio.                                                   |
	|           | Adaptado as perguntas para os fonte YOESTR06 e YESTR6M        |
	|           | Revis�o: Ivandro Santos - 20/03/13                            |
	|-----------+---------------------------------------------------------------|
	| Uso       | Espec�fico YOESTR06                                           |
	+---------------------------------------------------------------------------+
/*/

Static Function ValidPerg(cPerg)
	/*
	Local aArea     := GetArea()
	Local aAreaSx1  := SX1->( GetArea() )
	Local nX        := 0
	Local nY        := 0
	Local aCpoPerg  := {}
	Local aPerg     := {}

	dbSelectArea("SX1")
	dbSetOrder(1)
	cPerg := PADR(cPerg,10)

// Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
	aAdd( aPerg, {"01","Tipo de Consulta? ","","","MV_CH1","N",001,0,0,"C","","mv_par01","Nota","","","","","Embarque","","","","","","","","","","","","","","","","","",""})
	aAdd( aPerg, {"02","N� NF/EMBARQUE' ? ","","",'mv_ch2','C',009,0,0,'G',"",'MV_PAR02','','','','','','','','','','','','','','','','','','','','','','','','','','','',''})

//Geracao das perguntas na SX1
	aAdd( aCpoPerg, 'X1_ORDEM'   ) // 01
	aAdd( aCpoPerg, 'X1_PERGUNT' ) // 02
	aAdd( aCpoPerg, 'X1_PERSPA'  ) // 03
	aAdd( aCpoPerg, 'X1_PERENG'  ) // 04
	aAdd( aCpoPerg, 'X1_VARIAVL' ) // 05
	aAdd( aCpoPerg, 'X1_TIPO'    ) // 06
	aAdd( aCpoPerg, 'X1_TAMANHO' ) // 07
	aAdd( aCpoPerg, 'X1_DECIMAL' ) // 08
	aAdd( aCpoPerg, 'X1_PRESEL'  ) // 09
	aAdd( aCpoPerg, 'X1_GSC'     ) // 10
	aAdd( aCpoPerg, 'X1_VALID'   ) // 11
	aAdd( aCpoPerg, 'X1_VAR01'   ) // 12
	aAdd( aCpoPerg, 'X1_DEF01'   ) // 13
	aAdd( aCpoPerg, 'X1_DEFSPA1' ) // 14
	aAdd( aCpoPerg, 'X1_DEFENG1' ) // 15
	aAdd( aCpoPerg, 'X1_CNT01'   ) // 16
	aAdd( aCpoPerg, 'X1_VAR02'   ) // 17
	aAdd( aCpoPerg, 'X1_DEF02'   ) // 18
	aAdd( aCpoPerg, 'X1_DEFSPA2' ) // 19
	aAdd( aCpoPerg, 'X1_DEFENG2' ) // 20
	aAdd( aCpoPerg, 'X1_CNT02'   ) // 21
	aAdd( aCpoPerg, 'X1_VAR03'   ) // 22
	aAdd( aCpoPerg, 'X1_DEF03'   ) // 23
	aAdd( aCpoPerg, 'X1_DEFSPA3' ) // 24
	aAdd( aCpoPerg, 'X1_DEFENG3' ) // 25
	aAdd( aCpoPerg, 'X1_CNT03'   ) // 26
	aAdd( aCpoPerg, 'X1_VAR04'   ) // 27
	aAdd( aCpoPerg, 'X1_DEF04'   ) // 28
	aAdd( aCpoPerg, 'X1_DEFSPA4' ) // 29
	aAdd( aCpoPerg, 'X1_DEFENG4' ) // 30
	aAdd( aCpoPerg, 'X1_CNT04'   ) // 31
	aAdd( aCpoPerg, 'X1_VAR05'   ) // 32
	aAdd( aCpoPerg, 'X1_DEF05'   ) // 33
	aAdd( aCpoPerg, 'X1_DEFSPA5' ) // 34
	aAdd( aCpoPerg, 'X1_DEFENG5' ) // 35
	aAdd( aCpoPerg, 'X1_CNT05'   ) // 36
	aAdd( aCpoPerg, 'X1_F3'      ) // 37
	aAdd( aCpoPerg, 'X1_PYME'    ) // 38
	aAdd( aCpoPerg, 'X1_GRPSXG'  ) // 39
	aAdd( aCpoPerg, 'X1_HELP'    ) // 40

	SX1->(dbSetOrder( 1 ))
	For nX := 1 To Len( aPerg )

		If !SX1->( dbSeek( cPerg + aPerg[nX][1] ) )
			RecLock( "SX1", .T. )
			For nY := 1 To Len( aPerg[nX] )
				If aPerg[nX][nY] <> NIL .and. !Empty( aPerg[nX][nY] )
					SX1->( &( aCpoPerg[nY] ) ) := aPerg[nX][nY]
				EndIf
			Next
			SX1->X1_GRUPO := cPerg
			SX1->(MsUnlock())
		Else
			SX1->(RecLock( "SX1", .F. ))
			For nY := 1 To Len( aPerg[nX] )
				If aPerg[nX][nY] <> NIL .and. !Empty( aPerg[nX][nY] )
					SX1->( &( aCpoPerg[nY] ) ) := aPerg[nX][nY]
				EndIf
			Next
			SX1->X1_GRUPO := cPerg
			SX1->(MsUnlock())
		EndIf
	Next
	RestArea( aAreaSX1 )
	RestArea( aArea )
	*/
Return( Nil )


/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � YOER06Qtd�Autor  �Ivandro Santos      � Data �  20/03/13   ���
�������������������������������������������������������������������������͹��
���Desc.     � Rotina que permite alterar a quantidade a ser impressa das ���
���          � etiquetas permitindo alterar tamb�m volumes e qtde produto ���
�������������������������������������������������������������������������͹��
���Uso       � YOESTR06                                                   ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User Function YOER06Qtd()

//Posi��es array   		1            	2			3		4		5			6		7	 	8		9		  10	  11  12 13     14
//Estrutura _aLbxIt, {Nota Fiscal,PED COMPRAS ,PED VENDA,CLIENTE,PRODUTO,QUANT ETIQ,QUANT NOTA,VOLUME,COD JAP�O,DESCRI��O,LOTE,OP,BU,ENDERE�O}                          
	_nQtdEtiq  := 1 // _aLbxBK[_oLbxIt:nAt,6]
	_nQtProAtu := _aLbxBK[_oLbxIt:nAt,7]
	_nQtdVol   := _aLbxBK[_oLbxIt:nAt,8]

	nOpc := 0
	@ 0,0 TO 120,250 DIALOG oDlgQtd TITLE "Altera��o de Quantidades e Volumes"
	@ 02,10 SAY "Qtde Etiquetas"	Size 40
	@ 02,60 MSGET oQtdEtiq 	  VAR _nQtdEtiq  PICTURE "@E 999999.99" SIZE 30,07 OF oDlgQtd PIXEL When .T. Valid iif(_nQtdEtiq>=0,.T.,(Alert("A quantidade nao pode ser menor ou igual a zero"),.F.))
	@ 14,10 SAY "Qtde Produtos"		Size 40
	@ 14,60 MSGET oQtdProdAtu VAR _nQtProAtu PICTURE "@E 999999.99" SIZE 30,07 OF oDlgQtd PIXEL When .T. Valid iif(_nQtProAtu>=0,.T.,(Alert("A quantidade nao pode ser menor ou igual a zero"),.F.))
	@ 26,10 SAY "N� Volumes"		Size 40
	@ 26,60 MSGET oQtdVol 	  VAR _nQtdVol 	 PICTURE "@E 999999.99" SIZE 30,07 OF oDlgQtd PIXEL When .T. Valid iif(_nQtdVol>=0,.T.,(Alert("A quantidade nao pode ser menor ou igual a zero"),.F.))

	@ 45,38 BMPBUTTON TYPE 1 ACTION (nOpc := 1,Close(oDlgQtd))
	@ 45,70 BMPBUTTON TYPE 2 ACTION (nOpc := 2,Close(oDlgQtd))

	ACTIVATE MSDIALOG oDlgQtd CENTERED

	if nOpc==1
		_aLbxIt[_oLbxIt:nAt,6] := _nQtdEtiq
		_aLbxIt[_oLbxIt:nAt,7] := _nQtProAtu
		_aLbxIt[_oLbxIt:nAt,8] := _nQtdVol
	endif

Return

/*/
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	�������������������������������������������������������������������������ͻ��
	��� Programa � ArgoxImp � Autor � Anderson Messias   � Data �  26/02/2010 ���
	�������������������������������������������������������������������������͹��
	���Descri��o � Imprime etiquetas de codigo de barras Argox OS 214         ���
	���          �                                                            ���
	�������������������������������������������������������������������������͹��
	���Uso       � YOKOGAWA                                                   ���
	�������������������������������������������������������������������������ͼ��
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
/*/
Static Function ArgoxImp()

	RptStatus({|| ArgEtqEs() })



	_oDlg:Refresh()

/*/
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	�������������������������������������������������������������������������Ŀ��
	��� Programa � ArgEtqEs � Autor � Ivandro Santos        � Data �20/03/2013���
	�������������������������������������������������������������������������Ĵ��
	���Descri�ao � Imprime n etiquetas de codigo de barras conforme solicitado���
	���          � nos parametros.                                            ���
	�������������������������������������������������������������������������Ĵ��
	���Uso       � YOESTR06                                                   ���
	��������������������������������������������������������������������������ٱ�
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
/*/
Static Function ArgEtqEs()
	LOCAL _cZModel,_cZPorta, cPorta, cPadrao
	Local _nVelcImp := If(Alltrim(GetNewPar("YO_MODIMPE","ZDesigner GC420T"))=="ZDesigner GC420T",2,2) //_nVelcImp := 2
	Local nI, nAt, nE
	cPadrao := "?3"
	cPadrao := Chr(27) + cPadrao + Chr(27) + "A41" + Chr(27)
	_cZModel := Alltrim(GetNewPar("YO_MODIMPE","ZDesigner GC420T")) // parametro utilizado para definir a impressora termica. "OS 214"//
	_cZPorta := "LPT1"

	nNumEtiq := 2

	MSCBPRINTER(_cZModel,_cZPorta,,)
	MSCBCHKStatus(.F.)

	for nAt := 1 to Len(_aLbxIt)
		_nEtiq_Qtd := _aLbxIt[nAt][6]
		_nQtdProd  := _aLbxIt[nAt][7]
		_nEtiq_Vol := _aLbxIt[nAt][8]

		For nE := 1 to _nEtiq_Qtd
			nVol := 0
			For nI := 1 to _nEtiq_Vol

				MSCBBEGIN(1,_nVelcImp)
				nVol++
//Posi��es array   		2				3		4		5			6		7	 	8		9		   10	   11  12 13     14		15			1
//Estrutura _aLbxIt, {PED COMPRAS ,PED VENDA,CLIENTE,PRODUTO,QUANT ETIQ,QUANT PROD,VOLUME,COD JAP�O,DESCRI��O,LOTE,OP,BU,ENDERE�O,Fornecedor,Nota Fiscal}
				If _cZModel == "ZDesigner GC420T"
//MSCBSAYBAR(nXmm, nYmm, cConteudo, cRotacao, cTypePrt, nAltura, lDigVer, lLinha,lLinBaixo, cSubSetIni, nLargura, nRelacao, lCompacta, lSerial, cIncr,lZerosL)
//Posi��es array   		2				3		4		5			6		7	 	8		9		   10	   11  12 13     14		15			1
//Estrutura _aLbxIt, {PED COMPRAS ,PED VENDA,CLIENTE,PRODUTO,QUANT ETIQ,QUANT PROD,VOLUME,COD JAP�O,DESCRI��O,LOTE,OP,BU,ENDERE�O,Fornecedor,Nota Fiscal}
//MSCBSAYBAR(nXmm, nYmm, cConteudo, cRotacao, cTypePrt, nAltura, lDigVer, lLinha,lLinBaixo, cSubSetIni, nLargura, nRelacao, lCompacta, lSerial, cIncr,lZerosL)
					MSCBSAYBAR(05, 04, _aLbxIt[nAt][5]+_aLbxIt[nAt][11],"N","MB07",11.00,.F.,.F.,.F.,,2,4,.F.,.F.,.F.,.F.)
					MSCBSAY(   05, 16, _aLbxIt[nAt][5]+" LOTE:"+_aLbxIt[nAt][11],"N","0","35")
					//MSCBSAY(   71,04, Iif(nMV_PAR01 == 1,"N.F. - ","Emb. - ")+DTOC(dDataBase),"N","0","20")
					//MSCBSAY(   71,07, Iif(nMV_PAR01 == 1,_aLbxIt[nAt][1],_aLbxIt[nAt][11]),"N","0","33")
					If Len(Alltrim(_aLbxIt[nAt][10])) > 30
						MSCBSAY(   05, 22, Iif(nMV_PAR01 == 1, SubStr(Alltrim(_aLbxIt[nAt][10]),1,30),SubStr(Alltrim(_aLbxIt[nAt][9]),1,30)),"N","E","0,2")
						MSCBSAY(   05, 26, Iif(nMV_PAR01 == 1, SubStr(Alltrim(_aLbxIt[nAt][10]),31,30),SubStr(Alltrim(_aLbxIt[nAt][9]),31,30)),"N","E","0,2")
						MSCBSAY(   05, 30, Iif(nMV_PAR01 == 1, SubStr(Alltrim(_aLbxIt[nAt][10]),62,30),SubStr(Alltrim(_aLbxIt[nAt][9]),62,30)),"N","E","0,2")
					Else
						MSCBSAY(   05, 22, Iif(nMV_PAR01 == 1, PADR(_aLbxIt[nAt][10],30),PADR(_aLbxIt[nAt][9],30)),"N","E","1,8")
					Endif
					If !Empty(_aLbxIt[nAt][4])
						MSCBSAY(   35,  35, _aLbxIt[nAt][4],"N","0","35")
						MSCBSAY(   05, 35, "P.V : "+_aLbxIt[nAt][3],"N","0","35,0")
					Endif
					Iif(!Empty(_aLbxIt[nAt][12]),MSCBSAY(   05,  45, "O.P : "+_aLbxIt[nAt][12],"N","0","30,0")," ")
					Iif(!Empty(_aLbxIt[nAt][2]) ,MSCBSAY(   05,  40, "P.C : "+_aLbxIt[nAt][2] ,"N","0","30,0")," ")
					Iif(nMV_PAR01 == 1			,MSCBSAY(   35,  40, "FORN : "+_aLbxIt[nAt][15],"N","0","30,0")," ")
					//Iif(!Empty(_aLbxIt[nAt][13]),MSCBSAY(   60,  14, "BU : " +_aLbxIt[nAt][13],"N","0","30,0")," ")
					//Iif(!Empty(_aLbxIt[nAt][14]),MSCBSAY(   67,  42, "END : " +_aLbxIt[nAt][14],"N","0","30,0")," ")
					If _nEtiq_Qtd == _nQtdProd
						MSCBSAY(   67, 50, "QTDE : "+alltrim(str(_nQtdProd / _nEtiq_Qtd))+" "+GETADVFVAL("SB1","B1_UM",xFilial("SB1")+_aLbxIt[nAt][5],1," "),"N","0","35,0")
					Else
						MSCBSAY(   67, 50, "QTDE : "+alltrim(str(_nQtdProd))+" "+ GETADVFVAL("SB1","B1_UM",xFilial("SB1")+_aLbxIt[nAt][5],1," "),"N","0","35,0")
					Endif
					MSCBSAY(   67, 56, "VOL: "+alltrim(str(nVol))+" / "+alltrim(str(_nEtiq_Vol)),"N","0","30,0")
					//MSCBSAY(   03,47, Iif(nMV_PAR01 == 1,"N.F. - "+_aLbxIt[nAt][1],"Emb. - "+_aLbxIt[nAt][11]),"N","0","30")
					MSCBSAY(   05,50, DTOC(dDataBase),"N","0","30")
					//MSCBSAY(   03, 47, "YOKOGAWA AMERICA DO SUL","N","D","1,2")
					//MSCBSAY(   03, 51, "Praca Acapulco, 31 - Sao Paulo","N","D","1,0")
					//MSCBSAY(   03, 55, "CNPJ : 53.761.607/0001-50","N","D","1,0")
				Endif
				MSCBEnd()
				MSCBClosePrinter()
			Next
		Next
	Next


	#IFDEF WINDOWS
		Set Device To Screen
		Set Printer To
	#ENDIF

Return
