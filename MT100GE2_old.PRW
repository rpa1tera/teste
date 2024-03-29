#INCLUDE "PROTHEUS.CH"


/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �MT100GE2  �Autor  �Claudio Ferreira    � Data �  26/06/12   ���
�������������������������������������������������������������������������͹��
���Desc.     � PE chamado durante a gera��o da SE2.                       ���
���          � Utilizado para complementar o titulo a pagar              .���
�������������������������������������������������������������������������͹��
���Uso       � TBC-GO                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
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

	// verifico se o valor do t�tulo � inferior ou igual ao informado no parametro MV_XVLTIT
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
