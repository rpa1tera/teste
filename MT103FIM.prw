#include 'Protheus.ch'
#include 'TOPConn.ch'
#include 'Rwmake.ch'
#include "TbiConn.ch"

/*/{Protheus.doc} MT103FIM
//P.E. ap�s a grava��o do Documento de Entrada
@author TOTVS
@since 14/12/2012
@version 1.0
@history 14/12/2012, TOTVS, Construido inicialmente para levar codigo de barra para e2_codbar
@history 16/05/2019, Luciano.Camargo [TOTVS], Ajustado para atualizar a tabela SZ1 - Numeros de Serie 
@type function
/*/
User Function MT103FIM()

	//Local nOpcao := PARAMIXB[1]   	// Op��o Escolhida pelo usuario no aRotina 
	//Local nConfirma := PARAMIXB[2]  // Se o usuario confirmou a opera��o de grava��o da NFECODIGO DE APLICA��O DO USUARIO

	Local oFCodBar := TFont():New("Times New Roman",,022,,.T.,,,,,.F.,.F.)
	Local oGetCBar
	Local oGetForn
	Local cGetCBar := ""
	Local cGetForn := ""
	Local cGetNF := ""
	Local oGetNF
	Local oGroup1
	Local oSay1
	Local oSay2
	Local oSBSalvar
	Local oSButton1
	
	Private cTitulo := SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_SERIE + SF1->F1_DOC
	Private E2_CODBAR := ""

	Static oDlg

	//���������������������������������������������������������������������Ŀ
	//� Verificar se esta sendo executa sem interface                       �
	//�����������������������������������������������������������������������
	if IsBlind() .or. Type("cEmpAnt") == "U"
		RpcSetType(3) 		
		PREPARE ENVIRONMENT EMPRESA "02" FILIAL "0202" MODULO "FIN"
	endif

	//���������������������������������������������������������������������Ŀ
	//� Verificar se estavindo da inclus�o ou da Pr�-Nota					�
	//�����������������������������������������������������������������������
	if !(Type("PARAMIXB")  == "A" .and. (PARAMIXB[1] == 3 .or. PARAMIXB[1] == 4 ) .and. PARAMIXB[2] == 1)
		Return
	endif

	//*************************************************************
	
	//*************************************************************
	if !SuperGetMV("MV_XDECB", .F., .F.)	// Se o parametro Documento de Entrada Com Leitor de Codigo de Barras estiver ativo 
		Return 
	endif

	M->E2_CODBAR /*cGetCBar*/ := Space( len( SE2->E2_CODBAR ) )
	cGetForn := SF1->F1_FORNECE + '/' + SF1->F1_LOJA + '-' +SA2->A2_NOME
	cGetNF := SF1->F1_DOC + '/' + SF1->F1_SERIE

	DEFINE MSDIALOG oDlg TITLE " Leitura do C�digo de Barras " FROM 000, 000  TO 405, 800 COLORS 0, 16777215 PIXEL

	@ 148, 004 GROUP oGroup1 TO 185, 392 PROMPT " Digite ou Leia o C�digo de Barras Aqui " OF oDlg COLOR 0, 16777215 PIXEL

	fMSViewCodBar()

	@ 007, 008 SAY oSay1 PROMPT "FORNECEDOR:" SIZE 041, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 007, 245 SAY oSay2 PROMPT "NOTA:" SIZE 019, 007 OF oDlg COLORS 0, 16777215 PIXEL

	@ 006, 047 MSGET oGetForn VAR cGetForn SIZE 191, 010 OF oDlg PICTURE "@!" COLORS 0, 16777215 READONLY PIXEL
	@ 006, 265 MSGET oGetNF   VAR cGetNF   SIZE 042, 010 OF oDlg PICTURE "@!" COLORS 0, 16777215 READONLY PIXEL
	@ 160, 009 MSGET oGetCBar VAR M->E2_CODBAR /*cGetCBar*/ SIZE 330, 015 OF oDlg VALID u_ValCodBar() COLORS 0, 16777215 FONT oFCodBar PIXEL

	DEFINE SBUTTON oSBSalvar FROM 161, 355 TYPE 13 OF oDlg ONSTOP "Salvar Leitura" ENABLE ACTION GrvCBar(@M->E2_CODBAR /*@M->cGetCBar*/,oGetCBar)
	DEFINE SBUTTON oSButton1 FROM 187, 355 TYPE 01 OF oDlg ONSTOP "Fechar Janela e Gravar as Leituras" ENABLE ACTION {|| GrvSE2(),oDlg:End() }

	ACTIVATE MSDIALOG oDlg CENTERED
