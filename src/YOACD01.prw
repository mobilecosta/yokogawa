#INCLUDE "TOTVS.CH
#INCLUDE "PROTHEUS.CH
#INCLUDE "TBICONN.CH"
#INCLUDE "APVT100.CH"

#Define ENTER CHR(13)+CHR(10)

/*____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+--------------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ YOACD01 ¦ Autor ¦  Antonio Nunes       ¦    Data  ¦ 08/01/2024¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Descricao ¦ Rotina para gravar dados da Expedicao e Gerar Etiqueta        ¦¦¦
¦¦¦          ¦                                                               ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦Uso       ¦ YOKOGAWA       										         ¦¦¦
¦¦+----------+---------------------------------------------------------------¦¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
User Function YOACD01()

Local aTela    := VTSave(), cEtiqueta := cQuery := "", aColsCB0 := {}
Local aHeadCB0 := { "Etiqueta", "CB0_QTDE" }, nPos := 1, _aCabec := {}, _aItem := {}, nOpc := 3, aEtiqueta := {}, aSize := {}
Local cPict	   := PesqPict("SBF","BF_QUANT")//, cKey21 := VTDescKey(21)
Local lBlqTEnd := SuperGetMv("ES_BLQTEND", .F., .F.)
dbSelectArea(cAliasSZ3)
dbSetOrder(1)
mBrowse( 6,1,22,75,cAliasSZ3,,,,,,aCores)

While .T.
	VTClear()
	aEtiqueta := {}
	aColsCB0  := {}

	While .T.
		cEtiqueta := Space(10)
		@ 00,00 VtSay Padc("Endereçamento",VTMaxCol())
		@ 01,00 VtSay "Etiqueta:"
		@ 02,00 VtGet cEtiqueta pict "@!" F3 "CB0";
		Valid If(Val(cEtiqueta) > 0, (cEtiqueta := StrZero(Val(cEtiqueta), 10), .T.), .T.) .And. VldEtiqueta(cEtiqueta, aEtiqueta)

		aColsCB0 := {}
		If Len(aEtiqueta) == 0
			aadd(aColsCB0, { "", "" } )
		Else
			For nPos := 1 To Len(aEtiqueta)
				aadd(aColsCB0, { aEtiqueta[nPos][1], Trans(aEtiqueta[nPos][2], cPict) } )
			Next
		EndIf
		aSize := { Len(aColsCB0[1][1]), Len(aColsCB0[1][2]) }

		VtKeyboard(Chr(13))
		For nPos := 1 To Len(aHeadCB0)
			If aSize[nPos] < Len(AllTrim(aHeadCB0[nPos]))
				aSize[nPos] := Len(AllTrim(aHeadCB0[nPos]))
			EndIf
		Next
		VTaBrowse(3,0,VTMaxRow(),VtmaxCol(),aHeadCB0,aColsCB0, aSize )

		VtRead
		vtRestore(,,,,aTela)
		
		If (Empty(cEtiqueta) .And. Len(aEtiqueta) = 0) .Or. VtLastKey() == 27
			Return .F.
		EndIf

		If Empty(cEtiqueta)
			Exit
		EndIF

		Aadd(aEtiqueta, { cEtiqueta, SDA->DA_SALDO, CB0->(Recno()), SDA->(Recno()), CB0->CB0_CODPRO, CB0->CB0_LOCAL })
	EndDo

	DbSelectArea("CB0")
	DbSetOrder(1)
	DbGoto(aEtiqueta[1][3])

	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial() + CB0->CB0_CODPRO)
	M->CB0_QTDE := 0
	For nPos := 1 To Len(aEtiqueta)
		M->CB0_QTDE += aEtiqueta[nPos][2]
	Next

	SugEnd()

   	VtRestore(,,,,aTela)
	VtClear()
	M->BF_LOCALIZ := Space(Len(SBE->BE_LOCALIZ))

	@ 00,00 VtSay Padc("Endereçamento [" + aEtiqueta[1][1] + "]",VTMaxCol())
	@ 01,00 VtSay "Produto: " + CB0->CB0_CODPRO
	@ 02,00 VtSay "Qtde: " + AllTrim(Str(M->CB0_QTDE))
	@ 03,00 VtSay "Confirme o endereço:"
	@ 04,00 VtGet M->BF_LOCALIZ Pict PesqPict("SBE", "BE_LOCALIZ") F3 "SBE" Valid ExistCpo("SBE", CB0->CB0_LOCAL + M->BF_LOCALIZ, 1)

   	VTSetKey(21,{|| LstEnd()}, "Apresenta lista de endereços permitidos")
   	VtRead

   	VtRestore(,,,,aTela)
   	If Empty(M->BF_LOCALIZ)
		Loop
   	EndIf

	DbSelectArea("SBE")
	DbSetOrder(1)
	DbSeek(xFilial() + CB0->CB0_LOCAL + M->BF_LOCALIZ)

	If lBlqTEnd
	   If SB1->B1_XTPEND $ "1,2" .And. SB1->B1_XTPEND <> SBE->BE_XTPEND
			VtAlert("Atenção. O tipo de endereçamento do produto [" + AllTrim(CB0->CB0_CODPRO) + "] não é permitido para o endereço [" + AllTrim(M->BF_LOCALIZ) + "] !")
			Loop
		EndIf
	EndIf

	cQuery := "SELECT SUM(BF_QUANT) AS BF_QUANT FROM " + RetSqlName( "SBF" ) + " "
	cQuery +=  "WHERE D_E_L_E_T_ = ' ' AND BF_FILIAL = '" + xFilial( "SBF" ) + "' AND BF_LOCAL = '" + CB0->CB0_LOCAL + "' "
	cQuery +=    "AND BF_LOCALIZ = '" + M->BF_LOCALIZ + "' AND BF_PRODUTO <> '" + CB0->CB0_CODPRO + "' AND BF_QUANT > 0"

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QRY",.F.,.T. )
	M->BF_QUANT := QRY->BF_QUANT
	QRY->(DbCloseArea())
	If ! U_EndMPrd(CB0->CB0_CODPRO, CB0->CB0_LOCAL, M->BF_LOCALIZ)
		Loop
	EndIf

  	If ! VTYesNo("Confirma o endereçamento do produto [" + AllTrim(CB0->CB0_CODPRO) + "] no endereço [" + AllTrim(M->BF_LOCALIZ) + "] ?","Aviso",.t.)
		Loop
  	EndIf

  	BeginTran()
  	For nPos := 1 To Len(aEtiqueta)
		CB0->(DbGoto(aEtiqueta[nPos][3]))
     	SDA->(DbGoto(aEtiqueta[nPos][4]))

     	VTMsg("End Etiqueta [" + aEtiqueta[nPos][1] + "] ...")
     	VTProcessMessage()

     	_aCabec	:= {}
     	_aItem	:= {}
     	Aadd(_aCabec, {"DA_PRODUTO"	, SDA->DA_PRODUTO	, nil})
     	Aadd(_aCabec, {"DA_QTDORI"	, SDA->DA_QTDORI	, nil})
     	Aadd(_aCabec, {"DA_SALDO"	, SDA->DA_SALDO		, nil})
     	Aadd(_aCabec, {"DA_DATA"	, SDA->DA_DATA		, nil})
     	Aadd(_aCabec, {"DA_LOTECTL"	, SDA->DA_LOTECTL	, nil})
     	Aadd(_aCabec, {"DA_NUMLOTE"	, SDA->DA_NUMLOTE	, nil})
     	Aadd(_aCabec, {"DA_LOCAL"	, SDA->DA_LOCAL		, nil})
     	Aadd(_aCabec, {"DA_DOC"		, SDA->DA_DOC		, nil})
     	Aadd(_aCabec, {"DA_SERIE"	, SDA->DA_SERIE		, nil})
     	Aadd(_aCabec, {"DA_CLIFOR"	, SDA->DA_CLIFOR	, nil})
     	Aadd(_aCabec, {"DA_LOJA"	, SDA->DA_LOJA		, nil})
     	Aadd(_aCabec, {"DA_TIPONF"	, SDA->DA_TIPONF	, nil})
     	Aadd(_aCabec, {"DA_ORIGEM"	, SDA->DA_ORIGEM	, nil})
     	Aadd(_aCabec, {"DA_NUMSEQ"	, SDA->DA_NUMSEQ	, nil})
	  	Aadd(_aCabec, {"DA_QTSEGUM"	, SDA->DA_QTSEGUM	, nil})
	  	Aadd(_aCabec, {"DA_QTDORI2"	, SDA->DA_QTDORI2	, nil})

	  	nOpc := 3
	  	M->DB_ITEM := "0000"
	  	DbSelectArea("SDB")
	  	DbOrderNickName("DB_NUMSEQ")
	  	If DbSeek(xFilial() + CB0->(CB0_NUMSEQ + CB0_LOCAL))
			While SDB->DB_FILIAL = xFilial() .And. SDB->(DB_NUMSEQ + DB_LOCAL) == CB0->(CB0_NUMSEQ + CB0_LOCAL) .And. ! SDB->(Eof())
				If SDB->DB_PRODUTO == CB0->CB0_CODPRO .And. SDB->DB_TM <= "500" .And. SDB->DB_TIPO == "D" .And. If(Rastro(SDA->DA_PRODUTO),SDA->DA_LOTECTL==SDB->DB_LOTECTL,.T.)
					M->DB_ITEM := SDB->DB_ITEM
        	    	Aadd(_aItem, { 	{"DB_ITEM"		, SDB->DB_ITEM		, nil},;
        	    					{"DB_ESTORNO"	, SDB->DB_ESTORNO	, nil},;
	  							   	{"DB_LOCALIZ"	, SDB->DB_LOCALIZ	, nil},;
									{"DB_QUANT"		, SDB->DB_QUANT		, nil},;
									{"DB_DATA"		, SDB->DB_DATA		, nil} })
				EndIf
				
        	    SDB->(DbSkip())
         	EndDo
      	EndIf

      	M->DB_ITEM := Soma1(M->DB_ITEM)
      	Aadd(_aItem, { 	{"DB_ITEM"		, M->DB_ITEM		, nil},;
                        {"DB_LOCALIZ"	, M->BF_LOCALIZ		, nil},;
   						{"DB_QUANT"		, SDA->DA_SALDO		, nil},;
	   					{"DB_DATA"		, dDataBase			, nil},;
		   				{"DB_XCODETI"	, CB0->CB0_CODETI	, nil},;
			   			{"DB_XVOLUME"	, CB0->CB0_VOLUME	, nil} })

      	lMsErroAuto := .F.
      	MsExecAuto({|x, y, z| Mata265(x, y, z)}, _aCabec, _aItem, nOpc)
      	
      	If lMsErroAuto
         	MostraErro()
		 	DisarmTransaction()
		 	Exit
		//-- Atualização do endereço atual da etiqueta
		ElseIf TCSQLExec("UPDATE " + RetSqlName("CB0") + " " +;
       	    			    "SET CB0_LOCALI = '" + M->BF_LOCALIZ + "' " +;
			       	      "WHERE D_E_L_E_T_ = ' ' AND CB0_CODETI = '" + CB0->CB0_CODETI + "'") <> 0
			MsgAlert(TCSQLError())
			DisarmTran()
			Break
      	EndIf
   	Next
   	EndTran()
EndDo

Return
