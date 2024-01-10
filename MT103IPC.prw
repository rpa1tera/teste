/*
__________________________________________________________________________
�����������������������������������������������������������������������������
��+-----------------------------------------------------------------------+��
���Programa  � MT103IPC   � Autor � Totvs   � Data � 	          25/08/10���
��+----------+------------------------------------------------------------���
���Descri��o � Ponto de Entrada na confirma��o da sele�ao do PC usado para���
���          � atualizar os campos customizados no Documento de Entrada e ���
���          � na Pr� Nota de Entrada ap�s a importa��o dos itens do PC.  ���
��+----------+------------------------------------------------------------���
��� Uso      � Gravar a descri��o do produto na tabela SD1                ���
��+----------+------------------------------------------------------------���
��� Revisado � Por Jacqueline C�ndida                   � Data � 24/09/10 ���
��+-----------------------------------------------------------------------+��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User Function MT103IPC()      

Local nI 

For nI := 1 to len(acols)
	nPosDescri:=aScan(aHeader,{ |x| Upper(AllTrim(x[2])) == "D1_XDESCRI" })
	nPosCodigo:=aScan(aHeader,{ |x| Upper(AllTrim(x[2])) == "D1_COD" })
	Acols[nI,nPosDescri]:=SB1->(POSICIONE("SB1",1,xFilial("SB1")+Acols[nI,nPosCodigo],"B1_DESC"))                                                                                
Next nI

Return (.T.)
