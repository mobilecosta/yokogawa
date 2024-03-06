#include "rwmake.ch"
#include "protheus.ch"
#include "topconn.ch"

/*/
+---------------------------------------------------------------------------+
| Programa  | YOPCPA02   | Autor | Cristiano G. Cunha     | Data | 08/09/08 |
+-----------+---------------------------------------------------------------+
| Descrição | Pagamento das Ordens de Produção.                             |
+-----------+---------------------------------------------------------------+
| Uso       | Específico Yokogawa                                           |
+---------------------------------------------------------------------------+
/*/

User Function YOPCPA02

Private cPerg     := "YOPCPA02A"
Private aRotina   := { }
Private cCadastro := "Pagamento das Ordens de Produção"
Private cMV_PAR01
Private _cEndDes  := Space(TamSX3("BE_LOCALIZ")[1])
Private _linverte := .F.
Private _cMarca   := ""

aAdd(aRotina,{"Visualizar","U_YOPA02Vis()",0,2})
aAdd(aRotina,{"Pagamento" ,"U_YOPA02Pag()",0,4})

ValidPerg(cPerg)

While .T.
	
	If Pergunte(cPerg,.T.)
		cMV_PAR01 := MV_PAR01
		
		MsAguarde( {||YOPA02Trb()}, "Carregando Dados...")
		
		_aCpos := {}
		SX3->(dbSetOrder(2)) // X3_CAMPO
		SX3->(dbGoTop())
		
		aAdd(_aCpos,{"T_OK"     ,"",""            ,""             })
		SX3->(dbGoTop())
		SX3->(dbSeek("C2_NUM"))
		aAdd(_aCpos,{"T_NUM"    ,"",SX3->X3_TITULO,SX3->X3_PICTURE})
		SX3->(dbGoTop())
		SX3->(dbSeek("C2_ITEM"))
		aAdd(_aCpos,{"T_ITEM"   ,"",SX3->X3_TITULO,SX3->X3_PICTURE})
		SX3->(dbGoTop())
		SX3->(dbSeek("C2_SEQUEN"))
		aAdd(_aCpos,{"T_SEQUEN" ,"",SX3->X3_TITULO,SX3->X3_PICTURE})
		SX3->(dbGoTop())
		SX3->(dbSeek("C2_EMISSAO"))
		aAdd(_aCpos,{"T_EMISSAO","",SX3->X3_TITULO,SX3->X3_PICTURE})
		SX3->(dbGoTop())
		SX3->(dbSeek("C2_PRODUTO"))
		aAdd(_aCpos,{"T_PRODUTO","",SX3->X3_TITULO,SX3->X3_PICTURE})
		SX3->(dbGoTop())
		SX3->(dbSeek("C2_LOCAL"))
		aAdd(_aCpos,{"T_LOCAL"  ,"",SX3->X3_TITULO,SX3->X3_PICTURE})
		SX3->(dbGoTop())
		SX3->(dbSeek("C2_QUANT"))
		aAdd(_aCpos,{"T_QUANT"  ,"",SX3->X3_TITULO,SX3->X3_PICTURE})
		
		_cMarca := GetMark()
		MarkBrow("TRB","T_OK",,_aCpos,@_linverte,@_cMarca,"U_YOChkAll('TRB','T_OK',_cMarca)")
		
		TRB->(dbCloseArea())
		
	Else
		
		Exit
		
	EndIf
	
EndDo

Return