Return


Static Function GrvSE2()
	//���������������������������������������������������������������������Ŀ
	//� Preencher a SE2 com os dados da linha digitavel                     �
	//�����������������������������������������������������������������������
	Local cTitulo := SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_SERIE + SF1->F1_DOC
	Local ix := 0

	for ix:=1 to len(oMSViewCodBar:aCols)

		SE2->( DbSetOrder(6), DbSeek( xFilial("SE2") + cTitulo + oMSViewCodBar:aCols[ix][03] ) )

		if !Empty(oMSViewCodBar:aCols[ix][04]) .and. SE2->( Found() )
			RecLock("SE2")
			SE2->E2_CODBAR := oMSViewCodBar:aCols[ix][04]
			SE2->( DbUnLock() )
			SE2->( DbCommit() )

		endif

	next ix
Return



Static Function GrvCBar(cGetCBar,oGetCBar)
	if Empty(cGetCBar)
		Return 
	endif

	oMSViewCodBar:aCols[oMSViewCodBar:oBrowse:nAT][04] := cGetCBar
	oMSViewCodBar:oBrowse:Refresh()
	cGetCBar := Space( Len(SE2->E2_CODBAR) )
Return




//------------------------------------------------
Static Function fMSViewCodBar()
	//------------------------------------------------ 
	Local nX
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aFieldFill := {}
	Local aFields := {"E2_NUM","E2_PREFIXO","E2_PARCELA","E2_CODBAR"}
	Local aAlterFields := {}

	Static oMSViewCodBar

	// Define field properties
	SX3->( DbSetOrder(2) )
	For nX := 1 to Len(aFields)

		If SX3->( DbSeek(aFields[nX]) )
			Aadd(aHeaderEx, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
			SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})
		Endif

	Next nX


	//���������������������������������������������������������������������Ŀ
	//� Preencher o Vetor com as Informa��es dos Titulos                    �
	//�����������������������������������������������������������������������
	cTitulo := SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_SERIE + SF1->F1_DOC
	SE2->( DbSetOrder(6), DbSeek( xFilial("SE2") + cTitulo ) )

	while !SE2->( Eof() ) .and. (SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_SERIE + SF1->F1_DOC) == (SE2->E2_FORNECE + SE2->E2_LOJA + SE2->E2_PREFIXO + SE2->E2_NUM)

		aadd(aColsEx,{SE2->E2_NUM, SE2->E2_PREFIXO, SE2->E2_PARCELA, SE2->E2_CODBAR, .F.} )
		SE2->( DbSkip() )

	enddo

	oMSViewCodBar := MsNewGetDados():New( 020, 004, 142, 392, , "", "", "", aAlterFields,, 999, "", "", "", oDlg, aHeaderEx, aColsEx)
Return



/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �CODBAR   �Autor  �Marciane Gennari    � Data �  31/03/06   ���
�������������������������������������������������������������������������͹��
���Desc.     � PROGRAMA PARA TRATAMENTO DO CAMPO E2_CODBAR PARA UTILIZACAO���
���          � DO PAGFOR                                                  ���
�������������������������������������������������������������������������͹��
���Uso       � AP8                                                        ���
�������������������������������������������������������������������������ͼ��
�� Alteracao: Marciane 25/05/06                                           ���
��            Alguns boletos nao vem com o zeros preenchidos a esquerda   ���
��            no campo de valor e gerava inconsistencia no codigo de      ���
��            barras. Alterado programa para preencher com zeros a        ���
��            esquerda somente nas posicoes do codigo de barras.          ���
�����������������������������������������������������������������������������
*/

