#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �ANEXSE1   � Autor � NELSON HENRIQUE    � Data �  29/01/07   ���
�������������������������������������������������������������������������͹��
���Descricao � Verifica se existe anexos na tabela SC1                    ���
���          � Criar campo virtual e informar no inicializador de browser ���
���          � IF(u_ANEXSC1(),'SIM','NAO')                                 ��
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function ANEXSC1()

Local _cChave := ''
Local _lRet   := .f.
//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//����������������������������������������������������������������������

_cChave := SC1->C1_FILIAL+SC1->C1_NUM+SC1->C1_ITEM+SC1->C1_ITEMGRD

_cquery:= "SELECT"
_cquery+=" AC9_CODENT"

_cquery+=" FROM "
_cquery+=  retsqlname("AC9")+" AC9"

_cquery+=" WHERE"
_cquery+=    " AC9.D_E_L_E_T_=' '"
_cquery+=" AND AC9_FILIAL='"+xfilial("AC9")+"'"
_cquery+=" AND AC9_ENTIDA='SE1'"
_cquery+=" AND AC9_CODENT='"+pad(_cchave,len(ac9->ac9_codent))+"'"

tcquery _cquery new alias "TMP1"

tmp1->(dbgotop())
if empty(tmp1->ac9_codent)
	_lret:=.f.
else
	_lret:=.t.
endif
tmp1->(dbclosearea())

Return(_lRet)
