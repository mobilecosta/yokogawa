//@CHK12.1.2210
#INCLUDE "Protheus.ch"
#INCLUDE "Totvs.ch"
#INCLUDE "TopConn.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE 'rwmake.ch'

#Define ENTER CHR(13)+CHR(10)

/*
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
*/
User Function YOFATA10()

	Private cTitulo   := "Dados Expedição"
	Private cCadastro := OEMTOANSI (cTitulo)
	Private lEnd	  := .F.
	Private CdelFunc  := ".T."
	Private cAliasSZ3 := "SZ3" //Alterado
	Private aCores 	  := {}
	Private aRotina   := {	{"Pesquisa" 			,"AxPesqui" 					, 00, 1 },;
		{"Visualizar"			,"AxVisual"						, 00, 2 },;
		{"Informar Dados"		,"U_YOFAT10A(3)"				, 00, 3 },;
		{"Alterar Dados"		,"U_YOFAT10A(4)"				, 00, 4 },;
		{"Excluir Dados"		,"U_YOFAT10A(5)"				, 00, 5 },;
		{"Imprimir Etiqueta"	,"U_YOFAT10D(SZ3->Z3_PICK)"		, 00, 6 },;
		{"Faturar Pedido"		,"U_YOFAT10F(SZ3->Z3_PICK)"		, 00, 6 },;
		{"Monitor Sefaz"		,"Processa( {|| U_ChkMonSef(,,SZ3->Z3_PEDIDO)}, 'Verificando NFs...', 'Aguarde...', .T.)"	, 00, 6 },;
		{"Legenda"				,"U_UFATXLEG"					, 00, 6 }}
	
	AADD(aCores,{"Z3_IMPETQ == 'N' "	,"BR_VERDE" })
	AADD(aCores,{"Z3_IMPETQ == 'S' .And. Empty(GetAdvFVal('SC5','C5_NOTA',xFilial('SC5')+Z3_PEDIDO,1,''))","BR_VERMELHO" })
	AADD(aCores,{"Z3_IMPETQ == 'S' .And. !Empty(GetAdvFVal('SC5','C5_NOTA',xFilial('SC5')+Z3_PEDIDO,1,''))","BR_PRETO" })

	dbSelectArea(cAliasSZ3)
	dbSetOrder(1)
	mBrowse( 6,1,22,75,cAliasSZ3,,,,,,aCores)

Return

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFAT10A ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User Function YOFAT10A(_nOpc)
	Local aPosObj    	:= {}
	Local aObjects   	:= {}
	Local aSize      	:= MsAdvSize(.T.)
	Local cLinOK     	:= "AllwaysTrue"
	Local cTudoOK       := "AllwaysTrue"
	Local nLinhas		:= 100
//Local lPV 			:= .F.
//Local cFieldOK   	:= "AllwaysTrue"
//Local nPesoCarg		:= 0
//Local oOk      		:= LoadBitmap( GetResources(), "LBOK" )   //CHECKED    //LBOK  //LBTIK
//Local oNo      		:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO
//Local oChk     		:= Nil
	Private lChk     	:= .F.
	Private oLbx 	 	:= Nil
	Private _aYColsM1  	:= {} //Alterado
	Private _aYHeadM1 	:= {} //Alterado
	Private aEdiCpo	  	:= {}
	Private nOpc        := _nOpc
	Private _nYFreeze 	:= 0 //Alterado
	Private cAliaM1     := "TRIND"
	Private aRotina 	:= {}
	Private _oYGetDadM1     //Alterado
	Private oMainPV 	:= Nil
	Private _aTitTRB 	:= {}
	Private oValorPed 	:= 0
	Private _cNPedido 	:= ""
	Private aOpcoes 	:= {}
	Private aFilVal 	:= {}
	Private cEndFis		:= Space(15)
	Private _nYVolume	:= CriaVar("C6_QTDVEN") //Alterado
	Private nPesoT		:= CriaVar("C6_QTDVEN")
	Private cEmbalag	:= Space(40)
	Private cDescEmbal	:= CriaVar("Z3_DEMBALA")
	Private cNPick		:= CriaVar("C9_XPICKLT")
	Private cyarq		:= ""
	Private _cTo		:= ""
	Private _cTitle		:= ""
	Private _cMensage	:= ""
	Private nOpcProc    := 0
	//CHECK VARIAVEIS OTEMP
	Private oTemp

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Numero do Picking            MV_PAR01                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cPerg := PADR("YOPCPR26",10)

	ValPerg(cPerg)

	If nOpc == 3

		If !Pergunte(cPerg,.T.)
			Return
		Endif

		cNPick := MV_PAR01

		dbSelectArea("SZ3")
		dbSetOrder(1)
		SZ3->(dbGoTop())
		If SZ3->(dbSeek(xFilial("SZ3")+cNPick))
			Aviso("Atencao","O Picking List: "+cNPick+" já esta lançado. Utilize a opção Alterar Dados.",{"Ok"},2,"Processo Interrompido")
			Return
		Endif
	Else
		cNPick 		:= SZ3->Z3_PICK
		cEndFis		:= SZ3->Z3_LOCALIZ
		_nYVolume	:= SZ3->Z3_VOLUMES
		nPesoT		:= SZ3->Z3_PESOL
		nPesoT		:= SZ3->Z3_PBRUTO
		cEmbalag	:= SZ3->Z3_EMBALAG
		cDescEmbal	:= ""
	Endif

// Criacao do arquivo de Trabalho
	FCRIATRB()
// Alimenta Arquivos de Trabalho
	MsgRun("Selecionando Dados","Aguarde....",{||FSELEDADOS(nOpc)})
//Alimenta o aheader
	ADDAHEAD()
