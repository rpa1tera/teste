#include "topconn.ch"
//#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
//#INCLUDE "RWMAKE.CH"
#INCLUDE "AP5MAIL.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

/*/{Protheus.doc} PEDCOMGRAF
//Pedido de compras (Emissao em formato Grafico).
@since 18/11/2016ad
/*/
//A pedido da EMIBM o comprador está trazendo o usuario logado no momento da inclusão do pedido
User Function PEDCOMGRAF()

// alterar o parametro MV_PCOMPRA e colocar PEDCOMGRAF para substituir a impressão padrão.

Local lImprime	:= .F.

Private cStatus
Private cNumSC7		:= ""
Private cSystem		:= GetSrvProfString("StartPath","")
Private cDiretorio	:= ""
Private cTitulo		:= "AUTORIZAÇÃO DE FORNECIMENTO"
Private cPerg		:= "PEDCOMGRAF"
Private cNomeProg	:= "PEDCOMGRAF"	// Coloque aqui o nome do programa para impressao no cabecalho
Private cEmail		:= Posicione("SA2",1,xFilial("SA2")+ SC7->(C7_FORNECE+C7_LOJA),"A2_EMAIL")
Private cLclEntreg	:= Padr("",68)
Private cEndEntreg	:= Padr("",68)
Private cCepEntreg	:= PesqPict("SM0","M0_CEPENT")
Private cContEntre	:= Padr("",68)
Private CONTFL     	:= 01
Private nMinCol		:= 0010
Private nMinLin		:= 0000
Private nMaxCol		:= 2560 	// Retrato     		    3280 	// Paisagem
Private	nMaxLin		:= 3070 	// Retrato          	2350 	// Paisagem
//Private oPrn		:= TMSPrinter():New()
Private oPrn
Private oBrush 		:= TBrush():NEW("",CLR_HGRAY)
Private cNumPed		:= SC7->C7_NUM
Private dEmissao	:= SC7->C7_EMISSAO
Private nUnidade	:= 1
Private nMoeda		:= 1
Private lViewPDF	:= .T.
//Private lEmail		:= .T.

Private nColIt1 	:= nMinCol  + 90	//ITEM
Private nColIt2 	:= nColIt1  + 176	//PRODUTO
Private nColIt3 	:= nColIt2  + 424	//DESCRICAO 	          140 - Cabe 8 caracteres
Private nColIt4 	:= nColIt3  + 424	//OBSERVAÇÃO
Private nColIt5 	:= nColIt4  + 55	//UN
Private nColIt6 	:= nColIt5  + 115	//QTDE					-40
Private nColIt7 	:= nColIt6  + 160	//VLR UNITARIO
Private nColIt8 	:= nColIt7  + 170	//DESCONTO
Private nColIt9 	:= nColIt8  + 170	//VLR TOTAL
Private nColIt10 	:= nColIt9  + 120	//ICMS	         -40
Private nColIt11 	:= nColIt10 + 270 	//C. CUSTO
Private nColIt12 	:= nColIt11 + 205	//SOLICITANTE
Private nColIt13 	:= nMaxCol 			//DT ENTREGA

	// (INICIO) LEANDROM 12/12/2017 Valida se pedido de compras não bloqueado ou se já foi atendido)
	aAreaSC7 := SC7->(GetArea())	//Salva area da SC7
	dbSelectArea("SC7")
	dbSetOrder(1)
	lPedOK	:= .F.
	If dbSeek(xFilial("SC7") + cNumPed)
		While ! SC7->(EOF()) .And. (SC7->(C7_FILIAL+C7_NUM)) == (xFilial("SC7") + cNumPed)
			//Verifica se existe algum item apto para geração da autorização de fornecimento
			If (SC7->C7_CONAPRO <> "B") //.And. C7_QUJE < C7_QUANT)				// Não bloqueado
				//(Empty(SC7->C7_RESIDUO);										// Não eliminado residuo
				//.And. C7_QTDACLA == 0 ;										// Não usado em pré nota
				//.And. C7_QUJE < C7_QUANT) 									// Não atendido integralmente
				lPedOk := .T.
				Exit
			EndIf

			SC7->(dbSkip())
		EndDo
	Else
		MsgInfo("Pedido não encontrado", "PEDCOMGRAF :: Validação")
		Return
	EndIf

	If !lPedOk
		cMsgAlert := "Pedido não pode ser impresso." + Chr(13)+Chr(10)
		cMsgAlert += "Somente pedidos liberados e pendentes de entrega podem ser impressos !"
		MsgAlert(cMsgAlert, "PEDCOMGRAF :: Validação")
		Return
	EndIf
	RestArea(aAreaSC7)	//Restaura area da SC7
	// (FIM) LEANDROM 12/12/2017 Valida se pedido de compras não bloqueado ou se já foi atendido)

	//Apaga PDF gerado na sessão anterior - Cassiano
	cFilename := ALLTRIM(SC7->C7_FILIAL) + "_" + ALLTRIM(SC7->C7_NUM)
	cCaminho1 := GetTempPath()+ cFilename +".pdf" //  "C:\Users\Econsist\AppData\Local\Temp\"
	If File(cCaminho1)
		FERASE(cCaminho1)
	EndIf

	If ENTREGA()
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Inicio do lay-out / impressao                                ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		//lViewPDF := !lEmail		//Controla de envia por email ou visualiza o PDF
		lAdjustToLegacy := .T.
		lDisableSetup  	:= .T.
		//cFilename := Criatrab(Nil,.F.)
		//cFilename := ALLTRIM(SC7->C7_FILIAL) + "_" + ALLTRIM(SC7->C7_NUM)

		oPrn	:= FWMSPrinter():New(cFilename, IMP_PDF, lAdjustToLegacy, , lDisableSetup,,,,,,,lViewPDF)

		oPrn:SetResolution(78)
		oPrn:SetPortrait()			//SetPortrait() SetLandscape
		//oPrn:SetPaperSize(DMPAPER_A4)
		oPrn:SetPaperSize(9)

		/* Define tamanho do papel
		0 - Tamanho customizavel pelo usuario, informado em nHeight/nWidth. Aplicavel apenas em impressoes do tipo PDF.
	    1 - Letter   216mm x 279mm  637 x 823
	    3 - Tabloid  279mm x 432mm  823 x 1275
	    7 - Executive 184mm x 267mm  543 x 788
	    8 - A3     297mm x 420mm  876 x 1240
	    9 - A4     210mm x 297mm  620 x 876
	    */

		oPrn:SetMargin(10,00,10,00) // nEsquerda, nSuperior, nDireita, nInferior

		oPrn:cPathPDF := GetTempPath()
		cDiretorio	:= oPrn:cPathPDF

		DbSelectArea('SC7')
		SC7->(DbSetOrder(1))
		If	! SC7->(DbSeek(xFilial('SC7') + cNumPed))
			Help('',1,'PEDCOMGRAF',,OemToAnsi('Pedido não encontrado.'),1)
			Return
		EndIf

		//Executa a rotina de impressao
		Processa({ |lEnd| lImprime := FPrintRel(),OemToAnsi('Gerando o relatório.')}, OemToAnsi('Aguarde...'))

		If lImprime
			oPrn:EndPage()

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Imprime em Video, e finaliza a impressao. !³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			oPrn:Preview()		// Visualiza antes de imprimir

			If cStatus == "03" .OR. cStatus == "05" // Verifica se o pedido está liberado ou não
				If MSGYESNO("Deseja enviar esse pedido ao Fornecedor?","Confirmação de Envio")
					tela()
				EndIf
			EndIf
		Else
			MsgStop("Consulta não obteve dados", Funname())
		EndIf
	EndIf

	//Apaga pdf gerado - Cassiano
	cDirServ 	:= cSystem + "PedComGraf\"
	cAnexo		:= cDirServ + cFileName  +".pdf"
	cCaminho1	:= GetTempPath()+ cFilename +".pdf"
	If File(cCaminho1)
		If File(cAnexo)
			FERASE(cAnexo)
			FERASE(cCaminho1)
		EndIf
	EndIf

Return

//===========================================================================
// Impressão do relatorio
//===========================================================================
Static Function FPrintRel()

Local cQuery	:= ""
Local nLinSup	:= nMinLin
Local nLinInf	:= nMinLin
Local lImprime	:= .F.
Local nTxMoeda	:= 0
Local nQtdItens := 0
Local nI
Local nX