/*/
+--------------------------------------------------------------------------+
| Função    | YOPA02Trb  | Autor | Cristiano G. Cunha     | Data | 08/09/08 |
+-----------+---------------------------------------------------------------+
| Descrição | Carrega os dados de acordo com a seleção do usuário.          |
+-----------+---------------------------------------------------------------+
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/
Static Function YOPA02Trb()

Local _cQuery := ""

Pergunte(cPerg,.F.)

_cQuery += "SELECT '  ' T_OK,C2_NUM T_NUM,C2_ITEM T_ITEM,C2_SEQUEN T_SEQUEN,C2_EMISSAO T_EMISSAO,"
_cQuery += "C2_PRODUTO T_PRODUTO,C2_LOCAL T_LOCAL,C2_QUANT T_QUANT "
_cQuery += "FROM " + RetSQLName("SC2") + " SC2 "
_cQuery += "WHERE SC2.D_E_L_E_T_ = ' ' "
_cQuery += "AND SC2.C2_FILIAL = '" + xFilial("SC2") + "' "
_cQuery += "AND SC2.C2_NUM+SC2.C2_ITEM+SC2.C2_SEQUEN ='" + cMV_PAR01 + "' "
//_cQuery += "AND SC2.C2_EMISSAO BETWEEN '" + DtoS(mv_par02) + "' AND '" + DtoS(mv_par03) + "' "
_cQuery += "AND SC2.C2_TPOP = 'F' "
//_cQuery += "AND SC2.C2_DTPAG = '' "
_cQuery += "ORDER BY SC2.C2_NUM,SC2.C2_ITEM,SC2.C2_SEQUEN "

If Select("QRY") > 0
	QRY->(dbCloseArea())
EndIf

TCQuery _cQuery NEW ALIAS "QRY"

TCSetField("QRY","T_EMISSAO","D",08,00)
TCSetField("QRY","T_QUANT"  ,"N",09,02)

dbSelectArea("QRY")

_cNomeArq := CriaTrab(NIL,.F.)
Copy To &(_cNomeArq)

QRY->(dbCloseArea())

If Select("TRB") > 0
	TRB->(dbCloseArea())
EndIf

dbUseArea(.T.,,_cNomeArq,"TRB",.F.,.F.)
dbSelectArea("TRB")
TRB->(dbGoTop())

Return



/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02Vis  | Autor | Cristiano G. Cunha     | Data | 08/09/08 |
+-----------+---------------------------------------------------------------+
| Descrição | Visualização da Ordem de Produção.                            |
+-----------+---------------------------------------------------------------+
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

User Function YOPA02Vis()

Local _cChvSC2 := xFilial("SC2") + TRB->T_NUM + TRB->T_ITEM + TRB->T_SEQUEN

dbSelectArea("SC2")
SC2->(dbSetOrder(1))
If SC2->(dbSeek(_cChvSC2))
	A650View("SC2",SC2->(Recno()),2)   // Visualização da Ordem de Produção
EndIf

dbSelectArea("TRB")

Return

/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02Pag  | Autor | Cristiano G. Cunha     | Data | 08/09/08 |
+-----------+---------------------------------------------------------------+
| Descrição | Efetua o pagamento da produção das OP´s selecionadas.         |
+-----------+---------------------------------------------------------------+
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

User Function YOPA02Pag()

Local _lFirst    := .T.
Local _aItAux    := {}
Local _lGrv      := .F.
Local aRet 		 := {}
Local aParamBox  := {}
Local aCombo 	 := {"02","03","04","08"}
Local nI		 := 1

Private _aSelec  := {}
Private _aCampos := {}
Private _aCampo2 := {}
Private _aEstru  := {}
Private _aEstru2 := {}
Private _aProds  := {}
Private _oTrf    := LoadBitmap(GetResources(),"ENABLE")
Private _oCSldE  := LoadBitmap(GetResources(),"BR_AMARELO")
Private _oSSldE  := LoadBitmap(GetResources(),"BR_AZUL")
Private _oSSldT  := LoadBitmap(GetResources(),"DISABLE")
Private lMsErroAuto := .F.
Private _cLocEst := Alltrim(GetMV("MV_YLOCEST"))
Private aItMata381 := {}
Private aCbMata381 := {}

_aArea := GetArea()

aAdd(aParamBox,{2,"Armazem: ",,aCombo,40,"",.T.})
// Tipo 2 -> Combo
//           [2]-Descricao
//           [3]-Numerico contendo a opcao inicial do combo
//           [4]-Array contendo as opcoes do Combo
//           [5]-Tamanho do Combo
//           [6]-Validacao
//           [7]-Flag .T./.F. Parametro Obrigatorio ?

If ParamBox(aParamBox,"...Escolher Armazem...",@aRet)
   For nI:=1 To Len(aRet)
      _cLocEst := IIF(Valtype(aRet[nI])=="N","02",aRet[nI])
   Next 
Else
	Return
Endif

//_cLocEst := Alltrim(GetMV("MV_YLOCEST"))
//_cLocPci := Alltrim(GetMV("MV_YLOCPCI"))
//_cLocSis := Alltrim(GetMV("MV_YLOCSIS"))
//_cLocTEM := Alltrim(GetMV("MV_YLOCTEM"))
//_cLocANA := Alltrim(GetMV("MV_YLOCANA"))

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
dbSelectArea("TRB")
TRB->(dbGoTop())
While TRB->(!EOF())
	
	If IsMark("T_OK",ThisMark(),.F.)
		
		MsAguarde({|| YOPA02NOP()},"Analisando as Ordens de Produção...")
		
	EndIf
	
	dbSelectArea("TRB")
	TRB->(dbSkip())
	
EndDo

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

dbSelectArea("TRB")

If Len(_aSelec) > 0
	
	_aLbxIt := {}
	
	For _nCnt := 1 to Len(_aSelec)
		//Carregar apenas D4_PAGOP em branco
		dbSelectArea("SD4")
		SD4->(dbGoTo(_aSelec[_nCnt][19]))
		If Empty(SD4->D4_PAGOP)
			//Carregar apenas com Saldo
			If _aSelec[_nCnt][11] > 0 .Or. _aSelec[_nCnt][06] > 0 .Or. !Empty(_aSelec[_nCnt][08])
				aAdd(_aLbxIt,_aSelec[_nCnt])
			Endif
		Endif
	Next _nCnt
	If Len(_aLbxIt) <= 0
		Alert("Não ha itens com saldo para exibição")
		RestArea(_aArea)
		CloseBrowse()
		Return
	Endif
	
	aSort(_aLbxIt,,,{|x,y| x[2] < y[2] })
	
	_cTitulo := "Transferências"
	
	DEFINE MSDIALOG _oDlg TITLE _cTitulo FROM 000,000 to 037,150
	
	@ 005,005 LISTBOX _oLbxIt Var _oItem FIELDS HEADER	;
	" "					,; //||
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
	"Item Pedido 2"		 ; //31	
	SIZE 586,255 OF _oDlg PIXEL;
	ON DBLCLICK( MsgRun('Verificando Lotes Disponíveis...',,{|| YOPA02Lot()}))
	                        
	_aLbxBk := aClone(_aLbxIt)
	_oLbxIt:SetArray(_aLbxIt)
	_oLbxIt:bLine := {||{	;
	Iif(_aLbxIt[_oLbxIt:nAt,11] > 0,_oTrf,Iif(_aLbxIt[_oLbxIt:nAt,6] > 0 .Or. _aLbxIt[_oLbxIt:nAt,5] <= 0,_oCSldE,Iif(_aLbxIt[_oLbxIt:nAt,11] <= 0 .And. _aLbxIt[_oLbxIt:nAt,6] <= 0 .And. !Empty(_aLbxIt[_oLbxIt:nAt,8]),_oSSldE,_oSSldT))),;
	_aLbxIt[_oLbxIt:nAt,1],;
	_aLbxIt[_oLbxIt:nAt,2],;
	_aLbxIt[_oLbxIt:nAt,3],;
	_aLbxIt[_oLbxIt:nAt,4],;
	_aLbxIt[_oLbxIt:nAt,5],;
	_aLbxIt[_oLbxIt:nAt,6],;
	_aLbxIt[_oLbxIt:nAt,11],; //Posição da coluna alterado por solicitação do Rogério - Chamado 29695
	_aLbxIt[_oLbxIt:nAt,15],; //Posição da coluna alterado por solicitação do Rogério - Chamado 29695
	_aLbxIt[_oLbxIt:nAt,7],;
	_aLbxIt[_oLbxIt:nAt,8],;
	_aLbxIt[_oLbxIt:nAt,9],;
	_aLbxIt[_oLbxIt:nAt,10],;
	_aLbxIt[_oLbxIt:nAt,12],;
	_aLbxIt[_oLbxIt:nAt,13],;
	_aLbxIt[_oLbxIt:nAt,14],;
	_aLbxIt[_oLbxIt:nAt,16],;
	_aLbxIt[_oLbxIt:nAt,17],;
	_aLbxIt[_oLbxIt:nAt,18],;
	_aLbxIt[_oLbxIt:nAt,19],;
	_aLbxIt[_oLbxIt:nAt,20],;
	_aLbxIt[_oLbxIt:nAt,21],;
	_aLbxIt[_oLbxIt:nAt,22],;
	_aLbxIt[_oLbxIt:nAt,23],;
	_aLbxIt[_oLbxIt:nAt,24],;
	_aLbxIt[_oLbxIt:nAt,25],;
	_aLbxIt[_oLbxIt:nAt,26],;
	_aLbxIt[_oLbxIt:nAt,27],;
	_aLbxIt[_oLbxIt:nAt,28],;
	_aLbxIt[_oLbxIt:nAt,29],;
	_aLbxIt[_oLbxIt:nAt,30],;
	_aLbxIt[_oLbxIt:nAt,31]}}	
	//                    BMP 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017
	_oLbxIt:aColSizes := {010,040,040,80,020,045,030,040,050,050,050,050,050,050,050,050,040,050,050,050,050,050,050,050}
	_oItem:nAt := 1
	_oLbxIt:SetFocus()
	
	@ 026,002 Button oBtn4 Prompt "Zera Qtde" Size 039,015 Action u_YOPA02Zer()
	@ 026,012 Button oBtn4 Prompt "Qtde Transf." Size 039,015 Action u_YOPA02Qtd()
	@ 026,088 Button oBtn1 Prompt "Legenda"    Size 039,015 Action YOPA02Leg()
	@ 026,103 Button oBtn2 Prompt "Ok"         Size 039,015 Action (_lGrv:=.T.,_oDlg:End())
	@ 026,113 Button oBtn3 Prompt "Cancelar"   Size 039,015 Action Close(_oDlg)
	
	ACTIVATE MSDIALOG _oDlg CENTERED
	
EndIf

If _lGrv
	u_YOPA02G(cMV_PAR01, .F.)
	
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

CloseBrowse()

Return

User Function YOPA02G(cOp, lACD)

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
		If DBSeek(xFilial("SD4")+cOP)
			While !SD4->(Eof()) .AND. alltrim(SD4->D4_OP) == alltrim(cOP)
				aDadLog := {}
				aadd(aDadLog,{"ZF_FILIAL",xFilial("SZF"),Nil})
				aadd(aDadLog,{"ZF_OP",cOP,Nil})
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
	aAdd(_aItens,{Substr(cOP,1,8),dDataBase})
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

			//Campos Protheus 12
			/*
			If SD3->(FieldPos(PADR('D3_IDDCF',10))) > 0 //Campo Existe
				__nPos := Len(_aItAux[Len(_aItAux)])+1
				ASize(_aItAux[Len(_aItAux)], __nPos) //Redimensiona o Array
				_aItAux[Len(_aItAux)][__nPos] := CriaVar('D3_IDDCF')
			Endif	
			*/			
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
				//aAdd(_aItens,{Substr(cOP,1,8),dDataBase}) //Comentado para ajustar o EmpMod3
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
						aadd(aDadLog,{"ZF_OP",cOP,Nil})
						aadd(aDadLog,{"ZF_EMISSAO",dDataBase,Nil})
						aadd(aDadLog,{"ZF_HORA",Time(),Nil})
						aadd(aDadLog,{"ZF_USUARIO",Substr(cUsuario,7,15),Nil})
						aadd(aDadLog,{"ZF_TIPO","T",Nil})
						aadd(aDadLog,{"ZF_DOC",Substr(cOP,1,8),Nil})
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
						//aadd(aDadLog,{"ZF_NUMLOTD",_aItAux[_nCnt5][],Nil})	//Nao Utilizado na Rotina
						aadd(aDadLog,{"ZF_LOCALID",_aItAux[_nCnt5][09],Nil})	// 09 - Local Destino
						aadd(aDadLog,{"ZF_NUMSEQ",_aItAux[_nCnt5][19],Nil})		// 19 - Sequência
						//aadd(aDadLog,{"ZF_TRT",_aItAux[_nCnt5][],Nil})		//Nao Utilizado na Transferencia
						aadd(aDadLog,{"ZF_NUMSERI",_aItAux[_nCnt5][11],Nil})	// 11 - Número de Série
						aadd(aDadLog,{"ZF_DTVALIO",_aItAux[_nCnt5][14],Nil})	// 14 - Validade Origem
						aadd(aDadLog,{"ZF_DTVALID",_aItAux[_nCnt5][21],Nil})	// 21 - Validade Destino
						aadd(aItemLog,aDadLog)
					endif
				Next _nCnt5
				//Comentado abaixo para ajuste do EmpMod2
				/*
				lMsErroAuto := .F.
				cMsg := ""
				MSExecAuto({|x,y| MATA261(x,y)},_aItens,3)
				If lMsErroAuto
					DisarmTransaction()
					MostraErro()					
					lContinua := .F.
				EndIf
				//Verificando se deve gravar Log
				if SuperGetMV("MV_YOLOGOP",,.T.)
					u_YOLOGOP1(aItemLog,lContinua,cMsg)
				endif
				*/
				//Fim do comentario do ajuste Mod2
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
			// Inclui a Ordem de Producao com o Novo Saldo por lote
			//Comentado abaixo para ajustar para Empenho Mod2
			/* 
			_lEmpenho := YOPA02Emp(3,_cCodPro,_cNumOP,_cTrt,_cLocEmp,_nQtdTran,_nQtdTran,dDataBase,_cLoteTran,_cSubTran,"I",_aBenef,0)
			If _lEmpenho 
				_nPosReq := aScan(_aReqOps,{|x| x[1]+x[2] == _cCodPro+_cTrt })
				If _nPosReq > 0
					_aReqOps[_nPosReq,03] := _aReqOps[_nPosReq,03] + _nQtdTran
				Else
					AADD(_aReqOps,{_cCodPro,_cTrt,_nQtdTran})
				Endif
			Endif
			*/ //Fim do comentario do ajuste para EmpMod2
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
	    	aCbMata381 := {{"D4_OP",PadR(cOP,TamSx3("D4_OP")[1]),NIL},;
	    		     	   {"INDEX",2,Nil}}
			MSExecAuto({|x,y,z| mata381(x,y,z)},aCbMata381,aItMata381,4)
			If lMsErroAuto
				//Se ocorrer erro.
				DisarmTransaction()
				If lACD
					VTAlert("Erro na gravação do empenho [" + cOP + "] !", "Aviso", .T., 2000)
				Else
					MostraErro()
				EndIf
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
		if DBSeek(xFilial("SD4")+cOP)
			While !SD4->(Eof()) .AND. alltrim(SD4->D4_OP) == alltrim(cOP)
				aDadLog := {}
				aadd(aDadLog,{"ZF_FILIAL",xFilial("SZF"),Nil})
				aadd(aDadLog,{"ZF_OP",cOP,Nil})
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