///--------------------------------------------------------------------------\
//| Fun��o: CODBAR				Autor: Fl�vio Novaes		Data: 19/10/2003 |
//|--------------------------------------------------------------------------|
//| Essa Fun��o foi desenvolvida com base no Manual do Bco. Ita� e no RDMAKE:|
//| CODBARVL - Autor: Vicente Sementilli - Data: 26/02/1997.                 |
//|--------------------------------------------------------------------------|
//| Descri��o: Fun��o para Valida��o de C�digo de Barras (CB) e Representa��o|
//|            Num�rica do C�digo de Barras - Linha Digit�vel (LD).	         |
//|                                                                          |
//|            A LD de Bloquetos possui tr�s Digitos Verificadores (DV) que  |
//|				s�o consistidos pelo M�dulo 10, al�m do D�gito Verificador   |
//|				Geral (DVG) que � consistido pelo M�dulo 11. Essa LD t�m 47  |
//|            D�gitos.                                                      |
//|                                                                          |
//|            A LD de T�tulos de Concessin�rias do Servi�o P�blico e IPTU   |
//|				possui quatro Digitos Verificadores (DV) que s�o consistidos |
//|            pelo M�dulo 10, al�m do Digito Verificador Geral (DVG) que    |
//|            tamb�m � consistido pelo M�dulo 10. Essa LD t�m 48 D�gitos.   |
//|                                                                          |
//|            O CB de Bloquetos e de T�tulos de Concession�rias do Servi�o  |
//|            P�blico e IPTU possui apenas o D�gito Verificador Geral (DVG) |
//|            sendo que a �nica diferen�a � que o CB de Bloquetos �         |
//|            consistido pelo M�dulo 11 enquanto que o CB de T�tulos de     |
//|            Concession�rias � consistido pelo M�dulo 10. Todos os CB�s    |
//|            t�m 44 D�gitos.                                               |
//|                                                                          |
//|            Para utiliza��o dessa Fun��o, deve-se criar o campo E2_CODBAR,|
//|            Tipo Caracter, Tamanho 48 e colocar na Valida��o do Usu�rio:  |
//|            EXECBLOCK("CODBAR",.T.).                                      |
//|                                                                          |
//|            Utilize tamb�m o gatilho com a Fun��o CONVLD() para converter |
//|            a LD em CB.													 |
//\--------------------------------------------------------------------------/