Private lEmail	:= .F.	//Controla se envia pedido por email
Private nPagina	:= 0
Private nTotIPI	:= 0
Private nTotICM	:= 0
Private nTotFrt	:= 0
Private nTotPed	:= 0
Private cObsCab	:= ""
Private nDesc   := 0
Private cComp	:= ""
Private cAlter  := ""
Private cAprov	:= ""
Private cEmissCab
Private cNumPedido

	//Configuração das fontes utilizadas

	oFont6	 := TFont():New("Arial",06,06,,.F.,,,,.T.,.F.)
	oFont6N	 := TFont():New("Arial",06,06,,.T.,,,,.T.,.F.)
	oFont7	 := TFont():New("Arial",07,07,,.F.,,,,.T.,.F.)
	oFont7N	 := TFont():New("Arial",07,07,,.T.,,,,.T.,.F.)
	oFont8	 := TFont():New("Arial",08,08,,.F.,,,,.T.,.F.)
	oFont8N  := TFont():New("Arial",08,08,,.T.,,,,.T.,.F.)
	oFont9	 := TFont():New("Arial",09,09,,.F.,,,,.T.,.F.)
	oFont9N	 := TFont():New("Arial",09,09,,.T.,,,,.T.,.F.)
	oFont10	 := TFont():New("Arial",10,10,,.F.,,,,.T.,.F.)
	oFont10N := TFont():New("Arial",10,10,,.T.,,,,.T.,.F.)
	oFont11	 := TFont():New("Arial",11,11,,.F.,,,,.T.,.F.)
	oFont11N := TFont():New("Arial",11,11,,.T.,,,,.T.,.F.)
	oFont12	 := TFont():New("Arial",12,12,,.F.,,,,.T.,.F.)
	oFont12N := TFont():New("Arial",12,12,,.T.,,,,.T.,.F.)
	oFont13	 := TFont():New("Arial",13,13,,.F.,,,,.T.,.F.)
	oFont13N := TFont():New("Arial",13,13,,.T.,,,,.T.,.F.)
	oFont14	 := TFont():New("Arial",14,14,,.F.,,,,.T.,.F.)
	oFont14N := TFont():New("Arial",14,14,,.T.,,,,.T.,.F.)
	oFont15	 := TFont():New("Arial",15,15,,.F.,,,,.T.,.F.)
	oFont15N := TFont():New("Arial",15,15,,.T.,,,,.T.,.F.)
	oFont16  := TFont():New("Arial",16,16,,.F.,,,,.T.,.F.)
	oFont16N := TFont():New("Arial",16,16,,.T.,,,,.T.,.F.)
	oFont17  := TFont():New("Arial",17,17,,.F.,,,,.T.,.F.)
	oFont17N := TFont():New("Arial",17,17,,.T.,,,,.T.,.F.)
	oFont18  := TFont():New("Arial",18,18,,.F.,,,,.T.,.F.)
	oFont18N := TFont():New("Arial",18,18,,.T.,,,,.T.,.F.)
	oFont19	 := TFont():New("Arial",19,19,,.F.,,,,.T.,.F.)
	oFont19N := TFont():New("Arial",19,19,,.T.,,,,.T.,.F.)
	oFont20	 := TFont():New("Arial",20,20,,.F.,,,,.T.,.F.)
	oFont20N := TFont():New("Arial",20,20,,.T.,,,,.T.,.F.)
	oFont21	 := TFont():New("Arial",21,21,,.F.,,,,.T.,.F.)
	oFont21N := TFont():New("Arial",21,21,,.T.,,,,.T.,.F.)
	oFont23	 := TFont():New("Arial",23,23,,.F.,,,,.T.,.F.)
	oFont23N := TFont():New("Arial",23,23,,.T.,,,,.T.,.F.)
	oFont25	 := TFont():New("Arial",25,25,,.F.,,,,.T.,.F.)
	oFont25N := TFont():New("Arial",25,25,,.T.,,,,.T.,.F.)
	oFont27	 := TFont():New("Arial",27,27,,.F.,,,,.T.,.F.)
	oFont27N := TFont():New("Arial",27,27,,.T.,,,,.T.,.F.)

	// Monta consulta ao banco de dados
	//cQuery  := " SELECT ISNULL(CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(MAX), C7_XDESITE)),'') 	DSCPRODC7 "
	cQuery  := " SELECT C7.*, C7.R_E_C_N_O_ RECNOSC7, C1.R_E_C_N_O_ RECNOSC1 "

	cQuery  += " FROM " + RetSqlName("SC7") + " C7 (NOLOCK) "
	cQuery  += " 	LEFT JOIN " + RetSqlName("SC1") + " C1 (NOLOCK) ON "
	cQuery  += " 		C1_FILIAL	= C7_FILIAL AND "
	cQuery  += " 		C1_NUM		= C7_NUMSC AND "
	cQuery  += " 		C1_ITEM		= C7_ITEMSC AND "
	cQuery  += " 		C1_PRODUTO	= C7_PRODUTO AND "
	cQuery  += " 		C1.D_E_L_E_T_ = C7.D_E_L_E_T_ "
	cQuery  += " WHERE C7.D_E_L_E_T_ = ' ' "
	cQuery  += " 	AND C7_FILIAL  	= '" + xFilial("SC7") + "' "
	cQuery  += " 	AND C7_NUM     	= '" + cNumPed + "' "
	cQuery  += " 	AND (C7_CONAPRO <> 'B')"
	//cQuery  += " 	AND SC7.C7_QUJE < SC7.C7_QUANT) "	// Não bloqueado
	//cQuery  += " 	AND (C7_QUJE < SC7.C7_QUANT) "		// Não atendido integralmente
	//cQuery  += " 	AND (C7_QTDACLA = 0) "				// Não usado em pré nota

	cQuery  += " ORDER BY C7.C7_ITEM "

	If Select("QRY") > 0
		dbSelectArea("QRY")
		QRY->(dbCloseArea())
	EndIf

	//cQry := ChangeQuery(cQry)
	//TcQuery cQuery Alias "QRY" New
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QRY",.T.,.T.)

	QRY->(dbGoTop())

	cCompr := QRY->C7_USER

	cTipoSC7	:= IIF((SC7->C7_TIPO == 1 .OR. SC7->C7_TIPO == 3),"PC","AE")
	cComp 	:= UsrFullName(SC7->C7_USER)

	If !Empty(SC7->C7_GRUPCOM)
		dbSelectArea("SAJ")
		dbSetOrder(1)
		dbSeek(xFilial("SAJ")+SC7->C7_GRUPCOM)
		While !Eof() .And. SAJ->AJ_FILIAL+SAJ->AJ_GRCOM == xFilial("SAJ")+SC7->C7_GRUPCOM
			If SAJ->AJ_USER != SC7->C7_USER
				cAlter += AllTrim(UsrFullName(SAJ->AJ_USER))+"/"
			EndIf
			dbSelectArea("SAJ")
			dbSkip()
		EndDo
	EndIf

	// Aprovadores

	cNumSC7 := PADR(AllTrim(SC7->C7_NUM),(TamSX3("CR_NUM")[1]))
	dbSelectArea("SCR")
	dbSetOrder(1)
	If dbSeek(xFilial("SCR") + cTipoSC7 + cNumSC7)
		While !Eof() .And. SCR->(CR_FILIAL + CR_TIPO + CR_NUM) == (xFilial("SCR") + cTipoSC7 + cNumSC7)
			cAprov += AllTrim(UsrFullName(SCR->CR_USER))+" ["
			cStatus := SCR->CR_STATUS
			Do Case
				Case cStatus == "03" //Liberado
					cAprov   += "Ok"
				Case cStatus == "04" //Bloqueado
					cAprov   += "BLQ"
				Case cStatus == "05" //Nivel Liberado
					cAprov   += "##"
				OtherWise            //Aguar.Lib
					cAprov += "??"
			EndCase
				cAprov += "] - "
				dbSelectArea("SCR")
				dbSkip()
		Enddo
    Else
    	cStatus := "0"
    EndIf

	cChave 	:= ""
	lCabec	:= .T.
	If !Empty(QRY->C7_NUM)
		lImprime	:= .T.

		cEmissCab := DTOC(STOD(QRY->C7_EMISSAO))
		cNumPedido:= QRY->C7_NUM
		cChave := QRY->(C7_FILIAL + C7_NUM)
		While !QRY->(eof())
			If lCabec
				cObsCab := AllTrim(QRY->C7_XOBSCAB)

				//Cabeçalho do pedido
				ImpCabec(@nLinSup, @nLinInf)

				// Box de dados FORNECEDOR
				nLinAtu	:= nLinInf
				nLinSup	:= nLinInf
				nLinInf	+= 240
				nCol1 := 50
				nCol2 := 270
				nCol3 := 1250
				nCol4 := 1400
				nEspac:= 30

				oPrn:Box(nLinSup, nMinCol, nLinInf, nMaxCol)
				nLinSup += nEspac
				oPrn:Say(nLinSup, nMinCol+nCol1-30, "FORNECEDOR"	, oFont11N	, 100, CLR_BLUE)

				nLinSup += nEspac+10
				oPrn:Say(nLinSup, nMinCol+nCol1, "COD / NOME:"	, oFont10N	, 100)
				cCodLoj := QRY->C7_FORNECE + "-" + QRY->C7_LOJA + " "
				cNome := Posicione("SA2",1,xFilial("SA2") + QRY->(C7_FORNECE + C7_LOJA), "A2_NOME")
					oPrn:Say(nLinSup, nMinCol+nCol2, cCodLoj + cNome, oFont10	, 100)

				nLinSup += nEspac
				oPrn:Say(nLinSup, nMinCol+nCol1, "FONE:"	, oFont10N	, 100)
				cDDDForn := Posicione("SA2",1,xFilial("SA2") + QRY->(C7_FORNECE + C7_LOJA), "A2_DDD")
				cFonForn := Posicione("SA2",1,xFilial("SA2") + QRY->(C7_FORNECE + C7_LOJA), "A2_TEL")
				oPrn:Say(nLinSup, nMinCol+nCol2, cDDDForn + " " + cFonForn	, oFont10	, 100)

				nLinSup += nEspac+5
				oPrn:Say(nLinSup, nMinCol+nCol1, "ENDEREÇO:"	, oFont10N	, 100)
				cEndForn := Posicione("SA2",1,xFilial("SA2") + QRY->(C7_FORNECE + C7_LOJA), "A2_END")
				cMunForn := AllTrim(Posicione("SA2",1,xFilial("SA2") + QRY->(C7_FORNECE + C7_LOJA), "A2_MUN")) + "-"
				cUfForn  := Posicione("SA2",1,xFilial("SA2") + QRY->(C7_FORNECE + C7_LOJA), "A2_EST")
				oPrn:Say(nLinSup, nMinCol+nCol2, AllTrim(cEndForn) + " - "  +AllTrim(cMunForn)+"/"+AllTrim(cUfForn)	, oFont10	, 100)

				nLinSup += nEspac
				oPrn:Say(nLinSup, nMinCol+nCol1, "CONTATO:"	, oFont10N	, 100)
				oPrn:Say(nLinSup, nMinCol+nCol2, QRY->C7_CONTATO	, oFont10	, 100)

				oPrn:Say(nLinSup, 0800, "CNPJ:"	, oFont10N	, 100)
				cCGC := Posicione("SA2",1,xFilial("SA2") + QRY->(C7_FORNECE + C7_LOJA), "A2_CGC")
				If Len(AllTrim(cCGC)) > 11
					cCGC := TransForm(cCGC,'@R 99.999.999/9999-99')
				Else
					cCGC := TransForm(cCGC,'@R 999.999.999-99')
				EndIf
				oPrn:Say(nLinSup, 0950, cCGC	, oFont10	, 100)

				nLinSup += nEspac
				oPrn:Say(nLinSup, nMinCol+nCol1, "I.E.:"	, oFont10N	, 100)
				cIE := Posicione("SA2",1,xFilial("SA2") + QRY->(C7_FORNECE + C7_LOJA), "A2_INSCR")
				oPrn:Say(nLinSup,  nMinCol+nCol2, cIE	, oFont10	, 100)

				oPrn:Say(nLinSup, 0800, "CEP: "	, ofont10N	, 100)
				cCepForn := Transform(Posicione("SA2",1,xFilial("SA2") + QRY->(C7_FORNECE + C7_LOJA), "A2_CEP"), "@R 99.999-999")
				oPrn:Say(nLinSup,  0950, cCepForn, ofont10	, 100)

				nLinSup += nEspac
				oPrn:Say(nLinSup, nMinCol+nCol1, "EMAL:"	, oFont10N	, 100)
				cEmail := Posicione("SA2",1,xFilial("SA2") + QRY->(C7_FORNECE + C7_LOJA), "A2_EMAIL")
				oPrn:Say(nLinSup, nMinCol+nCol2, cEmail	, oFont10	, 100)

				// Box de dados ENTREGA
				nLinSup	:= nLinAtu
				nCol1 := (nMaxCol / 2) + 50
				nCol2 := nCol1 + 160
				nCol3 := nCol2 + 700
				nCol4 := nCol3 + 2000
				//cContEntre    cCepEntreg	cEndEntreg	  cLclEntreg
				oPrn:Box(nLinSup, (nMaxCol/2), nLinInf, nMaxCol+2)
				nLinSup += 45
				oPrn:Say(nLinSup, nCol1-30, "ENTREGA"	, oFont11N	, 100, CLR_BLUE)

				nLinSup += 50
				oPrn:Say(nLinSup, nCol1, "LOCAL:"	, oFont10N	, 100)
				cLocEnt	:= SM0->M0_NOMECOM
				oPrn:Say(nLinSup, nCol2, cLclEntreg, oFont10	, 100)

				nLinSup += 45
				oPrn:Say(nLinSup, nCol1, "END.:"	, oFont10N	, 100)
				cEndEnt	:= SM0->M0_ENDENT
				cCidEnt := SM0->M0_CIDENT
				cEstEnt := SM0->M0_ESTENT
				//oPrn:Say(nLinSup, nCol2, Alltrim(cEndEnt) + " " + AllTrim(cCidEnt) + "/" + AllTrim(cEstEnt), oFont10	, 100)
				oPrn:Say(nLinSup, nCol2, cEndEntreg, oFont10	, 100)

				nLinSup += 45
				oPrn:Say(nLinSup, nCol1, "CEP:"	, oFont10N	, 100)
				cCepEnt	:= cCepEntreg //SM0->M0_CEPENT
				oPrn:Say(nLinSup, nCol2, AllTrim(TransForm(cCepEnt,'@R 99.999-999')), oFont10	, 100)

				nLinSup += 45
				oPrn:Say(nLinSup, nCol1, "CONTATO:"	, oFont10N	, 100)
				oPrn:Say(nLinSup, nCol2, cContEntre, oFont10	, 100)


				// Box de dados INF GERAL
				nLinAtu := nLinInf
				nLinSup	:= nLinInf
				nLinInf	+= 250
				nCol1 := 50
				nCol2 := 250

				oPrn:Box(nLinSup-2, nMinCol, nLinInf, (nMaxCol / 3)+2)
				nLinSup += 45
				oPrn:Say(nLinSup, nMinCol+nCol1-30, "INF. GERAL"	, oFont11N	, 100, CLR_BLUE)

				nLinSup += 45

				oPrn:Say(nLinSup, nMinCol+nCol1, "COMPRADOR:"	, oFont10N	, 100)
				cComprador := ""
				//If ! Empty(QRY->C7_COMPRA)
				cComprador := UsrFullName(SC7->C7_USER)//Posicione("SY1",1,xFilial("SY1") + QRY->C7_COMPRA, "Y1_NOME")
				//EndIf
				oPrn:Say(nLinSup, nMinCol+nCol2+10, cComprador, oFont10	, 100)


				// Box de dados COBRANÇA
				nLinSup	:= nLinAtu
				nCol1 := (nMaxCol / 3) - 80
				nCol2 := nCol1 + 150
				nCol3 := nCol2 + 650
				nCol4 := nCol3 + 250
				nEspac:= 40

				oPrn:Box(nLinSup-2, (nMaxCol/3)-130, nLinInf, nMaxCol)
				nLinSup += nEspac
				oPrn:Say(nLinSup, nCol1-30, "COBRANÇA"	, oFont11N	, 100, CLR_BLUE)

				nLinSup += nEspac
				oPrn:Say(nLinSup, nCol1, "COND. PAGTO:"	, oFont10N	, 100)
				oPrn:Say(nLinSup, nCol2+90, ALLTRIM(POSICIONE("SE4",1,XFILIAL("SE4") + QRY->C7_COND, "E4_DESCRI")), oFont10	, 100)

				nLinSup += nEspac
				oPrn:Say(nLinSup, nCol1, "FORMATO DE PAGAMENTO:"	, oFont10N	, 100)
				cFormpag := QRY->C7_XFORMPG
				oPrn:Say(nLinSup, nCol2+240, cFormpag , oFont10	, 100)

				nLinSup += nEspac
				oPrn:Say(nLinSup, nCol1, "LOCAL:"	, oFont10N	, 100)
				oPrn:Say(nLinSup, nCol2-30, AllTrim(Upper(SM0->M0_NOMECOM)), oFont10	, 100)

				nLinSup += nEspac
				oPrn:Say(nLinSup, nCol1, "END.:"	, oFont10N	, 100)
				oPrn:Say(nLinSup, nCol2-60, AllTrim(SM0->M0_ENDCOB), oFont10	, 100)

				nLinSup += nEspac
				oPrn:Say(nLinSup, nCol1, "CEP:"	, oFont10N	, 100)
				oPrn:Say(nLinSup, nCol2-60, AllTrim(TransForm(SM0->M0_CEPCOB,'@R 99.999-999')), oFont10	, 100)
				oPrn:Say(nLinSup, nCol2+140, AllTrim(SM0->M0_CIDCOB)+'/'+AllTrim(SM0->M0_ESTCOB), oFont10	, 100)


				// Box de dados COLETA
				nLinSup	:= nLinAtu
				nCol1 := ((nMaxCol / 3) * 2) + 50
				nCol2 := nCol1 + 200

				oPrn:Box(nLinSup-2, ((nMaxCol / 3) * 2)+20, nLinInf, nMaxCol)
				nLinSup += 45
				oPrn:Say(nLinSup, nMinCol+nCol1-30, "COLETA"	, oFont11N	, 100, CLR_BLUE)

				nLinSup += 50
				oPrn:Say(nLinSup, nMinCol+nCol1, "TIPO:"	, oFont10N	, 100)
				cTipoCol := ""
				If AllTrim(QRY->C7_XTPFRET) == "CIF"
					cTipoCol := "CIF - FRETE POR CONTA DO FORNECEDOR"
				ElseIf AllTrim(QRY->C7_XTPFRET) == "FOB"
					cTipoCol := "FOB - FRETE A PAGAR"
				EndIf
				oPrn:Say(nLinSup, nMinCol+nCol2, cTipoCol, oFont10	, 100)

				nLinSup += 45
				oPrn:Say(nLinSup, nMinCol+nCol1, "LOCAL:"	, oFont10N	, 100)
				oPrn:Say(nLinSup, nMinCol+nCol2, QRY->C7_XLOCCOL, oFont10	, 100)

				nLinSup += 45
				oPrn:Say(nLinSup, nMinCol+nCol1, "TRANSP.:"	, oFont10N	, 100)
				cTransp := ""
				If ! Empty(QRY->C7_XTRANSP)
					cTransp := Posicione("SA4",1,xFilial("SA4") + QRY->C7_XTRANSP, "A4_NOME")
				EndIf
				oPrn:Say(nLinSup, nMinCol+nCol2, cTransp, oFont10	, 100)

				nLinSup += 45
				oPrn:Say(nLinSup, nMinCol+nCol1, "OBS.:"	, oFont10N	, 100)
				oPrn:Say(nLinSup, nMinCol+nCol2, QRY->C7_XOBSCOL, oFont10	, 100)

				// Box de dados ITENS
				ImpCabecIt(@nLinSup, @nLinInf)

				lCabec := .F.
			EndIf

			//Impressão dos ITENS
			nLinSup	:= nLinInf
			nAltLinha := 070 //Altura para uma linha

			//Verifica tamanho do campo OBS
			cDescri:= AllTrim(Posicione("SB1",1,xFilial("SB1")+QRY->C7_PRODUTO,"B1_DESC"))

			_areaSC7 := SC7->(GetArea())
			_areaSC1 := SC1->(GetArea())

			dbSelectArea("SC7")
			dbGoTo(QRY->RECNOSC7)
			cDscItSC7 := SC7->C7_DESCRI

			dbSelectArea("SC1")
			dbGoTo(QRY->RECNOSC1)
			cDscItSC1 := SC1->C1_DESCRI

			cDescri += If(!Empty(cDscItSC7)," - " + AllTrim(cDscItSC7), If(!Empty(cDscItSC1)," - " + AllTrim(cDscItSC1),""))

			RestArea(_areaSC1)
			RestArea(_areaSC7)

			nDiv:= len(cDescri)/69
			nInteiro:= Int(nDiv)
			nDecimais := nDiv - nInteiro
			if nDecimais > 0 .AND. nDecimais < 1
				nQtdLin1 := nInteiro + 1
			else
				nQtdLin1 := nInteiro
			endif

			//Verifica tamanho do campo CC
			cCentrC := Alltrim(QRY->C7_CC) + " - "+ AllTrim(Posicione("CTT",1,xFilial("CTT")+ QRY->C7_CC,"CTT_DESC01")) //CTT_DESC01)
			nDiv2:= Len(cCentrC)/17
			nInteiro2 := Int(nDiv2)
			nDecimais2 := nDiv2 - nInteiro2
			if nDecimais2 > 0 .AND. nDecimais2 < 1
				nQtdLin2 := nInteiro2 + 1
			else
				nQtdLin2 := nInteiro2
			endif

			//Verifica a quantidade de linhas
			If nQtdLin1 > nQtdLin2
				nQtdLinhas := nQtdLin1
			ElseIf nQtdLin1 == nQtdLin2
				nQtdLinhas	:= nQtdLin1
			Else
				nQtdLinhas := nQtdLin2
			EndIf
			nAltLiBox:= nAltLinha * nQtdLinhas
			nLinInf:= nLinSup + nAltLiBox

			oPrn:Box(nLinSup, nMinCol,nLinInf , nColIt1+1)
			oPrn:Say(nLinSup+42, nMinCol+5, QRY->C7_ITEM	, oFont10	, 100)

			oPrn:Box(nLinSup, nColIt1-1, nLinInf, nColIt2)
			cTemp := QRY->C7_PRODUTO
			oPrn:Say(nLinSup+42, nColIt1+5, cTemp	, oFont10	, 100)

			oPrn:Box(nLinSup, nColIt2-2, nLinInf, nColIt4+2)
			//cTemp := "101010101010101010100101101010101 101010110101 1010101001 101110 cassiano 10101010101010101010101010101100101010"
			oPrn:SayAlign(nLinSup, nColIt2, cDescri, oFont10	,nColIt4 - nColIt2,nLinInf-nLinSup,0,0,0)

			oPrn:Box(nLinSup, nColIt4-2, nLinInf, nColIt5+2)
			If nUnidade == 2 .And. !Empty(QRY->C7_SEGUM)
				oPrn:Say(nLinSup+42, nColIt4+4, QRY->C7_SEGUM	, oFont10	, 100)
			Else
				oPrn:Say(nLinSup+42, nColIt4+4, QRY->C7_UM	, oFont10	, 100)
			EndIF

			oPrn:Box(nLinSup, nColIt5, nLinInf, nColIt6+1)
			If nUnidade == 2 .And. !Empty(QRY->C7_QTSEGUM)
				cQuant := AllTrim(Transform(QRY->C7_QTSEGUM, PesqPict("SC7","C7_QUANT")))
			Else
				cQuant := AllTrim(Transform(QRY->C7_QUANT  , PesqPict("SC7","C7_QUANT")))
			EndIf
			oPrn:Say(nLinSup+42, nColIt5+5,	cQuant , oFont10	, 100) //cPreco

			oPrn:Box(nLinSup, nColIt6-1, nLinInf, nColIt7)
			nTxMoeda := IIF(QRY->C7_TXMOEDA > 0, QRY->C7_TXMOEDA,0)
			If nUnidade == 2 .And. !Empty(QRY->C7_QTSEGUM)
				cPreco	:= AllTrim(Transform(xMoeda((QRY->C7_TOTAL/QRY->C7_QTSEGUM),QRY->C7_MOEDA,nMoeda,QRY->C7_DATPRF,MsDecimais(QRY->C7_MOEDA),nTxMoeda), PesqPict("SC7","C7_PRECO")))
			Else
				cPreco	:= AllTrim(Transform(QRY->C7_PRECO, PesqPict("SC7","C7_PRECO")))
				//cPreco	:= AllTrim(Transform(xMoeda(QRY->C7_PRECO,QRY->C7_MOEDA,nMoeda,QRY->C7_DATPRF,MsDecimais(QRY->C7_MOEDA),nTxMoeda), PesqPict("SC7","C7_PRECO")))
			EndIf
			oPrn:Say(nLinSup+42, nColIt6+5, cPreco	, oFont10	, 100) //cPreco

			oPrn:Box(nLinSup, nColIt7, nLinInf, nColIt8)
			cDesc := AllTrim(Transform(QRY->C7_VLDESC, PesqPict("SC7","C7_VLDESC")))
			nDesc += QRY->C7_VLDESC
			oPrn:Say(nLinSup+42, nColIt7+10, cDesc	, oFont10	, 100) //cDesc

			oPrn:Box(nLinSup, nColIt8, nLinInf, nColIt9)
			cTotal := AllTrim(Transform(QRY->C7_TOTAL, PesqPict("SC7","C7_TOTAL")))

			//LEANDROM 11/12/2017 (AJUSTADO PARA ACRESCENTAR O VALOR DO FRETE)
			nTotPed	+= QRY->(C7_TOTAL-C7_VLDESC+C7_ICMSRET+C7_VALIPI+C7_VALFRE)
			//nTotPed	+= QRY->(C7_TOTAL-C7_VLDESC+C7_ICMSRET+C7_VALIPI)

			oPrn:Say(nLinSup+42, nColIt8+10, cTotal	, oFont10	, 100) //cTotal

			oPrn:Box(nLinSup, nColIt9, nLinInf, nColIt10)
			cICM := AllTrim(Transform(QRY->C7_PICM, PesqPict("SC7","C7_PICM")))
			nTotICM	+= QRY->C7_VALICM
			nTotIPI	+= QRY->C7_VALIPI
			oPrn:Say(nLinSup+42, nColIt9+5, cICM	, oFont10	, 100)//cICM

			nTotFrt += QRY->C7_VALFRE

			oPrn:Box(nLinSup, nColIt10, nLinInf, nColIt11+1)
			// LEANDROM 11/12/2017 (AJUSTE PARA QUEBRA DE LINHA NA DESCRIÇÃO DO CENTRO DE CUSTO)
			aDescric := {}
			nTamCol := 17	//Tamanho da coluna do centro de custo
			nQtdLinCC := 0
  			While ! Empty(cCentrC)
  				nQtdLinCC ++

  				If nQtdLinCC == 1
					aadd(aDescric, SubStr(cCentrC, 1, IIf(EspacoAt(cCentrC, nTamCol) > 1, EspacoAt(cCentrC, nTamCol) - 1, nTamCol)))
					cCentrC := SubStr(cCentrC, IIf(EspacoAt(cCentrC, nTamCol) > 1, EspacoAt(cCentrC, nTamCol), nTamCol) + 1)

				Else
					aadd(aDescric, cCentrC)
					cCentrC := ""
				EndIf
			EndDo

			For nI := 1 To Len(aDescric)
				oPrn:Say(nLinSup+(nI*42), nColIt10+5, aDescric[nI], oFont10	, 100)
			Next nI

			/*
			If Len(cCentrC) > 17
				cCentrC1 := ""
				cCentrC2 := ""
				nI:=17
				While nI >= 1
					If Substr(cCentrC,nI,1) == " "
						cCentrC1 := Substr(cCentrC,1,nI)
						cCentrC2 := Substr(cCentrC,nI+1,Len(cCentrC))
						nI:= 1
					EndIf
					nI--
				EndDo
				oPrn:Say(nLinSup+42, nColIt10+5, cCentrC1, oFont10	, 100)//cCentroC
				oPrn:Say(nLinSup+84, nColIt10+5, cCentrC2 , oFont10	, 100)
			Else
				oPrn:Say(nLinSup+42, nColIt10+5, cCentrC , oFont10	, 100)
			EndIf
			*/
			//oPrn:SayAlign(nLinSup+42, nColIt10+5, cCentrC , oFont10	,nColIt11-nColIt10,nLinInf-nLinSup,0,0,0)//cCentroC

			cSolicit := ""
			If !Empty(QRY->C7_NUMSC)
				cSolicit := Posicione("SC1",1,xFilial("SC1") + QRY->C7_NUMSC, "C1_SOLICIT")
			EndIf

			aDescric := {}
			aAdd(aDescric, QRY->C7_NUMSC)
			aAdd(aDescric, cSolicit)

			oPrn:Box(nLinSup, nColIt11-1, nLinInf, nColIt12)
			For nI := 1 To Len(aDescric)
				oPrn:Say(nLinSup+(nI*42), nColIt11+5, aDescric[nI], oFont10	, 100)
			Next nI

			oPrn:Box(nLinSup, nColIt12, nLinInf, nColIt13)
 			oPrn:Say(nLinSup+42, nColIt12+5, DTOC(STOD(QRY->C7_DATPRF))	, oFont10	, 100)

			QRY->(dbSkip())
			If Empty(QRY->C7_NUM)
				ImpRodape(@nLinSup, @nLinInf)
				Return (lImprime)

			//Verifica se encerrou os itens do pedido atual
			ElseIf cChave <> QRY->(C7_FILIAL + C7_NUM)
				ImpRodape(@nLinSup, @nLinInf)
				oPrn:EndPage() //Finaliza a página
				nQtdItens 	:= 0
				nLinSup		:= nMinLin
				nLinInf		:= 300
				lCabec 		:= .T.
				cChave 		:= QRY->(C7_FILIAL + C7_NUM)

			Else
				nQtdItens++
				If ((nPagina == 1 .And. nLinInf > 3050) .Or. (nPagina > 1 .And. nLinInf > 3050))
					oPrn:EndPage() //Finaliza a página

					ImpCabec(@nLinSup, @nLinInf)
					ImpCabecIt(@nLinSup, @nLinInf)

					nQtdItens := 0
				EndIf
			EndIf
		EndDo
	EndIf