//Alimenta o acols e cria o temporario
	ADDACOLS()

	dbSelectArea("TRIND")
	dbSetOrder(1)
	dbGoTop()
	If TRIND->(Bof()) .And. TRIND->(Eof())
		Aviso("Atencao","Não há dados para o Picking List: "+cNPick+". A nota fiscal já pode ter sido emitida!",{"Ok"},2,"Processo Interrompido")
		Return
	Endif

	If nOpc <> 5
		DEFINE FONT oFont1  NAME "Arial" SIZE 0,16 BOLD
		DEFINE FONT oFont2  NAME "Arial" SIZE 0,20 BOLD

		aSize := MsAdvSize()
		aObjects := {}
		AAdd( aObjects, { 100, 100, .t., .t. } )
		AAdd( aObjects, { 100, 100, .t., .t. } )
		AAdd( aObjects, { 100, 020, .t., .f. } )

		aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
		aPosObj := MsObjSize( aInfo, aObjects )

		DEFINE MSDIALOG oMainPV TITLE OemtoAnsi("Dados Expedição") From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL

		@ 010,010 To 055,aSize[3] LABEL  OF oMainPV PIXEL
		@ 017,015 Say "Pedido:  "	+_cNPedido		SIZE 60,10  OF oMainPV PIXEL FONT oFont1  	COLOR CLR_BLUE

		@ 017,090 Say "Endereço Fisico: "  						OF oMainPV PIXEL FONT oFont1  	COLOR CLR_BLUE
		@ 015,140 MSGET cEndFis PICTURE "@!"  		SIZE 60,10  OF oMainPV PIXEL FONT oFont1  	COLOR CLR_BLUE

		@ 017,220 Say "Volumes:  "					 			OF oMainPV PIXEL FONT oFont1  	COLOR CLR_BLUE
		@ 015,250 MSGET _nYVolume PICTURE "@E 9,999"				SIZE 40,10  OF oMainPV PIXEL FONT oFont1  	COLOR CLR_BLUE

		@ 017,315 Say "Peso Bruto:  "		 					OF oMainPV PIXEL FONT oFont1  	COLOR CLR_BLUE
		@ 015,350 MSGET nPesoT PICTURE "@E 9,999.99" 			SIZE 40,10  OF oMainPV PIXEL FONT oFont1  	COLOR CLR_BLUE

		@ 017,420 Say "Picking:  "	+cNPick			SIZE 75,10  OF oMainPV PIXEL FONT oFont1  	COLOR CLR_BLUE

		@ 036,015 Say "Embalagen(s):  "			 				OF oMainPV PIXEL FONT oFont1  	COLOR CLR_BLUE
		@ 034,075 MSGET cEmbalag PICTURE "@!" Valid (u_URETEMBA())	SIZE 150,10 OF oMainPV PIXEL FONT oFont1  	COLOR CLR_BLUE

		_oYGetDadM1 := MsNewGetDados():New(065,aPosObj[1,2]+8,aPosObj[2,3],aPosObj[2,4],0,cLinOK,cTudoOK,"","",_nYFreeze,9999,,,,oMainPV,_aYHeadM1,_aYColsM1)

		oTButton1 := TButton():Create( oMainPV,aPosObj[3,1],aPosObj[2,2]+05,"Gravar",({||nOpcProc := 1,oMainPV:End() }),50,15,,,,.T.,,,,,,)
		oTButton2 := TButton():Create( oMainPV,aPosObj[3,1],aPosObj[2,2]+60,"Sair"  ,({||oMainPV:End()}),45,15,,,,.T.,,,,,,)

		ACTIVATE MSDIALOG oMainPV CENTERED
	Else
		DEFINE FONT oFont1  NAME "Arial" SIZE 0,16 BOLD
		DEFINE FONT oFont2  NAME "Arial" SIZE 0,20 BOLD

		aSize := MsAdvSize()
		aObjects := {}
		AAdd( aObjects, { 100, 100, .t., .t. } )
		AAdd( aObjects, { 100, 100, .t., .t. } )
		AAdd( aObjects, { 100, 020, .t., .f. } )

		aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
		aPosObj := MsObjSize( aInfo, aObjects )

		DEFINE MSDIALOG oMainPV TITLE OemtoAnsi("Dados Expedição") From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL

		@ 010,010 To 055,aSize[3] LABEL  OF oMainPV PIXEL
		@ 017,015 Say "Pedido:  "	+_cNPedido					      OF oMainPV PIXEL FONT oFont1  COLOR CLR_BLUE

		@ 017,090 Say "Endereço Fisico: "+Alltrim(cEndFis)			  OF oMainPV PIXEL FONT oFont1  COLOR CLR_BLUE

		@ 017,220 Say "Volumes:  "+Alltrim(Str(_nYVolume))              OF oMainPV PIXEL FONT oFont1  COLOR CLR_BLUE

		@ 017,315 Say "Peso Bruto:  "+Alltrim(Str(nPesoT))            OF oMainPV PIXEL FONT oFont1  COLOR CLR_BLUE

		@ 017,420 Say "Picking:  "	+cNPick			                  OF oMainPV PIXEL FONT oFont1  COLOR CLR_BLUE

		@ 036,015 Say "Embalagen(s):  "+cEmbalag			 		  OF oMainPV PIXEL FONT oFont1  COLOR CLR_BLUE

		_oYGetDadM1 := MsNewGetDados():New(065,aPosObj[1,2]+8,aPosObj[2,3],aPosObj[2,4],0,cLinOK,cTudoOK,"","",_nYFreeze,9999,,,,oMainPV,_aYHeadM1,_aYColsM1)

		oTButton1 := TButton():Create( oMainPV,aPosObj[3,1],aPosObj[2,2]+05,"Excluir",({||nOpcProc := 1 }),50,15,,,,.T.,,,,,,)
		oTButton2 := TButton():Create( oMainPV,aPosObj[3,1],aPosObj[2,2]+60,"Sair",({||oMainPV:End()}),45,15,,,,.T.,,,,,,)

		ACTIVATE MSDIALOG oMainPV CENTERED
	EndIf
	If nOpcProc == 1
		YOFAT10B(nOpc)
		FWAlertSuccess("Mensagem de sucesso", "Informações Gravadas")
		//Aviso( "Processado", 'Informações Gravadas', { "Ok" },1,,, 'ROTINAAUTO', .F.)
		/*
		//Sintaxe
		//Aviso( <cTitulo>, <cMensagem>, <aBotoes>, <nTamTela>, <cSubTitulo>, <nRotAut>, <cBitMap>, <lEditMemo>, <nTimer> )

		//Parâmetros
		//Par	Nome		Tipo		Descrição													Default	Obg	Ref
		//01	cTitulo		Caracter	Titulo a ser Exibido			
		//02	cMensagem	Caracter	Mensagem a ser Exibida na Tela			
		//03	aBotoes		Array		Botões a ser Apresentado na tela									X	
		//04	nTamTela	Numérico	Tamanho da Tela. Valores: 1, 2 ou 3			
		//05	cSubTitulo	Caracter	SubTitulo. Titulo apresentado abaixo do Titulo definido			
		//06	nRotAuto	Numérico	Reservado Sistema			
		//07	cBitMap		Caracter	Nome da Imagem ser apresentado. Imagem compilada no APO			
		//08	lEditMemo	Boolean		Permite editação do Memo?									.F.		
		//09	nTimer		Numérico	Segundos para a Tela ser fechada Automaticamente			
		
		//Retorno
		//Retorno	Tipo		Descrição
		//nOpc		Numérico	Número da opção que foi Selecionada. Clique no botão.		
		*/
	EndIf