Return

/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02Leg  | Autor | Cristiano Gomes Cunha  | Data | 08/09/08 |
|-----------+---------------------------------------------------------------|
| Descrição | Legenda da situação do Produto.                               |
|-----------+---------------------------------------------------------------|
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOPA02Leg()

Local _aStatus := {}

aAdd(_aStatus,{"BR_VERDE"   ,"Transferência"})
aAdd(_aStatus,{"BR_AMARELO" ,"Saldo Suficiente"})
aAdd(_aStatus,{"BR_AZUL"    ,"Saldo Insuficiente"})
aAdd(_aStatus,{"BR_VERMELHO","Sem Saldo p/ Transferir"})

BrwLegenda("Pagamento da Produção","Situação",_aStatus)

Return .T.



/*/
+---------------------------------------------------------------------------+
| Função    | YOPA02NOP  | Autor | Cristiano Gomes Cunha  | Data | 24/09/08 |
|-----------+---------------------------------------------------------------|
| Descrição | Verifica a necessidade de cada Ordem de Produção.             |
|-----------+---------------------------------------------------------------|
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOPA02NOP()

Local _cNumOP := TRB->T_NUM + TRB->T_ITEM + TRB->T_SEQUEN

Private _nQOrigEs := 1

_cChvSC2 := xFilial("SC2") + _cNumOP
_cChvSD4 := xFilial("SD4") + _cNumOP

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

//	If Empty(Alltrim(_aEstru[_nCont][3]))   // Sem Endereçamento
//		_cChvSB8 := xFilial("SB8") + _aEstru[_nCont][1] + _aEstru[_nCont][2] + _aEstru[_nCont][5] + _aEstru[_nCont][6]
//		dbSelectArea("SB8")
//		SB8->(dbSetOrder(3))
//		If SB8->(dbSeek(_cChvSB8))
//			_nSaldo := SB8->B8_SALDO - (SB8->B8_EMPENHO + AvalQtdPre("SB8",1))
//		EndIf
//	Else
//		_cChvSBF := xFilial("SBF") + _aEstru[_nCont][2] + _aEstru[_nCont][3] + _aEstru[_nCont][1] + _aEstru[_nCont][4] + _aEstru[_nCont][5] + _aEstru[_nCont][6]
//		dbSelectArea("SBF")
//		SBF->(dbSetOrder(1))
//		If SBF->(dbSeek(_cChvSBF))
//			_nSaldo := SBF->BF_SALDO
//		EndIf
//	EndIf

dbSelectArea("SDC")
SDC->(dbSetOrder(2))

dbSelectArea("SD4")
SD4->(dbSetOrder(2))
If SD4->(dbSeek(_cChvSD4))
	
	While !SD4->(Eof()) .And. (Alltrim(SD4->(D4_FILIAL + D4_OP)) == Alltrim(_cChvSD4))
		
		If SD4->D4_QUANT > 0 .AND. EMPTY(SD4->D4_LOTECTL) .And. !(Alltrim(GetAdvFval("SB1","B1_GRUPO",xFilial("SB1")+SD4->D4_COD,1," ")) $ SuperGetMV("MV_YKANBAN",,"KANB/LM25"))
			//_cChvSDC := xFilial("SDC") + SD4->(D4_COD + D4_LOCAL + D4_OP + D4_TRT + D4_LOTECTL + D4_NUMLOTE)
			//If SDC->(dbSeek(_cChvSDC))
			//	While !SDC->(Eof()) .And. (SDC->(DC_FILIAL + DC_PRODUTO + DC_LOCAL + DC_OP + DC_TRT + DC_LOTECTL + DC_NUMLOTE) == _cChvSDC)
			//		aAdd(_aEstru2,{SD4->D4_COD,SD4->D4_LOCAL,SDC->DC_LOCALIZ,SDC->DC_NUMSERI,SDC->DC_LOTECTL,SDC->DC_NUMLOTE,SD4->D4_DTVALID,SDC->DC_QUANT,_cNumOP,"SDC",SD4->(Recno())})
			//		SDC->(dbSkip())
			//	EndDo
			//Else
			aAdd(_aEstru, {SD4->D4_COD,SD4->D4_LOCAL,"","",SD4->D4_LOTECTL,SD4->D4_NUMLOTE,SD4->D4_DTVALID,SD4->D4_QUANT,_cNumOP,"SD4",SD4->(Recno()),SD4->D4_TRT,SD4->D4_YFORNEC,SD4->D4_YLOJA,SD4->D4_YPEDBEN,SD4->D4_YPEDCOM,SD4->D4_YPEDITE,SD4->D4_NUMSC,SD4->D4_YFORNE2,SD4->D4_YLOJA2,SD4->D4_YPEDBE2,SD4->D4_YPEDCO2,SD4->D4_YPEDIT2})

			//EndIf
		EndIf
		
		dbSelectArea("SD4")
		SD4->(dbSkip())
		
	EndDo
	
EndIf

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
	/* Anderson Messias - Comentado por nao ter as variaveis no sistema
	Denise, verificar o que essas variaveis deveriam conter obrigado!
	20/04/2009
	If _nQtdTrf > 0
	Do Case
	Case Alltrim(_cLocDes) == _cLocPrd
	_cEndDes := GetMV("MV_YENDPRO")
	Case Alltrim(_cLocDes) == _cLocPrj
	_cEndDes := GetMV("MV_YENDPRJ")
	OtherWise
	_cEndDes := CriaVar("D3_LOCALIZ")
	EndCase
	Else
	_cEndDes := CriaVar("D3_LOCALIZ")
	EndIf
	*/
	//_cEndDes := _cLocDes
	If _cLocDes = GetMv("MV_YLOCSIS") .OR. _cLocDes = GetMv("MV_YLOCANA")
		_cEndDes := _cLocDes //YOPA02End(_cNumOP,_cLocDes) // Solicitado pelo Cristian Sampaio no chamado IR4102 em 09/02/18, porque conforme informação isso dificulta o envio para beneficiamento.
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
		//		_nTrfNec := _aLbxIt[_oLbxIt:nAt,5]
		//		If _aLotes[_nSelec,1] > _nTrfQtd
		//			If _aLotes[_nSelec,1] > _nTrfNec
		//				_aLbxIt[_oLbxIt:nAt,11] := _nTrfNec
		//			Else
		//				_aLbxIt[_oLbxIt:nAt,11] := _aLotes[_nSelec,1]
		//			EndIf
		//		Else
		//			_aLbxIt[_oLbxIt:nAt,11] := _aLotes[_nSelec,1]
		//		EndIf
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
| Função    | YOPA02Emp  | Autor | Cristiano G. Cunha     | Data | 28/04/09 |
+-----------+---------------------------------------------------------------+
| Descrição | Rotina que realiza o ajuste de empenho automaticamente.       |
+-----------+---------------------------------------------------------------+
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function YOPA02Emp(_nOpc,_cD4Cod,_cD4OP,_cD4TRT,_cD4Local,_nD4QtdOri,_nD4Quant,_dD4DtEmp,_cD4Lote,_cD4SubLote,_cD4PagOp,_aBenef,_nRegSD4)