Return (lImprime)

//============================================================
// Imprime cabeçalho do pedido
//============================================================
Static Function ImpCabec(nLinSup, nLinInf)

Local cLogo 	:= cSystem + "logo\logo" + cFilAnt + ".BMP" 	//Logomarca
Local cSemLogo	:= cSystem + "logo\semlogo.BMP"

	cEmail	:= Padr(cEmail,100)

	nLinSup	:= nMinLin
	nLinInf	:= 300

	oPrn:StartPage()
	nPagina++

	// Box da logomarca
	nCol1 := nMinCol + 600
	oPrn:Box(nLinSup, nMinCol, nLinInf, nCol1+2)

	// Impressão da Logo
	If File(cLogo)
		oPrn:SayBitmap(nLinSup+10, nMinCol+60, cLogo, 500, 190)
	ElseIf File(cSemLogo)
		oPrn:SayBitmap(nLinSup+15, nMinCol+60, cSemLogo, 500, 190)
	EndIf

	// Box do cabeçalho
	nCol2 := nMaxCol - 500
	oPrn:Box(nLinSup, nCol1, nLinInf, nCol2)
	nPosCentral	:= Int(nMaxCol-(Len(cTitulo)*100/10))/2
   //	oPrn:Say(nLinSup+60, nPosCentral, cTitulo, oFont19N, 100, CLR_BLUE)
	oPrn:SayAlign(nLinSup,nCol1,cTitulo,oFont16N,nCol2-nCol1,nLinInf-nLinSup,CLR_BLUE,2,1)

	// Box do numero pedido
	oPrn:Box(nLinSup, nCol2, nLinInf, nMaxCol)
	oPrn:Say(nLinSup+060,nCol2+160, "PÁGINA: " + CVALTOCHAR(nPagina), oFont14, 100)
	oPrn:Say(nLinSup+125,nCol2+25, "NRO PEDIDO: " + cNumPedido, oFont16N, 100, CLR_BLUE)
	oPrn:Say(nLinSup+190,nCol2+60, "EMISSAO: " + cEmissCab, oFont14, 100)

	nLinSup += 130
	oPrn:Say(nLinSup, nCol1+0050, AllTrim(SM0->M0_CODFIL) + " " + AllTrim(Upper(SM0->M0_NOMECOM)),oFont11N)

	nLinSup += 45
	oPrn:Say(nLinSup, nCol1+0050, "CPF/CNPJ: ",oFont14N)   //Coluna anterior 0800
	If Len(AllTrim(SM0->M0_CGC)) > 11
		oPrn:Say(nLinSup, nCol1+0250, TransForm(SM0->M0_CGC,'@R 99.999.999/9999-99'),oFont11) //Coluna anterior 1000
	Else
		oPrn:Say(nLinSup, nCol1+0250, TransForm(SM0->M0_CGC,'@R 999.999.999-99'),oFont11)
	EndIf
	oPrn:Say(nLinSup, nCol1+0800, "I.E.: ",oFont11N) // Coluna anterior 1100
	oPrn:Say(nLinSup, nCol1+0900, SM0->M0_INSC,oFont11) // Coluna anterior 1200

	nLinSup += 45
	cEndereco 	:= SM0->M0_ENDCOB
	cCidade		:= SM0->M0_CIDCOB
	cUF			:= SM0->M0_ESTCOB
	oPrn:Say(nLinSup, nCol1+0050, AllTrim(cEndereco) + " - " + AllTrim(cCidade)+'/'+AllTrim(cUF),oFont11)

	nLinSup += 45
	oPrn:Say(nLinSup, nCol1+0050, "FONE: ",oFont11N)
	cTelefone := SM0->M0_TEL
	//cTelefone := "("+Substr(alltrim(cTelefone),1,2)+")" + Substr(alltrim(cTelefone),3,4)+ "-" + Substr(alltrim(cTelefone),7,4)
	oPrn:Say(nLinSup, nCol1+0170, cTelefone,oFont11)

	oPrn:Say(nLinSup, nCol1+0500, "EMAIL: ",oFont11N)
	cEmailXML :=SuperGetMv("MV_XMAILNF", .T., "totvs@totvs.com.br")// Posicione("SA1", 3, XFILIAL("SA1") + SM0->M0_CGC, "A1_EMAIL")
	oPrn:Say(nLinSup, nCol1+0620, cEmailXML, oFont11)

	oPrn:Say(nLinSup, nCol1+1100, "CEP: ",oFont11N)
	cCep := TransForm(SM0->M0_CEPCOB ,'@R 99.999-999')
	oPrn:Say(nLinSup, nCol1+1200, AllTrim(cCep),oFont11)

