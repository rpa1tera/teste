#Include 'Protheus.ch'

Static nFlag := 0
Static chistorico := ""

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณMT100GE2  บAutor  ณClaudio Ferreira    บ Data ณ  26/06/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ PE chamado durante a gera็ใo da SE2.                       บฑฑ
ฑฑบ          ณ Utilizado para complementar o titulo a pagar              .บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ TBC-GO                                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function MT100GE2()
	Local nPosCc		:= aScan(aHEADER,{|x| Trim(x[2])=="D1_CC"})
	Local cCodNat		:= ""
	Local nOpc 			:= PARAMIXB[2] // 1=inclusใo de tํtulos; 2=exclusใo de tํtulos;
	Local nVlrTit		:= SuperGetMv("MV_XVLTIT", .F., 0)

	if nOpc <> 0 //Se for exclusใo ou inclusใo;
		//U_FAPRPED() 
	endIf

	if nOpc == 1 // Se for inclusใo

		if !empty(acols[1,nPosCc]) // Se o CC for informado;
			if	RecLock("SE2", .F. )
				SE2->E2_CCUSTO   := acols[1,nPosCc] //Grava o Centro de Custo informado na 1 linha
				SE2->(MsUnLock())
			endif
		endif

		if SF1->(FieldPos("F1_MENNOTA"))> 0 //Verifica se o campo existe;
			if !empty(SF1->F1_MENNOTA)
				if RecLock("SE2", .F. )
					SE2->E2_HIST    := SF1->F1_MENNOTA //Grava o Historico 
					SE2->(MsUnLock())
				endif
			else
				if nFlag == 0 //Primeira Execu็ใo;
					cHistorico := fHistSE2() //Obt๊m o hist๓rico;
					nFlag := 1
				endif
				if 	!Empty(cHistorico) 
					RecLock("SE2", .F. )
					SE2->E2_HIST    := cHistorico //Grava o Historico na tela
					MsUnLock()
				endif
			endif 
		endif

		// verifico se o valor do tํtulo ้ inferior ou igual ao informado no parametro MV_XVLTIT
		if SE2->E2_VALOR <= nVlrTit
			If RecLock('SE2',.F.)
				SE2->E2_DATALIB := Date()
				SE2->(MsUnlock())
			endif
		endIf 

		cCodNat := SE2->E2_NATUREZ    

		if !empty(cCodNat)
			if RecLock("SE2", .F. )
				SE2->E2_PORTADO	:= POSICIONE("SED", 1, xFilial("SED") + cCodNat, "ED_XBANCO")
				SE2->E2_XAGENCI	:= POSICIONE("SED", 1, xFilial("SED") + cCodNat, "ED_XAGENCI")
				SE2->E2_XNUMCON	:= POSICIONE("SED", 1, xFilial("SED") + cCodNat, "ED_XCONTA")  
				SE2->(MsUnLock())
			endif
		endif
	endif

Return

//--------------------------------------------------------------
/*/{Protheus.doc} fHistSE2
Description : Abre a Tela para digitacao do cHistorico do Titulo
na entrada de nota fiscal.
           
@param xParam Parameter Description
@return xRet Return Description
@author  -
@since 21/10/2015
/*/
//--------------------------------------------------------------
Static Function fHistSE2()
Local oGet1		:= NIL
Local oGroup1	:= NIL
Local oSay1		:= NIL                    
Local oSButton1 := NIL         
Local cHistSE2	:= Space(TamSX3("E2_HIST")[1]) 
Local cTitulo 	:= "Historico do Documento de Entrada"

Static oDlg

  DEFINE MSDIALOG oDlg TITLE cTitulo FROM 000, 000  TO 150, 500 COLORS 0, 16777215 PIXEL
	
	oDlg:lEscClose     := .F. // Impede o fechamento da tela;
	
    @ 003, 003 GROUP oGroup1 TO 071, 247 PROMPT cTitulo OF oDlg COLOR 0, 16777215 PIXEL
    @ 031, 020 MSGET oGet1 VAR cHistSE2 SIZE 210, 011 OF oDlg COLORS 0, 16777215 PIXEL
    DEFINE SBUTTON oSButton1 FROM 049, 108 TYPE 01 OF oDlg ENABLE ACTION If(fValida(cHistSE2),cHistSE2,.F.)
    @ 019, 068 SAY oSay1 PROMPT "Digite aqui o Hist๓rico para o Tํtulo Financeiro" SIZE 122, 007 OF oDlg COLORS 0, 16777215 PIXEL

  ACTIVATE MSDIALOG oDlg CENTERED

Return cHistSE2                                                

//--------------------------------------------------------------
/*/{Protheus.doc} fValida
Description : Valida se o cHistorico foi preenchido.

@param xParam Parameter Description
@return xRet Return Description
@author  -
@since 21/10/2015
/*/
//--------------------------------------------------------------
Static Function fValida(cRet)
Local lRet := .T.

Default cRet := ""

//Verifica se o cHistorico foi digitado
If Empty(cRet)
	MsgAlert("Hist๓rico do Financeiro nใo Digitado, favor Digitar!")
	Return lRet := .F.
EndIf        

oDlg:End()

Return lRet