Local _aArea	:= GetArea()
Local _aVetor	:= {}
Local _lRet		:= .T.
Local _cSelect  := ""
Local _lRast    := .F.

Private lMsErroAuto := .F.

DEFAULT _cD4Lote 	 := Space(10)
DEFAULT _cD4SubLote  := Space(06)
DEFAULT _cD4PagOp    := Space(05)
DEFAULT _aBenef      := {Space(06),Space(04),Space(06),Space(06),Space(04),Space(06), Space(06),Space(04),Space(06),Space(06),Space(04)}

If !EMPTY(_cD4Lote)
	
	_cSelect := "SELECT ISNULL(MAX(D4_TRT),'###') D4_TRT, ISNULL(COUNT(1),0) AS QTDITENS "
	_cSelect += "FROM " + RetSQLName("SD4") + " SD4 "
	_cSelect += "WHERE SD4.D_E_L_E_T_ = '' "
	_cSelect += "AND D4_FILIAL = '" + xFilial("SD4") + "' "
	_cSelect += "AND D4_OP = '" + _cD4OP + "' "
	_cSelect += "AND D4_COD = '" + _cD4Cod + "' "
	_cSelect += "AND D4_LOCAL = '" + _cD4Local + "' "

	If Select("TRBTRT") <> 0
		TRBTRT->(dbCloseArea())
	EndIf
	
	TCQuery (_cSelect) New Alias "TRBTRT"
	
	_cD4TRT := Space(3)
	dbSelectArea("TRBTRT")
	TRBTRT->(dbGoTop())
	//Se nao achar na base, retorna ### se retornar mesmo que vazio tem que somar1
	//Anderson Messias - 17/06/2009
	If TRBTRT->D4_TRT<>"###" .AND. TRBTRT->QTDITENS > 1
		_cD4TRT := Soma1(TRBTRT->D4_TRT)
	EndIf
	
