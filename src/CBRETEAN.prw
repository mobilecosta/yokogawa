#Include "TOTVS.CH"
 

User Function CBRETEAN()
    Local cId   := Padr(PARAMIXB[1], TAMSX3("B1_COD")[1])  // C�D. PRODUTO
    Local aRet  := {}                                              // DADOS DA ETIQUETA
    Local aAreaSB1 := {}                                      // ESTADO DOS ARQUIVOS DE TRABALHO
    Local aAreaSB8 := {}                                      //  
    Local cPrd  := ''                                              // C�DIGO DO PRODUTO (B1_COD)
    Local nQE   := 1
 
    // ARMAZENA A �REA CORRENTE
    aAreaSb1:= SB1->(GetArea())
    aAreaSB8:= SB8->(GetArea())
 
    dbselectarea('SB1')
    dbsetorder(1) // B1_FILIAL+B1_COD
    dbseek(xFilial("SB1")+cId)
    AAdd(aRet, PadR(B1_COD, TamSX3("B1_COD")[1]))
    cPrd := B1_COD
    // ARET[2] Calculo de quantidade por embalagem
    AAdd(aRet, nQE)
 
    // ARET[3] LOTE
    DbSelectArea("SB8")
    DbSetOrder(1)
    DbSeek(FwXFilial("SB8") + cPrd + Substr(PARAMIXB[1], TamSX3("B1_COD")[1]+1,TamSX3("B8_LOTECTL")[1]))
    AAdd(aRet, SB8->B8_LOTECTL)
 
    // ARET[4] DATA DE VALIDADE
    AAdd(aRet, SB8->B8_DTVALID)
    DbCloseArea() // RESTAURA O ESTADO FECHADO DO ARQUIVO SB8
 
    // ARET[5] N�MERO DE S�RIE
    AAdd(aRet, PadR("", TamSX3("BF_NUMSERI")[1]))
 
    // ARET[6] ENDERE�O DESTINO
    AAdd(aRet, PadR("", TamSX3("BE_LOCALIZ")[1]))



    // DEVOLVE AS AREAS
    RestArea(aAreaSB8)
    RestArea(aAreaSB1)

   RETURN(aRet)

