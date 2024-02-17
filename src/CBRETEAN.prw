
#Include "TOTVS.CH"
 

User Function CBRETEAN()
    Local cId   := Padr(PARAMIXB[1], TAMSX3("B1_CODBAR")[1])  // CÓD. PRODUTO
    Local aRet  := {}                                              // DADOS DA ETIQUETA
    Local aAreaSB1 := {}                                      // ESTADO DOS ARQUIVOS DE TRABALHO
    Local aAreaSB8 := {}                                      //  
    Local cPrd  := ''                                              // CÓDIGO DO PRODUTO (B1_COD)
    Local nQE   := 1
 
    // ARMAZENA A ÁREA CORRENTE
    aAreaSb1:= SB1->(GetArea())
    aAreaSB8:= SB8->(GetArea())
 
    dbselectarea('SB1')
    dbsetorder(5) // B1_FILIAL+B1_CODBAR
    dbseek(xFilial("SB1")+cId)
    AAdd(aRet, PadR(B1_COD, TamSX3("B1_COD")[1]))
    cPrd := B1_COD
    // ARET[2] Calculo de quantidade por embalagem
    AAdd(aRet, nQE)
 
    // ARET[3] LOTE
    DbSelectArea("SB8")
    DbSetOrder(1)
    DbSeek(FwXFilial("SB8") + PadR(cPrd, TamSX3("B8_LOTECTL")[1]))
    AAdd(aRet, SB8->B8_LOTECTL)
 
    // ARET[4] DATA DE VALIDADE
    AAdd(aRet, SB8->B8_DTVALID)
    DbCloseArea() // RESTAURA O ESTADO FECHADO DO ARQUIVO SB8
 
    // ARET[5] NÚMERO DE SÉRIE
    AAdd(aRet, PadR("", TamSX3("BF_NUMSERI")[1]))
 
    // ARET[6] ENDEREÇO DESTINO
    AAdd(aRet, PadR("", TamSX3("BE_LOCALIZ")[1]))



    // DEVOLVE AS AREAS
    RestArea(aAreaSB8)
    RestArea(aAreaSB1)

   RETURN(aRet)