EndIf

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
	_lRast := .T.
EndIf
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

Conout("Variavel aBenef: "+ _aBenef[7] + _aBenef[8] + _aBenef[9] )

//Verificando se deve gravar Log
aItemLog := {}
aDadLog	 := {}
if SuperGetMV("MV_YOLOGOP",,.T.)
	//Gravação do Log Para Validação
	aDadLog := {}
	aadd(aDadLog,{"ZF_FILIAL",xFilial("SZF"),Nil})
	aadd(aDadLog,{"ZF_OP",cMV_PAR01,Nil})
	aadd(aDadLog,{"ZF_EMISSAO",dDataBase,Nil})
	aadd(aDadLog,{"ZF_HORA",Time(),Nil})
	aadd(aDadLog,{"ZF_USUARIO",Substr(cUsuario,7,15),Nil})
	aadd(aDadLog,{"ZF_TIPO","E"+Substr(_cD4PagOp,1,1),Nil})
	aadd(aDadLog,{"ZF_COD",_cD4Cod,Nil})
	aadd(aDadLog,{"ZF_QUANTOR",_nD4QtdOri,Nil})
	aadd(aDadLog,{"ZF_LOCALOR",_cD4Local,Nil})
	aadd(aDadLog,{"ZF_LOTECTO",_cD4Lote,Nil})
	aadd(aDadLog,{"ZF_NUMLOTO",_cD4SubLote,Nil})
	aadd(aDadLog,{"ZF_QUANTDE",_nD4Quant,Nil})
	aadd(aDadLog,{"ZF_TRT",_cD4TRT,Nil})
	aadd(aItemLog,aDadLog)
