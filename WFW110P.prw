#include "rwmake.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �WFW120P   �Autor  �Sangelles Moraes    � Data �  27/03/2013 ���
�������������������������������������������������������������������������͹��
���Desc.     �Ponto de entrada para envio de Workflow na apos confirmacao ���
���          � da solicitacao de Compra                                	  ���
�������������������������������������������������������������������������͹��
���Uso       � celerador Totvs Goias                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User function WFW110P( nOpcao, oProcess )
	U_ACOMP007(nOpcao, oProcess) //chamada do Acelerador Totvs (Fonte exclusivo TOTVS Goi�s)
RETURN .T.