

User Function M110STTS() 
Local cNumSol	:= Paramixb[1]
Local nOpt		:= Paramixb[2]

If  (nOpt == 1 .or. nOpt == 2)         

	U_ACOMP007()// Chama acelerador TOTVS-GO -  Deixar sempre ap�s todas as valida��es.
	
Endif


Return Nil