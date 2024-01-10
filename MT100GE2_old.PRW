#INCLUDE "PROTHEUS.CH"


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MT100GE2  ºAutor  ³Claudio Ferreira    º Data ³  26/06/12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ PE chamado durante a geração da SE2.                       º±±
±±º          ³ Utilizado para complementar o titulo a pagar              .º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ TBC-GO                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

USER FUNCTION MT100GE2
	Local   nPosItem := aScan(aHEADER,{|x| Trim(x[2])=="D1_CC"})
	local 	codNat

	if !empty(acols[1,nPosItem])
		RecLock("SE2", .F. )
		SE2->E2_CCUSTO   := acols[1,nPosItem] //Grava o Centro de Custo informado na 1 linha
		MsUnLock()
	endif
	if SF1->(FieldPos("F1_MENNOTA"))> 0
		if !empty(SF1->F1_MENNOTA)
			RecLock("SE2", .F. )
			SE2->E2_HIST    := SF1->F1_MENNOTA //Grava o historico 
			MsUnLock()
		endif
	endif 

	// verifico se o valor do título é inferior ou igual ao informado no parametro MV_XVLTIT
	if SE2->E2_VALOR <= SUPERGETMV("MV_XVLTIT", .F., 0)
		If RecLock('SE2',.F.)
			SE2->E2_DATALIB := Date()
			SE2->(MsUnlock())
		endif
	endIf 

	RECLOCK("SE2", .F.)

	codNat := SE2->E2_NATUREZ

	MSUNLOCK()                  

	if !empty(codNat)
		RecLock("SE2", .F. )
		SE2->E2_PORTADO	:= POSICIONE("SED", 1, xFilial("SED") + codNat, "ED_XBANCO")
		SE2->E2_XAGENCI	:= POSICIONE("SED", 1, xFilial("SED") + codNat, "ED_XAGENCI")
		SE2->E2_XNUMCON	:= POSICIONE("SED", 1, xFilial("SED") + codNat, "ED_XCONTA")  
		MsUnLock()
	endif

Return  