Return

//============================================================
// Imprime cabeçalho dos itens
//============================================================
Static Function ImpCabecIt(nLinSup, nLinInf)

	nLinSup := nLinInf + 20
	nLinInf := nLinSup + 60

	oPrn:Box(nLinSup, nMinCol, nLinInf, nColIt1+1)
	oPrn:FillRect({nLinSup+4,nMinCol+3,nLinInf,nColIt1-1},oBrush)
   	oPrn:Say(nLinSup+40, nMinCol+5, "ITEM"	, oFont10N	, 100)
	//oPrn:SayAlign(nLinSup,nMinCol,"ITEM" ,oFont13N,060, 100,,2,2 )

	oPrn:Box(nLinSup, nColIt1-1, nLinInf, nColIt2)
	oPrn:FillRect({nLinSup+4,nColIt1+3,nLinInf,nColIt2-2},oBrush)
	oPrn:Say(nLinSup+40, nColIt1+10, "PRODUTO"	, oFont10N	, 100)
 	//oPrn:SayAlign(nLinSup,nColIt1,"PRODUTO" ,oFont13N,nLinInf-nLinSup, nColIt2-nColIt1,, 2, 2 )

	oPrn:Box(nLinSup, nColIt2-2, nLinInf, nColIt4+2)
	oPrn:FillRect({nLinSup+4,nColIt2,nLinInf,nColIt4-2},oBrush)
	oPrn:Say(nLinSup+40, nColIt2+10, "DESCRIÇÃO"	, oFont10N	, 100)
 	//oPrn:SayAlign(nLinSup,nColIt2,"DESCRIÇÃO" ,oFont13N,nLinInf-nLinSup, nColIt3-nColIt2,, 2, 2 )

	//oPrn:Box(nLinSup, nColIt3, nLinInf, nColIt4+2)
	//oPrn:FillRect({nLinSup+4,nColIt3+2,nLinInf,nColIt4-2},oBrush)
	//oPrn:Say(nLinSup+40, nColIt3+10, "OBSERVAÇÃO"	, oFont10N	, 100)
 	//oPrn:SayAlign(nLinSup,nColIt3,"NCM" ,oFont13N,nLinInf-nLinSup, nColIt4-nColIt3,, 2, 2 )

	oPrn:Box(nLinSup, nColIt4-2, nLinInf, nColIt5+2)
	oPrn:FillRect({nLinSup+4,nColIt4+1,nLinInf,nColIt5-2},oBrush)
	oPrn:Say(nLinSup+40, nColIt4+10, "UN"	, oFont10N	, 100)
 	//oPrn:SayAlign(nLinSup,nColIt4,"QTDE" ,oFont13N,nLinInf-nLinSup, nColIt5-nColIt4,, 2, 2 )

	oPrn:Box(nLinSup, nColIt5, nLinInf, nColIt6+1)
	oPrn:FillRect({nLinSup+4,nColIt5+1,nLinInf,nColIt6-2},oBrush)
	oPrn:Say(nLinSup+40, nColIt5+5, "QTDE"	, oFont10N	, 100)
	//oPrn:SayAlign(nLinSup,nColIt5,"UN" ,oFont13N,nLinInf-nLinSup, nColIt6-nColIt5,, 2, 2 )

	oPrn:Box(nLinSup, nColIt6-1, nLinInf, nColIt7)
	oPrn:FillRect({nLinSup+4,nColIt6+3,nLinInf,nColIt7-2},oBrush)
	oPrn:Say(nLinSup+40, nColIt6+3, "VLR UNIT"	, oFont10N	, 100)
	//oPrn:SayAlign(nLinSup,nColIt6,"VLR UNIT" ,oFont13N,nLinInf-nLinSup, nColIt7-nColIt6,, 2, 2 )

	oPrn:Box(nLinSup, nColIt7, nLinInf, nColIt8)
	oPrn:FillRect({nLinSup+4,nColIt7+1,nLinInf,nColIt8-2},oBrush)
	oPrn:Say(nLinSup+40, nColIt7+5, "DESCONTO"	, oFont10N	, 100)
	//oPrn:SayAlign(nLinSup,nColIt7,"VLR TOTAL" ,oFont13N,nLinInf-nLinSup, nColIt8-nColIt7,, 2, 2 )

	oPrn:Box(nLinSup, nColIt8, nLinInf, nColIt9)
	oPrn:FillRect({nLinSup+4,nColIt8+2,nLinInf,nColIt9-2},oBrush)
	oPrn:Say(nLinSup+40, nColIt8+5, "VLR TOTAL"	, oFont10N	, 100)
	//oPrn:SayAlign(nLinSup,nColIt8,"ICMS" ,oFont13N,nLinInf-nLinSup, nColIt9-nColIt8,, 2, 2 )

	oPrn:Box(nLinSup, nColIt9, nLinInf, nColIt10)
	oPrn:FillRect({nLinSup+4,nColIt9+2,nLinInf,nColIt10-2},oBrush)
	oPrn:Say(nLinSup+40, nColIt9+5, "ICMS"	, oFont10N	, 100)
	//oPrn:SayAlign(nLinSup,nColIt9,"IPI" ,oFont13N,nLinInf-nLinSup, nColIt10-nColIt9,, 2, 2 )

	oPrn:Box(nLinSup, nColIt10, nLinInf, nColIt11+1)
	oPrn:FillRect({nLinSup+4,nColIt10+2,nLinInf,nColIt11-2},oBrush)
	oPrn:Say(nLinSup+40, nColIt10+5, "C. CUSTO"	, oFont10N	, 100)
	//oPrn:SayAlign(nLinSup,nColIt10,"DT ENTR." ,oFont13N,nLinInf-nLinSup, nColIt9-nColIt10,, 2, 2 )

	oPrn:Box(nLinSup, nColIt11-1, nLinInf, nColIt12)
	oPrn:FillRect({nLinSup+4,nColIt11+2,nLinInf,nColIt12-5},oBrush)
	oPrn:Say(nLinSup+40, nColIt11+5, "SOLIC"	, oFont10N	, 100)
	//oPrn:SayAlign(nLinSup,nColIt11,"OBSERVAÇÃO" ,oFont13N,nLinInf-nLinSup, nColIt10-nColIt11,, 2, 2 )

	oPrn:Box(nLinSup, nColIt12-1, nLinInf, nColIt13)
	oPrn:FillRect({nLinSup+4,nColIt12+2,nLinInf,nColIt13-5},oBrush)
	oPrn:Say(nLinSup+40, nColIt12+5, "DT ENTR."	, oFont10N	, 100)
	//oPrn:SayAlign(nLinSup,nColIt11,"OBSERVAÇÃO" ,oFont13N,nLinInf-nLinSup, nColIt10-nColIt11,, 2, 2 )