endif

/*
lMSHelpAuto := .F.
lMSErroAuto := .F.
cMsg		:= ""
//MSExecAuto({|x,y| MATA380(x,y)},_aVetor,_nOpc)
*/
If _nOpc == 5
	Aadd(_aVetor,{"ZERAEMP", "S" ,NIL})
	MSExecAuto({|x,y,z,r| MATA380(x,y,z,r)},_aVetor,_nOpc,{},.T.)
Else
	If U_YEXMT380(_aVetor,_nOpc,{},_nRegSD4,_lRast)
		_lRet := .F.
		cPath := GetSrvProfString("Startpath","")+"\PagOPLog"
		cArquivo := alltrim(_cD4OP)+"_"+alltrim(_cD4Cod)+"_"+alltrim(DTOS(Date()))+"_"+alltrim(StrTran(Substr(Time(),1,5),":","_"))+".Log"
		cMsg := MemoRead(cPath+"\"+cArquivo)
	EndIf
EndIf

//Verificando se deve gravar Log
if SuperGetMV("MV_YOLOGOP",,.T.)
	u_YOLOGOP1(aItemLog,lContinua,cMsg)
endif

RestArea(_aArea)

Return _lRet

/*/
+---------------------------------------------------------------------------+
| Função    | ValidPerg  | Autor | Cristiano Gomes Cunha  | Data | 08/09/08 |
|-----------+---------------------------------------------------------------|
| Descrição | Verifica a existência das perguntas, criando-as caso seja     |
|           | necessário.                                                   |
|-----------+---------------------------------------------------------------|
| Uso       | Específico YOPCPA02                                           |
+---------------------------------------------------------------------------+
/*/

Static Function ValidPerg(cPerg)

Local _sAlias := Alias()
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)

// Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
aAdd(aRegs,{cPerg,"01","Ordem de Produção        ?","","","mv_ch1","C",11,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SC2"})

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


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ YOLOGOP1 ºAutor  ³Anderson Messias    º Data ³  10/06/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina que grava o Log da Movimentação que será gerada no  º±±
±±º          ³ Pagamento da OP                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function YOLOGOP1(aDados, lOk, cMsg)

Local aSavATU := GetArea()
Local nI := 1
Local nX := 1

IF ! AliasInDic("SZF")
	Return
EndIF

DBSelectArea("SZF")
DBSetOrder(1)
if Len(	aDados ) > 0
	For nI := 1 to len(aDados)
		RecLock("SZF",.T.)
		For nX := 1 to len(aDados[nI])
			nPos := FieldPos(aDados[nI][nX][1])
			if nPos > 0
				&("SZF->"+aDados[nI][nX][1]) := aDados[nI][nX][2]
			endif
		Next
		MsUnlock()
	Next
endif

RestArea(aSavATU)

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ YOPA02QtdºAutor  ³Anderson Messias    º Data ³  26/04/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina que permite alterar a quantidade a ser transferida  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ YOKOGAWA                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function YOPA02Qtd()
                          
nQtdSug := _aLbxBK[_oLbxIt:nAt,11]
nQtdNov := _aLbxIt[_oLbxIt:nAt,11]

nOpc := 0
@ 0,0 TO 110,250 DIALOG oDlgQtd TITLE "Quantidade a Transferir"
@ 10,10 SAY "Qtde Sugerida"	Size 40
@ 10,60 MSGET oQtdSug VAR nQtdSug PICTURE "@E 999999.99" SIZE 30,07 OF oDlgQtd PIXEL When .F.
@ 22,10 SAY "Nova Quantidade"	Size 40
@ 22,60 MSGET oQtdNov VAR nQtdNov PICTURE "@E 999999.99" SIZE 30,07 OF oDlgQtd PIXEL When .T. Valid iif((nQtdNov>=0 .AND. nQtdNov<=nQtdSug),.T.,(Alert("A nova quantidade nao pode ser maior que a quantidade original"),.F.))

@ 35,10 BMPBUTTON TYPE 1 ACTION (nOpc := 1,Close(oDlgQtd))
@ 35,40 BMPBUTTON TYPE 2 ACTION (nOpc := 2,Close(oDlgQtd))

oQtdNov:SetFocus()
ACTIVATE MSDIALOG oDlgQtd CENTERED

if nOpc==1
	_aLbxIt[_oLbxIt:nAt,11] := nQtdNov
endif

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

User Function YOPA02Zer()
Local nI := 1

if MsgYesNo(OemToAnsi("Deseja zerar a quantidade de transferencia de todos os produtos?"))

	For nI := 1 to Len(_aLbxIt)
		_aLbxIt[nI,11] := 0
	Next

endif

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ YOPA02EndºAutor  ³Ivandro Marcio      º Data ³  12/04/12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina que verifica o endereço do projeto no armazem 14    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ YOKOGAWA                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function YOPA02End(_cNumOP,_cLocDes)
local _cEndPrj := Space(TamSX3("AFM_PROJET")[1])
Local _nEndDes := 0

/*
If _cLocDes =  GetMv("MV_YLOCSIS")
_cWhere1 := "SELECT ISNULL(AFM_PROJET,'') PROJETO,ISNULL(BE_LOCALIZ,'') LOCALIZ "
_cWhere1 += "FROM " + RetSQLName("AFM") + " AFM "
_cWhere1 += "LEFT JOIN " + RetSQLName("SC2") + " SC2 ON C2_NUM+C2_ITEM+C2_SEQUEN = AFM_NUMOP+AFM_ITEMOP+AFM_SEQOP AND C2_FILIAL = '" + xFilial("SC2") + "' AND SC2.D_E_L_E_T_ = '' "
_cWhere1 += "LEFT JOIN " + RetSQLName("SBE") + " SBE ON BE_LOCAL = '"+ _cLocDes +"' AND BE_LOCALIZ = AFM_PROJET AND SBE.D_E_L_E_T_ = '' "
_cWhere1 += "WHERE AFM.AFM_FILIAL = '" + xFilial("AFM") + "' AND AFM.D_E_L_E_T_ = '' AND C2_NUM+C2_ITEM+C2_SEQUEN = '" + _cNumOP + "' "
Elseif _cLocDes = GetMv("MV_YLOCANA")
*/
_cWhere1 := "SELECT ISNULL(C5_NUM,'') PROJETO,ISNULL(BE_LOCALIZ,'') LOCALIZ "
_cWhere1 += "FROM " + RetSQLName("SC5") + " SC5 "
_cWhere1 += "LEFT JOIN " + RetSQLName("SC2") + " SC2 ON C2_PEDIDO = C5_NUM AND C2_FILIAL = '" + xFilial("SC2") + "' AND SC2.D_E_L_E_T_ = '' "
_cWhere1 += "LEFT JOIN " + RetSQLName("SBE") + " SBE ON BE_LOCAL = '"+ _cLocDes +"' AND BE_LOCALIZ = C5_NUM AND SBE.D_E_L_E_T_ = '' "
_cWhere1 += "WHERE SC5.C5_FILIAL = '" + xFilial("SC5") + "' AND SC5.D_E_L_E_T_ = '' AND C2_NUM+C2_ITEM+C2_SEQUEN = '" + _cNumOP + "' "
//Endif

If Select("TRBEND") > 0
	TRBEND->(dbCloseArea())
EndIf

TCQuery _cWhere1 NEW ALIAS "TRBEND"

_cEndPrj := TRBEND->PROJETO
_cEndDes := TRBEND->LOCALIZ
If !Empty(_cEndPrj) .AND. _cEndPrj <> _cEndDes
	_cEndDes := _cEndPrj
Elseif Empty(_cEndPrj)
	_cEndDes := YOPCPLOC()
End If


dbSelectArea("TRBEND")


//adicionado a busca do endereço
_cWhere2 := "SELECT COUNT(BE_LOCALIZ) LOCALIZ FROM SBE010 SBE WHERE BE_LOCAL = '"+ _cLocDes +"' AND BE_LOCALIZ = '"+ _cEndDes +"' AND SBE.D_E_L_E_T_='' GROUP BY BE_LOCALIZ "
If Select("TRBCNT") > 0
	TRBCNT->(dbCloseArea())
EndIf

TCQuery _cWhere2 NEW ALIAS "TRBCNT"
_nEndDes := TRBCNT->LOCALIZ

dbSelectArea("TRBCNT")
IF _nEndDes = 0
	YOMATA015()
END IF

Return(_cEndDes)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ YOPCPLOC ºAutor  ³Ivandro Marcio      º Data ³  12/04/12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina que abre a tela para o usuario informar o endereço  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ YOKOGAWA                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function YOPCPLOC()

Local _nOpcao := .F.
Local _cSemEnd := Space(TamSx3("BE_LOCALIZ")[1] )
Local _lvalid := .T.
Local _lEsc := .T.

While _lvalid
	
	DEFINE MSDIALOG _oDlgEnd TITLE "Criação de Localização" FROM 000,000 to 010,037
	@ 12,10 SAY "Digite Endereço" Size 40
	If _cLocDes = GetMv("MV_YLOCSIS")
		@ 10,50 MSGET oEndDes VAR _cSemEnd PICTURE PesqPict("AF8","AF8_PROJET") F3 "AF8" OF _oDlgEnd PIXEL
	Elseif _cLocDes = GetMv("MV_YLOCANA")
		@ 10,50 MSGET oEndDes VAR _cSemEnd PICTURE PesqPict("SC5","C5_NUM") F3 "SC5" OF _oDlgEnd PIXEL
	Endif
	@ 45,65 BMPBUTTON TYPE 1	ACTION (_nOpcao:=.T.,_oDlgEnd:End())
	@ 45,95 BMPBUTTON TYPE 2 	ACTION (_nOpcao:=.T.,Close(_oDlgEnd))
	ACTIVATE MSDIALOG _oDlgEnd CENTERED
		
	If Empty(_cSemEnd) .and. _nOpcao
		Aviso("ALERTA!","Não foi selecionado um Endereço.",{"OK"})
	ElseIf !Empty(_cSemEnd) .and. !_nOpcao
		Aviso("ALERTA!","Não foi selecionado um Endereço.",{"OK"})
    Else
		_lvalid := .F.
	endif
Enddo


Return(_cSemEnd)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ YOMATA015ºAutor  ³Ivandro Marcio      º Data ³  12/04/12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina que verifica e cria os endereços dos projetos       º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ YOKOGAWA                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function YOMATA015()

LOCAL aVetor:= {}
Local nOpc := 0 
Private lMsErroAuto := .F.
aVetor := 	{	{"BE_LOCAL"  ,_cLocDes			   ,Nil},;
				{"BE_LOCALIZ",_cEndDes			   ,NIL},;
				{"BE_DESCRIC","Projeto " + _cEndDes,NIL},;
				{"BE_PRIOR"	 ,"ZZZ"		           ,NIL},;
				{"BE_MSBLQL"  ,"2"			       ,NIL},;
				{"BE_STATUS" ,"1"		,NIL} }
			

nOpc := 3	// inclusao			
MSExecAuto({|x,y| MATA015(x,y)},aVetor, nOpc)     

If lMsErroAuto
	ConOut("Erro")	
	MostraErro()
Else
	ConOut("Sucesso! ")		
EndIf

Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³ YOChkAll ³ Autor ³ Anderson Sano 		³ Data ³	      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Marca todos os itens do MarkBrow							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ 										         			  ³±±
±±³			 ³ 															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function YOChkAll(_cYAlias,_cYCampoChk,_cMarca)
Local _nRecno := &(_cYAlias)->(Recno())

dbSelectArea(_cYAlias)
dbGotop()

While &(_cYAlias)->(!Eof())     
	If IsMark( _cYCampoChk, _cMarca )
		RecLock( _cYAlias, .F. )
		Replace &(_cYCampoChk) With Space(2)
		MsUnLock()
	Else
		RecLock( _cYAlias, .F. )
		Replace &(_cYCampoChk) With _cMarca
		MsUnLock()
	EndIf
	&(_cYAlias)->(dbSkip())
End

dbGoto( _nRecno )
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

User Function YOEmpMd2(_nOpc,_cD4Cod,_cD4OP,_cD4TRT,_cD4Local,_nD4QtdOri,_nD4Quant,_dD4DtEmp,_cD4Lote,_cD4SubLote,_cD4PagOp,_aBenef,_nRegSD4,_cOpOrig,_cSeqSD4)

Return YOEmpMod2(_nOpc,_cD4Cod,_cD4OP,_cD4TRT,_cD4Local,_nD4QtdOri,_nD4Quant,_dD4DtEmp,_cD4Lote,_cD4SubLote,_cD4PagOp,_aBenef,_nRegSD4,_cOpOrig,_cSeqSD4)

Static Function YOEmpMod2(_nOpc,_cD4Cod,_cD4OP,_cD4TRT,_cD4Local,_nD4QtdOri,_nD4Quant,_dD4DtEmp,_cD4Lote,_cD4SubLote,_cD4PagOp,_aBenef,_nRegSD4,_cOpOrig,_cSeqSD4)

Local _aArea	:= GetArea()
Local _aVetor	:= {}
Local _cSelect  := ""
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
	
	_cSelect := "SELECT ISNULL(MAX(D4_TRT),'###') D4_TRT, ISNULL(COUNT(1),0) AS QTDITENS "
	_cSelect += "FROM " + RetSQLName("SD4") + " SD4 "
	_cSelect += "WHERE SD4.D_E_L_E_T_ = '' "
	_cSelect += "AND D4_FILIAL = '" + xFilial("SD4") + "' "
	_cSelect += "AND D4_OP = '" + _cD4OP + "' "
	_cSelect += "AND D4_COD = '" + _cD4Cod + "' "
	_cSelect += "AND D4_LOCAL = '" + _cD4Local + "' "

	If Select("TRBTRT") <> 0
		TRBTRT->(dbCloseArea())
	EndIf
	
	TCQuery (_cSelect) New Alias "TRBTRT"
	
	_cD4TRT := Space(3)
	dbSelectArea("TRBTRT")
	TRBTRT->(dbGoTop())
	//Se nao achar na base, retorna ### se retornar mesmo que vazio tem que somar1
	//Anderson Messias - 17/06/2009
	If TRBTRT->D4_TRT<>"###" .AND. TRBTRT->QTDITENS > 0
		_cD4TRT := Soma1(TRBTRT->D4_TRT)
	EndIf

	If Select("TRBTRT") <> 0
		TRBTRT->(dbCloseArea())
	EndIf
	
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
	// Chave Unica do SD4 -> D4_FILIAL, D4_COD, D4_OP, D4_TRT, D4_LOTECTL, D4_NUMLOTE, D4_LOCAL, D4_ORDEM, D4_OPORIG, D4_SEQ, R_E_C_D_E_L_
	_cD4TRTAux := _cD4TRT
	_cSelect := "SELECT ISNULL(MAX(D4_TRT),'###') D4_TRT, ISNULL(COUNT(1),0) AS QTDITENS "
	_cSelect += "FROM " + RetSQLName("SD4") + " SD4 "
	_cSelect += "WHERE SD4.D_E_L_E_T_ = '' "
	_cSelect += "AND D4_FILIAL = '" + xFilial("SD4") + "' "
	_cSelect += "AND D4_OP = '" + _cD4OP + "' "
	_cSelect += "AND D4_COD = '" + _cD4Cod + "' "
	_cSelect += "AND D4_LOCAL = '" + _cD4Local + "' "
	_cSelect += "AND D4_LOTECTL = '" + _cD4Lote + "' "
	_cSelect += "AND D4_TRT = '" + _cD4TRT + "' "

	If Select("TRBTRT") <> 0
		TRBTRT->(dbCloseArea())
	EndIf
	
	TCQuery (_cSelect) New Alias "TRBTRT"
	
	dbSelectArea("TRBTRT")
	TRBTRT->(dbGoTop())
	//Se nao achar na base, retorna ### se retornar mesmo que vazio tem que somar1
	//Anderson Messias - 17/06/2009
	If TRBTRT->D4_TRT<>"###" .AND. TRBTRT->QTDITENS > 0
		_cD4TRTAux := Soma1(TRBTRT->D4_TRT)
	EndIf

	If Select("TRBTRT") <> 0
		TRBTRT->(dbCloseArea())
	EndIf
	
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