Return


/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18     ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function FCRIATRB()

	Local _nElem 	:= 0
	Local _aStru 	:= {}
	// Estrutura do temporario
	AADD(_aStru,{"ITEM"     	,"C",TamSX3("C9_ITEM")[1],0})
	AADD(_aStru,{"PRODUTO"    	,"C",TamSX3("C9_PRODUTO")[1],0})
	AADD(_aStru,{"DESCRICAO"  	,"C",TamSX3("B1_DESC")[1],0})
	AADD(_aStru,{"QTDLIB" 	  	,"N",TamSX3("C9_QTDLIB")[1],TamSX3("C9_QTDLIB")[2]})
	AADD(_aStru,{"ID" 	  		,"N",10,0})

	// Titulos dos Campos
	AADD(_aTitTRB,{"QTDLIB"		,"QUANTIDADE"})
	
	//Projeto release 12.1.2210
	//julio.nobre@grupoviseu.com.br

	// Criacao Temporario dos Produtos
	//_cArq     := CriaTrab(_aStru,.T.)
	//_cIndice  := CriaTrab(Nil,.F.)


	If Sele("TRIND") <> 0
		TRIND->(DbCloseArea())
	Endif
	
	_cChaveInd	 := {"ITEM","PRODUTO"}  // Luciano 05/09/2023

	If(oTemp <> NIL)
		oTemp:Delete()
		oTemp := NIL
	EndIf
	
	oTemp := FWTemporaryTable():New( "TRIND" )
	oTemp:SetFields( _aStru )
	oTemp:AddIndex("01", _cChaveInd )
	oTemp:Create()
	/*
	If Sele("TRIND") <> 0
		TRIND->(DbCloseArea())
	Endif
	*/

	//dbUseArea(.T.,,_cArq,"TRIND",.F.,.F.)
	//IndRegua("TRIND",_cIndice,_cChaveInd,,,"Selecionando Registros...")

Return

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function FSELEDADOS(nOpc)

	Local _aStru := {}
	Local cQuery := ""

	DbSelectArea("TRIND")
	__DbZap()

// Gravacao do Temporario
	cQuery := " SELECT C9_FILIAL,C9_PEDIDO,SC9.R_E_C_N_O_ AS RECSC9,C9_ITEM,C9_SEQUEN,C9_PRODUTO,B1_DESC,C9_QTDLIB "
	cQuery += " FROM "+RetSqlName("SC9")+" SC9 "
	cQuery += " LEFT JOIN "+RetSqlName("SB1")+" SB1 ON (B1_COD=C9_PRODUTO AND SB1.D_E_L_E_T_='') "
	cQuery += " WHERE SC9.D_E_L_E_T_='' AND C9_NFISCAL='' AND C9_XPICKLT='"+cNPick+"' AND SC9.C9_BLCRED = '  '"

	If Select("TSC9") > 0
		dbSelectArea("TSC9")
		dbCloseArea()
	EndIf

	TCQUERY cQuery NEW ALIAS "TSC9"

	dbSelectArea("TSC9")
	TSC9->(dbGoTop())
	While !TSC9->(Eof())

		RecLock("TRIND",.T.)
		TRIND->ITEM		 := TSC9->C9_ITEM
		TRIND->PRODUTO	 := TSC9->C9_PRODUTO
		TRIND->DESCRICAO := TSC9->B1_DESC
		TRIND->QTDLIB	 := TSC9->C9_QTDLIB
		TRIND->ID	 	 := TSC9->RECSC9

		//Variaveis para o Cabecalho da tela
		_cNPedido	   	 := TSC9->C9_PEDIDO

		dbSelectArea("TSC9")
		TSC9->(dbSkip())
	Enddo

Return

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function ADDAHEAD()

	Local cNotField := " "
	Local _nElem	:= 0

// Posiciona no SX3 apenas para pegar os campos usado, contexto,etc..
//Criacao dos Header Produto
	DbSelectArea("TRIND")
	_aStruTRB := DbStrucT()
	For _nElem := 1 To Len(_aStruTRB)
		_cCampo   := _aStruTRB[_nElem,01]
		_cTipo	  := _aStruTRB[_nElem,02]
		_nTamanho := _aStruTRB[_nElem,03]
		_nDecimal := _aStruTRB[_nElem,04]
		_cArquivo := "TRIND"
		_cPicture := "@!"
		_cTitulo  := _cCampo
		_nPosTipo := Ascan(_aTitTRB,{|x| X[1] == _cCampo})
		If _nPosTipo > 0
			_cTitulo := _aTitTrb[_nPosTipo][02]
		Endif
		If _cTipo == "N" .And. _cCampo <> "ID"
			_cPicture := "@E 999,999.99"
		Endif
		If Alltrim(_cCampo) $ cNotField
			Loop
		Endif
		AADD(aEdiCpo,_cCampo)
		dbSelectArea("SX3")
		dbSetOrder(2)
		If _cTipo == "C"
			MsSeek("B2_COD")
		ElseIf _cTipo == "N"
			MsSeek("B2_QATU")
		ElseIf _cTipo == "D"
			MsSeek("C2_EMISSAO")
		Endif
		AAdd(_aYHeadM1, {Trim(_cTitulo),;
			_cCampo          ,;
			_cPicture     ,;
			_nTamanho     ,;
			_nDecimal     ,;
			SX3->X3_Valid ,;
			SX3->X3_Usado ,;
			_cTipo        ,;
			_cArquivo     ,;
			SX3->X3_Context})
	Next _nElem

Return

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function ADDACOLS()

	Local nQtdM1  	 := Len(_aYHeadM1)
	Local nColuna 	 := 0
	Local nPos,nM	 := 0
	Local aCampos	 := TRIND->(dbStruct())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Alimenta Acols     |
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("TRIND")
	DbGoTop()
	While !Eof()
		AAdd(_aYColsM1, Array(nQtdM1+1))
		nColuna := Len(_aYColsM1)
		For nM := 1 To Len(aCampos)
			cCpoTRB := "TRIND->" + aCampos[nM][1]
			_cConteudo := &cCpoTRB
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Preenche o acols ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nPos := AScan(_aYHeadM1, {|aX| Alltrim(aX[2]) == Alltrim(aCampos[nM][1]) })
			If nPos > 0
				_aYColsM1[nColuna][nPos] := _cConteudo
			EndIf
		Next nM
		_aYColsM1[nColuna][nQtdM1+1]  := .F.
		dbSkip()
	EndDo

Return

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function ValPerg(cPerg)

	Local _sAlias := Alias()
	Local aRegs := {}
	Local i,j

	dbSelectArea("SX1")
	dbSetOrder(1)

// Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
	aAdd(aRegs,{cPerg,"01","Numero Picking        ?","","","mv_ch1","C",09,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","",""})


	For i := 1 to Len(aRegs)
		If !dbSeek(cPerg + aRegs[i,2])
			RecLock("SX1",.T.)
			For j := 1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

	DbSelectArea(_sAlias)

Return Nil

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function YOFAT10B(nOpc)

	//MsgRun("Processando","Aguarde....",{||YOFAT10C(nOpc)}) //Retirado a regua porque trava a tela
	YOFAT10C(nOpc)

Return .t.

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
Static Function YOFAT10C(nOpc)
	Local nAtuPV 	:= 1
	Local aEmbals	:= {}
	Local aAllusers := {}
	Local _cCliName := ""
	Local nXX,nCont

	ProcRegua(-1)
	dbSelectArea("TRIND")
	TRIND->(dbGoTop())
	While TRIND->(!Eof())
		//MsProcTxt("Gravandos Dados ")
		If nOpc <> 5

			dbSelectArea("SZ3")
			dbSetOrder(1) //Z3_FILIAL+Z3_PICK+Z3_PEDIDO+Z3_ITEM+Z3_PRODUTO
			SZ3->(dbSeek(xFilial("SZ3")+cNPick+_cNPedido+TRIND->ITEM+TRIND->PRODUTO))

			Reclock("SZ3",IIF(nOpc==3,.T.,.F.))
			SZ3->Z3_FILIAL 	 := xFilial("SZ3")
			SZ3->Z3_PEDIDO 	 := _cNPedido
			SZ3->Z3_PICK  	 := cNPick
			SZ3->Z3_LOCALIZ  := cEndFis
			SZ3->Z3_VOLUMES  := _nYVolume
			SZ3->Z3_PESOL    := nPesoT
			SZ3->Z3_PBRUTO   := nPesoT
			SZ3->Z3_EMBALAG  := cEmbalag
			SZ3->Z3_DEMBALA  := IIF(!Empty(cDescEmbal),cDescEmbal,SZ3->Z3_DEMBALA)
			SZ3->Z3_ITEM  	 := TRIND->ITEM
			SZ3->Z3_PRODUTO  := TRIND->PRODUTO
			SZ3->Z3_QTDLIB   := TRIND->QTDLIB
			SZ3->Z3_RECSC9   := TRIND->ID
			SZ3->Z3_USER     := cUserName
			SZ3->Z3_DATA   	 := dDatabase
			SZ3->Z3_HORA   	 := Time()
			SZ3->Z3_IMPETQ 	 := "N"
			SZ3->(msUnlock())
			//Atualiza o Pedido de Vendas
			If nAtuPV == 1
				//Verifica se a especie das embalagens são iguais
				aEmbals := STRTOKARR(cEmbalag, "/")
				cEspeci1 := ""
				cCompara := ""
				For nXX := 1 To Len(aEmbals)
					If nXX == 1
						cEspeci1 := Alltrim(GETADVFVAL("CB3","CB3_YESPEC",xFilial("CB3")+Alltrim(aEmbals[nXX]),1," "))
					Endif
					cCompara := Alltrim(GETADVFVAL("CB3","CB3_YESPEC",xFilial("CB3")+Alltrim(aEmbals[nXX]),1," "))
					If cCompara <> cEspeci1
						cEspeci1 := "Volume(S)"
						Exit
					Endif
				Next nXX

				dbSelectArea("SC5")
				SC5->(dbSetOrder(1))
				SC5->(dbSeek(xFilial("SC5")+_cNPedido))
				Reclock("SC5", .F. )
				SC5->C5_PESOL	:= nPesoT
				SC5->C5_PBRUTO	:= nPesoT
				SC5->C5_VOLUME1	:= _nYVolume
				SC5->C5_ESPECI1	:= cEspeci1
				SC5->(msUnlock())
			Endif
			nAtuPV++
		Else
			dbSelectArea("SZ3")
			dbSetOrder(1) //Z3_FILIAL+Z3_PICK+Z3_PEDIDO+Z3_ITEM+Z3_PRODUTO
			If SZ3->(dbSeek(xFilial("SZ3")+cNPick+_cNPedido+TRIND->ITEM+TRIND->PRODUTO))
				Reclock("SZ3",.F.)
				SZ3->(dbDelete())
				SZ3->(msUnlock())
			Endif
		Endif
		dbSelectArea("TRIND")
		TRIND->(dbSkip())
	Enddo

	If nOpc <> 5
		u_YOFAT10D(cNPick)
	    u_Env_Coleta(aEmbals)  // Luciano 22/09/2023 - chamado INC0625754
	EndIf
Return()

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User Function URETEMBA()

	Local cTitulo:=""
	Local MvPar,nXX
	Local MvParDef:=""
	Local lRet  := .T.
	Local nElem := 0
	Local nTam  := TamSX3("CB3_CODEMB")[1]	//Tamanho da Chave

	Static nVezAdt := 0

	Private aSit:={}

	If (nVezAdt = Nil .OR. nVezAdt < 1)

		nVezAdt ++

		cAliasSZ3 := Alias() 					 // Salva Alias Anterior
		MvPar:=&(Alltrim(ReadVar()))		 // Carrega Nome da Variavel do Get em Questao

		dbSelectArea("CB3")
		CB3->(dbGoTop())
		cTitulo := "Embalagens"

		CursorWait()
		While CB3->(!Eof())
			Aadd(aSit,Left(CB3->CB3_CODEMB,3) + " - " + Alltrim(CB3->CB3_DESCRI))
			//MvParDef += Alltrim(Str(Len(aSit)))
			MvParDef += Left(CB3->CB3_CODEMB,3)
			nElem ++
			CB3->(dbSkip())
		Enddo
		CursorArrow()

		nElem := IIF(nElem > 10, 10, nElem) //Maximo de 10 itens selecionados

		If f_Opcoes(@MvPar,cTitulo,@aSit,MvParDef,12,49,.F.,nTam,nElem,,,,,,.T.)  // Chama funcao f_Opcoes
			cEmbalag := Space(40)
			cDescEmbal	:= CriaVar("Z3_DEMBALA")

			For nXX := 1 To Len(MvPar)
				cEmbalag += Alltrim(MvPar[nXX])+"/"
				cDescEmbal += Alltrim(GetAdvFval("CB3","CB3_DESCRI",xFilial("CB3")+MvPar[nXX],1," "))+ENTER
			Next nXX
			cEmbalag := Subs(Alltrim(cEmbalag),1,Len(Alltrim(cEmbalag))-1)
		EndIf
		dbSelectArea(cAliasSZ3)
		lRet := .F.
	ElseIf nVezAdt >= 1
		nVezAdt := 0
		lRet := .T.
		oMainPV:Refresh()
	EndIf

Return(lRet)

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User Function UFATXLEG()

	Local aCor := {}
	aAdd(aCor,{"BR_VERDE" 			,"Etiqueta Não Impressa"})
	aAdd(aCor,{"BR_VERMELHO"		,"Etiqueta já Impressa"})
	aAdd(aCor,{"BR_PRETO"			,"Pedido Faturado"})

	BrwLegenda(cCadastro,OemToAnsi("Status Etiquetas"),aCor)

Return

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOFATA10 ¦ Autor ¦  Marcio Gois     ¦    Data  ¦ 22/02/18    ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/
User Function YOFAT10D(_cYPick)

	Local _cZModel,_cZPorta, cPorta, cPadrao,nYY,nI
	Local _nVelcImp := 4
	Local cTag 		:= ""
	Local cRange 	:= ""
	Local lCopias 	:= .T.
	Local cNumSerie := ""
	Local _cSequenc := ""
	Local _cPedVen	:= ""
	Local _cItmPed	:= ""
	Local cCodItm	:= ""
	Local aLinProd	:= {}

	SetPrvt("CPERG,NRESP,CPORTA,CPADRAO,MV_PAR06")
	SetPrvt("CARQ,NHDLARQ,I,CPRECO,CCOD,CLINHA1")
	SetPrvt("CLINHA2,CLINHA3,CLINHA4,_SALIAS,AREGS,J")

	cPadrao := "?3"
	cPadrao := Chr(27) + cPadrao + Chr(27) + "A41" + Chr(27)
	_cZModel := "SM4" // parametro utilizado para definir a impressora termica.
	_cZPorta := "LPT1"

	cQuery := " SELECT Z3_PRODUTO,SUM(Z3_QTDLIB) Z3_QTDLIB, C5_NUM, C5_PEDCLI, C5_TPFRETE, A1_NREDUZ, A1_EST, A1_MUN, Z3_VOLUMES, Z3_PBRUTO "
	cQuery += " FROM "+RetSqlName("SZ3")+" Z3 "
	cQuery += " LEFT JOIN "+RetSqlName("SC5")+" C5 ON (C5_FILIAL=Z3_FILIAL AND C5_NUM=Z3_PEDIDO AND C5.D_E_L_E_T_='') "
	cQuery += " LEFT JOIN "+RetSqlName("SA1")+" A1 ON (A1_COD=C5_CLIENTE AND A1_LOJA=C5_LOJACLI AND A1.D_E_L_E_T_='') "
	cQuery += " WHERE Z3.D_E_L_E_T_='' AND Z3_PICK='"+_cYPick+"' "
	cQuery += " GROUP BY Z3_PRODUTO,C5_NUM, C5_PEDCLI, C5_TPFRETE, A1_NREDUZ, A1_EST, A1_MUN, Z3_VOLUMES, Z3_PBRUTO "

	If Select("TRBETQ") > 0
		dbSelectArea("TRBETQ")
		dbCloseArea()
	EndIf

	TCQUERY cQuery NEW ALIAS "TRBETQ"

	nCont := 1
	dbSelectArea("TRBETQ")
	TRBETQ->(dbGoTop())
	While !TRBETQ->(Eof())
		cNumPV 	:= TRBETQ->C5_NUM
		cClient	:= TRBETQ->A1_NREDUZ
		cPVClie	:= TRBETQ->C5_PEDCLI
		cCidade	:= TRBETQ->A1_MUN
		cUF		:= TRBETQ->A1_EST
		cFrete	:= BSCXBOX("C5_TPFRETE", TRBETQ->C5_TPFRETE)
		nEtqVol	:= TRBETQ->Z3_VOLUMES
		nPesoB	:= TRBETQ->Z3_PBRUTO

		//Itens
		cCodItm += Alltrim(TRBETQ->Z3_PRODUTO) +"-"+ Alltrim(Str(TRBETQ->Z3_QTDLIB)) + "/" + IIF(nCont==4,"#","")

		If nCont==4
			nCont := 0
		Endif
		nCont++
		TRBETQ->(dbSkip())
	Enddo

	aLinProd := STRTOKARR(cCodItm, "#")
//Caso tenha mais produtos do que a etiqueta comporta
	If Len(aLinProd) > 9
		aLinProd := {"Produto conforme lista Romaneio"}
	Endif

	ASize(aLinProd, 9) //Maximo de 9 Linhas por Etiqueta
	For nYY := 1 To Len (aLinProd)
		aLinProd[nYY] := IIF(aLinProd[nYY] == Nil,"",aLinProd[nYY])
	Next nYY

//Inicia a Impressao da etiqueta
	MSCBPRINTER(_cZModel,_cZPorta,,)
	MSCBCHKStatus(.F.)

	nVol := 0
	For nI := 1 to nEtqVol

		MSCBBEGIN(1,_nVelcImp)

		nVol++
		//	   Pos X, Pos Y,      Texto, Rotacao, Fonte, Tamanho
		MSCBSAY(  08,   208, "YOKOGAWA","B"     , "0"  , "75,0")
		MSCBLineV(20,190,75,3)
		MSCBSAY(  22, 200, "YOKOGAWA America do Sul Ltda","B","0","30")

		MSCBSAY(  08, 120, "Alameda Xingu, 850 - Barueri/SP","B","D","1,0")
		MSCBSAY(  13, 120, "CNPJ : 53.761.607/0001-50","B","D","1,0")

		MSCBBOX( 07, 15, 23, 110)
		MSCBBOX( 07, 90, 23, 110)
		MSCBSAY( 14, 95, "NF: ","B","E","16")

		MSCBSAYBAR(19, 117, Alltrim(cNumPV),"B","MB07",15,.F.,.F.,.F.,,3,3,.F.,.F.,.F.,.F.)
		MSCBSAY(  27, 90, "PV: ","B","E","12")
		MSCBSAY(  27, 70, Alltrim(cNumPV),"B","0","40")
		MSCBSAY(  27, 15, "Data: "+DTOC(dDataBase),"B","E","12")
		MSCBLineV( 35, 5, 2000, 3)

		MSCBSAY(  42, 235, "Cliente: ","B","E","11",,,,,.T.)
		nSpace := 20 - Len(cClient)
		MSCBSAY(  40, 140, cClient+Space(nSpace),"B","0","50",,,,,.T.)
		MSCBSAY(  42, 90, "Pedido: ","B","E","11",,,,,.T.)
		nSpace := 20 - Len(cPVClie)
		MSCBSAY(  40, 15,  cPVClie,"B","0","50,0",,,,,.T.)

		MSCBSAY(  52, 235, "Codigos: ","B","E","11",,,,,.T.)
		nSpace := 82 - Len(aLinProd[1])
		MSCBSAY(  52, 10, aLinProd[1]+Space(nSpace),"B","F","12",,,,,.T.)

		nSpace := 82 - Len(aLinProd[2])
		MSCBSAY(   58, 10, aLinProd[2]+Space(nSpace),"B","F","12",,,,,.T.)

		nSpace := 82 - Len(aLinProd[3])
		MSCBSAY(   64, 10, aLinProd[3]+Space(nSpace),"B","F","12",,,,,.T.)

		nSpace := 82 - Len(aLinProd[4])
		MSCBSAY(   70, 10, aLinProd[4]+Space(nSpace),"B","F","12",,,,,.T.)

		nSpace := 82 - Len(aLinProd[5])
		MSCBSAY(   76, 10, aLinProd[5]+Space(nSpace),"B","F","12",,,,,.T.)

		nSpace := 82 - Len(aLinProd[6])
		MSCBSAY(   82, 10, aLinProd[6]+Space(nSpace),"B","F","12",,,,,.T.)

		nSpace := 82 - Len(aLinProd[7])
		MSCBSAY(   88, 10, aLinProd[7]+Space(nSpace),"B","F","12",,,,,.T.)

		nSpace := 82 - Len(aLinProd[8])
		MSCBSAY(   94, 10, aLinProd[8]+Space(nSpace),"B","F","12",,,,,.T.)

		nSpace := 82 - Len(aLinProd[9])
		MSCBSAY(   100, 10, aLinProd[9]+Space(nSpace),"B","F","12",,,,,.T.)

		MSCBSAY(  110, 235, "Cidade: ","B","E","11,0",,,,,.T.)
		nSpace := 25 - Len(cCidade)
		MSCBSAY(  110, 120, cCidade+Space(nSpace),"B","0","50",,,,,.T.)
		MSCBSAY(  110, 100, "UF: ","B","E","11")
		MSCBSAY(  110, 80, Alltrim(cUF),"B","0","50")
		MSCBSAY(  110, 40, Alltrim(cFrete),"B","0","50")

		MSCBSAY(  120, 229, "Volume(s): ","B","E","11")
		MSCBSAY(  120, 195, Alltrim(StrZERO(nVol,3))+" / "+Alltrim(StrZERO(nEtqVol,3)),"B","0","50")
		MSCBSAY(  120, 100, "Peso: ","B","E","11")
		MSCBSAY(  120, 60, Alltrim(Str(nPesoB))+" KG","B","0","50")

		MSCBEnd()
		MSCBClosePrinter()

	Next

	#IFDEF WINDOWS
		Set Device To Screen
		Set Printer To
	#ENDIF

	If MsgYesNo("Deseja faturar o pedido ?","Faturamento automático Yokogawa")
		Processa({|| U_YOFAT10F(_cYPick) },"Faturamento Automático")
	EndIf

//Atualiza o Flag de Impressao das Etiquetas
	dbSelectArea("SZ3")
	dbSetOrder(1)
	If SZ3->(dbSeek(xFilial("SZ3")+_cYPick+cNumPV))
		While SZ3->(!Eof() .And. SZ3->Z3_FILIAL==xFilial("SZ3") .And. SZ3->Z3_PICK==_cYPick .And. SZ3->Z3_PEDIDO==cNumPV  )
			Reclock("SZ3",.F.)
			SZ3->Z3_IMPETQ 	 := "S"
			SZ3->(msUnlock())
			SZ3->(dbSkip())
		Enddo
	Endif

Return

/*/{Protheus.doc} User Function YOFAT10F
	(long_description)
	@type  Function
	@author user
	@since 22/02/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function YOFAT10F(_cYPick)

	Local cQuery := ""
	Local cNumPV := ""
	Local aNF 	 := {}

	If SZ3->Z3_IMPETQ <> "S"
		MsgAlert("Etiquetas não impressas. Favor efetuar impressão primeiro.")
		Return
	EndIf

	cQuery := " SELECT Z3_PRODUTO,SUM(Z3_QTDLIB) Z3_QTDLIB, C5_NUM,C5_NOTA, C5_PEDCLI, C5_TPFRETE, A1_NREDUZ, A1_EST, A1_MUN, Z3_VOLUMES, Z3_PBRUTO "
	cQuery += " FROM "+RetSqlName("SZ3")+" Z3 "
	cQuery += " LEFT JOIN "+RetSqlName("SC5")+" C5 ON (C5_FILIAL=Z3_FILIAL AND C5_NUM=Z3_PEDIDO AND C5.D_E_L_E_T_='') "
	cQuery += " LEFT JOIN "+RetSqlName("SA1")+" A1 ON (A1_COD=C5_CLIENTE AND A1_LOJA=C5_LOJACLI AND A1.D_E_L_E_T_='') "
	cQuery += " WHERE Z3.D_E_L_E_T_='' AND Z3_PICK='"+_cYPick+"' "
	cQuery += " GROUP BY Z3_PRODUTO,C5_NUM,C5_NOTA, C5_PEDCLI, C5_TPFRETE, A1_NREDUZ, A1_EST, A1_MUN, Z3_VOLUMES, Z3_PBRUTO "

	If Select("TRBETQ") > 0
		dbSelectArea("TRBETQ")
		dbCloseArea()
	EndIf

	TCQUERY cQuery NEW ALIAS "TRBETQ"

	dbSelectArea("TRBETQ")
	TRBETQ->(dbGoTop())
	If TRBETQ->(!Eof())
		lFaturado := !Empty(TRBETQ->C5_NOTA)
		cNumPV 	:= TRBETQ->C5_NUM
	EndIf

	TRBETQ->(DbCloseArea())

	If lFaturado
		MsgInfo("Pedido já faturado!","Faturamento Automático")
		Return
	EndIf

	If !ValidaFci(cNumPV)
		Return
	EndIF
    
	// Luciano 21/09/2023 Chamado INC0625754 - Sano 14/11/2023 eu descomentei a parte de baixo do If ate EndIf porque não conseguim Emitir NF pelo botão EmitNF
	If MsgYesNo("Deseja faturar o pedido ?","Faturamento automático Yokogawa")
		Processa({|| infAdTran(cNumPV) },"Informações Transporte")
		Processa({|| aNF := U_FatpvEc(cNumPV) },"Faturamento Automático")
		If !Empty(aNF)
			Processa({|| u_ChkMonSef(aNF[1],aNF[2]) },"Processando transmissão...")
		EndIf
	EndIf

Return

/*/{Protheus.doc} infAdTran
	(long_description)
	@type  Static Function
	@author user
	@since date
	@version version
	@param param, param_type, param_descr
	@return return, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
Static Function infAdTran(cNumPV)

	Local _cTransp 	:= Space(TamSX3("C5_TRANSP")[1])
	Local _nVolume 	:= 0
	Local _nPesoLiq	:= 0
	Local _nPesoBrut:= 0
	Local _cEspecie := Space(10)
	Local _cTpFrete := Space(TamSX3("C5_TPFRETE")[1])
	Local _cCifTran := "2"
	Local oDlg3		:= Nil

	DbSelectArea("SZ3")
	SZ3->(DbSetorder(4))
	If SZ3->(DbSeek(xFilial("SZ3")+cNumPV))
		_nVolume 	:= SZ3->Z3_VOLUMES
		_nPesoLiq	:= SZ3->Z3_PESOL
		_nPesoBrut	:= SZ3->Z3_PBRUTO
	EndIf

	DbSelectArea("SC5")
	SC5->(DbSetOrder(1))
	If SC5->(DbSeek(xFilial("SC5")+cNumPV))

		@ 001,001 TO 300,500 DIALOG oDlg3 TITLE "Dados adicionais Pedido de Venda"
		@ 045,010 Say " Transportadora: "  OF oDlg3 PIXEL
		@ 045,070 GET _cTransp  SIZE 30,10 PICTURE "@!"  F3("SA4")
		@ 60,010 Say " Volume: "  OF oDlg3 PIXEL
		@ 60,070 GET _nVolume  SIZE 50,10 PICTURE "@E 99999" OF oDlg3 PIXEL
		@ 75,010 Say " Especie: "  OF oDlg3 PIXEL
		@ 75,070 GET _cEspecie  SIZE 50,10 PICTURE "@!" OF oDlg3 PIXEL
		@ 90,010 Say " Peso Liquido: "  OF oDlg3 PIXEL
		@ 90,070 GET _nPesoLiq  SIZE 70,10 PICTURE "@E 999,999,999.99" OF oDlg3 PIXEL
		@ 105,010 Say " Peso Bruto: "  OF oDlg3 PIXEL
		@ 105,070 GET _nPesoBrut  SIZE 70,10 PICTURE "@E 999,999,999.99" OF oDlg3 PIXEL
		@ 120,010 Say " Tipo de Frete: "  OF oDlg3 PIXEL
		@ 120,070 COMBOBOX oCombo VAR _cTpFrete ITEMS {" ","C-CIF","F-FOB","R-Por conta terceiros","S-Sem frete"} SIZE 70,10 OF oDlg3 PIXEL
		@ 135,010 Say " Cif Transportadora: "  OF oDlg3 PIXEL
		@ 135,070 COMBOBOX oCombo VAR _cCifTran ITEMS {"1-Sim","2-Nao"} SIZE 70,10 OF oDlg3 PIXEL
		ACTIVATE DIALOG oDlg3 CENTERED ON INIT EnchoiceBar(oDlg3,{|| Close(oDlg3)}, {|| Close(oDlg3)} , ,  )

		RecLock("SC5",.F.)
		If !Empty(_cTransp)
			SC5->C5_TRANSP:= _cTransp
		EndIf

		If !Empty(_nVolume)
			SC5->C5_VOLUME1:= _nVolume
		EndIf

		If !Empty(_cEspecie)
			SC5->C5_ESPECI1:= _cEspecie
		EndIf

		If !Empty(_nPesoLiq)
			SC5->C5_PESOL:= _nPesoLiq
		EndIf

		If !Empty(_nPesoBrut)
			SC5->C5_PBRUTO:= _nPesoBrut
		EndIf

		If !Empty(_cTpFrete)
			SC5->C5_TPFRETE:= Left(_cTpFrete,1)
		EndIf

		If Left(_cCifTran,1) == "1"
			SC5->C5_YCIFTRA := "1"
			SC5->C5_XMENNOT := Alltrim(SC5->C5_XMENNOT)+"CIF-Transp"
		Else
			SC5->C5_YCIFTRA := "2"
		EndIf

		SC5->(MsUnlock())

	EndIf

Return


/*/{Protheus.doc} ValidaFci
	(long_description)
	@type  Static Function
	@author user
	@since 03/06/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
Static Function ValidaFci(cNumPV)

	Local lRet         := .t.
	Local _cQuery      := ''
	Local _cResult     := "Itens - Produtos"+CHR(13)+CHR(10)
	Local _lAvisoMoeda := .F.
	Local _lFCI        := .T.
	Local _cNumPV      := ""

	_cQuery := " SELECT C6_NUM,C6_ITEM,C6_PRODUTO,A1_EST,C6_CLASFIS,C6_FCICOD,C5_MOEDA FROM "+RetSQLName("SC6")+" SC6 "
	_cQuery += " INNER JOIN "+RETSQLNAME("SC9")+" SC9 ON SC9.D_E_L_E_T_ = '' "
	_cQuery += " AND C9_FILIAL = C6_FILIAL AND C9_PEDIDO=C6_NUM AND C9_ITEM=C6_ITEM "
	_cQuery += " AND C9_NFISCAL = ''  AND C9_PEDIDO = '"+cNumPV+"' "
	_cQuery += " INNER JOIN "+RETSQLNAME("SC5")+" SC5 ON SC5.D_E_L_E_T_ = '' AND C5_FILIAL=C6_FILIAL AND C5_NUM=C6_NUM AND C5_TIPO = 'N' "
	_cQuery += " INNER JOIN "+RETSQLNAME("SA1")+" SA1 ON SA1.D_E_L_E_T_ = '' AND A1_FILIAL='"+xFilial("SA1")+"' AND A1_COD=C6_CLI AND A1_LOJA=C6_LOJA "
	_cQuery += " WHERE SC6.D_E_L_E_T_='' AND C6_FILIAL='"+xFilial("SC6")+"' "
//_cQuery += " AND LEFT(C6_CLASFIS,1) IN ('3','5','8') AND C6_FCICOD='' "
	_cQuery += " ORDER BY SC6.C6_ITEM "

	If Select("TPM_SC6") > 0
		DbSelectArea("TPM_SC6")
		DbCloseArea()
	Endif

	TCQUERY _cQuery NEW ALIAS "TPM_SC6"
	dbSelectArea("TPM_SC6")
	TPM_SC6->(dbGotop())
	_cNumPV := TPM_SC6->C6_NUM

	While !TPM_SC6->(Eof())
		If TPM_SC6->A1_EST<>'EX' .And. LEFT(TPM_SC6->C6_CLASFIS,1) $ ('3/5/8') .And. Empty(TPM_SC6->C6_FCICOD)
			_lFCI := .F.
			_cResult +=  TPM_SC6->C6_ITEM+" - "+C6_PRODUTO+CHR(13)+CHR(10)
		EndIf
		TPM_SC6->(dbSkip())
	Enddo

	If Select("TPM_SC6") > 0
		DbSelectArea("TPM_SC6")
		DbCloseArea()
	Endif

	If !_lFCI
		Alert("Não existe FCI para os "+CHR(13)+CHR(10)+_cResult)
		lRet := .f.
	Endif

Return lRet


/*/{Protheus.doc} 

	(long_description)
	@type  Function
	@Luciano Laborda
	@since 21/09/2023
	@12.1.2210 
	@param aEmbals Embalagens para impressão da etiqueta 
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function Env_Coleta(aEmbals)
Local nXX := 0
Local nCont := 0
	dbSelectArea("SC5")
	SC5->(dbSetOrder(1))
	SC5->(dbSeek(xFilial("SC5")+_cNPedido))
	//
	// Envio de e-mail de acordo com chamado INC0425605 - 21/03/2022
	//
	If SC5->C5_TPFRETE == "F"  // Tipo F-Fob
		cDimens:=""
		For nXX := 1 To Len(aEmbals)
			cDimens += "Embalagem " +Alltrim(aEmbals[nXX])+chr(13)+chr(10)
			cDimens += " Altura:"+ Alltrim(Str(GETADVFVAL("CB3","CB3_ALTURA",xFilial("CB3")+Alltrim(aEmbals[nXX]),1," "),3))+chr(13)+chr(10)
			cDimens += " Largura:"+Alltrim(Str(GETADVFVAL("CB3","CB3_LARGUR",xFilial("CB3")+Alltrim(aEmbals[nXX]),1," "),3))+chr(13)+chr(10)
			cDimens += " Profund:"+Alltrim(Str(GETADVFVAL("CB3","CB3_PROFUN",xFilial("CB3")+Alltrim(aEmbals[nXX]),1," "),3))+chr(13)+chr(10)
		Next nXX

		_cTo := Alltrim(GetNewPar("MV_WFYOKO1","ysa-seexp@yokogawa.com;ysa-fiscal@yokogawa.com"))
		IF !Empty(SC5->C5_YPRENOT)
			_cTo += ";"+Alltrim(SC5->C5_YPRENOT)
		EndIf
		// Chamado INC0479532 22/06/2022
		aAllusers := FWSFALLUSERS(,{"USR_NOME","USR_EMAIL"})
		For nCont := 1 To Len(aAllusers)
			If Alltrim(UPPER(SC5->C5_COORDE)) $ Alltrim(UPPER(aAllusers[nCont][3]))
				_cTo += ";"+Alltrim(aAllusers[nCont][4])
				Exit
			Endif
		Next

		If !(Alltrim(SC5->C5_TIPO) $ "B/D")
			_cCliName := GETADVFVAL("SA1","A1_NOME",xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,1," ")
		Else
			_cCliName := GETADVFVAL("SA2","A2_NOME",xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,1," ")
		EndIf

		_cTitle   := "Coleta automatica Pick-list "+cNPick+" PV: "+_cNPedido+" de: "+_cCliName

		_cMensage :="Prezados, por favor agendar coleta"+chr(13)+chr(10)
		_cMensage +="Apresentar numero do PV no momento da retirada do material "+chr(13)+chr(10)
		_cMensage +="Encontra-se disponivel para retirada o material do PV: "+_cNPedido+", pedido "+SC5->C5_PEDCLI+chr(13)+chr(10)
		_cMensage +=" CNPJ "+ Transform(GETADVFVAL("SA1","A1_CGC",xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,1," "),"@r 99.999.999/9999-99")+CHR(13)+CHR(10)
		_cMensage += ""+chr(13)+chr(10)
		_cMensage += " Volume :"+Str(_nYVolume,15)+ chr(13)+chr(10)+"Peso total :"+Str(nPesoT,15)+chr(13)+chr(10) + " Medidas "+cDimens+Chr(13)+chr(10)
		//_cMensage += "Valor :"+Transform(SC5->C5_,"@E 999,999,999.99")
		_cMensage += "ESTE E-MAIL PODE SER IMPRESSO E APRESENTADO COMO ORDEM DE COLETA " +chr(13)+chr(10)
		_cMensage += "(Sem este documento com as informações o material não será coletado)."+chr(13)+chr(10)
		_cMensage += ""+chr(13)+chr(10)
		_cMensage += " Local para coleta" +chr(13)+chr(10)
		_cMensage += "" +chr(13)+chr(10)
		_cMensage += " Yokogawa América do Sul CNPJ 53.761.607/0001-50"+chr(13)+chr(10)
		_cMensage += "" +chr(13)+chr(10)
		_cMensage += "Alameda Xingu, 850, Alphaville, CEP. 06455-030 Barueri/SP" +chr(13)+chr(10)
		_cMensage += "" +chr(13)+chr(10)
		_cMensage += "Nosso horário de atendimento é de segunda a sexta-feira: " +chr(13)+chr(10)
		_cMensage += "" +chr(13)+chr(10)
		_cMensage += "08:00hs até as 11:50hs " +chr(13)+chr(10)
		_cMensage += "" +chr(13)+chr(10)
		_cMensage += "13:00hs até as 16:00hs " +chr(13)+chr(10)
		_cMensage += "" +chr(13)+chr(10)
		_cMensage += "A NOTA FISCAL SERÁ EMITIDA NO ATO DA RETIRADA. "+chr(13)+chr(10)
		_cMensage += "" +chr(13)+chr(10)
		_cMensage += "O material está embalado em caixa de papelão." +chr(13)+chr(10)
		_cMensage += "" +chr(13)+chr(10)
		_cMensage += "Em caso de dúvidas entrar em contato pelo e-mail: ysa-seexp@yokogawa.com ou Telefone: +55 (11) 5681-2478 " +chr(13)+chr(10)
	EndIf	
	If nOpc <> 5 .And. SC5->C5_TPFRETE == "F"
		cyarq := U_PVSEFAZ(.T.) // Gera o pdf da Pre-Nota para envio a transportadora
		Iif(U_YENVMAIL(_cTo,_cTitle,_cMensage,cyarq),.T.,Alert("Não foi possível enviar e-mail para o "+Alltrim(_cTo)+" contacte o TI."))
		FERASE(cyarq)
	Endif	
Return 
