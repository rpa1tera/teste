#include 'Protheus.ch'
#include 'TOPConn.ch'
#include 'Rwmake.ch'
#include "TbiConn.ch"

/*/{Protheus.doc} MT103FIM
//P.E. após a gravação do Documento de Entrada
@author TOTVS
@since 14/12/2012
@version 1.0
@history 14/12/2012, TOTVS, Construido inicialmente para levar codigo de barra para e2_codbar
@history 16/05/2019, Luciano.Camargo [TOTVS], Ajustado para atualizar a tabela SZ1 - Numeros de Serie 
@type function
/*/
User Function MT103FIM()

	//Local nOpcao := PARAMIXB[1]   	// Opção Escolhida pelo usuario no aRotina 
	//Local nConfirma := PARAMIXB[2]  // Se o usuario confirmou a operação de gravação da NFECODIGO DE APLICAÇÃO DO USUARIO

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

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verificar se esta sendo executa sem interface                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	if IsBlind() .or. Type("cEmpAnt") == "U"
		RpcSetType(3) 		
		PREPARE ENVIRONMENT EMPRESA "02" FILIAL "0202" MODULO "FIN"
	endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verificar se estavindo da inclusão ou da Pré-Nota					³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

	DEFINE MSDIALOG oDlg TITLE " Leitura do Código de Barras " FROM 000, 000  TO 405, 800 COLORS 0, 16777215 PIXEL

	@ 148, 004 GROUP oGroup1 TO 185, 392 PROMPT " Digite ou Leia o Código de Barras Aqui " OF oDlg COLOR 0, 16777215 PIXEL

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
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Preencher a SE2 com os dados da linha digitavel                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Preencher o Vetor com as Informações dos Titulos                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cTitulo := SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_SERIE + SF1->F1_DOC
	SE2->( DbSetOrder(6), DbSeek( xFilial("SE2") + cTitulo ) )

	while !SE2->( Eof() ) .and. (SF1->F1_FORNECE + SF1->F1_LOJA + SF1->F1_SERIE + SF1->F1_DOC) == (SE2->E2_FORNECE + SE2->E2_LOJA + SE2->E2_PREFIXO + SE2->E2_NUM)

		aadd(aColsEx,{SE2->E2_NUM, SE2->E2_PREFIXO, SE2->E2_PARCELA, SE2->E2_CODBAR, .F.} )
		SE2->( DbSkip() )

	enddo

	oMSViewCodBar := MsNewGetDados():New( 020, 004, 142, 392, , "", "", "", aAlterFields,, 999, "", "", "", oDlg, aHeaderEx, aColsEx)
Return



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CODBAR   ºAutor  ³Marciane Gennari    º Data ³  31/03/06   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ PROGRAMA PARA TRATAMENTO DO CAMPO E2_CODBAR PARA UTILIZACAOº±±
±±º          ³ DO PAGFOR                                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP8                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±± Alteracao: Marciane 25/05/06                                           ±±±
±±            Alguns boletos nao vem com o zeros preenchidos a esquerda   ±±±
±±            no campo de valor e gerava inconsistencia no codigo de      ±±±
±±            barras. Alterado programa para preencher com zeros a        ±±±
±±            esquerda somente nas posicoes do codigo de barras.          ±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

///--------------------------------------------------------------------------\
//| Função: CODBAR				Autor: Flávio Novaes		Data: 19/10/2003 |
//|--------------------------------------------------------------------------|
//| Essa Função foi desenvolvida com base no Manual do Bco. Itaú e no RDMAKE:|
//| CODBARVL - Autor: Vicente Sementilli - Data: 26/02/1997.                 |
//|--------------------------------------------------------------------------|
//| Descrição: Função para Validação de Código de Barras (CB) e Representação|
//|            Numérica do Código de Barras - Linha Digitável (LD).	         |
//|                                                                          |
//|            A LD de Bloquetos possui três Digitos Verificadores (DV) que  |
//|				são consistidos pelo Módulo 10, além do Dígito Verificador   |
//|				Geral (DVG) que é consistido pelo Módulo 11. Essa LD têm 47  |
//|            Dígitos.                                                      |
//|                                                                          |
//|            A LD de Títulos de Concessinárias do Serviço Público e IPTU   |
//|				possui quatro Digitos Verificadores (DV) que são consistidos |
//|            pelo Módulo 10, além do Digito Verificador Geral (DVG) que    |
//|            também é consistido pelo Módulo 10. Essa LD têm 48 Dígitos.   |
//|                                                                          |
//|            O CB de Bloquetos e de Títulos de Concessionárias do Serviço  |
//|            Público e IPTU possui apenas o Dígito Verificador Geral (DVG) |
//|            sendo que a única diferença é que o CB de Bloquetos é         |
//|            consistido pelo Módulo 11 enquanto que o CB de Títulos de     |
//|            Concessionárias é consistido pelo Módulo 10. Todos os CB´s    |
//|            têm 44 Dígitos.                                               |
//|                                                                          |
//|            Para utilização dessa Função, deve-se criar o campo E2_CODBAR,|
//|            Tipo Caracter, Tamanho 48 e colocar na Validação do Usuário:  |
//|            EXECBLOCK("CODBAR",.T.).                                      |
//|                                                                          |
//|            Utilize também o gatilho com a Função CONVLD() para converter |
//|            a LD em CB.													 |
//\--------------------------------------------------------------------------/