Return

//============================================================
// Imprime valor totais do pedido
//============================================================
Static Function ImpRodape(nLinSup, nLinInf)

Local aTexto := {}
Local nX
Local nI

	If (nMaxLin - nLinInf) < 220
		oPrn:EndPage() //Finaliza a página

		//nPagina++

		ImpCabec(@nLinSup,@nLinInf)

		nQtdItens := 0
	EndIf

	// Box de OBSERVAÇÃO
	nLinAtu	:= nLinInf + 20
	nLinSup	:= nLinAtu
	nLinInf	+= 240
	nCol1	:= nMinCol
	nCOl2	:= 2000
	nCol3	:= (nMaxCol/4)*3
	nCol4	:= nCol3 + 500

	oPrn:Box(nLinSup, nCol1, nLinInf, nCol3-10)
	//oPrn:FillRect({nLinSup+2,nCol1+2,nLinInf-2,nCol3-2},oBrush)
	nLinSup += 10
	oPrn:Say(nLinSup+38, nCol1+20, "OBSERVAÇÃO:", ofont11N, 100)
	//oPrn:Say(nLinSup+45, nCol1+50, cObsCab, ofont11, 100)
	oPrn:SayAlign(nLinSup+58, nCol1+50, cObsCab, ofont11, nCol3-nCol1, nLinInf-nLinSup,0,0,0)

	// Box de dados TOTAIS
	nLinSup	:= nLinAtu
	oPrn:Box(nLinSup, nCol3, nLinInf, nMaxCol)
	nLinSup += 25
	oPrn:Say(nLinSup+20, nCol3+20, "IPI:", oFont11N, 100)
	cTotIPI := PADR(AllTrim(Transform(nTotIPI, "@E 999,999,999.99")), 14, " ")
	oPrn:Say(nLinSup+20, nCol4-20, cTotIPI, oFont11, 100)

	nLinSup += 40
	oPrn:Say(nLinSup+20, nCol3+20, "ICMS:", oFont11N, 100)
	cTotICM := PADR(AllTrim(Transform(nTotICM, "@E 999,999,999.99")), 14, " ")
	oPrn:Say(nLinSup+20, nCol4-20, cTotICM, oFont11, 100)

	nLinSup += 40
	oPrn:Say(nLinSup+20, nCol3+20, "FRETE:", oFont11N, 100)
	cTotFrt := PADR(AllTrim(Transform(nTotFrt, "@E 999,999,999.99")), 14, " ")//Frete
	oPrn:Say(nLinSup+20, nCol4-20, cTotFrt, oFont11, 100)

	nLinSup += 40
	oPrn:Say(nLinSup+20, nCol3+20, "DESCONTO:", oFont11N, 100)
	cDescont := PADR(AllTrim(Transform(nDesc, "@E 999,999,999.99")), 14, " ")
	oPrn:Say(nLinSup+20, nCol4-20, cDescont, oFont11, 100)

	nLinSup += 40
	oPrn:Say(nLinSup+20, nCol3+20, "TOTAL PEDIDO:", oFont11N, 100)
	cTotPed := PADR(AllTrim(Transform(nTotPed, "@E 999,999,999.99")), 14, " ")
	oPrn:Say(nLinSup+20, nCol4-20, cTotPed, oFont11, 100)

	If (nMaxLin - nLinInf) < 800
		oPrn:EndPage() //Finaliza a página

		//nPagina++

		ImpCabec(@nLinSup,@nLinInf)

		nQtdItens := 0
	End

	// Box de dados CONTRATO
		nLinSup	:= nLinInf + 20
		nLinInf	+= 80
		oPrn:Box(nLinSup, nMinCol, nLinInf, nMaxCol+2)
		oPrn:FillRect({nLinSup+4,nMinCol+3,nLinInf-1,nMaxCol-3},oBrush)
		oPrn:Say(nLinSup+49, nMinCol + 20, "CONDIÇÕES GERAIS DE FORNECIMENTO", oFont11N, 100)

		nLinSup := nLinInf
		nLinInf += 60

		aTexto := {{'1) Constar o número desta AF na Nota Fiscal.  '},;
			{'2) O material será inspecionado no recebimento estando, portanto, sujeito a rejeição com risco de devolução por conta do fornecedor'},;
			{'quando não preencher os requisitos e especificações exigidos.'},;
			{'3) Não serão efetuados pagamentos de Autorização de Fornecimento atendida parcialmente.  '},;
			{'4) Reservamo-nos o direito de cancelar esta Autorização de Fornecimento, na inobservação de quaisquer das condições estipuladas '},;
			{'5) É vedado ao fornecedor emitir sob quaisquer hipótese, faturas, duplicatas ou qualquer outro título representativo do valor'},;
			{'total ou parcial desta AF, sendo a liquidação feita através de Boleto Bancário ou Duplicata.'},;
			{'6) Não nos responsabilizamos pelo extravio ou não recebimento do boleto, desta forma se isenta de multas, juros e custas de cartório.  '},;
			{'7) É considerado o prazo de entrega, com a mercadoria dentro do nosso estabelecimento.  '},;
			{'8) Para pagamento parcelados, os valores das parcelas deverão ser iguais, salvo acordado e documentado com o departamento de compras. '},;
			{"Aprovador(es) : " +If( Len(cAprov) > 0 , Substr(cAprov,001,140) , " " )},;
			{If( Len(cAprov) > 0 , Substr(cAprov,141,140) , " " )}}

		For nI:=1 to Len(aTexto)

			If nLinInf > nMaxLin
				oPrn:Box(nLinSup, nMinCol, nLinSup, nMaxCol)
				oPrn:EndPage() //Finaliza a página
				oPrn:StartPage()
				nPagina++
				nLinSup	:= nMinLin + 10
				nLinInf	:= nLinSup + 50
				oPrn:Say(nLinSup+010, nMaxCol - 300, "PÁGINA: " + CVALTOCHAR(nPagina), oFont11N, 100)
				nLinSup += 50
				nLinInf += 50
				oPrn:Box(nLinSup, nMinCol, nLinSup, nMaxCol)
				nQtdItens := 0
			EndIf

			cMsg 	:= aTexto
			nIni	:= 1
			nTamLin := 190
			nFim	:= nTamLin
			If Len(cMsg) > nTamLin
				nQtdLin	:= Iif( Mod(Len(cMsg),nTamLin) > 0, Round(Len(cMsg)/nTamLin,0) + 1, (Len(cMsg)/nTamLin))
			Else
				nQtdLin := 1
			EndIf


			For nx := 1 To nQtdLin
				nIni := nIni + (nTamLin * (nI - 1))
				nFim := (nIni -1) + nTamLin

				cMsg := aTexto[nI,1]
				//cTemp := Substr(cMsg, nIni, nFim)
				oPrn:Box(nLinSup, nMinCol, nLinInf, nMinCol)
				oPrn:Say(nLinSup+38, nMinCol + 40, cMsg, ofont11, 100)
				oPrn:Box(nLinSup, nMaxCol, nLinInf, nMaxCol)
				nLinSup += 50
				nLinInf += 50
			Next nx
		Next nI

	   	oPrn:Box(nLinInf-48, nMinCol, nLinInf-48, nMaxCol+2)

    	//Box assinatura do Fornecedor e do Comprador
	    	nLinSup += 30
	    	nLinInf += 100
	    	oPrn:Box(nLinSup, nMinCol ,nLinInf ,nMaxCol/2)
	    	oPrn:Say(nLinSup+38, nMinCol + 40, "Diretor:", ofont14N, 100)
	    	oPrn:Line(nLinInf-30, nMinCol+100 ,nLinInf-30 ,nMaxCol/2-100)
	    	//oPrn:Box(nLinInf-30, nMinCol+20 ,nLinInf-30 ,nMaxCol/2-20)
	    	oPrn:Box(nLinSup, nMaxCol/2 ,nLinInf ,nMaxCol)
	    	oPrn:Say(nLinSup+38, nMaxCol/2 + 40, "Comprador:", ofont14N, 100)
	    	//oPrn:Box(nLinInf-30, nMinCol/2+20 ,nLinInf-30 ,nMaxCol-20)
	    	oPrn:Line(nLinInf-30, nMaxCol/2+100 ,nLinInf-30 ,nMaxCol-100)
