/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �MTA103MNU  �Autor  �Pedro Paulo        � Data �  04/10/13   ���
�������������������������������������������������������������������������͹��
���Desc.     � PE para inclusao de botao no aRotina.                      ���
���          �                                                            ���
���	   		 �               											  ���
�������������������������������������������������������������������������͹��
���Uso       � TBC                                                        ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User function MTA103MNU
    
    if EXISTBLOCK('PREDANFE')
        Aadd(aRotina,{'Pr� Danfe','U_PreDanfe(2)', 0, 4, 0, NIL})
    ENDIF    

Return 