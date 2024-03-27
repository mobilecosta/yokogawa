#Include "TOTVS.CH"
 

User Function CBRETEAN()
    Local cId         := PARAMIXB[1]          // Codigo de Barras - “1762010015070  17008301" - Código do Produto + Lote
    Local aRet        := {}                   // DADOS DA ETIQUETA
    Local aAreaSB1    := {}                   // ESTADO DOS ARQUIVOS DE TRABALHO
    Local aAreaSB8    := {}                   //  
    Local cB1_COD     := ''                   // Código do Produto
    Local cB8_LOTECTL := ""
    Local nQE         := 1
 
    // ARMAZENA A ï¿½REA CORRENTE
    aAreaSb1:= SB1->(GetArea())
    aAreaSB8:= SB8->(GetArea())

    cB1_COD     := Subs(cID, 1, Len(SB1->B1_COD))
    cB8_LOTECTL := Subs(cID, Len(SB1->B1_COD) + 1, Len(cID))
    cB8_LOTECTL := StrTran(cB8_LOTECTL, "LOTE: ", "")

    cB8_LOTECTL := Left(cB8_LOTECTL + Space(Len(SB8->B8_LOTECTL)), Len(SB8->B8_LOTECTL))
 
    dbselectarea('SB1')
    dbsetorder(1) // B1_FILIAL+B1_COD
    dbseek(xFilial("SB1")+cB1_COD)
    AAdd(aRet, PadR(B1_COD, TamSX3("B1_COD")[1]))
    // ARET[2] Calculo de quantidade por embalagem
    AAdd(aRet, nQE)
 
    // ARET[3] LOTE
    DbSelectArea("SB8")
    DbSetOrder(5)       // B8_FILIAL + B8_PRODUTO + B8_LOTECTL
    DbSeek(xFilial("SB8") + cB1_COD + cB8_LOTECTL)
    AAdd(aRet, SB8->B8_LOTECTL)
 
    // ARET[4] DATA DE VALIDADE
    AAdd(aRet, SB8->B8_DTVALID)
    DbCloseArea() // RESTAURA O ESTADO FECHADO DO ARQUIVO SB8
 
    // ARET[5] Nï¿½MERO DE Sï¿½RIE
    AAdd(aRet, PadR("", TamSX3("BF_NUMSERI")[1]))
 
    // ARET[6] ENDEREï¿½O DESTINO
    AAdd(aRet, PadR("", TamSX3("BE_LOCALIZ")[1]))

    // DEVOLVE AS AREAS
    RestArea(aAreaSB8)
    RestArea(aAreaSB1)

   RETURN(aRet)