Return

//===============================================================
// Cria a tela para preenchimento do local de entrega - Cassiano
//===============================================================

Static Function ENTREGA()

Local 	lRet := .T.
Local 	nOpca := 0

//Configuração das fontes
oFont21		:= TFont():New ("Arial",, 16,, .F.)
oFont21B	:= TFont():New ("Arial",, 16,, .T.)

cLimMin00 		:= 000 	//032
cLimMax00		:= 165
cColunMin00		:= 113
cColunMax00		:= 430

DEFINE MSDIALOG oDlg TITLE OemToAnsi(cTitulo) FROM C(cLimMin00),C(cColunMin00) TO C(cLimMax00),C(cColunMax00) PIXEL Style DS_MODALFRAME // Cria Dialog sem o botão X

	oDlg:lEscClose     := .F. //Nao permite sair ao se pressionar a tecla ESC.

	nLin 	:= 030
	nCol1	:= 010
	nCol2	:= 040
	@ C(nLin),C(nCol1) SAY OemToAnsi("Local de entrega")								SIZE C(150), C(008) OF oDlg PIXEL FONT oFont21B

	nLin += 010
	@ C(nLin),C(nCol1) SAY OemToAnsi("Local: ")									SIZE C(040), C(008) OF oDlg PIXEL
	@ C(nLin-2),C(nCol2) MSGET oLclEntreg VAR cLclEntreg When .T.							SIZE C(cColunMax00-315), C(008) OF oDlg PIXEL hasbutton

	nLin += 010
	@ C(nLin),C(nCol1) SAY OemToAnsi("End: ")										SIZE C(040), C(008) OF oDlg PIXEL
	@ C(nLin-2),C(nCol2) MSGET oEndEntreg VAR cEndEntreg  When .T. 					SIZE C(cColunMax00-315), C(008) OF oDlg PIXEL hasbutton

	nLin += 010
	@ C(nLin),C(nCol1) SAY OemToAnsi("CEP: ")										SIZE C(040), C(008) OF oDlg PIXEL
	@ C(nLin-2),C(nCol2) MSGET oCepEntreg VAR cCepEntreg When .T. 							SIZE C(cColunMax00-315), C(008) OF oDlg PIXEL

	nLin += 010
	@ C(nLin),C(nCol1) SAY OemToAnsi("Contato: ")										SIZE C(040), C(008) OF oDlg PIXEL
	@ C(nLin-2),C(nCol2) MSGET oContEntre VAR cContEntre When .T. 							SIZE C(cColunMax00-315), C(008) OF oDlg PIXEL