User Function ValCodBar()

	SetPRVT("cStr,lRet,cTipo,nConta,nMult,nVal,nDV,cCampo,i,nMod,nDVCalc,lFgts,cFgts")


	// Retorna .T. se o Campo estiver em Branco.
	IF VALTYPE(M->E2_CODBAR) == NIL .OR. EMPTY(M->E2_CODBAR)
		RETURN(.T.)
	ENDIF

	cStr := Alltrim(M->E2_CODBAR)

	// Se o Tamanho do String for 45 ou 46 est� errado! Retornar� .F.
	lRet := IF(LEN(cStr)==45 .OR. LEN(cStr)==46,.F.,.T.)

	// Se o Tamanho do String for menor que 44, completa com zeros at� 47 d�gitos. Isso �
	// necess�rio para Bloquetos que N�O t�m o vencimento e/ou o valor informados na LD.
	// Completa as 14 posicoes do valor do documento.
	//--- Marciane 25.05.06 - Completar com zeros a esquerda o valor do codigo de barras se n�o tiver preenchido
	//cStr := IF(LEN(cStr)<44,cStr+REPL("0",47-LEN(cStr)),cStr)
	cStr := IF(LEN(cStr)<44,subs(cStr,1,33)+Strzero(val(Subs(cStr,34,14)),14),cStr)
	//--- fim Marciane 25.05.06

	// Verifica se a LD � de (B)loquetos ou (C)oncession�rias/IPTU. Se for CB retorna (I)ndefinido.
	cTipo := IF(LEN(cStr)==47,"B",IF(LEN(cStr)==48,"C","I"))

	//--- Marciane 13.03.07 - Identifica se � FGTS
	lFgts := .F.
	If cTipo == "C"

		cFgts := Substr(cStr,17,4)  //--- Posicao 17 - 4 caracteres igual a 0179 ou 0180 ou 0181 significa FGTS
		If cFgts == "0179" .or. cFgts == "0180" .or. cFgts == "0181"
			lFgts := .T.
		EndIf

	EndIf

	// Verifica se todos os d�gitos s�o num�rios.
	FOR i := LEN(cStr) TO 1 STEP -1
		lRet := IF(SUBSTR(cStr,i,1) $ "0123456789",lRet,.F.)
	NEXT

	If !lRet
		HELP(" ",1,"ONLYNUM")
		Return(.F.)
	EndIf

	IF LEN(cStr) == 47 .AND. lRet

		// Consiste os tr�s DV�s de Bloquetos pelo M�dulo 10.
		nConta  := 1
		WHILE nConta <= 3
			nMult  := 2
			nVal   := 0
			nDV    := VAL(SUBSTR(cStr,IF(nConta==1,10,IF(nConta==2,21,32)),1))
			cCampo := SUBSTR(cStr,IF(nConta==1,1,IF(nConta==2,11,22)),IF(nConta==1,9,10))
			FOR i := LEN(cCampo) TO 1 STEP -1
				nMod  := VAL(SUBSTR(cCampo,i,1)) * nMult
				nVal  := nVal + IF(nMod>9,1,0) + (nMod-IF(nMod>9,10,0))
				nMult := IF(nMult==2,1,2)
			NEXT
			nDVCalc := 10-MOD(nVal,10)
			// Se o DV Calculado for 10 � assumido 0 (Zero).
			nDVCalc := IF(nDVCalc==10,0,nDVCalc)
			lRet    := IF(lRet,(nDVCalc==nDV),.F.)
			nConta  := nConta + 1
		ENDDO
		// Se os DV�s foram consistidos com sucesso (lRet=.T.), converte o n�mero para CB para consistir o DVG.
		cStr := IF(lRet,SUBSTR(cStr,1,4)+SUBSTR(cStr,33,15)+SUBSTR(cStr,5,5)+SUBSTR(cStr,11,10)+SUBSTR(cStr,22,10),cStr)

	ENDIF

	IF LEN(cStr) == 48 .AND. lRet

		// Consiste os quatro DV�s de T�tulos de Concession�rias de Servi�o P�blico e IPTU pelo M�dulo 10.
		nConta  := 1

		WHILE nConta <= 4

			If lFgts .OR. (SUBSTR(cStr,3,1) $ "8/9") //--- Valida pelo Modulo 11  para FGTS

				// Consiste o DV do FGTS pelo M�dulo 11.
				nDV    := VAL(SUBSTR(cStr,IF(nConta==1,12,IF(nConta==2,24,IF(nConta==3,36,48))),1))
				cCampo := SUBSTR(cStr,IF(nConta==1,1,IF(nConta==2,13,IF(nConta==3,25,37))),11)
				nDVCalc := VAL(modulo11(cCampo))

			Else

				nMult  := 2
				nVal   := 0
				nDV    := VAL(SUBSTR(cStr,IF(nConta==1,12,IF(nConta==2,24,IF(nConta==3,36,48))),1))
				cCampo := SUBSTR(cStr,IF(nConta==1,1,IF(nConta==2,13,IF(nConta==3,25,37))),11)
				FOR i := 11 TO 1 STEP -1
					nMod  := VAL(SUBSTR(cCampo,i,1)) * nMult
					nVal  := nVal + IF(nMod>9,1,0) + (nMod-IF(nMod>9,10,0))
					nMult := IF(nMult==2,1,2)
				NEXT
				nDVCalc := 10-MOD(nVal,10)
				// Se o DV Calculado for 10 � assumido 0 (Zero).
				nDVCalc := IF(nDVCalc==10,0,nDVCalc)

			EndIf

			lRet    := IF(nDVCalc==nDV,.T.,.F.)

			nConta  := nConta + 1

		ENDDO

		// Se os DV�s foram consistidos com sucesso (lRet=.T.), converte o n�mero para CB para consistir o DVG.
		//cStr := IF(lRet,SUBSTR(cStr,1,11)+SUBSTR(cStr,13,11)+SUBSTR(cStr,25,11)+SUBSTR(cStr,37,11),cStr)
		cStr := IF(lRet,SUBSTR(cStr,1,11)+SUBSTR(cStr,13,11)+SUBSTR(cStr,25,11)+SUBSTR(cStr,37,11),cStr)

	ENDIF

	IF LEN(cStr) == 44 .and. lRet

		IF cTipo == "B"

			// Consiste o DVG do CB de Bloquetos pelo M�dulo 11.
			nMult  := 2
			nVal   := 0
			nDV    := VAL(SUBSTR(cStr,5,1))
			cCampo := SUBSTR(cStr,1,4)+SUBSTR(cStr,6,39)

			FOR i := 43 TO 1 STEP -1
				nMod  := VAL(SUBSTR(cCampo,i,1)) * nMult
				nVal  := nVal + nMod
				nMult := IF(nMult==9,2,nMult+1)
			NEXT
			nDVCalc := 11-MOD(nVal,11)

			// Se o DV Calculado for 0,10 ou 11 � assumido 1 (Um).
			nDVCalc := IF(nDVCalc==0 .OR. nDVCalc==10 .OR. nDVCalc==11,1,nDVCalc)
			lRet    := IF(lRet,(nDVCalc==nDV),.F.)

			// Se o Tipo � (I)ndefinido E o DVG N�O foi consistido com sucesso (lRet=.F.), tentar�
			// consistir como CB de T�tulo de Concession�rias/IPTU no IF abaixo.

		ENDIF
		IF cTipo == "C" //.OR. (cTipo == "I" .AND. !lRet)

			// Consiste o DVG do CB de T�tulos de Concession�rias pelo M�dulo 10.
			IF SUBSTR(cStr,3,1) $ "6/7"

				lRet   := .T.
				nMult  := 2
				nVal   := 0
				nDV    := VAL(SUBSTR(cStr,4,1))
				cCampo := SUBSTR(cStr,1,3)+SUBSTR(cStr,5,40)

				FOR i := 43 TO 1 STEP -1
					nMod  := VAL(SUBSTR(cCampo,i,1)) * nMult
					nVal  := nVal + IF(nMod>9,1,0) + (nMod-IF(nMod>9,10,0))
					nMult := IF(nMult==2,1,2)
				NEXT

				nDVCalc := 10-MOD(nVal,10)
				// Se o DV Calculado for 10 � assumido 0 (Zero).
				nDVCalc := IF(nDVCalc==10,0,nDVCalc)
				lRet    := IF(lRet,(nDVCalc==nDV),.F.)

			ELSEIF SUBSTR(cStr,3,1) $ "8/9"
				lRet   := .T.
				nDV    := VAL(SUBSTR(cStr,4,1))
				cCampo := SUBSTR(cStr,1,3)+SUBSTR(cStr,5,40)
				nDVCalc := Val(modulo11(cCampo))
				lRet    := IF(nDVCalc==nDV,.T.,.F.)
			ENDIF

		ENDIF

	ENDIF

	IF !lRet

		MsgAlert('O c�digo de barras est� inv�lido. Informe novamente.')

	ENDIF
Return(lRet)