User Function ValCodBar()

	SetPRVT("cStr,lRet,cTipo,nConta,nMult,nVal,nDV,cCampo,i,nMod,nDVCalc,lFgts,cFgts")


	// Retorna .T. se o Campo estiver em Branco.
	IF VALTYPE(M->E2_CODBAR) == NIL .OR. EMPTY(M->E2_CODBAR)
		RETURN(.T.)
	ENDIF

	cStr := Alltrim(M->E2_CODBAR)

	// Se o Tamanho do String for 45 ou 46 está errado! Retornará .F.
	lRet := IF(LEN(cStr)==45 .OR. LEN(cStr)==46,.F.,.T.)

	// Se o Tamanho do String for menor que 44, completa com zeros até 47 dígitos. Isso é
	// necessário para Bloquetos que NÂO têm o vencimento e/ou o valor informados na LD.
	// Completa as 14 posicoes do valor do documento.
	//--- Marciane 25.05.06 - Completar com zeros a esquerda o valor do codigo de barras se não tiver preenchido
	//cStr := IF(LEN(cStr)<44,cStr+REPL("0",47-LEN(cStr)),cStr)
	cStr := IF(LEN(cStr)<44,subs(cStr,1,33)+Strzero(val(Subs(cStr,34,14)),14),cStr)
	//--- fim Marciane 25.05.06

	// Verifica se a LD é de (B)loquetos ou (C)oncessionárias/IPTU. Se for CB retorna (I)ndefinido.
	cTipo := IF(LEN(cStr)==47,"B",IF(LEN(cStr)==48,"C","I"))

	//--- Marciane 13.03.07 - Identifica se é FGTS
	lFgts := .F.
	If cTipo == "C"

		cFgts := Substr(cStr,17,4)  //--- Posicao 17 - 4 caracteres igual a 0179 ou 0180 ou 0181 significa FGTS
		If cFgts == "0179" .or. cFgts == "0180" .or. cFgts == "0181"
			lFgts := .T.
		EndIf

	EndIf

	// Verifica se todos os dígitos são numérios.
	FOR i := LEN(cStr) TO 1 STEP -1
		lRet := IF(SUBSTR(cStr,i,1) $ "0123456789",lRet,.F.)
	NEXT

	If !lRet
		HELP(" ",1,"ONLYNUM")
		Return(.F.)
	EndIf

	IF LEN(cStr) == 47 .AND. lRet

		// Consiste os três DV´s de Bloquetos pelo Módulo 10.
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
			// Se o DV Calculado for 10 é assumido 0 (Zero).
			nDVCalc := IF(nDVCalc==10,0,nDVCalc)
			lRet    := IF(lRet,(nDVCalc==nDV),.F.)
			nConta  := nConta + 1
		ENDDO
		// Se os DV´s foram consistidos com sucesso (lRet=.T.), converte o número para CB para consistir o DVG.
		cStr := IF(lRet,SUBSTR(cStr,1,4)+SUBSTR(cStr,33,15)+SUBSTR(cStr,5,5)+SUBSTR(cStr,11,10)+SUBSTR(cStr,22,10),cStr)

	ENDIF

	IF LEN(cStr) == 48 .AND. lRet

		// Consiste os quatro DV´s de Títulos de Concessionárias de Serviço Público e IPTU pelo Módulo 10.
		nConta  := 1

		WHILE nConta <= 4

			If lFgts .OR. (SUBSTR(cStr,3,1) $ "8/9") //--- Valida pelo Modulo 11  para FGTS

				// Consiste o DV do FGTS pelo Módulo 11.
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
				// Se o DV Calculado for 10 é assumido 0 (Zero).
				nDVCalc := IF(nDVCalc==10,0,nDVCalc)

			EndIf

			lRet    := IF(nDVCalc==nDV,.T.,.F.)

			nConta  := nConta + 1

		ENDDO

		// Se os DV´s foram consistidos com sucesso (lRet=.T.), converte o número para CB para consistir o DVG.
		//cStr := IF(lRet,SUBSTR(cStr,1,11)+SUBSTR(cStr,13,11)+SUBSTR(cStr,25,11)+SUBSTR(cStr,37,11),cStr)
		cStr := IF(lRet,SUBSTR(cStr,1,11)+SUBSTR(cStr,13,11)+SUBSTR(cStr,25,11)+SUBSTR(cStr,37,11),cStr)

	ENDIF

	IF LEN(cStr) == 44 .and. lRet

		IF cTipo == "B"

			// Consiste o DVG do CB de Bloquetos pelo Módulo 11.
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

			// Se o DV Calculado for 0,10 ou 11 é assumido 1 (Um).
			nDVCalc := IF(nDVCalc==0 .OR. nDVCalc==10 .OR. nDVCalc==11,1,nDVCalc)
			lRet    := IF(lRet,(nDVCalc==nDV),.F.)

			// Se o Tipo é (I)ndefinido E o DVG NÂO foi consistido com sucesso (lRet=.F.), tentará
			// consistir como CB de Título de Concessionárias/IPTU no IF abaixo.

		ENDIF
		IF cTipo == "C" //.OR. (cTipo == "I" .AND. !lRet)

			// Consiste o DVG do CB de Títulos de Concessionárias pelo Módulo 10.
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
				// Se o DV Calculado for 10 é assumido 0 (Zero).
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

		MsgAlert('O código de barras está inválido. Informe novamente.')

	ENDIF
Return(lRet)