//ACTIVATE MSDIALOG oDlg CENTERED
ACTIVATE DIALOG oDlg ON INIT EnchoiceBar(oDlg,{||nOpca:=1,oDlg:End() },{||nOpca:=2,oDlg:End() }) CENTERED

	If nOpca == 1
		lRet := .T.
	Else
		lRet := .F.
	EndIf

Return lRet

//============================================================
// Cria a tela para validação do pedido de compras - Cassiano
//============================================================

Static Function Tela()

Local cNomFornec	:= Posicione("SA2",1,xFilial("SA2")+ SC7->(C7_FORNECE+C7_LOJA),"A2_NOME")
Local cNumPed		:= SC7->C7_NUM
Local nOpca			:= 0

Private cEmail		:= Padr(Posicione("SA2",1,xFilial("SA2")+ SC7->(C7_FORNECE+C7_LOJA),"A2_EMAIL"),200)
Private cMessage	:= Padr("Texto",1000)

//Configuração das fontes
oFont21		:= TFont():New ("Arial",, 16,, .F.)
oFont21B	:= TFont():New ("Arial",, 16,, .T.)

cLimMin00 		:= 000	//032
cLimMax00		:= 260
cColunMin00		:= 113
cColunMax00		:= 430

DEFINE MSDIALOG oDlg TITLE OemToAnsi(cTitulo) FROM C(cLimMin00),C(cColunMin00) TO C(cLimMax00),C(cColunMax00) PIXEL Style DS_MODALFRAME // Cria Dialog sem o botão X

	oDlg:lEscClose     := .F. //Nao permite sair ao se pressionar a tecla ESC.

	nLin 	:= 030
	nCol1	:= 010
	nCol2	:= 040
	@ C(nLin),C(nCol1) SAY OemToAnsi("Dados do Pedido")								SIZE C(150), C(008) OF oDlg PIXEL FONT oFont21B

	nLin += 010
	@ C(nLin),C(nCol1) SAY OemToAnsi("Num. Pedido")									SIZE C(040), C(008) OF oDlg PIXEL
	@ C(nLin-2),C(nCol2) MSGET oNumPed VAR cNumPed When .F.							SIZE C(cColunMax00-315), C(008) OF oDlg PIXEL hasbutton

	nLin += 010
	@ C(nLin),C(nCol1) SAY OemToAnsi("Nome")										SIZE C(040), C(008) OF oDlg PIXEL
	@ C(nLin-2),C(nCol2) MSGET oNomFornec VAR cNomFornec  When .F. 					SIZE C(cColunMax00-315), C(008) OF oDlg PIXEL hasbutton

	nLin += 010
	@ C(nLin),C(nCol1) SAY OemToAnsi("Email")										SIZE C(040), C(008) OF oDlg PIXEL
	@ C(nLin-2),C(nCol2) MSGET oEmail VAR cEmail When .T. 							SIZE C(cColunMax00-315), C(008) OF oDlg PIXEL

	nLin += 010
	@ C(nLin),C(nCol1) SAY OemToAnsi("Corpo do email")						SIZE C(cColunMax00-280), C(008) OF oDlg PIXEL
	nLin += 010
	@ C(nLin),C(nCol1) GET oMessage VAR cMessage OF oDlg MULTILINE					SIZE C(cColunMax00-285), C(045) COLORS 0, 16777215 HSCROLL PIXEL
	//@ C(nLin),C(nCol1) MSGET oMessage VAR cMessage When .T. 						SIZE C(cColunMax00-290), C(043) OF oDlg PIXEL

//ACTIVATE MSDIALOG oDlg CENTERED
ACTIVATE DIALOG oDlg ON INIT EnchoiceBar(oDlg,{||nOpca:=1,oDlg:End() },{||nOpca:=2,oDlg:End() }) CENTERED
	If nOpca == 1
		EnvMail()
	EndIf

Return

//============================================================
// Envia o pedido de compras  -  Cassiano
//============================================================

Static Function EnvMail()

Local	cPara 		:= Alltrim(cEmail)
Local	cAssunto	:= "Pedido de compras"
Local	cMsg		:= ""
Local	dDataAtual 	:= DtoS(DDATABASE)
Local	cNumPed		:= cValToChar(SC7->C7_NUM)
Local 	cRemetente	:= AllTrim(Posicione("SY1",2,xFilial("SY1")+ substr(cUsuario,7,15),"Y1_EMAIL"))
Local 	cSenha		:= AllTrim(Posicione("SY1",2,xFilial("SY1")+ substr(cUsuario,7,15),"Y1_XSENHA"))
Local 	cCopia		:= ""
Local	cServidorx	:= SuperGetMv("MV_RELSERV",.T.,"192.168.10.227:465",)

	dDataAtual := SubStr(dDataAtual,7,2)+"/"+SubStr(dDataAtual,5,2)+"/"+SubStr(dDataAtual,1,4)

	cMsg := cMessage
	cNomFornec := AllTrim(Posicione("SA2",1,xFilial("SA2") + SC7->(C7_FORNECE + C7_LOJA),"A2_NOME"))
	cNumPedCom := ALLTRIM(SC7->C7_NUM)

	//Copia o PDF da temp para a system
	cLocal	 := GetTempPath()+ cFileName  +".pdf"
	cDirServ := cSystem + "PedComGraf\"
	CpyT2S(cDiretorio + cFileName  +".pdf", cDirServ , .T. )

	cAnexo		:= cDirServ + cFileName  +".pdf"
	cNomAnexo := cNomFornec +"_"+ cNumPedCom

	//Função para envio de email
	//U_EnvMail(cRemetente,cSenha,cPara,cAssunto,cMsg,cAnexo,cNomAnexo,cCopia)
	U_FEnvMail(cRemetente,cSenha,cPara,cAssunto,cMsg,cAnexo)
	//ACSENDMAIL(cRemetente,cSenha,cServidorx,cRemetente,cPara,cAssunto,cMsg,cAnexo)

Return

//*************************************************************************************
//Pega uma posição (nTam) na string cString, e retorna o caractere de espaço anterior.
//*************************************************************************************
Static Function EspacoAt(cString, nTam)

Local nRetorno := 0
Local nX       := 0

/**
* Caso a posição (nTam) for maior que o tamanho da string, ou for um valor
* inválido, retorna 0.
*/
If nTam > Len(cString) .Or. nTam < 1
	nRetorno := 0
	Return nRetorno
EndIf

/**
* Procura pelo caractere de espaço anterior a posição e retorna a posição
* dele.
*/
nX := nTam
While nX > 1
	If Substr(cString, nX, 1) == " "
		nRetorno := nX
		Return nRetorno
	EndIf

	nX--
EndDo

/**
* Caso não encontre nenhum caractere de espaço, é retornado 0.
*/
nRetorno := 0

Return nRetorno